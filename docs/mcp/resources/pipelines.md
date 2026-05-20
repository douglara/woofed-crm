# Resource: `woofed:///pipelines/{id}`

Reads a single pipeline with its stages ordered by position.

| Property | Value |
|---|---|
| URI template | `woofed:///pipelines/{id}` |
| File | [app/resources/pipelines_resource.rb](../../../app/resources/pipelines_resource.rb) |
| Resource name | `pipeline` |
| MIME type | `application/json` |

---

## Path parameters

| Name | Type | Description |
|---|---|---|
| `id` | integer | Pipeline ID |

---

## Behaviour

```ruby
class PipelinesResource < ApplicationResource
  uri 'woofed:///pipelines/{id}'
  resource_name 'pipeline'
  description 'A pipeline record, including its stages ordered by position.'
  mime_type 'application/json'

  def content
    pipeline = Pipeline.includes(:stages).find(params[:id])
    JSON.generate(
      pipeline.as_json(only: %i[id name created_at updated_at]).merge(
        stages: pipeline.stages.order(:position).as_json(only: %i[id name position created_at updated_at])
      )
    )
  end
end
```

`Pipeline.find(id)` raises `ActiveRecord::RecordNotFound` for invalid ids — fast-mcp catches it and returns a JSON-RPC error to the client.

---

## Example call

Request:

```json
{
  "jsonrpc": "2.0",
  "method": "resources/read",
  "params": { "uri": "woofed:///pipelines/1" },
  "id": 1
}
```

Parsed `result.contents[0].text`:

```jsonc
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
```

---

## When to use this vs `pipelines_list`

| Use the resource | Use the `pipelines_list` tool |
|---|---|
| You already know the pipeline id | You want a paginated list of pipelines |
| You only need this pipeline's stages | You're searching by name |

For managing stages individually (create/update/list), see [tools/stages.md](../tools/stages.md).
