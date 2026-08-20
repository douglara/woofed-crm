# Stage 9 — Backfill

**Parent plan:** [plan.md](plan.md) — delivery table §13, row 9. Builds on
[stage 5](stage-05-api-client.md) and [stage 6](stage-06-mapping-models.md).

The initial load: everything an enabled object has, downloaded into staging. Triggered by the user,
never automatically — connecting an org still imports nothing.

---

## 1. What was built

| File | Role |
|---|---|
| [backfill/start.rb](../../../../app/models/apps/salesforce/backfill/start.rb) | One run per enabled mapping, in dependency order |
| [backfill/soql.rb](../../../../app/models/apps/salesforce/backfill/soql.rb) | Builds the SELECT and the COUNT for an object |
| [backfill/relationship_fields.rb](../../../../app/models/apps/salesforce/backfill/relationship_fields.rb) | The lookups to carry, read from the object's describe |
| [backfill/store_records.rb](../../../../app/models/apps/salesforce/backfill/store_records.rb) | Writes a downloaded page into staging |
| [backfill/object_job.rb](../../../../app/jobs/apps/salesforce/backfill/object_job.rb) | Picks REST or Bulk and drives the download |
| [backfill/poll_job.rb](../../../../app/jobs/apps/salesforce/backfill/poll_job.rb) | Asks whether the bulk job finished, with backoff |
| [backfill/download_job.rb](../../../../app/jobs/apps/salesforce/backfill/download_job.rb) | Downloads the finished job page by page |

Plus the trigger: `POST /accounts/:id/apps/salesforce/sync` and a sync panel on the mapping screen
showing the latest run per object.

---

## 2. Decisions worth keeping

### 2.1 The cursor is stamped at submission, not taken from the data

Taking the high-water mark from the newest record downloaded loses edits made *while* a long
download runs:

```
14:00  run starts, record A downloaded with stamp 10:00
14:30  A is edited in Salesforce      → A's stamp becomes 14:30
14:45  record B downloaded with stamp 14:45
15:00  run ends, newest row seen = 14:45

next catch-up asks for > 14:45 → A's edit is never seen
```

So `SyncRun#start!` stamps the cursor with the submission instant. The next run re-reads a few
records that did not change, which the load ignores — far cheaper than losing one silently.

### 2.2 Strategy is chosen with one call

A `SELECT COUNT()` decides: below 50k records a paged REST query is simpler and finishes sooner,
because a bulk job costs a create, several polls and a download round-trip before the first record
arrives. Above it, paging REST would spend one API call per 2000 records against an allocation the
customer shares with every other integration they run.

### 2.3 Nothing waits in a worker

Salesforce never announces that a bulk job finished, and a job can run for over an hour. `PollJob`
reschedules itself with a growing interval (10s → 5min, capped) instead of sleeping, because every
poll is an API call spent. A job that never finishes is failed after a bounded number of attempts
rather than polled forever.

### 2.4 Resumption lives in the row, not in job arguments

The bulk job id is stored before anything else happens, so a retry polls the job the org already has
instead of submitting a second one. The locator is checkpointed after each page, so a download that
dies at 80% continues from there.

### 2.5 Objects come from the org, not from a constant

A Woofed Company may come from `Account` in one org and from `Escola__c` in another, so the object
picker is fed by the org's global describe and any object can be pointed at any of the four models
the sync writes to. Relationship fields are read from each object's describe for the same reason: a
custom object has its own lookups, and asking for a field an object does not have makes Salesforce
reject the whole query.

### 2.6 An object already downloading is skipped

Clicking "Sync now" twice must not create a second bulk job for the same data. A run in a `pending`
or `running` state is left alone.

---

## 3. Verification

219 examples across the Salesforce specs, 0 failures, **100% line coverage on every Salesforce
file**. Full suite: 1495 examples with the same 19 pre-existing failures from placeholder values in
the local `.env`.

One thing the specs forced: the test environment runs GoodJob inline, so asserting that a job
scheduled the next one would instead execute the whole chain — and a self-rescheduling poll would
recurse until it gave up. The backfill specs share a context that swaps in the ActiveJob test
adapter for the three jobs.

---

## 4. What is next

Stage 10 (load) reads the staged rows and creates the Woofed records, and it is blocked on stage 2:
`Contact` fires `after_commit :export_contact_to_chatwoot`, so importing 50,000 Salesforce contacts
would push all of them into the customer's Chatwoot account.

Stage 13 changes shape from the original plan: incoming changes will arrive by **webhook** (a
record-triggered Flow in the customer's org calling Woofed) with the cursor-based query kept as a
**daily catch-up**, since a webhook that is never delivered is never retried. Both already have
their query builder — a catch-up is the same SOQL with a cursor.
