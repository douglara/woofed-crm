# Stage 11 — Load: Opportunity → Deal

**Parent plan:** [plan.md](plan.md) — delivery table §13, row 11. Builds on
[stage 10](stage-10-load.md).

An opportunity carries an amount, a stage name and an account. A Woofed deal needs a stage, the
pipeline that stage belongs to, a contact and an outcome. This stage is the translation.

---

## 1. What was built

| File | Role |
|---|---|
| [load/deals/prepare.rb](../../../app/models/apps/salesforce/load/deals/prepare.rb) | Fills stage, pipeline, contact, outcome and the company link |
| [load/deals/find_stage.rb](../../../app/models/apps/salesforce/load/deals/find_stage.rb) | `StageName` → Woofed stage, from the user's map |
| [load/deals/find_contact.rb](../../../app/models/apps/salesforce/load/deals/find_contact.rb) | Who the deal hangs on |
| [load/find_company.rb](../../../app/models/apps/salesforce/load/find_company.rb) | The Woofed company a Salesforce lookup points at |

`Load::Record` dispatches to a preparer by target model, so Company and Contact go straight to save
and only Deal pays for this.

---

## 2. Decisions worth keeping

### 2.1 Stages must be mapped by the user

Salesforce stage names are free-form per record type — "Prospecting" in one org, "Qualificação" in
another — and have nothing in common with the pipeline the customer built in Woofed. Nothing can be
inferred, so `options['stage_map']` holds the correspondence and `options['default_stage_id']`
catches names it does not cover. A row whose stage is neither mapped nor defaulted is reported
rather than dropped onto an arbitrary stage, because a deal on the wrong stage is worse than a deal
the user is told about.

### 2.2 `AccountId` is the company, not a login

Salesforce's **Account** is the customer organisation, the equivalent of Woofed's `Company` — not a
user account. `Opportunity.AccountId` therefore says which company the deal is with, and the deal is
linked to it. The lookup is by `recordable_type: 'Company'` rather than by object name, so it works
whether that company was mapped from `Account` or from `Empresa__c`.

### 2.3 The placeholder contact is a documented fiction

`deals.contact_id` is NOT NULL; a Salesforce opportunity relates to an Account and only optionally to
people, through OpportunityContactRole. So a real case exists that Woofed cannot represent: a large
opportunity with a company and nobody on it.

Two answers are tried: a contact of the company, then — **only if the user ticked
`create_placeholder_contact`** — a contact named after the company. That placeholder is a fiction: a
"person" called Acme Ltda with no email and no phone, created so the deal can exist. It is off by
default because it pollutes the CRM, and offered because for some customers losing million-real
opportunities on import is worse than carrying contacts named after companies. With neither, the row
is reported and the deal is not imported.

**The better answer is not implemented.** OpportunityContactRole is where Salesforce actually records
the people on a deal. It can be fetched as a SOQL subquery, but Bulk API 2.0 rejects subqueries — so
exactly the large objects that need Bulk would be left out. Doing it properly means a second pass
over the junction object, which is its own piece of work.

### 2.4 Outcome comes from IsClosed and IsWon

Open until Salesforce says closed; then won or lost, stamped with `CloseDate` — which is what Woofed
shows as when it happened.

---

## 3. A bug this stage surfaced

`Deal` answers to `total_amount_in_cents=` — a concern defines the setter — but has no such column;
what it shows comes from its products. Mapping an Opportunity's `Amount` onto it raised
`NoMethodError` from inside the setter and took the whole batch down with it.

The loader now checks that every mapped field is a real column before assigning, and reports the row
naming the fields that are not. A mapping can outlive the column it points at, and one stale mapping
must not stop the other 9,999 rows in a page.

An Opportunity's amount therefore lands in a custom attribute until Woofed has a column for it.

---

## 4. Verification

252 examples across the Salesforce specs, 0 failures, **100% line coverage on every Salesforce
file**. Full suite: 1528 examples with the same 19 pre-existing failures from placeholder values in
the local `.env`.

Covered: stage and pipeline from the map, the default stage, an unmapped stage reported, contact
from the company, the opt-in placeholder, no contact reported, won and lost with their dates, the
company link and its idempotence, an opportunity whose account is not imported yet, and the whole
path through the loader.

---

## 5. What is next

Stage 12 (Task/Event → Event) needs a contact to hang each activity on — the same resolution
problem, this time through `WhoId` and `WhatId`. Stage 13 is the webhook receiver plus the daily
catch-up.
