# Tools: apps (integrations)

Tools that list third-party app integrations. These exist primarily so the LLM can discover the right `app_id` to pass to message-sending tools.

| Tool | File |
|---|---|
| [`apps_chatwoots_list`](#apps_chatwoots_list) | [app/tools/apps/chatwoots/list_tool.rb](../../../app/tools/apps/chatwoots/list_tool.rb) |
| [`apps_evolution_apis_list`](#apps_evolution_apis_list) | [app/tools/apps/evolution_apis/list_tool.rb](../../../app/tools/apps/evolution_apis/list_tool.rb) |

---

## `apps_chatwoots_list`

List Chatwoot integrations in the account. Used to discover:

- `id` → passed as `app_id` to [`events_send_chatwoot_message`](events.md#events_send_chatwoot_message).
- `inboxes[*]` → IDs available to pass as `chatwoot_inbox_id` in the same tool.

### Arguments

| Name | Type | Description |
|---|---|---|
| `id` | integer | Exact match on integration ID |
| `name` | string | `ILIKE %value%` |
| `status` | string | `active`, `inactive`, `sync`, `pair` |
| `chatwoot_endpoint_url` | string | `ILIKE %value%` |
| `chatwoot_account_id` | integer | Exact match (the *Chatwoot's own* account id, not Woofed's) |
| `created_from` / `created_to` | string (ISO8601) | `created_at` range |
| `updated_from` / `updated_to` | string (ISO8601) | `updated_at` range |
| `page` / `per_page` | integer | Pagination |

### Return

```jsonc
{
  "data": [
    {
      "id": 5,
      "name": "Sales Inbox",
      "status": "active",
      "chatwoot_endpoint_url": "https://chat.example.com",
      "chatwoot_account_id": 42,
      "inboxes": [
        { "id": 1, "name": "Sales WhatsApp" },
        { "id": 2, "name": "Support email" }
      ],
      "created_at": "...",
      "updated_at": "..."
    }
  ],
  "pagination": { "page": 1, ... }
}
```

### Notes

- Sensitive fields (`chatwoot_user_token`, `embedding_token`) are intentionally **not** included in the response.
- `inboxes` is a JSONB column populated by Chatwoot's sync flow.

---

## `apps_evolution_apis_list`

List Evolution API integrations (WhatsApp connections). Used to discover the `app_id` for [`events_send_whatsapp_message`](events.md#events_send_whatsapp_message).

### Arguments

| Name | Type | Description |
|---|---|---|
| `id` | integer | Exact match |
| `name` | string | `ILIKE %value%` |
| `phone` | string | `ILIKE %value%` (E.164 format, e.g. `+5511999999999`) |
| `connection_status` | string | `connected`, `disconnected`, `connecting`, `sync` |
| `created_from` / `created_to` | string (ISO8601) | `created_at` range |
| `updated_from` / `updated_to` | string (ISO8601) | `updated_at` range |
| `page` / `per_page` | integer | Pagination |

### Return

```jsonc
{
  "data": [
    {
      "id": 5,
      "name": "Main WhatsApp",
      "endpoint_url": "https://evolution.example.com",
      "instance": "main",
      "phone": "+5511999990001",
      "active": true,
      "connection_status": "connected",
      "created_at": "...",
      "updated_at": "..."
    }
  ],
  "pagination": { "page": 1, ... }
}
```

### Notes

- The `token` field (sensitive) is omitted from the response.
- `connection_status` reflects the current WebSocket-like state with the Evolution API server, not just whether the integration is *configured*.
