# Tools: pipelines

Tools that operate on `Pipeline` records.

| Tool | File | Mutates? |
|---|---|---|
| [`pipelines_list`](#pipelines_list) | [app/tools/pipelines/list_tool.rb](../../../app/tools/pipelines/list_tool.rb) | No |
| [`pipelines_create`](#pipelines_create) | [app/tools/pipelines/create_tool.rb](../../../app/tools/pipelines/create_tool.rb) | Yes |
| [`pipelines_update`](#pipelines_update) | [app/tools/pipelines/update_tool.rb](../../../app/tools/pipelines/update_tool.rb) | Yes |

For reading a single pipeline with stages, use the resource [`woofed:///pipelines/{id}`](../resources/pipelines.md).
To manage the stages inside a pipeline, see [tools/stages.md](stages.md).

---

## `pipelines_list`

Lists pipelines with their stages eagerly loaded. The LLM uses this to discover which `stage_id` / `pipeline_id` values to pass to `deals_create` and `deals_update`.

### Arguments

| Name | Type | Description |
|---|---|---|
| `id` | integer | Exact match on pipeline ID |
| `name` | string | `ILIKE %value%` on pipeline name |
| `page` / `per_page` | integer | Pagination |

### Return

```jsonc
{
  "data": [
    {
      "id": 1,
      "name": "sales",
      "created_at": "...",
      "updated_at": "...",
      "stages": [
        { "id": 1, "name": "Qualified",   "position": 1, "created_at": "...", "updated_at": "..." },
        { "id": 2, "name": "Negotiation", "position": 2, "created_at": "...", "updated_at": "..." }
      ]
    }
  ],
  "pagination": { "page": 1, ... }
}
```

### Notes

- Stages are ordered by `position` so the LLM sees them in pipeline-flow order.
- The `includes(:stages)` avoids N+1 when a pipeline has many stages.

---

## `pipelines_create`

Creates a new (empty) pipeline. Stages are added separately via [`stages_create`](stages.md#stages_create).

### Arguments

| Name | Type | Required | Description |
|---|---|---|---|
| `name` | string | **yes** | Pipeline name |

### Return

Success: the created pipeline serialized as JSON.

Validation failure: `{ "error": [...], "status": "unprocessable_entity" }`.

### Example call

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "pipelines_create",
    "arguments": { "name": "sales" }
  },
  "id": 1
}
```

After creating the pipeline, follow with one call per stage:

```json
{ "method": "tools/call", "params": { "name": "stages_create",
  "arguments": { "pipeline_id": 1, "name": "Qualified", "position": 1 } }, "id": 2 }
```

---

## `pipelines_update`

Updates an existing pipeline by ID. Only the fields provided are changed.

### Arguments

| Name | Type | Required | Description |
|---|---|---|---|
| `id` | integer | **yes** | Pipeline ID. `find` raises `RecordNotFound` if missing → `not_found_error`. |
| `name` | string | no | New name |

### Error responses

| Situation | Response |
|---|---|
| `id` not found | `{ "error": "Resource could not be found", "status": "not_found" }` |
| Validation failed | `{ "error": [...], "status": "unprocessable_entity" }` |
