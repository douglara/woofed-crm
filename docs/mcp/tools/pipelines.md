# Tools: pipelines

| Tool | File | Mutates? |
|---|---|---|
| [`pipelines_list`](#pipelines_list) | [app/tools/pipelines/list_tool.rb](../../../app/tools/pipelines/list_tool.rb) | No |

There is no `pipelines_create` / `pipelines_update` tool — pipelines are typically configured in the admin UI, not via LLM.

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
        { "id": 1, "name": "Qualified", "position": 1, "created_at": "...", "updated_at": "..." },
        { "id": 2, "name": "Negotiation", "position": 2, "created_at": "...", "updated_at": "..." }
      ]
    }
  ],
  "pagination": { "page": 1, ... }
}
```

### Notes

- Stages are ordered by `position` so the LLM sees them in pipeline-flow order.
- `Pipeline` model exposes only `id` and `name` ransackable, but this tool doesn't use ransack — explicit filters keep the schema clean for the LLM.
- The `includes(:stages)` avoids N+1 when a pipeline has many stages.
