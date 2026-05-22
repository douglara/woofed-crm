# Tools: deals

Tools that operate on `Deal` records.

| Tool | File | Mutates? |
|---|---|---|
| [`deals_list`](#deals_list) | [app/tools/deals/list_tool.rb](../../../app/tools/deals/list_tool.rb) | No |
| [`deals_create`](#deals_create) | [app/tools/deals/create_tool.rb](../../../app/tools/deals/create_tool.rb) | Yes |
| [`deals_update`](#deals_update) | [app/tools/deals/update_tool.rb](../../../app/tools/deals/update_tool.rb) | Yes |
| [`deals_mark_won`](#deals_mark_won) | [app/tools/deals/mark_won_tool.rb](../../../app/tools/deals/mark_won_tool.rb) | Yes |
| [`deals_mark_lost`](#deals_mark_lost) | [app/tools/deals/mark_lost_tool.rb](../../../app/tools/deals/mark_lost_tool.rb) | Yes |
| [`deals_add_assignee`](#deals_add_assignee) | [app/tools/deals/add_assignee_tool.rb](../../../app/tools/deals/add_assignee_tool.rb) | Yes |
| [`deals_remove_assignee`](#deals_remove_assignee) | [app/tools/deals/remove_assignee_tool.rb](../../../app/tools/deals/remove_assignee_tool.rb) | Yes |
| [`deals_add_product`](#deals_add_product) | [app/tools/deals/add_product_tool.rb](../../../app/tools/deals/add_product_tool.rb) | Yes |
| [`deals_update_product`](#deals_update_product) | [app/tools/deals/update_product_tool.rb](../../../app/tools/deals/update_product_tool.rb) | Yes |
| [`deals_remove_product`](#deals_remove_product) | [app/tools/deals/remove_product_tool.rb](../../../app/tools/deals/remove_product_tool.rb) | Yes |

For reading a single deal with full graph (contact, stage, pipeline, assignees, deal_products) use the resource [`woofed:///deals/{id}`](../resources/deals.md).

---

## `deals_list`

List deals with broad filter support: by name, status, stage, pipeline, contact, lost reason, and date ranges.

### Arguments

| Name | Type | Description |
|---|---|---|
| `id` | integer | Exact match |
| `name` | string | `ILIKE %value%` |
| `status` | string | One of `open`, `won`, `lost` |
| `stage_id` | integer | Exact match |
| `pipeline_id` | integer | Exact match |
| `contact_id` | integer | Exact match |
| `lost_reason` | string | `ILIKE %value%` |
| `created_from` / `created_to` | string (ISO8601) | `created_at` range |
| `updated_from` / `updated_to` | string (ISO8601) | `updated_at` range |
| `won_from` / `won_to` | string (ISO8601) | `won_at` range |
| `lost_from` / `lost_to` | string (ISO8601) | `lost_at` range |
| `custom_attributes` | hash | Each key/value AND-ed as JSONB lookup |
| `page` / `per_page` | integer | Pagination |

### Return

```jsonc
{
  "data": [
    {
      "id": 27,
      "name": "Lead site: Rubel",
      "status": "open",
      "stage_id": 1,
      "pipeline_id": 1,
      "contact_id": 1,
      "position": 1,
      "total_deal_products_amount_in_cents": 0,
      "lost_at": null, "won_at": null, "lost_reason": "",
      "custom_attributes": {},
      "created_at": "...", "updated_at": "..."
    }
  ],
  "pagination": { "page": 1, ... }
}
```

---

## `deals_create`

Create a deal. Internally goes through `DealBuilder` + `Deal::CreateOrUpdate` — the same path used by the REST API controller — so all hooks (created_by, deal assignees) fire as expected.

### Arguments

| Name | Type | Required | Description |
|---|---|---|---|
| `contact_id` | integer | **yes** | Contact this deal belongs to. Missing/invalid → validation error `"Contact must exist"`. |
| `stage_id` | integer | **yes** | Stage where the deal lives. |
| `pipeline_id` | integer | no | Inferred from the stage when omitted. Must match if provided. |
| `name` | string | no | Deal title |
| `status` | string | no | `open` (default), `won`, `lost` |
| `lost_reason` | string | no | Used when `status: 'lost'` |
| `custom_attributes` | hash | no | Free-form JSONB |

### Side effects

- The current user (from `Current.user`) is set as `created_by`.
- A `Deal::EventCreator` callback creates a `deal_opened` event automatically.
- `deal_assignees` is built with the current user.
- Wisper event `deal_created` is published.

### Return

JSON-serialized `Deal` on success. Validation error array on failure.

---

## `deals_update`

Update fields on an existing deal. Goes through `Deal::CreateOrUpdate` so the side-effect logic around `won_at`, `lost_at`, `lost_reason` runs correctly when `status` changes.

### Arguments

| Name | Type | Required | Description |
|---|---|---|---|
| `id` | integer | **yes** | Deal ID |
| `name` | string | no | |
| `status` | string | no | `open`, `won`, `lost` |
| `stage_id` | integer | no | Move to a different stage |
| `pipeline_id` | integer | no | Must match the stage's pipeline |
| `lost_reason` | string | no | |
| `lost_at` | string (ISO8601) | no | When the deal was marked lost (only used if account allows manual editing) |
| `won_at` | string (ISO8601) | no | When the deal was marked won |
| `custom_attributes` | hash | no | |

### Notes on `Deal::CreateOrUpdate`

The use case decides whether to set `won_at`/`lost_at` automatically:

```ruby
allow_edit = Current.account.deal_allow_edit_lost_at_won_at

if @deal.won?
  @deal.won_at = Time.current unless allow_edit && @params[:won_at].present?
  @deal.lost_at = nil
  @deal.lost_reason = ''
elsif @deal.lost?
  @deal.lost_at = Time.current unless allow_edit && @params[:lost_at].present?
  @deal.won_at = nil
end
```

So providing `won_at`/`lost_at` only matters if the account has `deal_allow_edit_lost_at_won_at` enabled.

---

## `deals_mark_won`

Convenience tool that wraps `Deal::CreateOrUpdate` with `{ status: 'won' }`.

### Arguments

| Name | Type | Required | Description |
|---|---|---|---|
| `id` | integer | **yes** | Deal ID |
| `won_at` | string (ISO8601) | no | Defaults to `Time.current` |

### Behaviour

Equivalent to calling `deals_update` with `{ id:, status: 'won', won_at: }`. Use this when the LLM is acting on user intent like *"mark deal 42 as won"*.

---

## `deals_mark_lost`

Convenience tool that wraps `Deal::CreateOrUpdate` with `{ status: 'lost' }`.

### Arguments

| Name | Type | Required | Description |
|---|---|---|---|
| `id` | integer | **yes** | Deal ID |
| `lost_reason` | string | no | Why the deal was lost |
| `lost_at` | string (ISO8601) | no | Defaults to `Time.current` |

### Behaviour

Equivalent to calling `deals_update` with `{ id:, status: 'lost', lost_reason:, lost_at: }`. Resets `won_at` to nil.

---

## `deals_add_assignee`

Assign a user as a responsible (assignee) of a deal. Mirrors the REST endpoint `POST /api/v1/accounts/deal_assignees`.

### Arguments

| Name | Type | Required | Description |
|---|---|---|---|
| `deal_id` | integer | **yes** | Deal ID |
| `user_id` | integer | **yes** | User ID to assign as responsible |

### Behaviour

Creates a `DealAssignee` record linking the user to the deal. The model has a uniqueness validation on `user_id` scoped to `deal_id`, so re-assigning a user that is already responsible returns a validation error (matching the REST API behaviour).

### Return

The created `DealAssignee` (`{ id, deal_id, user_id, created_at, updated_at }`) on success, or a `"Validation failed: ..."` text response when the user is already an assignee.

---

## `deals_remove_assignee`

Remove a user from the assignees of a deal. Mirrors the REST endpoint `DELETE /api/v1/accounts/deal_assignees/:id`, but takes `deal_id` + `user_id` instead of the `DealAssignee` id — so the LLM does not need to look the join record up first.

### Arguments

| Name | Type | Required | Description |
|---|---|---|---|
| `deal_id` | integer | **yes** | Deal ID |
| `user_id` | integer | **yes** | User ID to remove from the deal assignees |

### Return

The destroyed `DealAssignee` (`{ id, deal_id, user_id, created_at, updated_at }`) on success, or a `"Couldn't find DealAssignee"` text response when the user is not assigned to the deal.

---

## `deals_add_product`

Attach a product to a deal as a `deal_product` line. Mirrors the REST endpoint `POST /api/v1/accounts/deal_products` — internally uses `DealProductBuilder` + `DealProduct::CreateOrUpdate`.

### Arguments

| Name | Type | Required | Description |
|---|---|---|---|
| `deal_id` | integer | **yes** | Deal ID |
| `product_id` | integer | **yes** | Product ID to attach |
| `quantity` | integer | no | Quantity on this deal (default 1, must be >= 1) |

### Behaviour

- `unit_amount_in_cents`, `product_name` and `product_identifier` are snapshotted from the `Product` catalog at attachment time (so the deal_product survives later catalog edits). Use [`deals_update_product`](#deals_update_product) to override `unit_amount_in_cents` on the deal_product after attaching.
- `total_amount_in_cents` is computed as `quantity * unit_amount_in_cents`.
- The deal's `total_deal_products_amount_in_cents` is recalculated inside a transaction (`Deal::RecalculateAndSaveAllMonetaryValues`).
- The model has a uniqueness validation on `product_id` scoped to `deal_id`, so attaching the same product twice returns a validation error.

### Return

The created `DealProduct` on success, or a `"Validation failed: ..."` text response when the product is already attached.

---

## `deals_update_product`

Update the `quantity` and/or `unit_amount_in_cents` of a product already attached to a deal. Mirrors `PUT /api/v1/accounts/deal_products/:id` — but identifies the deal_product by `deal_id` + `product_id` instead of the join id, so the LLM does not need to look the join record up first.

### Arguments

| Name | Type | Required | Description |
|---|---|---|---|
| `deal_id` | integer | **yes** | Deal ID |
| `product_id` | integer | **yes** | Product ID (must already be attached) |
| `quantity` | integer | no | New quantity (must be >= 1) |
| `unit_amount_in_cents` | integer | no | Override unit price in cents for this deal_product |

At least one of `quantity` / `unit_amount_in_cents` must be provided — otherwise the tool returns `"Provide quantity or unit_amount_in_cents to update"`.

### Behaviour

- Both fields go through `DealProduct::CreateOrUpdate`, which recalculates `total_amount_in_cents = quantity * unit_amount_in_cents` and then triggers `Deal::RecalculateAndSaveAllMonetaryValues` inside a transaction.
- `product_name` / `product_identifier` are intentionally not exposed here — the API permits them but they are snapshot fields, not LLM-editable.

### Return

The updated `DealProduct` on success, or a `"Validation failed: ..."` text response.

---

## `deals_remove_product`

Remove a product (deal_product line) from a deal. Mirrors the existing UI endpoint that the REST API doesn't expose, going through `DealProduct::Destroy` so the deal totals are recalculated.

### Arguments

| Name | Type | Required | Description |
|---|---|---|---|
| `deal_id` | integer | **yes** | Deal ID |
| `product_id` | integer | **yes** | Product ID to remove |

### Return

The destroyed `DealProduct` on success, or a `"Couldn't find DealProduct"` text response when the product is not attached to the deal.
