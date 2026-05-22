# Resource: `woofed:///users/{id}`

Reads a single user along with the deals they are assigned to (via `deal_assignees`).

| Property | Value |
|---|---|
| URI template | `woofed:///users/{id}` |
| File | [app/resources/users_resource.rb](../../../app/resources/users_resource.rb) |
| Resource name | `user` |
| MIME type | `application/json` |

---

## Path parameters

| Name | Type | Description |
|---|---|---|
| `id` | integer | User ID |

---

## Behaviour

```ruby
class UsersResource < ApplicationResource
  uri_template 'woofed:///users/{id}'
  resource_name 'user'
  description 'A user record, including the deals the user is assigned to.'
  mime_type 'application/json'

  def content
    user = User.find(params[:id])
    JSON.generate(
      user.as_json(
        only: %i[id full_name email phone job_description language avatar_url created_at updated_at],
        include: :deals
      )
    )
  end
end
```

`User.find(id)` raises `ActiveRecord::RecordNotFound` for invalid ids — `ApplicationResource.read` catches it and returns the message as a `text/plain` content item.

---

## Example call

Request:

```json
{
  "jsonrpc": "2.0",
  "method": "resources/read",
  "params": { "uri": "woofed:///users/4" },
  "id": 1
}
```

Parsed `result.contents[0].text`:

```jsonc
{
  "id": 4,
  "full_name": "Jane Operator",
  "email": "jane@operator.com",
  "phone": "+5511999990001",
  "job_description": "sales_representative",
  "language": "pt-BR",
  "avatar_url": "",
  "created_at": "...",
  "updated_at": "...",
  "deals": [
    {
      "id": 10,
      "name": "Test Deal",
      "stage_id": 3,
      "contact_id": 7,
      "amount_in_cents": 0,
      "created_at": "...",
      "updated_at": "..."
    }
  ]
}
```

---

## Notes

- Sensitive fields (`encrypted_password`, `reset_password_token`, `unlock_token`, Devise tracking columns, `notifications`) are explicitly excluded — only the whitelist in `only:` is serialized.
- `deals` is the `User#deals` association (`has_many :deals, through: :deal_assignees`) — the deals the user is the assignee of, not deals the user created.
- For filtering/listing users use the [`users_list`](../tools/users.md) tool instead.
