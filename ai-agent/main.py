"""Woofed CRM AI agent — agno + Woofed MCP (Streamable HTTP).

Run: `uv run main.py` (or via `bin/dev` → `agent-ai` process).

Required env vars (loaded from .env):
- WOOFED_MCP_URL    URL of the MCP endpoint (e.g. http://localhost:3000/mcp)
- WOOFED_MCP_TOKEN  Doorkeeper opaque access token with scope `mcp` and
                    `resource: <base_url>/mcp`. See docs/mcp/authentication.md
                    for how to mint one via the Rails console.
- GROQ_API_KEY      Used by the Groq chat model.
"""

import os

from agno.agent import Agent
from agno.models.groq import Groq
from agno.os import AgentOS
from agno.tools.mcp import MCPTools, StreamableHTTPClientParams
from dotenv import load_dotenv
from fastapi.middleware.cors import CORSMiddleware

load_dotenv()

WOOFED_MCP_URL = os.environ["WOOFED_MCP_URL"]
WOOFED_MCP_TOKEN = os.environ["WOOFED_MCP_TOKEN"]

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
    "Operating principles:",
    "- Prefer the MCP tools over guessing. If a request needs CRM data, call a",
    "  tool — do not invent IDs, names, stages, pipelines, or users.",
    "- For lookups, start with the *_list tools (with filters) and narrow down.",
    "  For full details of one record, prefer the matching resource URI",
    "  (woofed:///contacts/{id}, /deals/{id}, /pipelines/{id}, /products/{id},",
    "  /users/{id}) — it returns the record plus its associations in one call.",
    "- Before any mutation (create/update/mark_won/mark_lost/add_*/remove_*),",
    "  confirm you have the right target. If the user gave a name, resolve it",
    "  to an ID via the appropriate *_list tool first.",
    "- When creating a deal you typically need a contact_id and a stage_id;",
    "  use contacts_list and stages_list (or pipelines_list) to resolve them.",
    "- For sending messages (events_send_chatwoot_message,",
    "  events_send_whatsapp_message) first list the available integrations",
    "  (apps_chatwoots_list, apps_evolution_apis_list) and pick the right one.",
    "- Render list results as concise markdown tables. Keep columns relevant to",
    "  the question (id, name, stage, value, updated_at — not every field).",
    "- If a tool returns an error, surface the message plainly and suggest the",
    "  next step (e.g. fix the validation, look up the missing id).",
    "- Reply in the same language the user wrote in.",
]

woofed_agent = Agent(
    name="Woofed CRM Agent",
    description="AI agent that operates Woofed CRM through the MCP server.",
    model=Groq(id="llama-3.3-70b-versatile"),
    tools=[woofed_mcp],
    instructions=INSTRUCTIONS,
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
