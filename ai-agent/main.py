"""Woofed CRM AI agent — agno + Woofed MCP (Streamable HTTP).

Run: `uv run main.py` (or via `bin/dev` → `agent-ai` process).

Required env vars:
- FRONTEND_URL      Base URL of the Rails app. The MCP endpoint is built as
                    `<FRONTEND_URL>/mcp`. Also used by Rails to bind the
                    user's MCP token via RFC 8707, so this must match the
                    public URL where /mcp is served.
- DATABASE_URL      Reused from the Rails app. The agent stores sessions in
                    the same Postgres (under `agno_*` tables) and also reads
                    `apps_ai_assistents` (model/api_key) and
                    `oauth_access_tokens` (per-user MCP token).
- RAILS_ENV         Optional; defaults to `development`. Mirrors how Rails
                    derives the database name from DATABASE_URL.

The MCP bearer token is NOT read from env. Each user has their own Doorkeeper
access token (minted by User::WoofedAiTokenMinter on create + backfilled by
db/migrate/...backfill_woofed_ai_tokens_for_users.rb). API callers send it as
`X-Woofed-AI-Token: <token>`. The bundled agent-ui doesn't send one, so the
agent falls back to the first user's token.

The chat model and API key come from the Rails `Apps::AiAssistent` row. If no
usable row exists the agent starts in degraded mode (process up, no agent
registered). When the row is created/updated/deleted, a Postgres NOTIFY (sent
by an after_commit callback in the Rails model) makes the listener restart
the process so the new config is picked up.
"""

from __future__ import annotations

import logging
import os
from contextlib import asynccontextmanager
from contextvars import ContextVar
from pathlib import Path
from typing import Any, Optional

from agno.agent import Agent
from agno.db.postgres import PostgresDb
from agno.os import AgentOS
from agno.tools.mcp import MCPTools, StreamableHTTPClientParams
from dotenv import load_dotenv
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from agent_config import AssistantConfig, try_load_assistant_config
from db_listener import start_listener_task

# Load ai-agent/.env (override=True so empty values from the repo-root .env
# exported by overmind/foreman don't shadow the real ones).
load_dotenv(override=True)
# Also load the repo-root .env so DATABASE_URL is available when running
# `uv run main.py` standalone (overmind already exports it).
load_dotenv(Path(__file__).resolve().parent.parent / ".env")

log = logging.getLogger("woofed-agent")
logging.basicConfig(level=logging.INFO, format="[%(name)s] %(levelname)s %(message)s")


def _build_agent_db_url() -> str:
    """Mirror Rails' config/database.yml resolution for DATABASE_URL.

    - production: DATABASE_URL already carries the database name → use as-is.
    - dev/test:   DATABASE_URL is just `postgres://user:pw@host/`; Rails
                  appends `woofed_crm_<env>`. We do the same here.

    SQLAlchemy dropped the `postgres://` alias, so we rewrite the scheme to
    `postgresql+psycopg://` (psycopg3 driver).
    """
    raw = os.environ["DATABASE_URL"]
    rails_env = os.environ.get("RAILS_ENV", "development")
    if rails_env != "production":
        raw = f"{raw.rstrip('/')}/woofed_crm_{rails_env}"
    if raw.startswith("postgres://"):
        raw = "postgresql+psycopg://" + raw[len("postgres://") :]
    elif raw.startswith("postgresql://"):
        raw = "postgresql+psycopg://" + raw[len("postgresql://") :]
    return raw


AGENT_DB_URL = _build_agent_db_url()
WOOFED_MCP_URL = os.environ["FRONTEND_URL"].rstrip("/") + "/mcp"

agent_db = PostgresDb(db_url=AGENT_DB_URL)

# Per-request token, set by `extract_woofed_ai_token` middleware and read by
# `mcp_header_provider`. asyncio tasks created inside the request handler
# (including the agent run) inherit this context.
_request_token_var: ContextVar[Optional[str]] = ContextVar("woofed_ai_token", default=None)


def _first_user_token() -> Optional[str]:
    """Fallback for agent-ui (no auth header): the first user's MCP token."""
    sql = text(
        """
        SELECT t.token
        FROM oauth_access_tokens t
        JOIN oauth_applications a ON a.id = t.application_id
        WHERE a.name = 'Woofed AI'
          AND t.scopes LIKE '%mcp%'
          AND t.revoked_at IS NULL
        ORDER BY t.resource_owner_id ASC
        LIMIT 1
        """
    )
    with agent_db.db_engine.connect() as conn:
        row = conn.execute(sql).fetchone()
    return row[0] if row else None


def mcp_header_provider(**_kwargs: Any) -> dict[str, str]:
    """Build the Authorization header for each MCP session.

    Per-run: agno calls this when it creates a fresh MCP session for the
    current agent run. We resolve the token in this order:
      1. `X-Woofed-AI-Token` header on the inbound request (third-party API).
      2. First user's MCP token (agent-ui fallback).
    """
    token = _request_token_var.get() or _first_user_token()
    if not token:
        raise RuntimeError(
            "No Woofed AI token available. Either send X-Woofed-AI-Token, or "
            "ensure at least one User exists (User::WoofedAiTokenMinter mints "
            "one on create)."
        )
    return {"Authorization": f"Bearer {token}"}


