# Tools: users

| Tool | File | Mutates? |
|---|---|---|
| [`users_list`](#users_list) | [app/tools/users/list_tool.rb](../../../app/tools/users/list_tool.rb) | No |

Read a single user (with the deals they are assigned to) via the resource [`woofed:///users/{id}`](../resources/users.md).

---

## `users_list`

List users in the account with filtering and pagination.

### Arguments

| Name | Type | Description |
|---|---|---|
| `id` | integer | Exact match |
| `full_name` | string | `ILIKE %value%` |
| `email` | string | `ILIKE %value%` |
| `phone` | string | `ILIKE %value%` (E.164) |
| `job_description` | string | Exact match (enum value, e.g. `ceo`, `sales_representative`, `software_engineer`) |
| `language` | string | Exact match (e.g. `en`, `pt-BR`, `es`) |
| `created_from` / `created_to` | string (ISO8601) | `created_at` range |
| `updated_from` / `updated_to` | string (ISO8601) | `updated_at` range |
| `page` / `per_page` | integer | Pagination (default 25, max 100) |

### Return

```jsonc
{
  "data": [
    {
      "id": 4,
      "full_name": "Jane Operator",
      "email": "jane@operator.com",
      "phone": "+5511999990001",
      "job_description": "sales_representative",
      "language": "pt-BR",
      "avatar_url": "",
      "created_at": "...",
      "updated_at": "..."
    }
  ],
  "pagination": { "page": 1, ... }
}
```

### Notes

- Sensitive fields (`encrypted_password`, `reset_password_token`, `unlock_token`, Devise tracking columns, `notifications`) are never serialized.
- `job_description` values come from the `User#job_description` enum — see [app/models/user.rb](../../../app/models/user.rb) for the full list.
- For listing the deals owned by a user, prefer the [`woofed:///users/{id}`](../resources/users.md) resource — it includes `deals` in the payload.
