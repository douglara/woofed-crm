import logging
import os
from pydantic import BaseModel, Field
from agno.agent import Agent, AgentFactory
from agno.db.postgres import PostgresDb
from agno.factory import FactoryPermissionError, RequestContext
from agno.tools.mcp import MCPTools, StreamableHTTPClientParams
from agno.os import AgentOS

log = logging.getLogger("woofed-agent.listener")


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
    "- By default, answer in concise plain text, summarizing only the fields",
    "  relevant to the question (id, name, stage, value, updated_at — not every",
    "  field). The format is the user's choice: only use a markdown table (or",
    "  any other format) when the user asks for it.",
    "- If a tool returns an error, surface the message plainly and suggest the",
    "  next step (e.g. fix the validation, look up the missing id).",
    "- Reply in the same language the user wrote in.",
]

def _build_agent_model(model: str = "", api_key: str = ""):
    """Construct the right agno model class for the configured provider."""
    provider = _detect_provider(model)

    if provider == "openai":
        from agno.models.openai import OpenAIChat
        return OpenAIChat(id=model, api_key=api_key)

    if provider == "anthropic":
        from agno.models.anthropic import Claude
        return Claude(id=model, api_key=api_key)

    if provider == "google":
        from agno.models.google import Gemini
        return Gemini(id=model, api_key=api_key)

    if provider == "xai":
        from agno.models.xai import xAI
        return xAI(id=model, api_key=api_key)

    return None

def _mcp_header_provider(mcp_token: str = ''):
    """Build the Authorization header for each MCP session.
    """
    return {"Authorization": f"Bearer {mcp_token}"}

def _detect_provider(model: str = ""):
    """Map an `model` string to an agno provider name.

    The Rails form accepts free-text, so users enter things like `gpt-4o`,
    `gpt-3.5-turbo`, `claude-sonnet-4-5`, `gemini-2.5-flash`, `grok-4`. We
    classify by a substring unique to each family. Unknown models return
    `None` so the caller can reject them instead of guessing a provider.
    """
    m = model.lower()
    if any(tag in m for tag in ("claude", "sonnet", "opus", "haiku")):
        return "anthropic"
    if "gemini" in m:
        return "google"
    if "grok" in m:
        return "xai"
    if any(tag in m for tag in ("gpt", "o1", "o3", "o4", "chatgpt")):
        return "openai"
    return None

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

AGENT_DB_URL = os.environ["WOOFED_AI_DATABASE_URL"]
WOOFED_MCP_URL = os.environ["FRONTEND_URL"].rstrip("/") + "/mcp"

db = PostgresDb(db_url=AGENT_DB_URL)

# ---------------------------------------------------------------------------
# Input schema
# ---------------------------------------------------------------------------

class AgentFactoryInput(BaseModel):
    """Schema for factory_input -- validated by AgentOS before the factory runs."""
    mcp_token: str = Field(..., description="MCP token for authentication")
    llm_token: str = Field(..., description="LLM token for authentication")
    llm_model: str = Field(..., description="LLM model to use")

# ---------------------------------------------------------------------------
# Factory: build a per-tenant agent
# ---------------------------------------------------------------------------


def build_tenant_agent(ctx: RequestContext) -> Agent:
    """Called on every request. Returns a fresh Agent for the calling tenant."""
    cfg: AgentFactoryInput = ctx.input

    agent_model = _build_agent_model(cfg.llm_model, cfg.llm_token)

    if not agent_model:
        raise FactoryPermissionError("model is invalid")


    woofed_mcp = MCPTools(
      transport="streamable-http",
      server_params=StreamableHTTPClientParams(url=WOOFED_MCP_URL),
      header_provider=lambda: {
        "Authorization": f"Bearer {cfg.mcp_token}"
    },
      timeout_seconds=60,
    )

    return Agent(
      name="Woofed CRM Agent",
      description="AI agent that operates Woofed CRM through the MCP server.",
      model=agent_model,
      db=db,
      tools=[woofed_mcp],
      instructions=INSTRUCTIONS,
      add_history_to_context=True,
      num_history_runs=20,
      markdown=True,
    )


tenant_factory = AgentFactory(
    db=db,
    id="woofed-ai-agent",
    name="Woofed CRM Agent",
    description="AI agent that operates Woofed CRM through the MCP server.",
    factory=build_tenant_agent,
    input_schema=AgentFactoryInput
)

# ---------------------------------------------------------------------------
# AgentOS -- factories and prototypes coexist
# ---------------------------------------------------------------------------

agent_os = AgentOS(
    id="woofed-crm-os",
    description="Woofed CRM AgentOS — exposes the Woofed MCP through agno.",
    db=db,
    agents=[tenant_factory]
)

app = agent_os.get_app()
if __name__ == "__main__":
    agent_os.serve(app="main:app", port=7777, reload=True)
