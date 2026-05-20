# Tools: stages

Tools that operate on `Stage` records (the columns of a Kanban-like pipeline). Position is managed by `acts_as_list scope: :pipeline` on the model.

| Tool | File | Mutates? |
|---|---|---|
| [`stages_list`](#stages_list) | [app/tools/stages/list_tool.rb](../../../app/tools/stages/list_tool.rb) | No |
| [`stages_create`](#stages_create) | [app/tools/stages/create_tool.rb](../../../app/tools/stages/create_tool.rb) | Yes |
| [`stages_update`](#stages_update) | [app/tools/stages/update_tool.rb](../../../app/tools/stages/update_tool.rb) | Yes |

For listing stages embedded inside a pipeline, see [`pipelines_list`](pipelines.md#pipelines_list) and the resource [`woofed:///pipelines/{id}`](../resources/pipelines.md).

---

## `stages_list`

Lists stages. Stages are returned ordered by `pipeline_id` and then `position`, so iterating gives a stable, pipeline-grouped order.

### Arguments

| Name | Type | Description |
|---|---|---|
| `id` | integer | Exact match on stage ID |
| `pipeline_id` | integer | Filter to stages of a specific pipeline |
| `name` | string | `ILIKE %value%` on stage name |
| `page` / `per_page` | integer | Pagination |

### Return

```jsonc
{
  "data": [
    {
      "id": 1, "name": "Qualified", "position": 1, "pipeline_id": 1,
      "created_at": "...", "updated_at": "..."
    },
    {
      "id": 2, "name": "Negotiation", "position": 2, "pipeline_id": 1,
      "created_at": "...", "updated_at": "..."
    }
  ],
  "pagination": { "page": 1, ... }
}
```

---

## `stages_create`

Creates a new stage inside an existing pipeline. Uses `acts_as_list` so position is auto-managed.

### Arguments

| Name | Type | Required | Description |
|---|---|---|---|
| `pipeline_id` | integer | **yes** | Pipeline this stage belongs to. `find` raises `RecordNotFound` if missing → `not_found_error`. |
| `name` | string | **yes** | Stage name |
| `position` | integer | no | Position within the pipeline. When omitted, the stage is appended at the end. When provided, `acts_as_list` shifts siblings down to make room. |

### Return

Success: the created stage serialized as JSON.

Validation failure: `{ "error": [...], "status": "unprocessable_entity" }`.

### Example: building a pipeline from scratch

```json
{ "method": "tools/call", "params": { "name": "pipelines_create",
  "arguments": { "name": "Onboarding" } }, "id": 1 }
```

Response includes the new pipeline `id` (let's call it `5`). Then add stages:

```json
{ "method": "tools/call", "params": { "name": "stages_create",
  "arguments": { "pipeline_id": 5, "name": "Welcome",       "position": 1 } }, "id": 2 }

{ "method": "tools/call", "params": { "name": "stages_create",
  "arguments": { "pipeline_id": 5, "name": "Configuration", "position": 2 } }, "id": 3 }

{ "method": "tools/call", "params": { "name": "stages_create",
  "arguments": { "pipeline_id": 5, "name": "Go live",       "position": 3 } }, "id": 4 }
```

---

## `stages_update`

Updates an existing stage. Mostly used to rename or reorder.

### Arguments

| Name | Type | Required | Description |
|---|---|---|---|
| `id` | integer | **yes** | Stage ID. `find` raises `RecordNotFound` if missing → `not_found_error`. |
| `name` | string | no | New name |
| `position` | integer | no | New position. `acts_as_list` reorders siblings automatically. |

### Error responses

| Situation | Response |
|---|---|
| `id` not found | `{ "error": "Resource could not be found", "status": "not_found" }` |
| Validation failed | `{ "error": [...], "status": "unprocessable_entity" }` |

### Notes

- The model has `belongs_to :pipeline, touch: true`, so updating a stage also bumps the parent pipeline's `updated_at`.
- Reordering via `position` does not delete deals — they keep their `stage_id` association.
