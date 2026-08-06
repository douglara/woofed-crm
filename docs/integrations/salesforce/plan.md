# Salesforce → Woofed CRM sync — plan and technical study

**Scope of phase 1: one-way sync, Salesforce → Woofed.** Woofed reads Salesforce data and
materialises it as Woofed records. Nothing is written back to Salesforce. The architecture,
however, keeps a write-back path open (see [Designing for phase 2](#12-designing-for-phase-2-write-back)),
because the expensive part — the record mapping table and the field mapping model — is the same
in both directions.

---

## Table of contents

1. [Goals and non-goals](#1-goals-and-non-goals)
2. [High-level architecture](#2-high-level-architecture)
3. [Authentication](#3-authentication)
4. [Initial load — the "backup / export" question](#4-initial-load--the-backup--export-question)
5. [Real-time updates — Salesforce's WAL](#5-real-time-updates--salesforces-wal)
6. [Data model in Woofed](#6-data-model-in-woofed)
7. [Entity and field mapping (user-configurable)](#7-entity-and-field-mapping-user-configurable)
8. [The ingestion pipeline](#8-the-ingestion-pipeline)
9. [Conflicts, duplicates and data-quality risks](#9-conflicts-duplicates-and-data-quality-risks)
10. [UI](#10-ui)
11. [Testing strategy](#11-testing-strategy)
12. [Designing for phase 2 (write-back)](#12-designing-for-phase-2-write-back)
13. [Delivery plan and status](#13-delivery-plan-and-status)
14. [Decisions](#14-decisions)

---

## 1. Goals and non-goals

**Goals**

- A `Apps::Salesforce` record holds the connection settings, mirroring how `Apps::Chatwoot` and
  `Apps::EvolutionApi` work today (`app/models/apps/chatwoot.rb`).
- The user connects a Salesforce org, then **maps Salesforce objects and fields onto Woofed
  entities and fields** through the UI. Mapping is data, not code.
- A full initial load, then continuous incremental updates.
- Every synced Woofed record can be traced back to its Salesforce record, and re-syncing is
  idempotent (no duplicates).

**Non-goals for phase 1**

- Writing anything to Salesforce (no create/update/delete on the Salesforce side).
- Syncing Salesforce metadata that has no Woofed counterpart (Campaigns, Quotes, Price Books,
  Cases, Knowledge, Chatter).
- Acting as a backup/DR product for Salesforce data. Woofed stores a *projection* of Salesforce,
  not an archive (see §4).

---

## 2. High-level architecture

```
┌─────────────────────────────────────────┐
│              Salesforce org             │
│  Account · Contact · Lead · Opportunity │
│  Task · Event · User                    │
└───────┬──────────────┬──────────────────┘
        │              │
        │ (A) backfill │ (B) delta
        │ Bulk API 2.0 │ SOQL SystemModstamp poll  → phase 1
        │ query jobs   │ CDC / Pub/Sub API         → phase 2
        ▼              ▼
┌─────────────────────────────────────────────────────────┐
│ Ingestion (GoodJob)                                     │
│  · fetch → normalise envelope → write raw payload       │
└──────────────────────┬──────────────────────────────────┘
                       ▼
        apps_salesforce_sync_records  (staging, raw JSON)
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ Transform (per-object mapper, driven by ObjectMapping)  │
│  · field mapping · type coercion · phone/email normalise│
└──────────────────────┬──────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────┐
│ Load — idempotent upsert keyed by apps_salesforce_       │
│ record_mappings (salesforce_id ⇄ Woofed record)         │
│  · import guard: no Chatwoot export, no outbound webhook│
└──────────────────────┬──────────────────────────────────┘
                       ▼
     Contact · Company · Deal · Event · custom_attributes
```

Two properties this shape buys us:

1. **Raw payloads are persisted before mapping.** Changing a field mapping later re-runs the
   transform from staging instead of re-downloading from Salesforce — which matters because API
   calls are a metered resource (§4).
2. **The load step is keyed on a mapping table, not on a jsonb attribute.** That is what makes
   re-running the sync idempotent and makes "which Woofed record is this Salesforce record?"
   an indexed lookup.

---

## 3. Authentication

### 3.1 Flow comparison

| Flow | User interaction | Refresh token | Setup burden | Fit |
|---|---|---|---|---|
| **Web Server (authorization code + PKCE)** | One consent click | Yes | Customer creates an External Client App in their org, pastes `client_id` / `client_secret` | **Decided — this is the flow we ship** |
| JWT Bearer | None (headless) | No — a fresh access token is minted per request from a signed JWT | Customer must generate a certificate, upload it, and pre-authorize the app | Good for a hosted/managed offering, heavy for self-hosted |
| Client Credentials | None | No | Requires nominating a "run-as" user; all records attributed to it | Simple, but loses per-user attribution and needs admin setup |
| Username-Password | None | No | Deprecated/disabled by default in new orgs | Do not use |

**Decided: Web Server flow with PKCE, refresh token stored encrypted, on a customer-created
External Client App.**

Rationale: Woofed is self-hosted, so instances live on arbitrary domains. A single
Woofed-owned Connected App cannot register every customer's redirect URI. So the customer
creates an **External Client App** (the current name; "Connected App" is the legacy term) in
their own org, sets the callback to `https://<their-woofed>/apps/salesforces/oauth/callback`,
and pastes `client_id` + `client_secret` into the Woofed form — the same shape as the Chatwoot
form, which already asks for an endpoint URL plus a token.

Required OAuth scopes: `api` (REST/Bulk access), `refresh_token offline_access` (long-lived
refresh), and `chatter_api` is *not* needed. If phase 2 uses Pub/Sub API, no extra scope is
required — `api` covers it.

#### Consequence: the user configures the External Client App by hand

There is no automated provisioning step on the Salesforce side and none is planned. Woofed never
creates, edits or inspects the External Client App — it only consumes the credentials the user
pastes in. Concretely, before connecting, the user does the following **in their own Salesforce
org**:

1. Setup → App Manager → **New External Client App**.
2. Enable OAuth, set the callback URL to `https://<their-woofed>/apps/salesforces/oauth/callback`
   (the Connect screen shows this value pre-filled, ready to copy).
3. Select the scopes `api` and `refresh_token offline_access`, and enable
   "Issue a refresh token" / PKCE.
4. Save, wait the few minutes Salesforce takes to propagate the app, then copy the
   **Consumer Key** (`client_id`) and **Consumer Secret** (`client_secret`).
5. Paste both into Woofed's Connect screen, pick production or sandbox, and click
   "Connect to Salesforce".

This has two implications for the build:

- **The Connect screen is also documentation.** It must display the exact callback URL for this
  install and the exact scope list, with copy buttons and a link to the Salesforce docs. A
  mistyped callback URL is the single most likely failure in onboarding, and Salesforce's error
  for it (`redirect_uri_mismatch`) is opaque — the callback controller must translate it into a
  readable message that names the expected URL.
- **Errors caused by app misconfiguration must be distinguishable from errors caused by bad
  credentials**, since the fix differs (edit the app in Salesforce vs. re-paste the secret).

This also settles the phase-2 posture: a Woofed-owned app with a fixed redirect is only viable
for a managed/cloud offering, and we are not building one, so it stays out of scope.

### 3.2 Fields on `apps_salesforces`

| Column | Type | Note |
|---|---|---|
| `name` | string | Label shown in the UI |
| `status` | string | `inactive` / `active` / `syncing` / `error` — mirrors `Apps::Chatwoot#status` |
| `environment` | string | `production` (`login.salesforce.com`) or `sandbox` (`test.salesforce.com`) |
| `client_id` | string | From the customer's External Client App |
| `client_secret` | string (encrypted) | idem |
| `instance_url` | string | Returned by the token response; **always** use it as the API base, never `login.salesforce.com` |
| `organization_id` | string | Returned in the token `id` field; guards against re-pointing at a different org |
| `access_token` | string (encrypted) | Short-lived |
| `refresh_token` | string (encrypted) | Long-lived |
| `token_expires_at` | datetime | Proactive refresh instead of waiting for a 401 |
| `api_version` | string | e.g. `v64.0`, pinned per install and discoverable via `/services/data` |
| `settings` | jsonb | Sync toggles, poll interval, replay checkpoints |
| `webhook_token` | string | Only needed if the Outbound Message option in §5 is chosen |

### 3.2.1 Exactly one Salesforce connection per install

**Decided: a Woofed install has at most one Salesforce integration.**

The table keeps the same shape as `apps_chatwoots` — plain rows, no singleton column, no partial
unique index — so the storage layer physically allows several, exactly like the Chatwoot
integration does today. The single-connection rule lives one level up, as a model validation on
create:

```ruby
validate :only_one_connection, on: :create

def only_one_connection
  return if self.class.where.not(id: id).none?

  errors.add(:base, I18n.t('activerecord.errors.messages.salesforce_connection_already_exists'))
end
```

Keeping the rule in the model rather than in the schema means lifting it later is a one-line
change plus UI work, with no migration and no backfill — which is the whole point of deciding it
now: the migrations can land without being blocked on a multi-connection design.

What follows from "exactly one" throughout the rest of this document:

- **`app_id` stays on every child table** (`object_mappings`, `record_mappings`, `sync_records`,
  `sync_runs`) and stays in every unique index, as §6.1 already specifies. It costs nothing today
  and is what makes a future second connection a UI problem instead of a data-migration problem.
- **The GoodJob cron entries are global**, not per connection: one `Delta::PollJob` and one
  `Connection::RefreshJob` that load the single connection and no-op when it is absent or
  inactive. No fan-out over connections is needed.
- **The concurrency key on sync jobs is still the `Apps::Salesforce` id** (§8.1), not a constant.
  It reads the same, and it keeps working unchanged if the rule is ever relaxed.
- **The UI never lists connections** (§10): the Salesforce app page is either the Connect form or
  the connected state, and reconnecting edits the existing record instead of creating a second one.

### 3.3 Token handling

- **Encryption at rest.** The repo currently has no `encrypts` usage — `Apps::Chatwoot` stores
  `chatwoot_user_token` in plaintext. A Salesforce refresh token is a much larger blast radius
  (full org read). Introduce Rails 7 `ActiveRecord::Encryption` for these columns and set
  `active_record.encryption` keys from ENV. This is a prerequisite task, not an optional polish.
- **Refresh on demand.** A single `Apps::Salesforce::Connection` object owns the Faraday client,
  refreshes the access token when `token_expires_at` is within ~5 minutes, retries once on a
  `401 INVALID_SESSION_ID`, and flips `status` to `error` when the refresh token is revoked so
  the UI can prompt for reconnection.
- **Revocation.** `before_destroy` posts to `/services/oauth2/revoke`, matching
  `Apps::Chatwoot#chatwoot_delete_flow` which cleans up remote state on destroy.
- **Do not log payloads.** Salesforce records are PII. Log record ids and counts, never bodies.

### 3.4 API budget

Salesforce Enterprise Edition allocates ~100,000 API requests per rolling 24 hours, plus 1,000
per user licence, shared across REST, SOAP, Bulk and Connect. This is the hard constraint that
drives every decision in §4 and §5: **a naive per-record REST sync will exhaust a customer's org
allocation**, and it is *their* allocation, shared with every other integration they run.
Design targets: backfill via Bulk (a job counts as a handful of calls, not one per record), and
delta via either one paged SOQL query per object per interval, or CDC events (which draw on the
event allocation, not the API allocation).

---

## 4. Initial load — the "backup / export" question

The doubt raised was whether to export/back up the data first. There are three different things
that are easy to conflate; only one of them is the sync's initial load.

| Mechanism | What it actually is | Verdict for us |
|---|---|---|
| **Data Export Service** (Setup → Data Export) | Weekly/monthly ZIP of CSVs, scheduled by an admin, delivered hours later | **Not** a sync mechanism. Manual, high-latency, no API trigger for the schedule. Ignore. |
| **Salesforce Backup** (paid add-on) | Managed backup/restore product | Out of scope. Woofed is not a DR product. |
| **Bulk API 2.0 query jobs** | Async server-side SOQL, results streamed as CSV, ~150M records/day allocation | **This is the initial load.** |

**Recommendation:** the initial load is a **Bulk API 2.0 query job per mapped object**, ordered
by dependency (`Account` → `Contact` → `Lead` → `Opportunity` → `Task`/`Event`), each with an
explicit field list derived from the user's field mapping plus `Id`, `SystemModstamp`,
`IsDeleted`, and the relevant relationship ids (`AccountId`, `OwnerId`, `ConvertedContactId`…).

Below roughly 50k records per object a plain paged REST `/query` is simpler and finishes faster
(no job polling round-trip), so the loader should pick its strategy from a `COUNT()` probe rather
than being hardcoded to one.

Notes that matter in practice:

- **Persist raw rows in staging** (`apps_salesforce_sync_records`) as they arrive, before mapping.
  Re-mapping is then a local operation. This is the concrete answer to "should we export the data
  first?" — yes, but the export lands in *our* staging table, not in a CSV a human downloads.
- **Checkpoint the high-water mark.** Record `max(SystemModstamp)` per object as the starting
  cursor for the delta phase, so the switch from backfill to incremental has no gap.
- **The backfill must be resumable.** A GoodJob job that dies at 80% must restart from its
  locator/cursor, not from zero. Bulk 2.0 gives a `Sforce-Locator` header for exactly this.
- **Throttle the load side.** Bulk downloads arrive far faster than Woofed can validate and
  insert. Insert in batches with `insert_all`/`upsert_all` where model callbacks allow, or
  enqueue chunked transform jobs — do not create records one HTTP page at a time in the fetch job.

---

## 5. Real-time updates — Salesforce's WAL

Salesforce does not expose a WAL. The closest equivalent is **Change Data Capture (CDC)** read
through the **Pub/Sub API**: an ordered event stream where each event carries a `replay_id`
identifying its position, and a subscriber can resume from a stored `replay_id`. Retention is
**72 hours** — that is the size of the recovery window, and the reason a fallback path is
mandatory.

### 5.1 Options

| Option | Latency | Ordering / replay | Effort in a Rails stack | API cost |
|---|---|---|---|---|
| **SOQL poll on `SystemModstamp`** | Interval (1–15 min) | No replay needed — the cursor *is* the state | Low: Faraday + a GoodJob cron | 1 paged query per object per tick |
| **CDC via Pub/Sub API** | Seconds | `replay_id` checkpoint, 72h window | High: gRPC + Avro decoding, a persistent subscriber process | Event allocation (default ~25k/day, 5 entities on Enterprise) |
| **Flow / Outbound Message → webhook** | Seconds | None (no replay, no ordering) | Low: reuses the existing Chatwoot webhook pattern | None (no API calls consumed) |
| PushTopic / CometD Streaming | Seconds | Legacy replay | Medium | Legacy — do not build new work on it |

### 5.2 Recommendation: polling first, CDC second

**Phase 1 ships polling.** One GoodJob cron entry per install, running
`SELECT <fields> FROM <Object> WHERE SystemModstamp > :cursor ORDER BY SystemModstamp LIMIT 2000`,
advancing the cursor to the max `SystemModstamp` returned, paging until drained. Reasons:

- It is pure Faraday and slots straight into the existing `config/good_job.rb` cron block next to
  `apps_chatwoot_connection_refresh`.
- It has no dependency on the customer enabling CDC entities (which is capped at 5 by default on
  Enterprise and costs money to raise).
- It is self-healing: an outage of any length just means a bigger next batch. No 72-hour cliff.
- For a CRM, "the contact appears within 5 minutes" is nearly always acceptable. Real-time is
  a nice-to-have here, not a requirement — unlike the Chatwoot integration, where a message must
  appear immediately.

**Deletes are the gap in polling.** A deleted record simply stops appearing in query results.
Two mitigations, both cheap: query `IsDeleted = true` against the recycle bin using
`queryAll`, or call the SOAP `getDeleted(start, end)` replication endpoint per object per tick.
Use `queryAll` — it keeps everything on REST and avoids introducing a SOAP client. Records
deleted in Salesforce should be **soft-marked** in Woofed (mapping row flagged `deleted_at`), not
hard-deleted, because Woofed records may have accumulated local data (deals, events, notes) that
the user does not want to lose.

**Phase 2 adds CDC** for installs that want seconds-level latency, behind the same
`SyncRecord` ingestion interface so the transform/load half is untouched. Implementation notes
for when we get there: the `grpc` and `avro` gems cover the wire format; the subscriber must be a
long-lived process (a dedicated GoodJob worker or a separate `bin/` process), it must checkpoint
`replay_id` after each successful *persist* (not on receipt), and on `replay_id` expiry
(gap > 72h) it must fall back to a `SystemModstamp` catch-up query before resuming the stream.
CDC event payloads also only contain *changed* fields plus a `ChangeEventHeader`, so the
transform layer must handle partial records — worth designing the mapper for that from day one
even while polling delivers full records.

---

## 6. Data model in Woofed

### 6.1 New tables

```
apps_salesforces                 — the connection (§3.2); at most one row (§3.2.1)
apps_salesforce_object_mappings  — "Salesforce Object X ⇄ Woofed model Y", + field mapping jsonb
apps_salesforce_record_mappings  — "Salesforce record id ⇄ Woofed record" (the identity map)
apps_salesforce_sync_records     — raw staging payloads
apps_salesforce_sync_runs        — one row per backfill/delta execution: counters, errors, timing
```

**`apps_salesforce_record_mappings`** is the load-bearing one:

| Column | Note |
|---|---|
| `salesforce_id` | 18-char id. Always normalise the 15-char form to 18 before storing |
| `salesforce_object` | `Account`, `Contact`, `Lead`, `Opportunity`, `Task`, `Event` |
| `recordable_type` / `recordable_id` | Polymorphic → `Contact`, `Company`, `Deal`, `Event` |
| `salesforce_system_modstamp` | Last seen remote modification — used to skip no-op updates |
| `last_synced_at`, `sync_status`, `sync_error` | Per-record observability, powers a "failed rows" UI |
| `deleted_at` | Set when the Salesforce record is deleted; the Woofed record survives |

Unique index on `(app_id, salesforce_object, salesforce_id)`, plus one on
`(recordable_type, recordable_id)`. The `app_id` in that index is redundant while only one
connection exists (§3.2.1) and is kept on purpose: it is what lets a second connection be added
later without a migration, exactly as the Chatwoot tables are structured today.

### 6.2 Why a table and not `additional_attributes['salesforce_id']`

The Chatwoot integration stores its foreign id in jsonb
(`index_contacts_on_chatwoot_id` is a functional index on
`additional_attributes ->> 'chatwoot_id'`). That works for one id on one model. It does not
extend to: multiple Salesforce objects mapping onto the same Woofed model (Contact *and* Lead →
`Contact`), per-record sync state and error messages, or tombstones for deleted remote records.

**Do both:** the mapping table is the source of truth, and the loader also mirrors the id into
`additional_attributes['salesforce_id']` so it stays visible in the record detail UI and
searchable through the existing ransack `additional_attributes` allowlist — consistent with how
users already see `chatwoot_id`.

### 6.3 Default entity mapping

| Salesforce | Woofed | Notes |
|---|---|---|
| `Account` | `Company` | `Name` is required on both — a clean match |
| `Contact` | `Contact` | Email/phone uniqueness is the risk (§9) |
| `Lead` | `Contact` | Converted leads (`IsConverted`) must resolve to the *converted* Contact's mapping, never create a second record. Consider a `salesforce_lead` label to keep them distinguishable |
| `Opportunity` | `Deal` | Needs pipeline/stage mapping and a contact resolution rule (§9) |
| `Task` / `Event` | `Event` | Woofed `Event` requires a `contact_id`; `kind` maps to an activity kind |
| `User` | `User` | **Match by email only, never create.** Used to attribute `OwnerId` → `deal_assignees` / `created_by_id`. Unmatched owners are left blank rather than inventing users |
| Custom fields | `custom_attributes` + `CustomAttributeDefinition` | Auto-create definitions with the right `attribute_model` (`contact_attribute`, `deal_attribute`, `company_attribute`) |

---

## 7. Entity and field mapping (user-configurable)

This is the feature that makes the integration usable rather than hardcoded, and it is the part
most likely to be underestimated.

**`apps_salesforce_object_mappings`**

```
app_id            → Apps::Salesforce
salesforce_object → "Opportunity"
woofed_model      → "Deal"
enabled           → boolean (per-object sync toggle)
field_mappings    → jsonb
options           → jsonb  (stage map, pipeline id, filters)
```

`field_mappings` shape:

```json
[
  { "salesforce_field": "Name",        "woofed_field": "name",   "kind": "attribute" },
  { "salesforce_field": "Amount",      "woofed_field": "total_amount_in_cents",
    "kind": "attribute", "transform": "currency_to_cents" },
  { "salesforce_field": "Industry__c", "woofed_field": "industry",
    "kind": "custom_attribute" }
]
```

To populate the UI's field pickers, read Salesforce's **`/services/data/vXX.X/sobjects/<Object>/describe`**
(field names, labels, types, picklist values) and Woofed's own columns plus
`CustomAttributeDefinition`s. Cache the describe response — it is large and changes rarely.

`options` carries what does not fit a flat field pair:

- **Opportunity → Deal**: `pipeline_id` plus a `StageName → stage_id` map. Salesforce stages are
  free-form per record type, so this must be an explicit user-provided mapping with a fallback
  stage for unmapped values, and `IsWon`/`IsClosed` → Woofed `status` (`won` / `lost` / `open`).
- **Filters**: an optional SOQL `WHERE` fragment (e.g. only Opportunities from the last 2 years).
  Validate/whitelist it — do not concatenate raw user input into SOQL.

**Type coercion is where this breaks in practice.** Salesforce `date`/`datetime` need timezone
handling, `currency` needs the `total_amount_in_cents` conversion the `Deal::HandleInCentsValues`
concern already expects, multi-select picklists arrive semicolon-delimited, and Salesforce numbers
can exceed Woofed column precision. Implement coercion as a small set of named transforms
(`currency_to_cents`, `picklist_to_label_list`, `datetime`, `text`) referenced by name from the
mapping, and reject a mapping at save time if the types are incompatible — a mapping that fails
only at row 400,000 of a backfill is a bad experience.

---

## 8. The ingestion pipeline

### 8.1 Job layout

Per `AGENTS.md`: **GoodJob** for long-running/scheduled work, **Sidekiq** for short async tasks.

| Job | Engine | Trigger |
|---|---|---|
| `Apps::Salesforces::Backfill::RunJob` | GoodJob | User clicks "Sync now" after mapping |
| `Apps::Salesforces::Backfill::ObjectJob` | GoodJob | Fan-out, one per mapped object, dependency-ordered |
| `Apps::Salesforces::Delta::PollJob` | GoodJob cron | `config/good_job.rb`, e.g. `*/5 * * * *` |
| `Apps::Salesforces::Transform::BatchWorker` | Sidekiq | Chunk of staged rows → Woofed records |
| `Apps::Salesforces::Connection::RefreshJob` | GoodJob cron | Daily token/connection health check, mirroring `Apps::Chatwoot::Connection::RefreshJob` |

Use `GoodJob::ActiveJobExtensions::Concurrency` with a key of the `Apps::Salesforce` id — as
`Accounts::Apps::Chatwoots::Webhooks::ProcessWebhookJob` already does — so two syncs for the same
org can never interleave and race on the same mapping rows.

### 8.2 The import guard (critical)

Woofed models fire side effects on commit that must **not** run during an import:

- `Contact` has `after_commit :export_contact_to_chatwoot, on: %i[create update]`
  (`app/models/contact.rb`) — importing 50,000 Salesforce contacts would push all of them into
  the customer's Chatwoot account.
- `Contact` publishes Wisper events on create; `Deal` and `Event` trigger broadcasts, webhooks and
  webpush notifications.

The existing `skip_validation` attribute happens to suppress the Chatwoot export and the Wisper
publish, but it *also* disables the email/phone validations — which is exactly what we do not want
during an import that needs to reject malformed data. **Introduce an explicit
`Current.sync_source` (or an `importing` attribute) and gate the outbound side effects on it**,
leaving validations intact. This is a small refactor of `Contact`/`Deal`/`Event` and should be
scheduled *before* the loader, not after.

### 8.3 Idempotency

Every load operation is: resolve mapping → compare `SystemModstamp` → skip if unchanged →
otherwise update inside a transaction and touch the mapping row. Re-running any job for any
window must be safe; that property is what lets us re-drive a failed backfill or replay a CDC
window without producing duplicates.

---

## 9. Conflicts, duplicates and data-quality risks

These are the issues most likely to derail the project, and each needs a decision before coding.

1. **Woofed enforces global uniqueness that Salesforce does not.** `contacts` has a unique index
   on `lower(email)` and on `phone`; `companies` likewise. Salesforce happily holds thousands of
   contacts sharing `info@company.com` or a blank email. **A naive import will fail on a large
   fraction of rows.** Required strategy: match-or-create by email → then phone → then Salesforce
   id; when a *different* Woofed record already owns the email, do not fail silently — record the
   row in `sync_records` with `status: :conflict` and surface it in a "Conflicts" tab for the user
   to resolve. Expect this list to be non-trivial on real orgs.
2. **Phone format.** Woofed requires E.164 (`/\+[1-9]\d{1,14}\z/`); Salesforce phone fields are
   free text (`(11) 99999-9999`, `+55 11 99999 9999`, `ext. 204`). Normalise with a phone library
   using the org's default country; when normalisation fails, import the contact with a blank
   phone and keep the original in `additional_attributes['salesforce_phone_raw']` rather than
   dropping the record.
3. **`Deal` requires `contact_id` and `stage_id`.** Salesforce Opportunities are related to an
   Account, not necessarily to a Contact. Resolution order: primary `OpportunityContactRole` →
   any `OpportunityContactRole` → a contact of the mapped Company → otherwise **skip and report**.
   Auto-creating placeholder contacts pollutes the CRM; make it an explicit opt-in checkbox.
4. **Converted Leads** produce a Lead *and* a Contact for the same human. Always follow
   `ConvertedContactId` and map both Salesforce ids onto the single Woofed contact.
5. **Deletes and merges.** Salesforce record merges leave the losing id dangling
   (`MasterRecordId` points at the survivor). Handle it like a delete-with-redirect: repoint the
   mapping row at the surviving record.
6. **Volume.** A mid-size org is 100k+ contacts and 500k+ tasks. Everything above must be batched,
   and the UI must show progress rather than a spinner — a first sync can legitimately take hours.

---

## 10. UI

Per `AGENTS.md`, new UI is **Inertia + TypeScript (React)**, not Hotwire. Controllers go in
`app/controllers/inertia/accounts/apps/salesforces_controller.rb` with routes inside the existing
`scope module: :inertia` block in `config/routes.rb` (which deliberately drops the `/inertia` path
prefix), and pages in `app/javascript/pages/Apps/Salesforce/`.

Screens:

1. **Connect** — environment (production/sandbox), `client_id`/`client_secret`, "Connect to
   Salesforce" → OAuth redirect → callback stores tokens and org id. Because the user builds the
   External Client App by hand (§3.1), this screen carries the setup instructions inline: the
   exact callback URL for this install and the required scope list, both with copy buttons, plus a
   link to the Salesforce documentation. Since only one connection is allowed (§3.2.1), the page
   is single-state — the Connect form when disconnected, the connection detail when connected —
   with no "add connection" affordance and no connection list.
2. **Mapping** — per Salesforce object: enable toggle, target Woofed model, field-by-field mapping
   built from the cached `describe`, and for Opportunity the pipeline + stage map. Nothing syncs
   until the user saves a mapping, so an accidental connect never floods the CRM.
3. **Sync** — "Run initial sync", current status, per-object progress and counters, last run
   timestamp, next scheduled poll.
4. **Conflicts / errors** — the rows that failed or were skipped, with the reason and a link to
   the conflicting Woofed record. This is what makes the integration debuggable in production;
   without it, every support ticket is "some contacts are missing".

---

## 11. Testing strategy

Following `AGENTS.md`:

- **WebMock** for every Salesforce HTTP interaction — OAuth token exchange and refresh, describe,
  Bulk job create/poll/download, SOQL query paging with `nextRecordsUrl`, `401` refresh-and-retry.
  No real network calls.
- **Request specs** through the real HTTP stack for the OAuth callback and the mapping CRUD, so the
  wiring is covered end to end rather than by mocking the use case.
- **Factories with traits** for `:apps_salesforce` (`:connected`, `:token_expired`,
  `:with_contact_mapping`) instead of inline `create` chains.
- Behaviour-focused examples covering the branches that will actually bite: duplicate email →
  conflict row, unparseable phone → blank phone + raw kept, Opportunity with no contact → skipped
  with reason, unchanged `SystemModstamp` → no write, deleted record → mapping tombstoned and
  Woofed record retained, expired refresh token → `status: error`, and a second connection →
  invalid with the "already exists" message while updating the existing one stays valid (§3.2.1).
- 100% patch coverage on changed files, per the Codecov gate.

---

## 12. Designing for phase 2 (write-back)

Phase 1 does not write to Salesforce, but three decisions taken now are what make phase 2 cheap
rather than a rewrite:

- The **record mapping table is bidirectional by construction** — it already answers "which
  Salesforce record is this Woofed record?".
- **Field mappings are declarative**, so an inverse mapper can reuse them with the transforms run
  backwards.
- Tracking `salesforce_system_modstamp` alongside Woofed's `updated_at` gives the raw material for
  last-write-wins conflict resolution without a schema change.

What phase 2 will still need and phase 1 deliberately omits: an outbound change queue, loop
suppression (a Woofed write that originated from Salesforce must not be pushed back), and the
`api` scope's write permissions.

---

## 13. Delivery plan and status

| # | Stage | Deliverable | Depends on | Status |
|---|---|---|---|---|
| 0 | Discovery / decisions | §14.2 answered, target org identified, sandbox available | — | ⬜ Not started |
| 1 | Token encryption | `ActiveRecord::Encryption` configured; keys via ENV | 0 | ⬜ Not started |
| 2 | Import guard | `Current.sync_source` gate on `Contact`/`Deal`/`Event` side effects | — | ⬜ Not started |
| 3 | `Apps::Salesforce` model + migration | Table, validations (incl. the single-connection guard, §3.2.1), `status` enum, revoke on destroy | 1 | ⬜ Not started |
| 4 | OAuth (web server flow) | Authorize + callback controllers, token refresh, connection health job | 3 | ⬜ Not started |
| 5 | API client | Faraday client: describe, SOQL query + paging, `queryAll`, Bulk 2.0 jobs, retry/401 handling | 4 | ⬜ Not started |
| 6 | Mapping models | `object_mappings` + `record_mappings` + `sync_records` + `sync_runs` migrations and models | 3 | ⬜ Not started |
| 7 | Mapping UI (Inertia) | Connect screen (with the External Client App setup instructions, callback URL and scopes) + object/field mapping screen fed by cached describe | 5, 6 | ⬜ Not started |
| 8 | Transform layer | Named transforms, per-object mappers, conflict detection | 6 | ⬜ Not started |
| 9 | Backfill | Bulk/REST strategy selection, staging writes, resumable, high-water mark | 5, 8 | ⬜ Not started |
| 10 | Load — Account/Contact/Lead | Idempotent upsert into `Company`/`Contact`, dedup rules | 2, 8, 9 | ⬜ Not started |
| 11 | Load — Opportunity | `Deal` + pipeline/stage mapping + contact resolution | 10 | ⬜ Not started |
| 12 | Load — Task/Event | Woofed `Event` records | 10 | ⬜ Not started |
| 13 | Delta poll | `SystemModstamp` cursor job + GoodJob cron entry | 9, 10 | ⬜ Not started |
| 14 | Deletes | `queryAll` / `IsDeleted` sweep, mapping tombstones | 13 | ⬜ Not started |
| 15 | Sync + conflicts UI | Progress, counters, per-record errors, conflict resolution | 7, 13 | ⬜ Not started |
| 16 | Hardening | Rate-limit backoff, API-usage telemetry, PII-safe logging, docs | 13–15 | ⬜ Not started |
| 17 | Pilot on a real org | Sandbox → one production org, measured | 16 | ⬜ Not started |
| 18 | *(Phase 2)* CDC via Pub/Sub API | gRPC subscriber, `replay_id` checkpointing, 72h gap fallback | 17 | ⬜ Not started |
| 19 | *(Phase 2)* Write-back | Outbound queue, loop suppression | 18 | ⬜ Not started |

Status legend: ⬜ Not started · 🟡 In progress · ✅ Done · ⛔ Blocked

A viable first release is stages **0–16**; stage 17 is the gate before calling it GA. Stages 1
and 2 are unglamorous but genuinely blocking — doing them after the loader means reworking it.

---

## 14. Decisions

### 14.1 Settled

1. **The customer owns the External Client App, and configures it manually in Salesforce.**
   Woofed never provisions it; the user creates the app, sets the callback URL, selects the
   scopes, and pastes `client_id`/`client_secret` into the Connect screen. A Woofed-owned app with
   a fixed redirect is rejected — it only works for a managed/cloud offering, which we are not
   building. Details and the exact user-facing steps in §3.1; UI consequences in §10.
2. **Exactly one Salesforce connection per Woofed install.** Enforced by a model validation on
   create, not by the schema: the tables mirror `apps_chatwoots` and physically allow several
   rows, and every child table keeps `app_id`. Allowing more than one later is therefore a UI
   change plus removing the validation — no migration. Details in §3.2.1.

### 14.2 Still open

1. **Latency requirement.** If 5-minute polling is acceptable, stage 18 (CDC) can be deferred
   indefinitely — and it is by far the most expensive stage on the list.
2. **Do Salesforce Tasks/Events belong in Woofed at all?** They are the highest-volume objects and
   the lowest-value ones. Consider shipping stages 10–11 only and treating stage 12 as optional.
3. **Conflict policy on the first sync**: skip conflicting records and report, or merge into the
   existing Woofed record? Skipping is safer and is the assumption above.
4. **Owner mapping when no Woofed user matches** the Salesforce `OwnerId` — leave unassigned
   (assumed) or assign to a default user?
