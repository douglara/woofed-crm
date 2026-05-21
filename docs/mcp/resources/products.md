# Resource: `woofed:///products/{id}`

Reads a single product with its `deal_products` (the join records connecting it to deals).

| Property | Value |
|---|---|
| URI template | `woofed:///products/{id}` |
| File | [app/resources/products_resource.rb](../../../app/resources/products_resource.rb) |
| Resource name | `product` |
| MIME type | `application/json` |

---

## Path parameters

| Name | Type | Description |
|---|---|---|
| `id` | integer | Product ID |

---

## Behaviour

```ruby
class ProductsResource < ApplicationResource
  uri 'woofed:///products/{id}'
  resource_name 'product'
  description 'A product record, including the deal_products that reference it.'
  mime_type 'application/json'

  def content
    product = Product.find(params[:id])
    JSON.generate(product.as_json(include: :deal_products))
  end
end
```

`Product.find(id)` raises `ActiveRecord::RecordNotFound` for invalid ids — fast-mcp catches it and returns a JSON-RPC error to the client.

---

## Example call

Request:

```json
{
  "jsonrpc": "2.0",
  "method": "resources/read",
  "params": { "uri": "woofed:///products/1" },
  "id": 1
}
```

Parsed `result.contents[0].text`:

```jsonc
{
  "id": 1,
  "identifier": "SNS895SASXVDW",
  "name": "Car",
  "description": "Nice car",
  "amount_in_cents": 1000035,
  "quantity_available": 2,
  "custom_attributes": { "number_of_doors": "4" },
  "additional_attributes": {},
  "created_at": "...", "updated_at": "...",
  "deal_products": [
    {
      "id": 3,
      "product_id": 1,
      "deal_id": 10,
      "unit_amount_in_cents": 0,
      "total_amount_in_cents": 0,
      "quantity": 1,
      "product_identifier": "",
      "product_name": "",
      "created_at": "...", "updated_at": "..."
    }
  ]
}
```

---

## Notes

- `deal_products` are the *join records* — they carry the quantity and the snapshot of amount/identifier/name at the time of attachment.
- To find which deals reference this product, follow `deal_products[*].deal_id` and read each deal via [`woofed:///deals/{id}`](deals.md).
- For listing products with filters (price range, name, etc.) use the [`products_list`](../tools/products.md) tool instead.
