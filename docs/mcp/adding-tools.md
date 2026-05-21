# Adding a new MCP tool

Step-by-step guide for adding a tool to the MCP server, using a hypothetical `users_list` tool as the example.

---

## Table of contents

1. [What a tool is](#what-a-tool-is)
2. [Step 1 — Create the tool class](#step-1--create-the-tool-class)
3. [Step 2 — Register (automatic)](#step-2--register-automatic)
4. [Step 3 — Write the spec](#step-3--write-the-spec)
5. [Step 4 — Document](#step-4--document)
6. [Conventions and gotchas](#conventions-and-gotchas)

---

## What a tool is

A tool is a Ruby class under `app/tools/` that:

- Inherits from `ApplicationTool` (which itself inherits from `MCP::Tool` — the official Ruby SDK base).
- Declares a `tool_name` (the canonical id used by the LLM).
- Declares `description` (free-form, used by the LLM to decide whether to call this tool).
- Declares `input_schema` with a JSON-Schema-style `properties:` / `required:` block.
- Implements `def self.call(server_context:, **named_args)` returning an `MCP::Tool::Response`.

By inheriting from `ApplicationTool` you get:

- `paginate(scope, page:, per_page:)` helper (Pagy-backed).
- `current_user(server_context)` and `current_account(server_context)` shortcuts.
- `json_response(payload)` and `text_response(message)` for the two common reply shapes.
- `handle_errors { ... }` which converts `ActiveRecord::RecordNotFound`, `ActiveRecord::RecordInvalid`, and `StandardError` into readable text responses.

---

## Step 1 — Create the tool class

File: `app/tools/users/list_tool.rb`

```ruby
module Users
  class ListTool < ApplicationTool
    tool_name 'users_list'
    description 'List users in the account. Supports filters by id, full_name, email and pagination.'

    input_schema(
      properties: {
        id:        { type: 'integer', description: 'Filter by user ID' },
        full_name: { type: 'string',  description: 'Filter by full name (case-insensitive partial match)' },
        email:     { type: 'string',  description: 'Filter by email (partial match)' },
        page:      { type: 'integer', description: 'Page number (default 1)' },
        per_page:  { type: 'integer', description: 'Items per page (default 25, max 100)' }
      }
    )

    def self.call(server_context:, id: nil, full_name: nil, email: nil, page: 1, per_page: 25)
      handle_errors do
        scope = User.all
        scope = scope.where(id: id) if id.present?
        scope = scope.where('full_name ILIKE ?', "%#{full_name}%") if full_name.present?
        scope = scope.where('email ILIKE ?', "%#{email}%") if email.present?

        records, pagination = paginate(scope.order(created_at: :desc), page: page, per_page: per_page)
        json_response(
          data: records.as_json(only: %i[id full_name email phone language created_at updated_at]),
          pagination: pagination
        )
      end
    end
  end
end
```

Key rules:

1. **`self.call` is a class method**, not an instance method. The MCP SDK invokes tools as `Tool.call(...)`.
2. **`server_context:` is always required** in the signature, even when the tool doesn't use it. The SDK always passes it.
3. **Return `MCP::Tool::Response`**, never a plain string or hash. Use `json_response(payload)` for structured payloads and `text_response(message)` for human-readable text.
4. **Wrap in `handle_errors`** so common ActiveRecord exceptions become readable text responses.

---

## Step 2 — Register (automatic)

Nothing to do. [config/initializers/mcp.rb](../../config/initializers/mcp.rb) preloads every file under `app/tools/**/*.rb` on boot, so `ApplicationTool.descendants` is populated by the time [McpController](../../app/controllers/mcp_controller.rb) builds the per-request `MCP::Server` instance.

Restart the server (or trigger a code reload in dev) and the tool is available.

---

## Step 3 — Write the spec

File: `spec/tools/users/list_tool_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe 'MCP tool: users_list', type: :request do
  let!(:account) { create(:account) }
  let!(:user)    { create(:user, account: account, full_name: 'Jane Operator', email: 'jane@operator.com') }
  let!(:other)   { create(:user, account: account, full_name: 'Bob Admin',    email: 'bob@admin.com') }
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_tool_call_body('users_list'),
                   headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'returns all users when no filter is provided' do
      post '/mcp', params: mcp_tool_call_body('users_list'), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to match_array([user.id, other.id])
    end

    it 'filters by id, full_name and email' do
      post '/mcp', params: mcp_tool_call_body('users_list', { id: user.id }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([user.id])

      post '/mcp', params: mcp_tool_call_body('users_list', { full_name: 'jane' }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([user.id])

      post '/mcp', params: mcp_tool_call_body('users_list', { email: 'admin.com' }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([other.id])
    end

    it 'paginates results' do
      post '/mcp', params: mcp_tool_call_body('users_list', { per_page: 1, page: 1 }), headers: auth_headers
      expect(mcp_result['data'].size).to eq(1)
      expect(mcp_result['pagination']).to include('count' => 2, 'pages' => 2)
    end
  end
end
```

See [testing.md](testing.md) for more spec patterns.

---

## Step 4 — Document

Add an entry to:

1. [readme.md](readme.md) in the *Available tools* table.
2. The relevant `docs/mcp/tools/*.md` file (create one if the domain is new).

---

## Conventions and gotchas

### Naming

- `tool_name` uses **snake_case** and groups by resource: `contacts_list`, `contacts_create`, `deals_mark_won`.
- File path mirrors the class: `app/tools/contacts/list_tool.rb` → `Contacts::ListTool`.

### Field descriptions matter

The LLM reads `description:` on each property to decide whether and how to call the tool. Be specific:

```ruby
# Good
phone: { type: 'string', description: 'Filter by phone in E.164 format, e.g. +5511999999999 (partial match)' }

# Bad
phone: { type: 'string' }
```

### Returning errors

Use the helpers, not raw strings:

```ruby
# Good
return text_response('Provide deal_id or contact_id') if deal_id.blank? && contact_id.blank?

# Bad — bypasses the MCP::Tool::Response wrapper
return 'Provide deal_id or contact_id'
```

### Pagination

Use `paginate(scope, page:, per_page:)` — returns `[records, pagination_hash]` and clamps `per_page` to `[1, 100]`. It builds the pagination metadata manually so it doesn't need a controller `request` object.

### `custom_attributes` filter

Standard pattern across list tools:

```ruby
custom_attributes&.each do |key, value|
  scope = scope.where('custom_attributes->>? = ?', key.to_s, value.to_s)
end
```

Each key/value pair translates to a JSONB lookup, ANDed together.

### Date range filters

Use `_from` / `_to` suffixes (not `_gteq` / `_lteq` like the REST API), to keep the schema LLM-friendly:

```ruby
created_from: { type: 'string', description: 'Created on/after this ISO8601 UTC datetime' },
created_to:   { type: 'string', description: 'Created on/before this ISO8601 UTC datetime' },
```

### When the tool fetches by id

Use `Model.find(id)` (bang version). It raises `ActiveRecord::RecordNotFound`, which `handle_errors` turns into a clean text response. Don't use `find_by(id:)` — it returns `nil` and you'd have to handle that manually:

```ruby
def self.call(server_context:, id:, **attrs)
  handle_errors do
    record = Model.find(id)               # raises if not found
    if record.update(attrs.compact)
      json_response(record.as_json)
    else
      text_response("Validation failed: #{record.errors.full_messages.join(', ')}")
    end
  end
end
```

### Accessing the current user

```ruby
def self.call(server_context:, content:, deal_id: nil)
  handle_errors do
    user = current_user(server_context)            # User instance
    EventBuilder.new(user, params).build
  end
end
```

`current_user` and `current_account` are helpers on `ApplicationTool` that pull from `server_context`, which `McpController` populates per request from the Doorkeeper access token.
