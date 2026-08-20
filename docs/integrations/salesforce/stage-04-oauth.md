# Stage 4 — OAuth (web server flow)

**Parent plan:** [plan.md](plan.md) — delivery table §13, row 4. Builds on
[stages 1 + 3](stage-01-token-encryption.md).

Connects a Salesforce org: consent, code exchange, token refresh, disconnection, and the daily
health check that notices when the customer revokes the app.

---

## 1. What was built

| File | Role |
|---|---|
| [apps/salesforce/oauth/authorize_request.rb](../../../app/models/apps/salesforce/oauth/authorize_request.rb) | Builds the consent URL and the PKCE pair |
| [apps/salesforce/oauth/token_request.rb](../../../app/models/apps/salesforce/oauth/token_request.rb) | The only place that talks to `/services/oauth2/token` |
| [apps/salesforce/oauth/exchange_code.rb](../../../app/models/apps/salesforce/oauth/exchange_code.rb) | `authorization_code` grant |
| [apps/salesforce/oauth/error_message.rb](../../../app/models/apps/salesforce/oauth/error_message.rb) | Salesforce error code → message whose fix the user can act on |
| [apps/salesforce/connection/refresh_token.rb](../../../app/models/apps/salesforce/connection/refresh_token.rb) | `refresh_token` grant, under a row lock |
| [apps/salesforce/connection/refresh.rb](../../../app/models/apps/salesforce/connection/refresh.rb) + [refresh_job.rb](../../../app/jobs/apps/salesforce/connection/refresh_job.rb) | Daily health check, wired into `config/initializers/good_job.rb` |
| [inertia/accounts/apps/salesforces_controller.rb](../../../app/controllers/inertia/accounts/apps/salesforces_controller.rb) | `create` starts the flow, `destroy` disconnects |
| [apps/salesforces/oauth_controller.rb](../../../app/controllers/apps/salesforces/oauth_controller.rb) | The fixed callback URL |
| `config/locales/apps/salesforce/{en,pt-BR,es}.yml` | Flash and OAuth error messages |

Routes: `POST/DELETE /accounts/:account_id/apps/salesforce` (singular — one connection per install)
and `GET /apps/salesforces/oauth/callback`.

---

## 2. Decisions worth keeping

### 2.1 The callback URL carries no ids

The customer registers it by hand in their External Client App, so it is fixed for the whole
install: `https://<woofed>/apps/salesforces/oauth/callback`. It therefore cannot include an account
or connection id, and relies on the signed-in session to know where to send the user back to. This
is also why `redirect_uri` lives on the model — the same string has to be sent on the authorize
redirect and on the token exchange, and Salesforce compares all three.

### 2.2 PKCE state stays in the session

`state` and `code_verifier` are generated when the flow starts and kept in the Rails session. The
callback refuses any code whose `state` does not match what this browser session started
(`secure_compare`), and the verifier is only ever sent server-to-server on the exchange. Neither
value is stored in the database — an interrupted flow simply expires with the session.

### 2.3 One request object for both grants

`TokenRequest` is shared by the code exchange and the refresh: same endpoint, same response
handling, different form parameters. Its result carries `code` when **Salesforce** rejected the
call, and omits it when the org could not be reached. That distinction is what lets `RefreshToken`
flip `status` to `error` for a revoked app while leaving a timeout — or a proxy's HTML error page —
alone, since those are transient and not the customer's problem to fix.

### 2.4 The refresh holds a row lock

Web, sidekiq and goodjob refresh independently, and Salesforce keeps a limited number of active
access tokens per user per app: concurrent refreshes can evict a token another process is still
using. `RefreshToken` therefore takes a row lock and, unless forced, returns early when whoever held
the lock already refreshed. `force: true` exists for the 401 retry that stage 5's API client needs.

### 2.5 Error messages name the fix, not the code

`redirect_uri_mismatch` is the most likely onboarding failure and the most opaque one, so the
message names the exact callback URL this install expects — the string the user has to paste into
Salesforce. `invalid_client` (re-paste the secret) and `invalid_grant` (reconnect) are separated for
the same reason: the fix differs.

---

## 3. What is deliberately not here

- **No UI.** Stage 7 builds the Inertia screens; the controllers redirect to the settings page with
  a flash. The Connect screen is where the callback URL and the required scopes get shown with copy
  buttons, per §3.1 of the parent plan.
- **No decryption-error handling yet.** [Stage 1's notes](stage-01-token-encryption.md) call for
  `ActiveRecord::Encryption::Errors::Decryption` to land in the same "reconnect" state as
  `invalid_grant`. It belongs with stage 5's API client, where reads of the token actually happen in
  a request path.
- **No My Domain login host.** Only `login`/`test`. If a customer's org requires their own domain,
  the fix is a third `environment` option with a stored login URL.

---

## 4. Verification

79 examples across the Salesforce specs, 0 failures, **100% line coverage on all twelve files**.

The request specs drive the real flow end to end: `start_flow` performs the actual `POST` that
begins the connection, then the callback spec uses the `state` that flow produced, so the session
handling and the PKCE round-trip are exercised rather than mocked. Covered: the consent redirect
(host, scopes, challenge method, redirect URI), sandbox host selection, reconnecting an existing
connection instead of creating a second one, blank credentials, the successful exchange (tokens, org
id, estimated expiry, `status: active`), a tampered `state`, a denied authorization, a callback URL
mismatch, a missing connection, refresh success/skip/force, a revoked refresh token, an unreachable
org, a non-JSON response, and the daily job over every one of those states.
