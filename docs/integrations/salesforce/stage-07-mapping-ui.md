# Stage 7 — Connect and mapping UI

**Parent plan:** [plan.md](plan.md) — delivery table §13, row 7. Builds on
[stage 5](stage-05-api-client.md) and [stage 6](stage-06-mapping-models.md).

The first stage a human can actually use: connect an org, then say which Salesforce object becomes
which Woofed model and which field feeds which field.

---

## 1. What was built

Inertia + React, per `AGENTS.md`. The controller moved under `Inertia::` and its routes into the
`scope module: :inertia` block, so the OAuth actions and the screen live in one place.

| File | Role |
|---|---|
| [inertia/…/salesforces_controller.rb](../../../app/controllers/inertia/accounts/apps/salesforces_controller.rb) | `show`, `create` (starts OAuth), `destroy`, `describe` (JSON for the field pickers) |
| [inertia/…/salesforces/object_mappings_controller.rb](../../../app/controllers/inertia/accounts/apps/salesforces/object_mappings_controller.rb) | Saves one object mapping |
| [apps/salesforce/woofed_fields.rb](../../../app/models/apps/salesforce/woofed_fields.rb) | The Woofed side of the pickers: columns + custom attributes |
| [pages/Apps/Salesforce/Show.tsx](../../../app/javascript/pages/Apps/Salesforce/Show.tsx) | The page |
| [components/salesforce/](../../../app/javascript/components/salesforce/) | `ConnectForm`, `ConnectionSummary`, `ObjectMappingCard`, `CopyableValue` |

Routes: `GET/POST/DELETE /accounts/:account_id/apps/salesforce`,
`GET …/describe/:salesforce_object`, `POST …/object_mappings`.

---

## 2. Decisions worth keeping

### 2.0 Reachable from settings, and self-documenting

The integration is listed on the settings page alongside WhatsApp, Chatwoot and the others, and its
own screen opens with the setup guide: the API-access requirement, then eight numbered steps from
"open Setup" to "copy the Consumer Key". The guide is expanded while there is no connection and
collapses once connected — the callback URL is still needed whenever the app has to be rebuilt in
Salesforce.

The API requirement is stated first and in the danger colours because it is the one thing the user
cannot fix on their side: Professional and Essentials editions only have API access with a paid
add-on, and without it no integration can read their data.

### 2.1 The connect screen is the documentation

Woofed never provisions anything in Salesforce: the customer registers the External Client App by
hand. The two values that have to match exactly — the callback URL for **this** install and the
scope list — are rendered verbatim with copy buttons, above the numbered setup steps, rather than
described in prose. A mistyped callback is the most likely onboarding failure and the one whose
Salesforce error is most opaque; stage 4 already turns `redirect_uri_mismatch` into a message naming
the expected URL, and this screen is where the user gets that URL right in the first place.

### 2.2 Describe is fetched per card, on open

The describe payload is hundreds of KB per object and every org has different custom fields, so it
cannot ship with the page. Each `ObjectMappingCard` fetches its object's fields the first time it is
opened, through a JSON endpoint that reuses the cached describe from stage 5 — opening the same card
twice costs the org nothing. The controller returns only `name`, `label`, `type` and `custom`; the
rest of the payload is not something a picker needs.

### 2.3 The Woofed picker offers custom attributes too

A Salesforce custom field has no column to land in: `Industria__c` can only become
`custom_attributes['industria']`, which requires a `CustomAttributeDefinition`. `WoofedFields`
therefore returns real columns and this install's custom attributes for the target model, and the
card records which kind was chosen so the transform knows where to write.

### 2.4 Nothing syncs until a mapping is saved and enabled

Every object starts disabled. Connecting an org on its own imports nothing, so an accidental connect
never floods the CRM — which matters because the first sync of a real org is hundreds of thousands
of records.

### 2.5 Saving a mapping is an upsert

The screen has one card per object and the table has a unique index per object, so `create`
does `find_or_initialize_by(salesforce_object:)`. Saving the same card twice edits the row instead of
failing on the index.

---

## 3. What is deliberately not here

- **The sync screen** (stage 15): progress, counters, per-record errors and the conflicts tab. There
  is nothing to show yet — stages 8 to 14 produce that data.
- **Opportunity's stage map** — pipeline id and `StageName → stage_id` live in `options` and need
  their own editor. It belongs with stage 11, which is where the mapping is first consumed.
- **A "Sync now" button**, for the same reason: stage 9 is what it would trigger.

---

## 4. Verification

130 examples across the Salesforce specs, 0 failures, **100% line coverage on every Salesforce
file**. `tsc -p tsconfig.app.json` is clean for the new files (two pre-existing errors in
`components/filters/filter-item.tsx` are untouched). Full suite: 1406 examples with the same 19
pre-existing failures from placeholder values in the local `.env`.

Covered: unauthenticated access redirected, the connect screen's callback URL and scopes, the
syncable object list, the Woofed field list including a custom attribute, a connected org rendering
its status and saved mappings, the OAuth start (production and sandbox hosts, PKCE parameters),
reconnecting instead of creating a second connection, blank credentials, disconnect with revocation,
describe success / refusal / no connection, and mapping save, upsert, invalid target model and no
connection.
