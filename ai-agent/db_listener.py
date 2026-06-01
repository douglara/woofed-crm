"""Background task: LISTEN ai_assistent_changed and trigger an agent restart.

When `Apps::AiAssistent` is saved or destroyed in Rails, an `after_commit`
callback runs `NOTIFY ai_assistent_changed`. This listener picks up the
notification and:

1. `touch_trigger()` — bumps the mtime of `agent_config.py`. In dev with
   uvicorn `--reload`, that's enough; the worker is restarted in-place.
2. `os.kill(pid, SIGTERM)` — for prod (no --reload), exits the process so a
   supervisor (k8s, docker --restart, systemd Restart=always) brings up a
   fresh container, which then re-runs `try_load_assistant_config()`.

The listener uses a dedicated psycopg3 async connection (not the SQLAlchemy
engine) because LISTEN/NOTIFY needs a long-lived autocommit connection and we
don't want to pin one from the SQLAlchemy pool.
"""

from __future__ import annotations

import asyncio
import logging
import os
import signal

import psycopg

from agent_config import touch_trigger

log = logging.getLogger("woofed-agent.listener")

CHANNEL = "ai_assistent_changed"


def _to_psycopg_dsn(sqlalchemy_url: str) -> str:
    """Strip SQLAlchemy's `+psycopg` driver suffix; psycopg accepts the rest."""
    if sqlalchemy_url.startswith("postgresql+psycopg://"):
        return "postgresql://" + sqlalchemy_url[len("postgresql+psycopg://") :]
    return sqlalchemy_url


async def _listen_loop(dsn: str) -> None:
    """Open a connection, LISTEN, and react to the first notification.

    Reconnects on disconnect so a Postgres restart doesn't permanently disable
    the restart trigger.
    """
    while True:
        try:
            async with await psycopg.AsyncConnection.connect(dsn, autocommit=True) as conn:
                await conn.execute(f"LISTEN {CHANNEL}")
                log.info("Listening for Postgres NOTIFY on '%s'", CHANNEL)
                async for notify in conn.notifies():
                    log.info(
                        "NOTIFY %s received (pid=%s, payload=%r) — restarting agent",
                        notify.channel, notify.pid, notify.payload,
                    )
                    _trigger_restart()
                    return  # process will exit; nothing left to do
        except asyncio.CancelledError:
            raise
        except Exception:  # noqa: BLE001 — log and keep trying
            log.exception("LISTEN connection error; reconnecting in 5s")
            await asyncio.sleep(5)


def _trigger_restart() -> None:
    """Fire both restart mechanisms; whichever applies wins."""
    try:
        touch_trigger()
    except Exception:  # noqa: BLE001 — touch failing must not block SIGTERM
        log.exception("Failed to touch trigger file")
    # SIGTERM is the prod path (supervisor restarts the container). In dev with
    # uvicorn --reload the touch already triggered a reload; SIGTERM here is
    # redundant but harmless.
    os.kill(os.getpid(), signal.SIGTERM)


def start_listener_task(sqlalchemy_url: str) -> asyncio.Task:
    """Schedule the LISTEN loop on the running asyncio event loop."""
    dsn = _to_psycopg_dsn(sqlalchemy_url)
    return asyncio.create_task(_listen_loop(dsn), name="ai-assistent-listener")
