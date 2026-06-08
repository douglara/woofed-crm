# AI agent — architecture

The Woofed AI agent is a Python service ([AgentOS](https://docs.agno.com/) / FastAPI + [agno](https://github.com/agno-agi/agno)) that wraps the [Woofed MCP](../mcp/readme.md). It is **multi-tenant and stateless about configuration**: it holds no model, api key, or MCP token at boot. Every request carries its own configuration in a `factory_input` payload, and an [`AgentFactory`](https://docs.agno.com/) builds a fresh agent for that caller on the spot.

This document explains how a run is served, where the model / tokens come from, and how the factory isolates one tenant's request from another's.

---

## Table of contents

1. [High-level flow](#high-level-flow)
2. [Components](#components)
3. [Calling the agent](#calling-the-agent)
4. [`factory_input` schema](#factory_input-schema)
5. [Run sequence](#run-sequence)
6. [Provider detection](#provider-detection)
7. [API authorization](#api-authorization)
8. [MCP authentication](#mcp-authentication)
9. [Configuration](#configuration)
10. [File layout](#file-layout)
11. [Related documents](#related-documents)

---

## High-level flow

```mermaid
flowchart LR
    subgraph Caller
        C[Rails / third-party / agent-ui<br/>POST /agents/woofed-ai-agent/runs]
    end

    subgraph "Python process (ai-agent/)"
        AOS[AgentOS / FastAPI<br/>:7777]
        FAC[AgentFactory<br/>build_tenant_agent per request]
        AG[agno Agent<br/>model + MCPTools]
        AOS --> FAC
        FAC --> AG
    end

    subgraph "Rails (web)"
        MCP[McpController<br/>POST /mcp]
    end

    subgraph "PostgreSQL (agent DB)"
        T[(agno_sessions, agno_memories, …)]
    end

    C -->|message + factory_input| AOS
    AG -->|Bearer mcp_token<br/>Streamable HTTP| MCP
    AOS -->|sessions/history| T
```

The only Postgres database the agent touches is its **own** session store (`WOOFED_AI_DATABASE_URL`). All tenant-specific configuration — which model, which LLM key, which MCP token — is supplied by the caller per request through `factory_input`.

---

## Components

All of these live in a single file, [ai-agent/main.py](../../ai-agent/main.py):

| Component | Role |
|---|---|
| `AgentFactoryInput` | Pydantic schema for `factory_input`. AgentOS validates the payload against it **before** the factory runs, so an invalid/incomplete config is rejected early. Fields: `mcp_token`, `llm_token`, `llm_model`. |
| `build_tenant_agent(ctx)` | The factory function. Called on **every** request. Reads `ctx.input` (the validated `AgentFactoryInput`), builds the model, wires up `MCPTools` with the caller's token, and returns a fresh `Agent`. |
| `AgentFactory` | Registers `build_tenant_agent` under id `woofed-ai-agent`, with `input_schema=AgentFactoryInput`. This is what turns a normally single-instance agent into a per-request factory. |
| `_build_agent_model(model, api_key)` | Maps a model string to the right agno model class (`OpenAIChat` / `Claude` / `Gemini` / `xAI`) and instantiates it with the caller's `llm_token`. Returns `None` for an unknown provider. |
| `_detect_provider(model)` | Classifies a free-text model string into a provider by substring. Returns `None` when nothing matches. |
| `AgentOS` | The FastAPI surface (id `woofed-crm-os`). Holds the agent DB and the registered factory; `agent_os.get_app()` produces the ASGI app served on `:7777`. |

---

## Calling the agent

A run is a standard AgentOS `POST .../runs` call. The configuration travels as a `factory_input` form field containing a JSON object:

```bash
curl -X POST http://localhost:7777/agents/woofed-ai-agent/runs \
  -H "Authorization: Bearer $OS_SECURITY_KEY" \
  -F "message=Create a contact named Yukio" \
  -F "user_id=USER_ID" \
  -F "session_id=SESSION_ID" \
  -F 'factory_input={"mcp_token":"MCP_TOKEN","llm_token":"LLM_TOKEN","llm_model":"LLM_MODEL"}'
```

| Part | Meaning |
|---|---|
| `Authorization: Bearer $OS_SECURITY_KEY` | The static API token (the `OS_SECURITY_KEY` secret, verbatim). Gates **every** call — see [API authorization](#api-authorization). Without it the request is rejected with `401`. |
| `message` | The user's prompt. |
| `user_id` | Identifies the tenant/user for agno session ownership. |
| `session_id` | Conversation id. Reusing it keeps the history (see [Run sequence](#run-sequence) — `add_history_to_context` replays up to 20 prior runs). |
| `factory_input` | JSON object validated against `AgentFactoryInput`. Drives which model the agent uses and which Bearer token it presents to `/mcp`. |

Note the two distinct tokens: the **`Authorization` Bearer token** (`OS_SECURITY_KEY`) authenticates the caller *to the agent API*, while **`factory_input.mcp_token`** is what the agent later presents *to the Rails `/mcp` server*. They are unrelated and serve different hops.

Because every field that used to be global is now per-request, two callers can hit the same process with different models and different MCP tokens at the same time, fully isolated.

---

## `factory_input` schema

```python
class AgentFactoryInput(BaseModel):
    mcp_token: str   # Bearer token for the Woofed MCP server (per-user Doorkeeper token)
    llm_token: str   # API key for the LLM provider
    llm_model: str   # free-text model name, e.g. "claude-sonnet-4-5", "gpt-4o", "grok-4"
```

- All three fields are **required**. AgentOS rejects a request with a missing or wrongly-typed field before `build_tenant_agent` is ever called.
- `llm_model` is free text. It is classified into a provider by [`_detect_provider`](#provider-detection). If it matches no known provider, `_build_agent_model` returns `None` and the factory raises `FactoryPermissionError("model is invalid")` — the run fails with a clear permission error instead of silently guessing.

---

## Run sequence

```mermaid
sequenceDiagram
    autonumber
    participant C as Caller
    participant AOS as AgentOS / FastAPI
    participant Sch as AgentFactoryInput
    participant Fac as build_tenant_agent
    participant M as _build_agent_model
    participant MCP as MCPTools → Rails /mcp
    participant DB as Agent Postgres

    C->>AOS: POST /agents/woofed-ai-agent/runs<br/>message + factory_input
    AOS->>Sch: validate factory_input
    alt invalid payload
        Sch-->>C: 4xx validation error
    else valid
        AOS->>Fac: build_tenant_agent(ctx)  (ctx.input = AgentFactoryInput)
        Fac->>M: _build_agent_model(llm_model, llm_token)
        alt unknown provider
            M-->>Fac: None
            Fac-->>C: FactoryPermissionError "model is invalid"
        else known provider
            M-->>Fac: OpenAIChat / Claude / Gemini / xAI
            Fac->>Fac: MCPTools(header_provider → Bearer mcp_token)
            Fac-->>AOS: fresh Agent (history=20, markdown)
            AOS->>DB: load/persist session (user_id, session_id)
            AOS->>MCP: tool calls with Bearer mcp_token
            MCP-->>AOS: tool results
            AOS-->>C: agent response
        end
    end
```

The agent is built with `add_history_to_context=True` and `num_history_runs=20`, so reusing a `session_id` replays the last 20 runs of that conversation from the agent's own Postgres store — the model resolves names → ids from earlier turns without re-asking (see the `INSTRUCTIONS` block in `main.py`).

---

## Provider detection

`llm_model` is free text, so the agent classifies it heuristically in `_detect_provider`. The match is case-insensitive and based on a substring unique to each family. **Unknown models are rejected** (no default provider).

| Substring (case-insensitive) | Provider | agno class | Examples |
|---|---|---|---|
| `claude`, `sonnet`, `opus`, `haiku` | `anthropic` | `agno.models.anthropic.Claude` | `claude-sonnet-4-5`, `claude-opus-4-1` |
| `gemini` | `google` | `agno.models.google.Gemini` | `gemini-2.5-flash`, `gemini-1.5-pro` |
| `grok` | `xai` | `agno.models.xai.xAI` | `grok-4`, `grok-3-mini` |
| `gpt`, `o1`, `o3`, `o4`, `chatgpt` | `openai` | `agno.models.openai.OpenAIChat` | `gpt-4o`, `gpt-3.5-turbo`, `o1-mini`, `o3-mini` |
| anything else | — | — (returns `None`) | run fails with `FactoryPermissionError` |

To add a provider: extend both `_detect_provider()` and `_build_agent_model()` in [main.py](../../ai-agent/main.py), and add the SDK to [pyproject.toml](../../ai-agent/pyproject.toml).

---

## API authorization

The agno API uses agno's **basic authentication** (a single static bearer token), enabled simply by setting the `OS_SECURITY_KEY` environment variable — no constructor arguments, no JWT. AgentOS reads it automatically:

```python
# main.py — no authorization config; agno picks up OS_SECURITY_KEY from the env
agent_os = AgentOS(
    id="woofed-crm-os",
    description="…",
    db=db,
    agents=[tenant_factory],
)
```

```bash
# repo-root .env
OS_SECURITY_KEY=a-long-random-secret
```

When `OS_SECURITY_KEY` is set, every route requires `Authorization: Bearer <OS_SECURITY_KEY>` and returns `401 Unauthorized` otherwise. The token is the key **verbatim** — it is not a JWT, carries no claims, scopes, or `sub`, and never expires. The caller simply echoes back the shared secret.

| Condition | Result |
|---|---|
| Header matches `OS_SECURITY_KEY` | request proceeds |
| Header missing | `401` "Authorization header required" |
| Header present but wrong | `401` "Invalid authentication token" |

The unauthenticated routes are the agno defaults: `/`, `/health`, `/info`, `/docs`, `/redoc`, `/openapi.json`.

> **Note:** agno documents basic auth as "simple key validation for development". If this service is ever exposed publicly, switch to agno's JWT/RBAC mode (`authorization=True` + `AuthorizationConfig`) for per-caller scopes. See the [agno security docs](https://docs.agno.com/agent-os/security/overview).

---

## MCP authentication

The agent presents the Woofed MCP server a **per-request** Bearer token — the `mcp_token` from `factory_input`. The caller is responsible for sending the token of the user it is acting on behalf of.

Inside `build_tenant_agent`, `MCPTools` is given a `header_provider` closure that returns the Authorization header for each MCP session:

```python
woofed_mcp = MCPTools(
    transport="streamable-http",
    server_params=StreamableHTTPClientParams(url=WOOFED_MCP_URL),
    header_provider=lambda: {"Authorization": f"Bearer {cfg.mcp_token}"},
    timeout_seconds=60,
)
```

A `header_provider` (rather than static `headers={...}`) keeps the token bound to **this** request's agent instance. Since the factory builds a new agent — and a new closure capturing this caller's `cfg.mcp_token` — for every run, two concurrent callers never share a token.

### Where the token comes from

The `mcp_token` is a long-lived Doorkeeper access token (scope `mcp`, `resource: <FRONTEND_URL>/mcp`) minted on the Rails side, one per user, by the [`User::WoofedAiToken`](../../app/models/concerns/user/woofed_ai_token.rb) concern:

| Source | When it fires |
|---|---|
| `after_create :generate_woofed_ai_token` | Every time a new user is created (signup, console, factory). |
| Backfill migration | One-shot — mints a token for each pre-existing user. |

The Rails caller reads the acting user's token via `User#woofed_ai_token` and passes it through as `factory_input.mcp_token`:

```ruby
# app/models/concerns/user/woofed_ai_token.rb
def woofed_ai_token
  access_tokens
    .where(revoked_at: nil)
    .joins(:application)
    .find_by(oauth_applications: { name: WOOFED_AI_APP_NAME })
    &.token
end
```

It returns the active token for the `'Woofed AI'` Doorkeeper application (skipping revoked tokens and tokens minted for any other application), or `nil` when the user has none. The MCP server validates this Bearer token on each `/mcp` call exactly as documented in [MCP authentication](../mcp/authentication.md).

---

## Configuration

The agent reads these environment variables (from the repo-root `.env`):

| Variable | Used for | Example |
|---|---|---|
| `WOOFED_AI_DATABASE_URL` | The agent's **own** Postgres (agno sessions, memories). Not the Rails DB. | `postgresql+psycopg://postgres:password@localhost/` |
| `FRONTEND_URL` | Public URL of the Rails app. The MCP endpoint is built as `<FRONTEND_URL>/mcp`. | `http://localhost:3000` |
| `OS_SECURITY_KEY` | Static bearer token the API caller must send (agno basic auth — see [API authorization](#api-authorization)). When unset, the API is **open**. | a long random string |

`WOOFED_AI_URL` (e.g. `http://localhost:7777`) is the address **callers** use to reach the agent; the agent itself doesn't read it. Everything else that drives a run (model, LLM key, MCP token) arrives per request in `factory_input` — the Rails caller assembles it from the `Apps::AiAssistent` row (`model` / `api_key`) and the user's `woofed_ai_token`.

---

## File layout

```
woofed-crm/
├── ai-agent/
│   ├── main.py            ← AgentFactory, model builder, provider detection, AgentOS
│   ├── pyproject.toml     ← agno, mcp, openai, anthropic, google-genai, groq, psycopg, sqlalchemy
│   ├── agent-ui/          ← bundled Next.js chat UI
│   └── .env               ← provider sandbox keys (agent reads FRONTEND_URL + WOOFED_AI_DATABASE_URL from repo-root .env)
├── app/models/concerns/user/
│   └── woofed_ai_token.rb ← mints + exposes the per-user MCP token (User#woofed_ai_token)
└── docs/
    ├── ai-agent/
    │   └── architecture.md  ← this file
    └── mcp/                  ← Woofed MCP server docs
```

---

## Related documents

- 🧰 [MCP architecture](../mcp/architecture.md) — how `/mcp` is structured on the Rails side
- 🔐 [MCP authentication](../mcp/authentication.md) — minting the Bearer token passed as `factory_input.mcp_token`
- 📋 [Agent README](../../ai-agent/README.md) — quickstart and how to run the agent + UI
