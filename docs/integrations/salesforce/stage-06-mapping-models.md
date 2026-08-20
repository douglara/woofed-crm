# Stage 6 — Mapping models

**Parent plan:** [plan.md](plan.md) — delivery table §13, row 6. Builds on
[stage 5](stage-05-api-client.md).

The four tables that give the API client somewhere to write: what the user configured, what was
already synced, what was downloaded, and how each run went.

---

## 1. What was built

| Table / model | What it holds |
|---|---|
| `apps_salesforce_object_mappings` — [ObjectMapping](../../../app/models/apps/salesforce/object_mapping.rb) | Configuration: Account → Company, and which field feeds which field |
| `apps_salesforce_record_links` — [RecordLink](../../../app/models/apps/salesforce/record_link.rb) | Identity map: Account `001Hn…` ⇄ Company #42 |
| `apps_salesforce_raw_records` — [RawRecord](../../../app/models/apps/salesforce/raw_record.rb) | Staging: the raw row exactly as Salesforce sent it |
| `apps_salesforce_sync_runs` — [SyncRun](../../../app/models/apps/salesforce/sync_run.rb) | One execution per object: bulk job id, locator, cursor, counters |

Plus [RecordId](../../../app/models/apps/salesforce/record_id.rb), which normalises Salesforce ids.

---

## 2. The mapping table and the link table are different levels

`ObjectMapping` is **configuration** — four to six rows in the whole install, written by the user,
answering "how do I translate an Account?". `RecordLink` is **data** — hundreds of thousands of
rows on a real org, written by the sync, answering "which Company is this particular Account?".

A load does both lookups: the object mapping tells it an Account becomes a Company with `Name`
feeding `name` (the same for all 100k Accounts), and the record link tells it this Account is
already Company #42, so it updates instead of creating a second one.

### 2.1 The record link is keyed on the pair, not on the id

`Contact` and `Lead` both become a Woofed `Contact`, so `recordable_type` alone does not say where a
row came from. The unique index is `(app_id, salesforce_object, salesforce_id)`: the object plus the
id is what identifies a record on the Salesforce side.

`recordable` is polymorphic rather than four nullable columns (`company_id`, `contact_id`, …), so
adding a new target model later needs no migration.

### 2.2 Ids are normalised to 18 characters

Salesforce has two ids for the same record: 15 characters, case-sensitive, shown in record URLs and
report exports, and 18 characters, case-insensitive, returned by the API. Both circulate, and
storing whichever arrived would let one Salesforce record occupy two link rows and become two
Woofed records — the exact duplicate the table exists to prevent.

`normalizes :salesforce_id` runs every write **and every lookup** through `RecordId`, so a 15-char
id finds the row stored under its 18-char form. The conversion is local arithmetic over the
capitalisation of the first fifteen characters; no call to Salesforce is involved.

---

## 3. Why staging exists

`RawRecord` keeps the raw payload before any mapping is applied. Three things depend on that:

- **Remapping without re-downloading.** When the user changes a field mapping — and they will — the
  transform re-runs from staging. API calls are the customer's metered resource, shared with every
  other integration they run.
- **Problem rows have somewhere to live.** A contact whose email already belongs to another Woofed
  record becomes `status: conflict` with its reason, which is what the conflicts screen will list.
  Without it, those records simply vanish and every support ticket is "some contacts are missing".
- **Download speed is decoupled from write speed.** Bulk results arrive far faster than Woofed can
  validate and insert.

Staging deliberately allows the same record to be staged twice: a re-run has to be able to bring the
row again. Deduplication happens at load time, through `RecordLink`.

---

## 4. Why the run state is a row and not a job argument

`SyncRun` carries `bulk_job_id`, `locator`, `cursor` and the counters. GoodJob would persist job
arguments too, but that is not enough:

- **Idempotency.** If the job that created the bulk job dies before scheduling the poll, a retry
  that only had arguments would submit a **second** bulk job — duplicated work, quota spent twice.
  With the row, the retry sees a `bulk_job_id` and goes straight to polling.
- **Observability.** The sync screen has to show progress per object: how many records arrived, what
  state the run is in, what the error was. That has to be a queryable row.

`complete!` only advances the `cursor` when a run actually finished, since the cursor is where the
next delta starts — advancing it on a partial run would silently skip records.

---

## 5. Verification

118 examples across the Salesforce specs, 0 failures, **100% line coverage on every Salesforce
file**. Full suite: 1394 examples with the same 19 pre-existing failures (Evolution API and woofbot,
from placeholder values in the local `.env`).

Covered: an object mapped twice rejected, an unsupported target model rejected, only enabled
mappings returned, the SOQL field list de-duplicated, the same id allowed under a different
Salesforce object but not under the same one, the 15-char form colliding with a stored 18-char row,
lookup by either form, modstamp comparison in both directions and with either side missing,
tombstoning that keeps the Woofed record, run start/complete/fail including the cursor kept when
there is nothing newer, resumption state surviving, and the three staging outcomes.

---

## 6. What is next

Stage 7 (mapping UI) is what makes any of this reachable: the Connect screen with the callback URL
and scopes, and the object/field mapping screen fed by `describe_object`. Stage 8 (transform) is the
first consumer of `ObjectMapping`, and stage 9 (backfill) the first writer of `SyncRun` and
`RawRecord`.
