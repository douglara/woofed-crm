# Stage 5 — API client

**Parent plan:** [plan.md](plan.md) — delivery table §13, row 5. Builds on
[stage 4](stage-04-oauth.md).

Everything that reads from a Salesforce org: describe, SOQL with paging, `queryAll`, and Bulk API
2.0 query jobs.

---

## 1. What was built

One generic client, reached through `salesforce.api_client`, and **one class per endpoint** with a
`self.call`, each with a `.http` file next to it documenting the raw request.

| File | Role |
|---|---|
| [api/client.rb](../../../app/models/apps/salesforce/api/client.rb) | Bearer token, 401 refresh-and-retry, undecryptable-credential guard, error normalisation |
| [api/sobject/describe.rb](../../../app/models/apps/salesforce/api/sobject/describe.rb) | Object metadata, cached |
| [api/query/page.rb](../../../app/models/apps/salesforce/api/query/page.rb) | First page of a SOQL result, `query` or `queryAll` |
| [api/query/next_page.rb](../../../app/models/apps/salesforce/api/query/next_page.rb) | Follows the `nextRecordsUrl` cursor |
| [api/query/all_pages.rb](../../../app/models/apps/salesforce/api/query/all_pages.rb) | Walks the pages to the end, optionally streaming each one |
| [api/bulk/query/create.rb](../../../app/models/apps/salesforce/api/bulk/query/create.rb) · [state.rb](../../../app/models/apps/salesforce/api/bulk/query/state.rb) · [results.rb](../../../app/models/apps/salesforce/api/bulk/query/results.rb) | Bulk 2.0 job: submit, poll, download |

`Page` and `NextPage` are separate because they are separate endpoints: one takes SOQL, the other
takes an opaque cursor that already encodes the query, the offset and whether it was `query` or
`queryAll`.

---

## 2. Decisions worth keeping

### 2.1 A 401 is the real expiry signal

`token_expires_at` is a guess — Salesforce never says how long a session lasts (§3.2 of the
[stage 1 + 3 notes](stage-01-token-encryption.md)). So the client treats a 401 as normal: refresh
with `force: true`, rebuild the connection with the new token, replay the request **once**. A second
401, or a refresh Salesforce rejects, is reported instead of looping.

### 2.2 Undecryptable credentials land in the same place as a revoked app

Reading `access_token` after a `SECRET_KEY_BASE` rotation raises
`ActiveRecord::Encryption::Errors::Decryption`. The client catches it before making any request,
flips the connection to `status: error` and returns "connect again" — the same dead end as an app
the customer revoked, and the closing of the loop stage 1 opened.

### 2.3 Describe is cached; failures are not

The payload is hundreds of KB per object and only changes when an admin edits the object, so it is
cached for 12 hours keyed by connection **and api version** — bumping the version changes the
payload shape. A failed describe is never cached, otherwise a transient error would blank the
mapping screen's field pickers for half a day.

### 2.4 Query pages, and can stream

Salesforce returns ~2000 records plus a `nextRecordsUrl`. `query` follows that chain to the end so
no caller reimplements it, and takes an optional block that receives each page as it arrives —
accumulating 100k records in a worker's memory is not an option. `include_deleted: true` switches to
`queryAll`, the only endpoint that still returns deleted rows, which is how stage 14 will notice a
record that simply stopped appearing.

### 2.5 Bulk is three separate steps, on purpose

A plain query costs one call per 2000 records against an allocation of ~100k calls per day that the
customer shares with every other integration they run. A bulk job costs a handful of calls
regardless of volume, and its records come out of a separate allocation.

Salesforce never announces that a job finished — the only way to know is to poll `state` — and a job
can run for over an hour. So `create`, `state` and `results` are separate calls with no sleeping in
between: stage 9's job will reschedule itself with backoff, since every poll is a call spent against
the customer's quota. `results` takes a `locator`, which is what makes a download that dies at 80%
resume instead of restarting.

### 2.6 CSV is handed over as strings

Bulk results are CSV only — there is no JSON option for query jobs. Every value arrives as a string
and a null is indistinguishable from an empty string. `Results` parses rows and stops there;
coercion belongs to the transform layer (stage 8), and nothing is written to Woofed records here.

---

## 3. Verification

77 examples across the Salesforce specs, 0 failures, **100% line coverage on all sixteen files**.
Full suite: 1353 examples with the same 19 pre-existing failures (Evolution API and woofbot, caused
by placeholder values in the local `.env`).

Covered: the token on every request, a 401 refreshed and replayed, a refresh Salesforce rejects,
error bodies turned into their messages, a status-only fallback, an unreachable org, credentials
that no longer decrypt, JSON and raw bodies, describe served from cache and failures not cached,
single-page and multi-page queries, block streaming, `queryAll`, a failure on a later page, bulk job
creation for both operations, job states including `Failed`, CSV parsing, locator resumption, an
empty result, and a failed download.

---

## 4. What is next

Stage 6 (mapping models) and stage 7 (mapping UI) are what turn this into something a user can
point at their org: `object_mappings` / `record_links` / `raw_records` / `sync_runs`, then the
Connect and mapping screens that `describe_object` now has the data for.
