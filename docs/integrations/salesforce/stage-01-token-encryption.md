# Stages 1 + 3 — Encryption at rest and the `Apps::Salesforce` connection

**Parent plan:** [plan.md](plan.md) — delivery table §13, rows 1 and 3.

The two stages were merged. Stage 1 on its own would have been infrastructure with no consumer:
its original verification plan was to encrypt an existing Chatwoot column, and touching the Chatwoot
integration is out of bounds for this work. Landing the encryption config together with the first
model that declares `encrypts` gives the same coverage without leaving the Salesforce scope.

---

## 1. What was built

| File | Role |
|---|---|
| [config/initializers/active_record_encryption.rb](../../../config/initializers/active_record_encryption.rb) | Encryption keys, derived from `secret_key_base` |
| [db/migrate/20260810120000_create_apps_salesforces.rb](../../../db/migrate/20260810120000_create_apps_salesforces.rb) | The `apps_salesforces` table |
| [app/models/apps/salesforce.rb](../../../app/models/apps/salesforce.rb) | Connection model: encrypted credentials, single-connection rule, revoke on destroy |
| `config/locales/models/apps/salesforce/{en,pt-BR,es}.yml` | Attribute, enum and error translations |
| [spec/factories/apps/salesforces.rb](../../../spec/factories/apps/salesforces.rb) | `:apps_salesforces` with `:connected`, `:sandbox`, `:token_expired` traits |
| [spec/models/apps/salesforce_spec.rb](../../../spec/models/apps/salesforce_spec.rb) | 16 examples covering every branch of the model |

---

## 2. Encryption

### 2.1 Why the Salesforce credentials are encrypted and the Chatwoot token is not

The Salesforce `refresh_token` is a long-lived credential with `api` scope — full read access to the
customer's CRM — and Salesforce never rotates it. A database dump taken months ago still contains a
working key to the customer's org. The access token expires on its own within hours; the refresh
token does not. That asymmetry is the reason this is worth doing before any sync code exists.

### 2.2 Where the keys come from

Active Record Encryption needs `primary_key`, `deterministic_key` and `key_derivation_salt`. The
Rails default is `credentials.yml.enc` + `master.key`, which this app does not have — every secret
comes from the environment ([config/secrets.yml](../../../config/secrets.yml)). A separate set of
ENV variables was considered and rejected as configuration burden for something the operator would
almost always leave at its default. The keys are derived from `secret_key_base` instead, so an
install needs no new configuration.

**The trade-off, stated plainly:** rotating `SECRET_KEY_BASE` makes the encrypted columns
unreadable. Today rotating it already logs everyone out, kills issued JWTs
([json_web_token.rb:4](../../../app/use_cases/users/json_web_token.rb#L4)) and invalidates pending
Devise reset links — all of which recover by themselves. The encrypted columns do not: the
integration has to be reconnected.

That is acceptable because only re-obtainable third-party credentials are encrypted, never user
data. It does impose one requirement on stage 4: `ActiveRecord::Encryption::Errors::Decryption` must
be caught and turned into `status: error` with a "reconnect" prompt, exactly like an `invalid_grant`
from a refresh token the customer revoked on the Salesforce side. Both causes are invisible to us
until a request fails, and both have the same fix.

### 2.3 One implementation detail worth remembering

The keys are applied inside `ActiveSupport.on_load(:active_record)`, not by assigning
`config.active_record.encryption` in the initializer. Other initializers in this app load Active
Record before `config/initializers/active_record_encryption.rb` runs, and by then the encryption
config has already been read — the assignment silently does nothing and every write fails with
`Missing Active Record encryption credential`. This was caught by the specs, not by reasoning.

---

## 3. The `apps_salesforces` table

Follows §3.2 of the parent plan, minus `webhook_token` (only needed for the Outbound Message option,
which was not chosen).

| Column | Note |
|---|---|
| `name`, `status`, `environment` | `status`: `inactive` / `active` / `syncing` / `error`. `environment`: `production` / `sandbox` |
| `client_id` | Consumer key from the customer's External Client App |
| `client_secret`, `access_token`, `refresh_token` | **`text`, encrypted** — the ciphertext envelope is several times longer than the plaintext, so a `string` with a limit would truncate |
| `instance_url` | Returned by the token response; the base for every API call |
| `organization_id` | Guards against re-pointing at a different org |
| `token_expires_at` | Estimate only — see below |
| `api_version` | `v64.0`, pinned per install |
| `settings` | jsonb: sync toggles, poll interval, checkpoints |

### 3.1 `environment` decides the OAuth host only

A sandbox org cannot authenticate against `login.salesforce.com`, and a production org cannot
authenticate against `test.salesforce.com`. That is all this column controls: which of the two
static, global Salesforce hosts the authorize/token/revoke calls go to. Once the token arrives,
every API call uses the `instance_url` from the response.

Known limitation for stage 4: orgs with My Domain may require login on their own domain
(`https://acme.my.salesforce.com`), which is neither value. If that shows up in the field, the fix is
a third option with a free-text URL — `LOGIN_URLS.fetch` becomes a stored login URL and nothing else
changes.

### 3.2 `token_expired?` is a heuristic, deliberately

Salesforce does not return `expires_in` on the token response, and the session lifetime is set by
the customer's org (Session Settings — commonly 2 hours, configurable from 15 minutes to 24 hours).
So `token_expires_at` can only ever be an estimate, and `token_expired?` returns `false` when it is
unknown. The authoritative expiry signal is a `401 INVALID_SESSION_ID`, which stage 4's API client
must handle by refreshing and retrying once. The proactive check exists to avoid the round-trip, not
to replace it.

This matters most during the backfill: a first sync can run for hours (§9.6 of the parent plan), so
the session *will* expire mid-job. The refresh has to live inside the connection object that wraps
Faraday, transparent to callers, and it has to hold a lock — the web, sidekiq and goodjob processes
refreshing concurrently can evict each other's tokens, since Salesforce keeps a limited number of
active access tokens per user per app.

### 3.3 Single connection per install

Enforced by a model validation on create, not by the schema, so allowing several later is removing
the validation plus UI work — no migration. `revoke_refresh_token` on `before_destroy` posts to
`/services/oauth2/revoke` and is best-effort: a token Salesforce already invalidated, or an
unreachable org, must never block the user from disconnecting.

---

## 4. Verification

`bundle exec rspec spec/models/apps/salesforce_spec.rb` — 16 examples, 0 failures. The full model
suite passes unchanged (310 examples), which is what confirms the global encryption initializer did
not disturb anything else.

Covered branches: blank `client_id` / `client_secret`, second connection rejected while the existing
one stays editable, credentials absent from the raw database row but readable through the model,
production vs. sandbox login host, versioned API URL, `connected?` with each field missing, unknown
/ past / inside-margin / far-future token expiry, and revocation in three shapes — performed,
skipped when no token was stored, and survived when Salesforce is unreachable.

---

## 5. What is next

Stage 4 (OAuth web server flow) is the natural continuation: authorize and callback controllers,
the token refresh path described in §3.2, and the two error branches from §2.2 (`invalid_grant` and
decryption failure) collapsing into a single "reconnect" state.

Stage 2 (the import guard) remains open and independent. Note that it conflicts with the "no
Chatwoot changes" constraint by construction: the side effect it has to suppress during an import is
`Contact`'s `after_commit :export_contact_to_chatwoot`, so importing Salesforce contacts without it
would push every one of them into the customer's Chatwoot account. That needs an explicit decision
before the loader stages.
