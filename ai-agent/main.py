"""Woofed CRM AI agent — agno + Woofed MCP (Streamable HTTP).

Run: `uv run main.py` (or via `bin/dev` → `agent-ai` process).

Required env vars:
- WOOFED_MCP_URL    URL of the MCP endpoint (e.g. http://localhost:3000/mcp)
- WOOFED_MCP_TOKEN  Doorkeeper opaque access token with scope `mcp` and
                    `resource: <base_url>/mcp`. See docs/mcp/authentication.md.
- OPENAI_API_KEY    Used by the OpenAI chat model.
- DATABASE_URL      Reused from the Rails app. The agent stores sessions and
                    memory in the same Postgres, under `agno_*` tables that
                    do not collide with Rails-managed tables.
- RAILS_ENV         Optional; defaults to `development`. Mirrors how Rails
                    derives the database name from DATABASE_URL.
"""

import os
from pathlib import Path

from agno.agent import Agent
from agno.db.postgres import PostgresDb
from agno.models.openai import OpenAIChat
from agno.os import AgentOS
from agno.tools.mcp import MCPTools, StreamableHTTPClientParams
from dotenv import load_dotenv
from fastapi.middleware.cors import CORSMiddleware

# Load ai-agent/.env (override=True so empty values from the repo-root .env
# exported by overmind/foreman don't shadow the real ones).
load_dotenv(override=True)
# Also load the repo-root .env so DATABASE_URL is available when running
# `uv run main.py` standalone (overmind already exports it; harmless either way).
load_dotenv(Path(__file__).resolve().parent.parent / ".env")


def _build_agent_db_url() -> str:
    """Mirror Rails' config/database.yml resolution for DATABASE_URL.

    - production: DATABASE_URL already carries the database name → use as-is.
    - dev/test:   DATABASE_URL is just `postgres://user:pw@host/`; Rails
                  appends `woofed_crm_<env>` (config/database.yml). We do
                  the same here.

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


WOOFED_MCP_URL = os.environ["WOOFED_MCP_URL"]
WOOFED_MCP_TOKEN = os.environ["WOOFED_MCP_TOKEN"]

agent_db = PostgresDb(db_url=_build_agent_db_url())

woofed_mcp = MCPTools(
    transport="streamable-http",
    server_params=StreamableHTTPClientParams(
        url=WOOFED_MCP_URL,
        headers={"Authorization": f"Bearer {WOOFED_MCP_TOKEN}"},
    ),
    timeout_seconds=60,
)

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

woofed_agent = Agent(
    name="Woofed CRM Agent",
    description="AI agent that operates Woofed CRM through the MCP server.",
    model=OpenAIChat(id="gpt-4.1-mini"),
    db=agent_db,
    tools=[woofed_mcp],
    instructions=INSTRUCTIONS,
    # Send the last N runs to the model so it remembers what was just discussed.
    # Without this, the model sees only the current user message — that's why
    # follow-ups like "create a deal for Yukio" used to lose context.
    add_history_to_context=True,
    num_history_runs=20,
    markdown=True,
)

agent_os = AgentOS(
    id="woofed-crm-os",
    description="Woofed CRM AgentOS — exposes the Woofed MCP through agno.",
    agents=[woofed_agent],
)

app = agent_os.get_app()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

if __name__ == "__main__":
    agent_os.serve(app="main:app", reload=True)
