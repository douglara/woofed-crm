# Tools: deals

Tools that operate on `Deal` records.

| Tool | File | Mutates? |
|---|---|---|
| [`deals_list`](#deals_list) | [app/tools/deals/list_tool.rb](../../../app/tools/deals/list_tool.rb) | No |
| [`deals_create`](#deals_create) | [app/tools/deals/create_tool.rb](../../../app/tools/deals/create_tool.rb) | Yes |
| [`deals_update`](#deals_update) | [app/tools/deals/update_tool.rb](../../../app/tools/deals/update_tool.rb) | Yes |
| [`deals_mark_won`](#deals_mark_won) | [app/tools/deals/mark_won_tool.rb](../../../app/tools/deals/mark_won_tool.rb) | Yes |
| [`deals_mark_lost`](#deals_mark_lost) | [app/tools/deals/mark_lost_tool.rb](../../../app/tools/deals/mark_lost_tool.rb) | Yes |

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