def _build_model(cfg: AssistantConfig):
    """Construct the right agno model class for the configured provider."""
    if cfg.provider == "openai":
        from agno.models.openai import OpenAIChat
        return OpenAIChat(id=cfg.model, api_key=cfg.api_key)
    if cfg.provider == "anthropic":
        from agno.models.anthropic import Claude
        return Claude(id=cfg.model, api_key=cfg.api_key)
    if cfg.provider == "google":
        from agno.models.google import Gemini
        return Gemini(id=cfg.model, api_key=cfg.api_key)
    raise RuntimeError(f"Unsupported provider: {cfg.provider!r}")


INSTRUCTIONS = [
    "You are the Woofed CRM assistant. You operate the user's CRM through the",
    "Woofed MCP server: contacts, deals, pipelines, stages, products, events,",
    "and app integrations (Chatwoot, Evolution API/WhatsApp).",
    "",
    "## Conversation context",
    "- Treat the conversation history as authoritative. If the user already",
    "  mentioned a contact, deal, pipeline, stage, product, or user — by name",
    "  or by id — REUSE that reference for every subsequent action in the same",
    "  conversation. Do NOT re-ask the user for it.",
    "- When a previous turn already resolved a name to an id via *_list, cache",
    "  that id mentally and reuse it for follow-up actions instead of calling",
    "  *_list again.",
    "- Only ask the user a clarifying question when the request is genuinely",
    "  ambiguous (e.g. two contacts named 'Yukio' exist, or the requested",
    "  stage name does not exist anywhere). Re-confirmation is not allowed.",
    "",
    "## Resolving names to ids",
    "- Always look up by name through the matching *_list tool, then use the",
    "  returned id for the mutation.",
    "- STAGES belong to PIPELINES. When the user names a stage (e.g.",
    "  'Prospectando'), search stages_list across ALL pipelines and pick the",
    "  stage whose name matches exactly (case-insensitive). NEVER fall back to",
    "  the first stage of a different pipeline. If no stage matches, ask the",
    "  user — do not silently pick something else.",
    "- If multiple records match (e.g. two contacts), present the candidates",
    "  with their ids and ask which one. Do not pick arbitrarily.",
    "",
    "## Tool usage",
    "- For lookups, start with the *_list tools (with filters) and narrow down.",
    "  For full details of one record, prefer the matching resource URI",
    "  (woofed:///contacts/{id}, /deals/{id}, /pipelines/{id}, /products/{id},",
    "  /users/{id}) — it returns the record plus its associations in one call.",
    "- For sending messages (events_send_chatwoot_message,",
    "  events_send_whatsapp_message) first list the available integrations",
    "  (apps_chatwoots_list, apps_evolution_apis_list) and pick the right one.",
    "- Dates from the user (e.g. 'amanhã', 'segunda que vem às 22h') must be",
    "  converted to ISO 8601 in the user's local timezone before the tool call.",
    "  Assume America/Sao_Paulo unless the user states otherwise.",
    "",
    "## Output",
    "- Render list results as concise markdown tables. Keep columns relevant to",
    "  the question (id, name, stage, value, updated_at — not every field).",
    "- If a tool returns an error, surface the message plainly and suggest the",
    "  next step (e.g. fix the validation, look up the missing id).",
    "- Reply in the same language the user wrote in.",
]


def _build_agent(cfg: AssistantConfig) -> Agent:
    woofed_mcp = MCPTools(
        transport="streamable-http",
        server_params=StreamableHTTPClientParams(url=WOOFED_MCP_URL),
        header_provider=mcp_header_provider,
        timeout_seconds=60,
    )
    return Agent(
        name="Woofed CRM Agent",
        description="AI agent that operates Woofed CRM through the MCP server.",
        model=_build_model(cfg),
        db=agent_db,
        tools=[woofed_mcp],
        instructions=INSTRUCTIONS,
        add_history_to_context=True,
        num_history_runs=20,
        markdown=True,
    )


# --- Boot: load config, decide degraded vs normal mode --------------------------

assistant: Optional[AssistantConfig] = try_load_assistant_config(agent_db.db_engine)

if assistant is None:
    log.warning(
        "No usable Apps::AiAssistent found — starting in DEGRADED MODE. "
        "The agent is not registered; chat will be unavailable until you "
        "create/enable an Apps::AiAssistent in Rails (Settings → AI Assistant)."
    )
    agents = []
else:
    log.info(
        "Loaded Apps::AiAssistent — provider=%s model=%s",
        assistant.provider, assistant.model,
    )
    agents = [_build_agent(assistant)]


@asynccontextmanager
async def listener_lifespan(_app: FastAPI):
    """Start the Postgres LISTEN task while the app is up."""
    task = start_listener_task(AGENT_DB_URL)
    try:
        yield
    finally:
        task.cancel()
        try:
            await task
        except BaseException:  # noqa: BLE001 — shutdown path, swallow
            pass


agent_os = AgentOS(
    id="woofed-crm-os",
    description="Woofed CRM AgentOS — exposes the Woofed MCP through agno.",
    db=agent_db,
    agents=agents,
    lifespan=listener_lifespan,
)

app = agent_os.get_app()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def extract_woofed_ai_token(request: Request, call_next):
    """Capture the caller's Woofed AI token for `mcp_header_provider` to read.

    Third-party API clients send `X-Woofed-AI-Token: <token>`. The bundled
    agent-ui doesn't send anything, in which case the header_provider falls
    back to the first user's token.
    """
    token = request.headers.get("X-Woofed-AI-Token")
    if token:
        _request_token_var.set(token)
    return await call_next(request)

if __name__ == "__main__":
    agent_os.serve(app="main:app", reload=True)
