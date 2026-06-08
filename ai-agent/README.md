# Woofed CRM AI agent

An [agno](https://github.com/agno-agi/agno) agent that operates the Woofed CRM through the [Woofed MCP server](../docs/mcp/readme.md). The agent uses every tool and resource exposed by `/mcp` (contacts, deals, pipelines, stages, products, events, app integrations, users).

Stack: Python 3.12, agno ≥ 2.6, [`MCPTools`](https://docs.agno.com/) over the MCP Streamable HTTP transport, dynamic chat model picked from `Apps::AiAssistent` (OpenAI / Anthropic / Gemini), AgentOS (FastAPI) for the HTTP surface, and the bundled [Agent UI](./agent-ui) (Next.js) for chat.

> 🏗️ **Architecture & lifecycle:** see [docs/ai-agent/architecture.md](../docs/ai-agent/architecture.md) — boot sequence, degraded mode, LISTEN/NOTIFY restart trigger, per-environment supervisor requirements.

## How it connects

```
agent-ui (Next.js, :3001)
        │
        ▼
AgentOS / FastAPI (:7777)   ← main.py
        │
        ▼  Streamable HTTP — Bearer <opaque token>
Woofed CRM /mcp (Rails, :3000)
```

`MCPTools(url=..., transport="streamable-http", headers={"Authorization": ...})` is registered as a tool on the Woofed agent. AgentOS's built-in `mcp_lifespan` calls `connect()` on startup and `close()` on shutdown, so the agent already has the tool list when the first request comes in.

## Setup

1. Install the runtime (`uv` + Python 3.12 from `mise.toml`):

    ```bash
    mise install
    uv sync
    ```

2. Run pending Rails migrations to backfill Woofed AI tokens for existing users:

    ```bash
    bin/rails db:migrate
    ```

    The migration mints one Doorkeeper access token (scope `mcp`, `resource: <FRONTEND_URL>/mcp`) per existing user. Going forward, `User::WoofedAiToken` (an `after_create` concern) mints a token automatically when a new user signs up.

3. Make sure `FRONTEND_URL` and `DATABASE_URL` are set in the repo-root `.env` (they already are in this project):

    ```
    FRONTEND_URL=http://localhost:3000
    DATABASE_URL=postgres://postgres:password@localhost/
    ```

    `FRONTEND_URL` is the public URL of the Rails app — the agent builds `<FRONTEND_URL>/mcp` for the MCP endpoint, and Rails binds each user's token to that exact URL via RFC 8707.

4. The model and api_key come from the **`Apps::AiAssistent`** row in Rails (Settings → AI Assistant). Enable it, paste an OpenAI / Anthropic / Gemini key, save. The agent restarts automatically (LISTEN/NOTIFY) and picks up the new config.

## Run

The repository's `Procfile.dev` already wires the agent and the UI:

```bash
bin/dev
# web        → Rails on :3000
# agent-ai   → AgentOS on :7777
# agent-ai-ui→ Next.js chat on :3001
```

Standalone:

```bash
cd ai-agent
uv run main.py            # AgentOS on http://localhost:7777
cd agent-ui && npm run dev  # UI on http://localhost:3001
```

Open the UI, point it at `http://localhost:7777`, pick **Woofed CRM Agent**, and chat. Tool calls and their results are rendered inline.

## What the agent can do

The agent has the full Woofed MCP surface — see [`docs/mcp/readme.md`](../docs/mcp/readme.md) for the canonical list. Sample prompts:

- "Liste os últimos 10 contatos criados."
- "Crie um deal para o contato 'Maria Silva' no stage 'Qualificação' do pipeline padrão, valor R$ 5.000."
- "Marque o deal 142 como ganho."
- "Adicione uma nota no deal 87: 'cliente pediu para retomar em junho'."
- "Envie um WhatsApp para o contato 42 dizendo que o orçamento foi aprovado."

The agent resolves names → IDs through the `*_list` tools before mutating, and uses the resource URIs (`woofed:///deals/{id}` etc.) when it needs the full record with associations in one call.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `401 invalid_token` on every call | The user's token `resource` ≠ `<FRONTEND_URL>/mcp`. Re-mint by destroying the old token and re-creating the user, or update the `resource` column directly. |
| `401 Unauthorized` on every call | The user has no active Woofed AI token (migration didn't run, or token was revoked). Run `bin/rails db:migrate`. |
| `RuntimeError: No Woofed AI token available` | No user exists in the DB, so the fallback finds nothing. Create at least one user. |
| `connect` hangs at startup | Rails is not running, or `FRONTEND_URL` points at the wrong host/port. |

To list a user's active Woofed AI tokens:

```ruby
user.access_tokens.where(revoked_at: nil).joins(:application).where(oauth_applications: { name: 'Woofed AI' })
```

To revoke one: `Doorkeeper::AccessToken.by_token('...').revoke!`.
