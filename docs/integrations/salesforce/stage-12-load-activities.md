# Stage 12 — Load: Task and Event → Event

**Parent plan:** [plan.md](plan.md) — delivery table §13, row 12. Builds on
[stage 11](stage-11-load-opportunity.md).

Salesforce activities become Woofed events. The whole difficulty is the same as with deals: Woofed
requires a contact on every event, and Salesforce does not.

---

## 1. What was built

| File | Role |
|---|---|
| [load/events/prepare.rb](../../../app/models/apps/salesforce/load/events/prepare.rb) | Kind, contact, deal and the done stamp |
| [load/events/find_contact.rb](../../../app/models/apps/salesforce/load/events/find_contact.rb) | Who the activity belongs to |
| [load/find_mapped.rb](../../../app/models/apps/salesforce/load/find_mapped.rb) | The identity map read backwards, for any lookup field |

`FindCompany` became `FindMapped`: three near-identical lookups — `AccountId` → Company, `WhoId` →
Contact, `WhatId` → Deal — are the same question asked with different arguments.

---

## 2. Decisions worth keeping

### 2.1 Salesforce splits an activity's relations in two

`WhoId` points at a person (Contact or Lead) and `WhatId` at whatever else the activity concerns —
an Opportunity, an Account, a custom object. So the contact is looked for in that order:

1. `WhoId`, the person Salesforce itself recorded
2. the contact of the deal in `WhatId`
3. a contact of the company in `WhatId`

A call logged against an opportunity with nobody on it, and against a company with no contacts, has
no one to belong to. It is reported rather than imported as an orphan.

### 2.2 The activity lands on the deal's timeline

When `WhatId` resolves to a Deal, the event is attached to it as well as to the contact — which is
what makes an imported call show up where a user would look for it.

### 2.3 Kind defaults to activity

Woofed's other event kinds are things Woofed itself produces: a message, a stage change, a deal
won. A Salesforce task or event is an `activity`, and the mapping can override it (`options['kind']`)
for orgs that use tasks as notes. An unknown kind falls back rather than failing the row.

---

## 3. A consequence worth stating

`Event` schedules a webpush notification whenever `scheduled_at` is set
([event.rb:80](../../../app/models/event.rb#L80)). Nothing here sets that column — it is only written
if the user maps a Salesforce date onto it — but if they do, importing historical tasks will
schedule a notification per row, and past dates fire immediately. This is the same class of problem
as the Chatwoot export on `Contact`, and the same answer applies: stage 2's import guard is what
would gate it.

---

## 4. Verification

259 examples across the Salesforce specs, 0 failures, **100% line coverage on every Salesforce
file**. Full suite: 1535 examples with the same 19 pre-existing failures from placeholder values in
the local `.env`.

Covered: contact from `WhoId`, from the deal in `WhatId`, from the company in `WhatId`, none of them
reported, the deal attached, done stamped from `ActivityDate`, a configured kind, and a kind Woofed
does not have.

---

## 5. What is next

Stage 13, in the shape decided during this work: a **webhook receiver** for changes made in
Salesforce, plus the **daily catch-up** query as the safety net, since a webhook that is never
delivered is never retried. Both already have their query builder and their loader — a catch-up is
the same SOQL with a cursor, and a webhook payload is one more staged row.
