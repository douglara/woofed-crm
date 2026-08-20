# Stage 15 — Sync and conflicts UI

**Parent plan:** [plan.md](plan.md) — delivery table §13, row 15. Builds on
[stage 7](stage-07-mapping-ui.md) and the load stages.

What makes the integration debuggable in production. Without it, a user learns that some records are
missing and never which ones or why.

---

## 1. What was built

| File | Role |
|---|---|
| [components/salesforce/SyncPanel.tsx](../../../../app/javascript/components/salesforce/SyncPanel.tsx) | "Sync now" and the state of the latest run per object |
| [components/salesforce/ProblemRecords.tsx](../../../../app/javascript/components/salesforce/ProblemRecords.tsx) | The rows that did not make it, with their reason and a retry |
| [salesforces/raw_records_controller.rb](../../../../app/controllers/inertia/accounts/apps/salesforces/raw_records_controller.rb) | Loads one row again |

The screen shows, per object: status, how many records were downloaded, and the error if the run
stopped. Below it, up to fifty failed or conflicting rows — a bad mapping can produce thousands, and
a list nobody can read is not a list.

---

## 2. Decisions worth keeping

### 2.1 Conflicts and failures share a list but not a meaning

A **failure** is something that may work on a second attempt: a validation, a mapping pointing at a
column that does not exist, a value the transform could not convert. A **conflict** is a decision
waiting for a human — the email belongs to another record, and no rule can say which one keeps it.
They are badged differently and both carry the reason on the row, because "some contacts are
missing" is the support ticket this screen exists to prevent.

### 2.2 Retrying is possible because the payload was kept

Staging holds the raw row, so resolving a problem is loading it again — after the user fixed the
mapping in Woofed or the record in Salesforce. Nothing has to be downloaded from the org again,
which is the point of staging in the first place (§4 of the plan).

The retry runs the load inline and reports what happened to that row: imported, failed again with
the new reason, or still conflicting. Telling the user "queued" and leaving them to refresh would
hide exactly the answer they asked for.

---

## 3. Verification

263 examples across the Salesforce specs, 0 failures, **100% line coverage on every Salesforce
file**; TypeScript clean. Full suite: 1539 examples with the same 19 pre-existing failures from
placeholder values in the local `.env`.

Covered: the problem list rendered with its reason, a retry that succeeds, one that fails again and
keeps the new reason, and a row that no longer exists.

---

## 4. What is left in the plan

- **Stage 13 — incoming changes**, deferred by choice: a webhook receiver (a record-triggered Flow
  in the customer's org) plus the daily cursor query as the safety net.
- **Stage 14 — deletes**: a `queryAll` sweep tombstoning the mapping while the Woofed record
  survives, since it may have accumulated local data.
- **Stage 16 — hardening**: rate-limit backoff, API-usage telemetry, PII-safe logging, docs.
- **Stage 2 — the import guard**, still unbuilt: `Contact`'s Chatwoot export and `Event`'s webpush
  scheduling both fire during an import.
