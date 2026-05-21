# Tools: contacts

Tools that operate on `Contact` records.

| Tool | File | Mutates? |
|---|---|---|
| [`contacts_list`](#contacts_list) | [app/tools/contacts/list_tool.rb](../../../app/tools/contacts/list_tool.rb) | No |
| [`contacts_create`](#contacts_create) | [app/tools/contacts/create_tool.rb](../../../app/tools/contacts/create_tool.rb) | Yes |
| [`contacts_update`](#contacts_update) | [app/tools/contacts/update_tool.rb](../../../app/tools/contacts/update_tool.rb) | Yes |

For reading a single contact (with deals and events) use the resource [`woofed:///contacts/{id}`](../resources/contacts.md).

---

## `contacts_list`

List contacts in the account with partial-match filters and pagination.

### Arguments

| Name | Type | Required | Description |
|---|---|---|---|
| `id` | integer | no | Exact match on contact ID |
| `full_name` | string | no | `ILIKE %value%` on `full_name` |
| `email` | string | no | `ILIKE %value%` on `email` |
| `phone` | string | no | `ILIKE %value%` on `phone` (E.164 expected, e.g. `+5511999999999`) |
| `created_from` | string | no | ISO8601 UTC datetime, `created_at >= value` |
| `created_to` | string | no | ISO8601 UTC datetime, `created_at <= value` |
| `updated_from` | string | no | ISO8601 UTC datetime, `updated_at >= value` |
| `updated_to` | string | no | ISO8601 UTC datetime, `updated_at <= value` |
| `custom_attributes` | hash | no | Each key/value pair AND-ed as `custom_attributes->>key = value` |
| `page` | integer | no | Default `1` |
| `per_page` | integer | no | Default `25`, clamped to `[1, 100]` |

### Return

```jsonc
{
  "data": [
    {
      "id": 42,
      "full_name": "John Doe",
      "email": "john@example.com",
      "phone": "+5511999990001",
      "custom_attributes": { "city": "RJ" },
      "additional_attributes": {},
      "created_at": "2026-05-01T12:00:00.000Z",
      "updated_at": "2026-05-01T12:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1, "items": 25, "count": 1, "pages": 1,
    "from": 1, "to": 1, "prev": null, "next": null, "last": 1
  }
}
```

### Example call

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "contacts_list",
    "arguments": {
      "full_name": "john",
      "created_from": "2026-01-01T00:00:00Z",
      "per_page": 10
    }
  },
  "id": 1
}
```

---

## `contacts_create`

Create a new contact. At least one of `email` or `phone` is recommended for future matching, but neither is strictly required.

### Arguments

| Name | Type | Required | Description |
|---|---|---|---|
| `full_name` | string | no | Contact full name |
| `email` | string | no | Unique within account (case-insensitive) |
| `phone` | string | no | E.164 format, e.g. `+5511999999999`. Unique within account |
| `label_list` | string[] | no | Tags to apply via `acts-as-taggable-on` |
| `custom_attributes` | hash | no | Free-form key/value pairs persisted to the JSONB column |

### Return

Success: the created contact serialized as JSON.

Validation failure: `{ "error": [...full_messages], "status": "unprocessable_entity" }`.

### Side effects

The `Contact` model has callbacks that:

1. Publish a Wisper event (`contact_created`) → consumed by `WebhookListener`.
2. Schedule an `Accounts::Apps::Chatwoots::ExportContactWorker` async job *if* there is a connected Chatwoot integration.

Both happen via Sidekiq in production and are inspectable in tests via the standard helpers.

### Example call

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "contacts_create",
    "arguments": {
      "full_name": "Tim Maia",
      "phone": "+5541996910256",
      "email": "tim@maia.com",
      "label_list": ["customer", "vip"],
      "custom_attributes": { "city": "RJ" }
    }
  },
  "id": 2
}
```

---

## `contacts_update`

Update an existing contact by id. Only the fields provided in `arguments` are changed.

### Arguments

| Name | Type | Required | Description |
|---|---|---|---|
| `id` | integer | **yes** | Contact ID. `find` raises `RecordNotFound` if missing → `not_found_error`. |
| `full_name` | string | no | |
| `email` | string | no | |
| `phone` | string | no | E.164 format |
| `label_list` | string[] | no | **Replaces** the existing tag list (does not append). |
| `custom_attributes` | hash | no | Full replacement of the JSONB column. |

### Return

Same shape as `contacts_create`.

### Error responses

| Situation | Response |
|---|---|
| `id` not found | `{ "error": "Resource could not be found", "status": "not_found" }` |
| Validation failed | `{ "error": [...], "status": "unprocessable_entity" }` |
