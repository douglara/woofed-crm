# Stage 10 — Load

**Parent plan:** [plan.md](plan.md) — delivery table §13, row 10. Builds on
[stage 8](stage-08-transform.md) and [stage 9](stage-09-backfill.md).

Staged rows become Woofed records. This is the step that closes the loop: after it, a Salesforce
org's accounts and contacts exist in the CRM.

---

## 1. What was built

| File | Role |
|---|---|
| [load/record.rb](../../../app/models/apps/salesforce/load/record.rb) | One staged row → one Woofed record, with its mapping |
| [load/record/find_or_build.rb](../../../app/models/apps/salesforce/load/record/find_or_build.rb) | Decides update vs. create |
| [load/batch_worker.rb](../../../app/models/apps/salesforce/load/batch_worker.rb) | Loads the pending rows of a run (Sidekiq) |

The backfill enqueues a batch after every page it stages, so loading trails the download instead of
waiting for it: on a large object the first records are usable long before the last page arrives.

---

## 2. Decisions worth keeping

### 2.1 Three ways to find the target record

```
record link exists?     → that record, update it
email or phone matches? → adopt that record, and link it from now on
neither                 → a new record
```

The middle case is what keeps a first sync from duplicating half the CRM. Someone the sales team
added by hand last week is the same person Salesforce is now sending, and `contacts` has a unique
index on `lower(email)` — creating a second one would fail on insert anyway. Email is matched before
phone, because a number may be the company switchboard while an email identifies a person.

### 2.2 A collision is a decision, not an error

Adopting a record whose email nobody owns is normal. Writing an email that belongs to a **different**
Woofed record is not something the sync can decide: the row is marked `conflict` with the reason and
the record that owns the value, and a human resolves it. Without this, the same situation would be a
failed insert whose only trace is a log line.

### 2.3 An unchanged record does nothing

The mapping stores the last modification stamp seen. A catch-up brings back its whole window, most
of it untouched, so a row whose stamp has not moved skips the write entirely — which also keeps the
`updated_at` of Woofed records from churning on every sweep.

### 2.4 jsonb columns are merged, never replaced

`custom_attributes` and `additional_attributes` also hold what the user and other integrations put
there. The load merges its keys in, so importing a Salesforce field does not wipe a Chatwoot id.

### 2.5 Every row ends marked

Processed, conflict, or failed with the reason on the row. A bad record costs one row, not the
batch: rows are loaded individually, so one contact whose name Salesforce left blank does not stop
the other 9,999 in the page.

---

## 3. A consequence worth stating once

Loading contacts fires `Contact`'s `after_commit :export_contact_to_chatwoot`. On an install that
has the Chatwoot integration configured, importing Salesforce contacts will push them into that
Chatwoot account — stage 2 of the plan (the import guard) is what would gate this, and it has not
been built. On installs without Chatwoot the callback returns immediately and nothing happens.

---

## 4. Verification

240 examples across the Salesforce specs, 0 failures, **100% line coverage on every Salesforce
file**. Full suite: 1516 examples with the same 19 pre-existing failures from placeholder values in
the local `.env`.

Covered: create with custom attributes and the mirrored Salesforce id, update through the mapping,
no-op when the stamp has not moved, adoption by email and by phone, email preferred over phone,
case-insensitive matching, a value owned by another record becoming a conflict, an invalid record
keeping its reason, a mapping deleted after staging, and jsonb merged rather than replaced.

---

## 5. What is next

Stage 11 (Opportunity → Deal) needs pipeline and stage mapping plus a contact resolution rule, and
stage 12 (Task/Event → Event) needs a contact to hang the event on. Both are where relationship
resolution finally happens — `AccountId` on a Contact linking it to the Company that Salesforce says
it belongs to is the same machinery, and belongs with them rather than duplicated here.
