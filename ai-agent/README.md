# Woofed CRM AI agent

An [agno](https://github.com/agno-agi/agno) agent that operates the Woofed CRM through the [Woofed MCP server](../docs/mcp/readme.md). The agent uses every tool and resource exposed by `/mcp` (contacts, deals, pipelines, stages, products, events, app integrations, users).

Stack: Python 3.12, agno ≥ 2.6, [`MCPTools`](https://docs.agno.com/) over the MCP Streamable HTTP transport, OpenAI (`gpt-4.1-mini`) for the chat model, AgentOS (FastAPI) for the HTTP surface, and the bundled [Agent UI](./agent-ui) (Next.js) for chat.

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

2. Mint a Doorkeeper access token from the Rails app (`rails console`):

    ```ruby
    user = User.find_by(email: 'you@example.com')

    app = Doorkeeper::Application.find_or_create_by!(name: 'agno') do |a|
      a.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
      a.scopes = 'mcp'
      a.confidential = true
    end

    token = Doorkeeper::AccessToken.create!(
      application:       app,
      resource_owner_id: user.id,
      scopes:            'mcp',
      resource:          'http://localhost:3000/mcp',  # MUST match WOOFED_MCP_URL
      expires_in:        nil                            # never expires; drop for 8h tokens
    )

    puts token.token
    ```

    `resource:` must match `WOOFED_MCP_URL` exactly — `McpController#validate_token_audience!` rejects mismatches (RFC 8707). For staging/prod swap both to the public URL.

3. Fill in `.env`:

    ```
    WOOFED_MCP_URL=http://localhost:3000/mcp
    WOOFED_MCP_TOKEN=<the token printed above>
    OPENAI_API_KEY=<your openai key>
    ```

    Why OpenAI: the 27 MCP tool schemas pushed Groq's free-tier 12k TPM limit on
    the very first request. `gpt-4.1-mini` handles the schemas comfortably and
    is strong at tool calling.

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
| `401 invalid_token` on every call | Token's `resource` ≠ `WOOFED_MCP_URL`. Re-mint with the right URL. |
| `401 Unauthorized` on every call | Token missing the `mcp` scope, expired, or revoked. |
| Agent answers without calling tools | `WOOFED_MCP_TOKEN` empty → `MCPTools.connect()` failed silently. Restart `agent-ai`. |
| `connect` hangs at startup | Rails is not running, or `WOOFED_MCP_URL` points at the wrong host/port. |

To list active tokens for cleanup:

```ruby
user.access_tokens.where(revoked_at: nil, resource: 'http://localhost:3000/mcp')
```

To revoke one: `Doorkeeper::AccessToken.by_token('...').revoke!`.
