# Resource: `woofed:///deals/{id}`

Reads a single deal with its full relational graph: contact, stage, pipeline, assignees, and deal_products.

| Property | Value |
|---|---|
| URI template | `woofed:///deals/{id}` |
| File | [app/resources/deals_resource.rb](../../../app/resources/deals_resource.rb) |
| Resource name | `deal` |
| MIME type | `application/json` |

---

## Path parameters

| Name | Type | Description |
|---|---|---|
| `id` | integer | Deal ID |

---

## Behaviour

```ruby
class DealsResource < ApplicationResource
  uri 'woofed:///deals/{id}'
  resource_name 'deal'
  description 'A deal record, including its contact, stage, pipeline, deal_assignees and deal_products.'
  mime_type 'application/json'

  def content
    deal = Deal.find(params[:id])
    JSON.generate(deal.as_json(include: %i[contact stage pipeline deal_assignees deal_products]))
  end
end
```

`Deal.find(id)` raises `ActiveRecord::RecordNotFound` for invalid ids — fast-mcp catches it and returns a JSON-RPC error to the client.

---

## Example call

Request:

```json
{
  "jsonrpc": "2.0",
  "method": "resources/read",
  "params": { "uri": "woofed:///deals/1" },
  "id": 1
}
```

Parsed `result.contents[0].text`:

```jsonc
{
  "id": 1,
  "name": "Lead site: Rubel",
  "status": "open",
  "stage_id": 1,
  "pipeline_id": 1,
  "contact_id": 1,
  "position": 1,
  "total_deal_products_amount_in_cents": 0,
  "lost_at": null, "won_at": null, "lost_reason": "",
  "custom_attributes": { "source": "Website" },
  "created_at": "...", "updated_at": "...",
  "contact": {
    "id": 1,
    "full_name": "Tim Maia",
    "phone": "+5541996910256",
    "email": "tim@maia.com",
    "custom_attributes": {},
    "additional_attributes": {},
    "app_type": null,
    "app_id": null,
    "created_at": "...", "updated_at": "..."
  },
  "stage": {
    "id": 1, "name": "Qualified", "position": 1, "pipeline_id": 1,
    "created_at": "...", "updated_at": "..."
  },
  "pipeline": {
    "id": 1, "name": "sales",
    "created_at": "...", "updated_at": "..."
  },
  "deal_assignees": [
    { "id": 2, "deal_id": 1, "user_id": 9, "created_at": "...", "updated_at": "..." }
  ],
  "deal_products": [
    {
      "id": 1, "product_id": 4, "deal_id": 1,
      "unit_amount_in_cents": 0, "total_amount_in_cents": 0,
      "quantity": 1, "product_identifier": "", "product_name": "",
      "created_at": "...", "updated_at": "..."
    }
  ]
}
```

---

## When to use this vs `deals_list`

| Use the resource | Use the `deals_list` tool |
|---|---|
| You already know the deal id | You're searching by attribute |
| You want the full graph (contact + stage + pipeline + assignees + products) | You want a paginated/filtered list |

---

## Notes

- The `as_json(include: ...)` serialization includes **all** attributes of nested records (Rails default). If you want to slim it down later, switch to `include: { contact: { only: %i[id full_name email] } }`.
- `events` are **not** included here (they're on the contact resource). If you need them, query `woofed:///contacts/{contact_id}` after.
