# Adding a new MCP resource

Resources represent read-only records identified by URI. They are conceptually closer to a REST GET-by-id than to a function call.

---

## Table of contents

1. [Tool vs Resource — when to use which](#tool-vs-resource--when-to-use-which)
2. [Step 1 — Create the resource class](#step-1--create-the-resource-class)
3. [Step 2 — Register (automatic)](#step-2--register-automatic)
4. [Step 3 — Write the spec](#step-3--write-the-spec)
5. [Step 4 — Document](#step-4--document)
6. [URI template syntax](#uri-template-syntax)
7. [Conventions](#conventions)

---

## Tool vs Resource — when to use which

| Use case | Tool | Resource |
|---|---|---|
| List with filters and pagination | ✅ | ❌ |
| Mutation (create/update/delete/mark won) | ✅ | ❌ |
| Single-record read by id | ❌ (possible but redundant) | ✅ |
| Multi-line content (notes, transcripts) | ❌ | ✅ |
| MCP host can subscribe to changes | ❌ | ✅ (future) |

A resource is invoked via the JSON-RPC method `resources/read` with `params.uri`. The MCP host treats resources as referenceable URIs (similar to file URIs) the user can mention in conversation.

---

## Step 1 — Create the resource class

File: `app/resources/users_resource.rb`

```ruby
class UsersResource < ApplicationResource
  uri_template 'woofed:///users/{id}'
  resource_name 'user'
  description 'A user record, including job description and language.'
  mime_type 'application/json'

  def content
    user = User.find(params[:id])
    JSON.generate(user.as_json(only: %i[id full_name email phone job_description language created_at updated_at]))
  end
end
```

Class anatomy:

| Macro / Method | Purpose |
|---|---|
| `uri_template 'woofed:///users/{id}'` | URI template. Path variables (`{id}`) become entries in `params`. |
| `resource_name 'user'` | Short name listed in `resources/list`. Should be a singular lowercased noun. |
| `description '...'` | Free-form description used by MCP hosts. |
| `mime_type 'application/json'` | MIME of the `text` field returned. Use `application/json` for structured payloads. |
| `def content` | Must return a **string**. The dispatcher wraps it as `result.contents[0].text`. |

`content` raises `ActiveRecord::RecordNotFound` when the id is invalid. `ApplicationResource.read` catches this and returns the message as a `text/plain` content item, so the client sees `"Couldn't find User with 'id'=99999"` instead of a generic JSON-RPC internal error.

---

## Step 2 — Register (automatic)

[McpController](../../app/controllers/mcp_controller.rb) builds the per-request `MCP::Server` with `resource_templates: ApplicationResource.descendants.map(&:to_resource_template)` and registers a `resources_read_handler` that delegates to `ApplicationResource.read`. Add your class file and restart — no manual wiring.

The preload in [config/initializers/mcp.rb](../../config/initializers/mcp.rb) ensures `descendants` is populated even in environments that don't eager-load (e.g. test).

---

## Step 3 — Write the spec

File: `spec/resources/users_resource_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe 'MCP resource: woofed:///users/{id}', type: :request do
  let!(:account) { create(:account) }
  let!(:requesting_user) { create(:user, account: account) }
  let!(:target_user) do
    create(:user, account: account, full_name: 'Jane Operator', email: 'jane@operator.com')
  end
  let(:auth_headers) { mcp_auth_headers(requesting_user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_resource_read_body("woofed:///users/#{target_user.id}"),
                   headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'returns the user with all serialized fields' do
      post '/mcp', params: mcp_resource_read_body("woofed:///users/#{target_user.id}"),
                   headers: auth_headers
      expect(mcp_result).to include(
        'id' => target_user.id,
        'full_name' => 'Jane Operator',
        'email' => 'jane@operator.com'
      )
    end

    it 'returns an error when the user does not exist' do
      post '/mcp', params: mcp_resource_read_body('woofed:///users/99999'),
                   headers: auth_headers
      expect(mcp_text).to match(/Couldn't find|No resource matches/i)
    end
  end
end
```

For not-found behaviour, use `mcp_text` since the dispatcher returns the error message as text content (not as a JSON-RPC top-level error).

---

## Step 4 — Document

Add an entry to:

1. [readme.md](readme.md) in the *Available resources* table.
2. A new file under `docs/mcp/resources/` (e.g. `users.md`).

---

## URI template syntax

`ApplicationResource` uses a simple `{placeholder}` syntax — placeholders become `params` keys (as strings):

| Pattern | Example URI | `params` |
|---|---|---|
| `woofed:///users/{id}` | `woofed:///users/42` | `{ id: "42" }` |
| `woofed:///users/{user_id}/deals/{id}` | `woofed:///users/42/deals/7` | `{ user_id: "42", id: "7" }` |

All placeholders are captured as **strings**. `Model.find` accepts string ids, so casting is usually unnecessary.

---

## Conventions

### Scheme

Use `woofed:///` for all internal resources. The MCP spec is flexible — any scheme works — but a project-specific one prevents collisions if the host loads multiple MCP servers.

### Returning JSON

Always wrap the payload in `JSON.generate(...)`. Returning a raw `Hash` would `to_s` upstream and produce unparseable garbage on the client.

### Including associations

Resources are a good fit for *fat reads* — the full graph of a record. Current resources include:

| Resource | `include:` |
|---|---|
| `ContactsResource` | `%i[deals events]` |
| `DealsResource` | `%i[contact stage pipeline deal_assignees deal_products]` |
| `ProductsResource` | `:deal_products` |
| `PipelinesResource` | (manual; stages merged into the JSON) |

Keep the `include` list focused on what the LLM would reasonably want. Don't pull in attachments or large binary fields.

### When NOT to make a resource

If a query needs:

- Pagination
- Multi-field filters
- Date range filters
- Any conditional logic beyond *"give me record X"*

… use a **tool** instead. The URI template can't carry arbitrary filters cleanly.

### Accessing the current user inside `content`

`ApplicationResource` exposes `current_user` and `current_account` as instance methods that read from `server_context`:

```ruby
def content
  user = current_user            # User instance, populated by McpController per request
  # scope by user.account, audit, etc.
end
```

The default resources don't scope by user because they're already protected by `doorkeeper_authorize! :mcp` and `validate_token_audience!` at the controller. Use `current_user`/`current_account` when you have stricter per-user access rules.
