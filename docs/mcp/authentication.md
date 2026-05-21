# Authentication

The MCP server accepts the same JWT shape from two sources:

1. **Manually-issued JWTs** via `Users::JsonWebToken.encode_user` — used by Claude Desktop, agno, curl, and any other client that lets you paste a Bearer token into config.
2. **OAuth 2.1 dynamically-issued JWTs** via Doorkeeper + Dynamic Client Registration (RFC 7591) — used by Claude Web, Claude Code (remote MCP), Cursor, and any MCP client that follows the [authorization spec](https://modelcontextprotocol.io/specification/2025-06-18/basic/authorization).

Both paths produce a JWT with the same shape (`{ sub: user_id, ... }`, signed with `secret_key_base`) and both are validated by the same `Mcp::JwtAuthenticator` middleware — there is **one validator, two emitters**.

---

## Table of contents

1. [The JwtAuthenticator middleware](#the-jwtauthenticator-middleware)
2. [Token format and lifecycle](#token-format-and-lifecycle)
3. [Generating a token for a user](#generating-a-token-for-a-user)
4. [Client configuration](#client-configuration)
5. [OAuth 2.1 authorization server](#oauth-21-authorization-server)
6. [Loading the middleware](#loading-the-middleware)
7. [Why `Current.set` with a block](#why-currentset-with-a-block)

---

## The JwtAuthenticator middleware

File: [config/middleware/mcp/jwt_authenticator.rb](../../config/middleware/mcp/jwt_authenticator.rb)

The middleware validates the Bearer JWT and, on 401, advertises the OAuth metadata endpoint via the `WWW-Authenticate` header — that is what triggers OAuth-capable clients (Claude Web, ChatGPT) to start the OAuth dance.

Behaviour:

| Step | What happens |
|---|---|
| `request.path.start_with?(@path_prefix)` | Only enforces auth for `/mcp/*`. Other paths pass through untouched. |
| `extract_token(request)` | Uses Rails' built-in `Token.token_and_options`, which handles both `Authorization: Bearer xxx` and `Authorization: Token xxx`. |
| `Users::JsonWebToken.decode_user(token)` | Existing method from the REST API. Returns `{ ok: user }` on success, `{ error: e }` on failure. Verifies `exp` automatically when the claim is present. |
| `return unauthorized unless user` | Returns 401 with `WWW-Authenticate: Bearer realm="Woofed CRM MCP", resource_metadata="<base_url>/.well-known/oauth-protected-resource"`. Clients without OAuth support simply ignore the header. |
| `Current.set(user: user) { @app.call(env) }` | Wraps the downstream call with `Current.user = user`, automatically reverted after the block (see [below](#why-currentset-with-a-block)). |

---

## Token format and lifecycle

Tokens are standard JWTs signed with `Rails.application.secrets.secret_key_base`. The minimum payload is `{ sub: user_id }`; the OAuth path also adds `exp` and `jti`.

| Source | Method | Payload | Expiry |
|---|---|---|---|
| Manual | `Users::JsonWebToken.encode_user(user)` | `{ sub }` | Never |
| Manual (Chatwoot embed) | `Users::JsonWebToken.encode_embed(user)` | `{ sub, exp, aud: 'embed' }` | 8 hours |
| OAuth `/oauth/token` | Doorkeeper + doorkeeper-jwt | `{ sub, exp, jti }` | 8 hours (refreshable) |

`Users::JsonWebToken.decode_user` (used by the middleware) verifies `exp` automatically when present, so all three sources are validated by the same code path with no special-casing.

> **Trade-off (manual tokens):** No expiry — a leaked manual token grants access until `secret_key_base` is rotated.
>
> **Trade-off (OAuth tokens):** Access tokens expire in 8h, but **refresh tokens never expire on their own** (doorkeeper does not provide a `refresh_token_expires_in` option). A leaked refresh token grants access until the corresponding `Doorkeeper::AccessToken` row is revoked. If this becomes a problem, schedule a GoodJob cleanup task to delete records with `created_at < N.days.ago`.

---

## Generating a token for a user

In the Rails console or a one-off script:

```ruby
user = User.find_by(email: 'user@example.com')
token = Users::JsonWebToken.encode_user(user)
puts token
# eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOjF9.…
```

The same `User#get_jwt_token` shortcut is also available:

```ruby
user.get_jwt_token
```

---

## Client configuration

For Claude Desktop, the token is configured once in `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "woofed-crm": {
      "url": "https://app.woofedcrm.com/mcp/sse",
      "headers": {
        "Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOjF9.…"
      }
    }
  }
}
```

The same header travels with every request the client makes — both the long-lived `GET /mcp/sse` and the subsequent `POST /mcp/messages` calls.

---

## OAuth 2.1 authorization server

For clients that cannot accept a pasted Bearer token (Claude Web custom connectors, Claude Code remote MCP, Cursor, etc.), the server implements the [MCP authorization spec](https://modelcontextprotocol.io/specification/2025-06-18/basic/authorization) on top of Doorkeeper.

### Endpoints

| Endpoint | Purpose | Auth required |
|---|---|---|
| `GET /.well-known/oauth-protected-resource` | RFC 9728 metadata pointing to the auth server | None |
| `GET /.well-known/oauth-authorization-server` | RFC 8414 metadata advertising endpoints + capabilities | None |
| `POST /oauth/register` | RFC 7591 Dynamic Client Registration | None (rate-limited 10/h per IP) |
| `GET /oauth/authorize` | Consent screen (requires Devise login) | Devise session |
| `POST /oauth/authorize` | User clicks "Allow" → redirects with `code` | Devise session |
| `POST /oauth/token` | Exchange `code` (with PKCE verifier) or `refresh_token` for JWT | Client credentials |

### Sequence diagram

```mermaid
sequenceDiagram
    autonumber
    participant U as User browser
    participant C as Claude backend
    participant W as Woofed CRM
    participant D as Devise session

    C->>W: POST /mcp (no token)
    W-->>C: 401 + WWW-Authenticate (resource_metadata=…)

    Note over C,W: Discovery (RFC 9728 + RFC 8414)
    C->>W: GET /.well-known/oauth-protected-resource
    W-->>C: { authorization_servers }
    C->>W: GET /.well-known/oauth-authorization-server
    W-->>C: { authorization_endpoint, token_endpoint, registration_endpoint }

    Note over C,W: Dynamic Client Registration (RFC 7591)
    C->>W: POST /oauth/register { client_name, redirect_uris }
    W-->>C: { client_id, client_secret }

    Note over U,W: Authorization with PKCE — only step the user sees
    C->>U: redirect to /oauth/authorize?client_id&code_challenge&S256
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

    Note over C,W: Token exchange + first MCP call
    C->>W: POST /oauth/token { grant_type=authorization_code, code, code_verifier, client_id, client_secret }
    W-->>C: { access_token: JWT(8h), refresh_token, token_type: Bearer }
    C->>W: POST /mcp Authorization: Bearer <JWT>
    W-->>C: tool response (JwtAuthenticator validates JWT)

    Note over C,W: After 8h — silent refresh, user not involved
    C->>W: POST /oauth/token { grant_type=refresh_token, refresh_token }
    W-->>C: { access_token: new JWT, refresh_token: rolled token }
```

### Configuration

Doorkeeper is configured in [config/initializers/doorkeeper.rb](../../config/initializers/doorkeeper.rb):

- `force_pkce` + `pkce_code_challenge_methods ['S256']` — OAuth 2.1 / MCP spec compliance
- `access_token_expires_in 8.hours`
- `use_refresh_token` — rolling refresh enabled (`previous_refresh_token` column kept; old refresh tokens stay valid until manually revoked)
- `access_token_generator '::Doorkeeper::JWT'` — emits JWTs that the existing middleware can validate without DB lookup
- `default_scopes :mcp` — single coarse scope (tools/resources have no read/write split today)
- `grant_flows %w[authorization_code refresh_token]` — `client_credentials` disabled
- `enforce_content_type` — `/oauth/token` rejects requests without `application/x-www-form-urlencoded`

JWT payload bridge in the same file:

```ruby
Doorkeeper::JWT.configure do
  secret_key Rails.application.secrets.secret_key_base.to_s
  signing_method :hs256

  token_payload do |opts|
    payload = { sub: opts[:resource_owner_id], jti: SecureRandom.uuid }
    payload[:exp] = Time.current.to_i + opts[:expires_in] if opts[:expires_in]
    payload
  end
end
```

`jti` (RFC 7519 §4.1.7) is mandatory: without it, two tokens issued in the same second with the same `sub`+`exp` would be byte-identical and collide on the `oauth_access_tokens.token` unique index.

### Why `/oauth/register` is open

Per RFC 7591, anyone (Claude's backend, ChatGPT's backend, …) can register a client without prior provisioning. The endpoint only mints `client_id`+`client_secret`; **actual data access requires the human consent flow at `/oauth/authorize`**. Closing this endpoint would prevent Claude Web from auto-configuring as a custom connector. Abuse risk is mitigated by:

1. Rate limit (10 registrations per IP per hour) — prevents `oauth_applications` bloat
2. Consent screen at `/oauth/authorize` — registered clients are useless without a logged-in user explicitly approving them

---

## Loading the middleware

The middleware lives in `config/middleware/mcp/jwt_authenticator.rb`, deliberately outside Rails' autoload paths. The initializer ([config/initializers/fast_mcp.rb](../../config/initializers/fast_mcp.rb)) `require`s it manually:

```ruby
require Rails.root.join('config/middleware/mcp/jwt_authenticator').to_s

FastMcp.mount_in_rails(...)

Rails.application.config.middleware.insert_before(
  FastMcp::Transports::RackTransport,
  Mcp::JwtAuthenticator,
  path_prefix: '/mcp'
)
```

### Why not put it under `app/middleware/` or `lib/`?

Because of an ordering issue with Zeitwerk:

1. Rails initializers run *before* Zeitwerk's main loader is fully set up (`setup_main_autoloader` is in `Rails::Application::Finisher`, which runs after `load_config_initializers`).
2. The `insert_before` call references the `Mcp::JwtAuthenticator` constant inline. The constant must be defined at that exact moment.
3. If the file were in `app/middleware/` or `lib/`, Zeitwerk would *want* to manage it. A manual `require` of an autoloaded file in `eager_load=true` mode (CI/production) can raise `Zeitwerk::NameError` ("constant defined manually but autoloadable").

Putting the file in `config/middleware/` avoids the conflict entirely: Rails does not autoload `config/`, so a manual `require` is the only loading mechanism. No collision with Zeitwerk.

---

## Why `Current.set` with a block

`ActiveSupport::CurrentAttributes` is thread-local. Without proper scoping, a request that sets `Current.user` could leak that value into the next request running on the same Puma thread.

`Current.set(attrs) { ... }`:

1. Snapshots the current attribute values.
2. Sets the new attributes.
3. Runs the block.
4. Restores the snapshot on exit, even if the block raises.

This is equivalent to a `begin/ensure` pair but more concise:

```ruby
# Equivalent imperative form
prev = Current.user
Current.user = user
begin
  @app.call(env)
ensure
  Current.user = prev
end
```

Inside the block, any tool calling `current_user` (helper on `ApplicationTool`) reads `Current.user` and gets the authenticated user. After the block, the previous value (usually `nil`) is restored.

There is also a belt-and-suspenders `Current.reset` in the `ensure` of [Mcp::Concerns::RequestExceptionHandler#handle_with_exception](../../app/tools/mcp/concerns/request_exception_handler.rb), guaranteeing clean state even if something inside the tool bypasses `Current.set`.
