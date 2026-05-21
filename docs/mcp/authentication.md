# Authentication

Every request to `/mcp` must carry an `Authorization: Bearer <token>` header. Authentication is delegated to Doorkeeper's `doorkeeper_authorize!` — the token is an **opaque, DB-backed access token** (no JWT, no self-contained payload). Two emission paths converge on the same validation:

1. **OAuth 2.1 dynamic flow** — Claude Web custom connectors, Claude Code remote MCP, Cursor, ChatGPT. Client does DCR → authorize → token exchange.
2. **Manual token (rails console)** — Claude Desktop, agno, curl. Operator mints a long-lived `Doorkeeper::AccessToken` and pastes it into the client config.

The MCP entry point is [McpController](../../app/controllers/mcp_controller.rb). Two before_actions guard every request:

- `doorkeeper_authorize! :mcp` — confirms the token exists, isn't revoked, isn't expired, and has the `mcp` scope.
- `validate_token_audience!` — confirms the token's `resource` claim equals `<request.base_url>/mcp` (RFC 8707). Rejects tokens issued for any other resource.

---

## Table of contents

1. [Generating a token for Claude Desktop](#generating-a-token-for-claude-desktop)
2. [Client configuration](#client-configuration)
3. [OAuth 2.1 authorization server](#oauth-21-authorization-server)
4. [Validation flow inside McpController](#validation-flow-inside-mcpcontroller)
5. [Revoking access](#revoking-access)
6. [Trade-offs](#trade-offs)

---

## Generating a token for Claude Desktop

Run in the Rails console (`rails console -e production`):

```ruby
user = User.find_by(email: 'yukioarie@gmail.com')

# Reuse one Application per integration. The redirect_uri is a placeholder —
# Claude Desktop doesn't follow it, but doorkeeper requires the column.
app = Doorkeeper::Application.find_or_create_by!(name: 'Claude Desktop') do |a|
  a.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
  a.scopes = 'mcp'
  a.confidential = true
end

token = Doorkeeper::AccessToken.create!(
  application:       app,
  resource_owner_id: user.id,
  scopes:            'mcp',
  resource:          'https://app.woofedcrm.com/mcp',   # MUST match the public URL of the MCP endpoint
  expires_in:        nil                                  # nil = never expires; omit this for 8h tokens
)

puts token.token
# => "cKj5xXk-9qR2vN8aBp4mZt7eY3wF6sH1iL0nO8uV2pQ"
```

`resource:` is required — `McpController#validate_token_audience!` rejects tokens whose `resource` doesn't match the request base URL.

---

## Client configuration

The Bearer header is identical for every client. Only the way you obtain the token differs.

### Claude Desktop / agno / curl

```json
{
  "mcpServers": {
    "woofed-crm": {
      "url": "https://app.woofedcrm.com/mcp",
      "headers": {
        "Authorization": "Bearer cKj5xXk-9qR2vN8aBp4mZt7eY3wF6sH1iL0nO8uV2pQ"
      }
    }
  }
}
```

### Claude Web custom connector / Claude Code remote MCP / Cursor

Just provide the URL `https://app.woofedcrm.com/mcp`. The client auto-discovers the OAuth metadata, registers itself via DCR, opens the consent screen in a browser, and stores the resulting access token internally. See the next section for the flow.

---

## OAuth 2.1 authorization server

Doorkeeper exposes the standard OAuth endpoints (configured in [config/initializers/doorkeeper.rb](../../config/initializers/doorkeeper.rb)):

| Endpoint | Purpose | Auth required |
|---|---|---|
| `GET /.well-known/oauth-protected-resource` | RFC 9728 metadata pointing to the auth server | None |
| `GET /.well-known/oauth-authorization-server` | RFC 8414 metadata advertising endpoints + capabilities | None |
| `POST /oauth/register` | RFC 7591 Dynamic Client Registration | None (rate-limited 10/h per IP) |
| `GET /oauth/authorize` | Consent screen (requires Devise login) | Devise session |
| `POST /oauth/authorize` | User clicks "Allow" → redirects with `code` | Devise session |
| `POST /oauth/token` | Exchange `code` (with PKCE verifier) or `refresh_token` for opaque access token | Client credentials |

### Configuration highlights

- `force_pkce` + `pkce_code_challenge_methods ['S256']` — OAuth 2.1 / MCP spec compliance.
- `access_token_expires_in 8.hours` — short-lived OAuth tokens; refresh handles renewal.
- `use_refresh_token` — rolling refresh enabled (the previous refresh stays valid during a grace window).
- `default_scopes :mcp` — single coarse scope.
- `grant_flows %w[authorization_code refresh_token]` — `client_credentials` and `password` disabled.
- `enforce_content_type` — `/oauth/token` rejects requests without `application/x-www-form-urlencoded`.
- `custom_access_token_attributes [:resource]` — RFC 8707 Resource Indicators, persisted via an `after_successful_authorization` hook.

### Sequence diagram

```mermaid
sequenceDiagram
    autonumber
    participant U as User browser
    participant C as Claude backend
    participant W as Woofed CRM
    participant D as Devise session

    C->>W: POST /mcp (no token)
    W-->>C: 401 Unauthorized

    Note over C,W: Discovery (RFC 9728 + RFC 8414)
    C->>W: GET /.well-known/oauth-protected-resource
    W-->>C: { authorization_servers }
    C->>W: GET /.well-known/oauth-authorization-server
    W-->>C: { authorization_endpoint, token_endpoint, registration_endpoint }

    Note over C,W: Dynamic Client Registration (RFC 7591)
    C->>W: POST /oauth/register { client_name, redirect_uris }
    W-->>C: { client_id, client_secret }

    Note over U,W: Authorization with PKCE — the only step the user sees
    C->>U: redirect to /oauth/authorize?client_id&code_challenge&S256&resource=<mcp_url>
    U->>W: GET /oauth/authorize
    W->>D: current_user?
    D-->>W: not logged in
    W-->>U: Devise login form
    U->>W: submit credentials
    W->>D: sign_in
    W-->>U: consent screen ("Allow Claude to access?")
    U->>W: POST /oauth/authorize (Allow)
    W-->>U: 302 → claude.ai/callback?code=XYZ
    U->>C: callback with code

    Note over C,W: Token exchange — opaque token (NOT a JWT)
    C->>W: POST /oauth/token { grant_type=authorization_code, code, code_verifier, client_id, client_secret, resource }
    W-->>C: { access_token, refresh_token, token_type: Bearer }

    Note over C,W: Use
    C->>W: POST /mcp Authorization: Bearer <opaque token>
    W-->>C: tool response

    Note over C,W: After 8h — silent refresh, user not involved
    C->>W: POST /oauth/token { grant_type=refresh_token, refresh_token }
    W-->>C: { access_token (new), refresh_token (rolled) }
```

### Why `/oauth/register` is open

Per RFC 7591, anyone can register a client without prior provisioning. The endpoint only mints `client_id`+`client_secret`; **actual data access requires the consent flow at `/oauth/authorize` with a logged-in user**. Closing this endpoint would prevent Claude Web from auto-configuring. Abuse is mitigated by:

1. Rate limit (10 registrations per IP per hour) — prevents `oauth_applications` bloat.
2. Consent screen — registered clients are useless without an explicit user approval.

---

## Validation flow inside McpController

```ruby
class McpController < ActionController::API
  before_action -> { doorkeeper_authorize! :mcp }
  before_action :validate_token_audience!

  def handle
    return head(:accepted) if params[:method] == 'notifications/initialized'
    render(json: mcp_server.handle_json(request.body.read))
  end

  private

  def validate_token_audience!
    return if doorkeeper_token.resource == "#{request.base_url}/mcp"
    render json: { error: 'invalid_token', error_description: 'Token not valid for this resource' },
           status: :unauthorized
  end
end
```

Per request:

1. `doorkeeper_authorize! :mcp` extracts the Bearer token, looks it up in `oauth_access_tokens`, and verifies scope/expiry/revocation. On failure: 401.
2. `validate_token_audience!` confirms the stored `resource` matches the request base_url. Rejects cross-resource tokens.
3. `mcp_server.handle_json(request.body.read)` runs the JSON-RPC routing inside the `mcp` gem.

---

## Revoking access

Unlike a JWT scheme, opaque tokens can be revoked **individually**:

```ruby
# Revoke a specific token
Doorkeeper::AccessToken.by_token('cKj5xXk-...').revoke!

# Revoke every token a user has
user.access_tokens.where(revoked_at: nil).update_all(revoked_at: Time.current)

# Revoke every token issued to a given client (e.g. Claude Desktop)
Doorkeeper::Application.find_by(name: 'Claude Desktop')
  .access_tokens.where(revoked_at: nil).update_all(revoked_at: Time.current)
```

To list active tokens:

```ruby
user.access_tokens.where(revoked_at: nil, resource: 'https://app.woofedcrm.com/mcp')
```

---

## Trade-offs

| Aspect | Choice | Reason |
|---|---|---|
| Token format | Opaque, DB-backed (not JWT) | Granular revocation, audit trail, alignment with the [mcp-on-rails](https://github.com/pstrzalk/mcp-on-rails) template. |
| OAuth token TTL | 8h access + rolling refresh | Short blast radius if leaked. Refresh keeps UX seamless. |
| Refresh token TTL | No explicit expiration (lives until revoked) | Doorkeeper 5.9 has no `refresh_token_expires_in` option. Mitigation: periodic cleanup job, or explicit revocation. |
| Manual tokens | `expires_in: nil` permitted | Claude Desktop's static config can't refresh — a non-expiring token mirrors the previous JWT UX. |
| Resource binding | `resource` column on `oauth_access_tokens` (RFC 8707) | Prevents a token issued for the REST API from being replayed against `/mcp`, and vice versa. |
| Consent screen | Always shown | CRM holds private data — implicit auth would be too permissive. |
