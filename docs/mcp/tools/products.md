# Tools: products

| Tool | File | Mutates? |
|---|---|---|
| [`products_list`](#products_list) | [app/tools/products/list_tool.rb](../../../app/tools/products/list_tool.rb) | No |

Read a single product (with `deal_products`) via the resource [`woofed:///products/{id}`](../resources/products.md).

---

## `products_list`

List products in the catalog with rich filter options.

### Arguments

| Name | Type | Description |
|---|---|---|
| `id` | integer | Exact match |
| `name` | string | `ILIKE %value%` |
| `identifier` | string | Exact match (SKU) |
| `description` | string | `ILIKE %value%` |
| `amount_in_cents_min` | integer | `amount_in_cents >= value` |
| `amount_in_cents_max` | integer | `amount_in_cents <= value` |
| `quantity_available_min` | integer | `quantity_available >= value` |
| `created_from` / `created_to` | string (ISO8601) | `created_at` range |
| `updated_from` / `updated_to` | string (ISO8601) | `updated_at` range |
| `custom_attributes` | hash | Each key/value AND-ed as JSONB lookup |
| `page` / `per_page` | integer | Pagination |

### Return

```jsonc
{
  "data": [
    {
      "id": 7,
      "identifier": "SKU-CAR-001",
      "name": "Car",
      "description": "Nice car",
      "amount_in_cents": 1000035,
      "quantity_available": 2,
      "custom_attributes": { "number_of_doors": "4" },
      "additional_attributes": {},
      "created_at": "...",
      "updated_at": "..."
    }
  ],
  "pagination": { "page": 1, ... }
}
```

### Notes

- `amount_in_cents` is **always cents**. `1000035` cents = `R$ 10,000.35` (currency from account settings).
- `identifier` is matched exactly because SKUs are usually full-string identifiers, not substrings.
- The `name` and `description` filters use partial match because they're free-form.
