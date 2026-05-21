# Resource: `woofed:///contacts/{id}`

Reads a single contact with its full timeline graph (deals and events).

| Property | Value |
|---|---|
| URI template | `woofed:///contacts/{id}` |
| File | [app/resources/contacts_resource.rb](../../../app/resources/contacts_resource.rb) |
| Resource name | `contact` |
| MIME type | `application/json` |

---

## Path parameters

| Name | Type | Description |
|---|---|---|
| `id` | integer | Contact ID |

---

## Behaviour

```ruby
class ContactsResource < ApplicationResource
  uri 'woofed:///contacts/{id}'
  resource_name 'contact'
  description 'A contact record, including its deals and events.'
  mime_type 'application/json'

  def content
    contact = Contact.find(params[:id])
    JSON.generate(contact.as_json(include: %i[deals events]))
  end
end
```

`Contact.find(id)` raises `ActiveRecord::RecordNotFound` for invalid ids — fast-mcp catches it and returns a JSON-RPC error to the client.

---

## Example call

Request:

```json
{
  "jsonrpc": "2.0",
  "method": "resources/read",
  "params": { "uri": "woofed:///contacts/1" },
  "id": 1
}
```

Response (delivered via SSE):

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "contents": [
      {
        "uri": "woofed:///contacts/1",
        "mimeType": "application/json",
        "text": "{\"id\":1,\"full_name\":\"Tim Maia\",\"phone\":\"+5541996910256\",...}"
      }
    ]
  }
}
```

After parsing `result.contents[0].text`:

```jsonc
{
  "id": 1,
  "full_name": "Tim Maia",
  "phone": "+5541996910256",
  "email": "tim@maia.com",
  "custom_attributes": { "city": "RJ" },
  "additional_attributes": {},
  "app_type": null,
  "app_id": null,
  "created_at": "2026-05-01T12:00:00.000Z",
  "updated_at": "2026-05-01T12:00:00.000Z",
  "deals": [
    {
      "id": 1,
      "name": "Test Deal",
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
  "events": [
    {
      "id": 1,
      "kind": "deal_opened",
      "deal_id": 1,
      "contact_id": 1,
      "scheduled_at": null,
      "done_at": "...",
      "additional_attributes": {
        "stage_id": 1,
        "deal_name": "Test Deal",
        "stage_name": "Stage 1",
        "pipeline_id": 1,
        "pipeline_name": "sales"
      },
      "created_at": "...", "updated_at": "..."
    }
  ]
}
```

---

## When to use this vs `contacts_list`

| Use the resource | Use the `contacts_list` tool |
|---|---|
| You already know the contact id | You're searching by attribute |
| You want the full graph (deals, events) | You want a paginated/filtered list |
| The LLM wants to mention a specific contact by URI | The LLM wants to summarise multiple contacts |
