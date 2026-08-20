# Stage 8 — Transform layer

**Parent plan:** [plan.md](plan.md) — delivery table §13, row 8. Builds on
[stage 6](stage-06-mapping-models.md).

Turns a raw Salesforce row into the attributes a Woofed record is built from, driven entirely by the
user's field mapping. It never touches the database, so a staged payload can be re-transformed after
a mapping change without downloading the org again.

---

## 1. What was built

| File | Role |
|---|---|
| [transform/record.rb](../../../app/models/apps/salesforce/transform/record.rb) | One row + one object mapping → attributes, custom attributes, warnings |
| [transform/value.rb](../../../app/models/apps/salesforce/transform/value.rb) | Dispatches a value to the transform named in the mapping |
| [transform/inferred.rb](../../../app/models/apps/salesforce/transform/inferred.rb) | Picks the transform when the mapping does not name one |
| `transform/{text,currency_to_cents,datetime,picklist_to_label_list,boolean,phone}.rb` | The named transforms |
| [transform/conflict.rb](../../../app/models/apps/salesforce/transform/conflict.rb) | Detects a uniqueness collision before the insert fails |

---

## 2. Decisions worth keeping

### 2.1 An unconvertible value never drops the record

A contact whose phone Salesforce stores as `(11) 3333-4444` is still worth importing. The row is
transformed, the original is kept under `additional_attributes['salesforce_phone_raw']`, and the
reason is returned as a warning. Dropping the record would lose the name, the email and the company
in order to avoid losing a phone number.

### 2.2 Phone numbers are never guessed into a country

Woofed requires E.164; Salesforce phone fields are free text. A number without a country code cannot
be normalised without knowing which country it belongs to, and prefixing a default would silently
create contacts nobody can call. So the transform applies a country code only when the mapping
carries one (`options['country_code']`), and otherwise reports the value as unconvertible. Extensions
— everything from the first letter on — are stripped, because they are never part of the number.

### 2.3 Timestamps are stored in UTC

Values arrive with an explicit offset over REST and Bulk alike, but a plain date field carries none.
Those are parsed as UTC rather than in the app's zone, so the stored instant is zone-independent and
the browser renders every timestamp in the viewer's timezone.

### 2.4 A field Salesforce did not send is left alone

An empty value and an absent field are different things: the first is a value the user cleared and
gets written, the second says nothing about the record and is skipped. This is not hypothetical —
CDC events carry only the changed fields (§5 of the plan), so conflating the two would let a phone
update wipe the rest of a contact.

### 2.5 The transform is inferred from the target column

The mapping screen asks which field feeds which field, not how to convert it — a question most users
cannot answer. The target column already carries the answer: an `_in_cents` integer needs cents, a
datetime column needs a parsed time, a phone column needs E.164. A mapping can still name a
transform explicitly, and that wins.

### 2.6 Conflicts are detected, not discovered on insert

`contacts` has a unique index on `lower(email)` and on `phone`, `companies` likewise, while a
Salesforce org happily holds thousands of contacts sharing `info@company.com`. A naive import would
fail on a large fraction of rows. `Conflict` looks the value up first and names the Woofed record
that already owns it, which is what turns "some contacts are missing" into a listed conflict a human
can resolve. The record this row already maps to owning the value is not a conflict — that is the
record being updated.

---

## 3. Verification

168 examples across the Salesforce specs, 0 failures, **100% line coverage on every Salesforce
file**. Full suite: 1444 examples with the same 19 pre-existing failures from placeholder values in
the local `.env`.

Two things the specs caught: a hash passed without braces became keyword arguments under Ruby 3, and
creating a `Contact` in a spec fires the Chatwoot export callback — the very side effect stage 2's
import guard exists to gate.

---

## 4. What is next

Stage 9 (backfill) is the first writer of `SyncRun` and `RawRecord`, and stage 10 the first consumer
of this layer: it resolves the record link, runs `Conflict`, and creates or updates the Woofed
record.

**Stage 2 is now on the critical path.** `Contact` fires `after_commit :export_contact_to_chatwoot`,
so importing 50,000 Salesforce contacts would push all of them into the customer's Chatwoot account.
It has to land before stage 10, and it conflicts with the "no Chatwoot changes" constraint by
construction — that callback is the one that has to be gated.
