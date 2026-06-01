"""Loads the active AI assistant from the Rails `apps_ai_assistents` table.

Degraded mode: if no usable assistant is configured, `try_load_assistant_config`
returns None instead of raising. main.py then starts the agent server in a
"no-model" state — the chat is disabled but the process stays up so the
LISTEN/NOTIFY restart trigger can fire when the user creates one.

The same restart trigger also covers updates (e.g. changing the api_key or
swapping providers) and deletions (the next process boots in degraded mode).
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from sqlalchemy import text
from sqlalchemy.engine import Engine


@dataclass(frozen=True)
class AssistantConfig:
    """Snapshot of the Apps::AiAssistent row used to build the agno model."""

    provider: str  # "openai" | "anthropic" | "google"
    model: str
    api_key: str


def _detect_provider(model: str) -> str:
    """Map an `Apps::AiAssistent.model` string to an agno provider name.

    The Rails form accepts free-text, so users enter things like `gpt-4o`,
    `gpt-3.5-turbo`, `claude-sonnet-4-5`, `gemini-2.5-flash`. We classify by
    a substring unique to each family.
    """
    m = model.lower()
    if any(tag in m for tag in ("claude", "sonnet", "opus", "haiku")):
        return "anthropic"
    if "gemini" in m:
        return "google"
    # OpenAI catches gpt-*, o1-*, o3-*, etc. — the default family.
    return "openai"


def try_load_assistant_config(engine: Engine) -> Optional[AssistantConfig]:
    """Return the active assistant config, or None if not usable.

    Returns None (instead of raising) so the agent can run in degraded mode
    until the user creates / enables / fills an Apps::AiAssistent row.
    """
    sql = text(
        "SELECT model, api_key, enabled FROM apps_ai_assistents ORDER BY id LIMIT 1"
    )
    with engine.connect() as conn:
        row = conn.execute(sql).fetchone()

    if row is None:
        return None
    model, api_key, enabled = row
    if not enabled or not api_key or not model:
        return None
    return AssistantConfig(provider=_detect_provider(model), model=model, api_key=api_key)


TRIGGER_FILE = Path(__file__).resolve()


def touch_trigger() -> None:
    """Bump this file's mtime so uvicorn's reload watcher restarts the worker.

    In dev with `reload=True`, touching a watched .py file is enough. In prod
    (no --reload), main.py also sends SIGTERM to the process so the supervisor
    (k8s, docker, systemd, …) brings it back up.
    """
    TRIGGER_FILE.touch()
