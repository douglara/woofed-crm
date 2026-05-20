# Adding a new MCP tool

This is a step-by-step guide for adding a new tool to the MCP server. We will use a hypothetical `users_list` tool as the example.

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

- Inherits from `ApplicationTool` (which itself inherits from `ActionTool::Base`, an alias for `FastMcp::Tool`).
- Declares a `tool_name` (the canonical id used by the LLM).
- Declares `description` (free-form, used by the LLM to decide whether to call this tool).
- Declares `arguments` with a `dry-schema`-based DSL.
- Implements `call(**args)` returning a **JSON string** (the response payload).

By inheriting from `ApplicationTool` you get for free:

- `Pagy::Backend` for pagination.
- `Mcp::Concerns::RequestExceptionHandler` (provides `handle_with_exception`, `not_found_error`, `unprocessable_error`, `record_invalid_error`).
- `current_user` and `current_account` helpers.
- `paginate(scope, page:, per_page:)` helper.

---

## Step 1 — Create the tool class

File: `app/tools/users/list_tool.rb`

```ruby
module Users
  class ListTool < ApplicationTool
    tool_name 'users_list'
    description 'List users in the account. Supports filters by id, full_name, email and pagination.'

    arguments do
      optional(:id).filled(:integer).description('Filter by user ID')
      optional(:full_name).filled(:string).description('Filter by full name (case-insensitive partial match)')
      optional(:email).filled(:string).description('Filter by email (partial match)')
      optional(:page).filled(:integer).description('Page number (default 1)')
      optional(:per_page).filled(:integer).description('Items per page (default 25, max 100)')
    end

    def call(id: nil, full_name: nil, email: nil, page: 1, per_page: 25)
      handle_with_exception do
        scope = User.all
        scope = scope.where(id: id) if id.present?
        scope = scope.where('full_name ILIKE ?', "%#{full_name}%") if full_name.present?
        scope = scope.where('email ILIKE ?', "%#{email}%") if email.present?

        records, pagination = paginate(scope.order(created_at: :desc), page: page, per_page: per_page)
        {
          data: records.as_json(only: %i[id full_name email phone language created_at updated_at]),
          pagination: pagination
        }.to_json
      end
    end
  end
end
```

Key rules:

1. **Always wrap in `handle_with_exception`** so `ActiveRecord::RecordNotFound` and friends become structured errors instead of HTTP 500s.
2. **Return a JSON string**, not a Ruby hash. fast-mcp wraps the return value into `content[0].text`, and it expects a string. Returning a hash makes fast-mcp call `Hash#to_s` (Ruby inspect format) which is unusable JSON.
3. **For mutations, the failure path uses helpers from the concern**:
   ```ruby
   if record.save
     record.to_json
   else
     unprocessable_error(record.errors.full_messages)
   end
   ```

---

## Step 2 — Register (automatic)

There's nothing to do. The initializer auto-registers every descendant of `ApplicationTool`:

```ruby
# config/initializers/fast_mcp.rb
Rails.application.config.after_initialize do
  server.register_tools(*ApplicationTool.descendants)
  server.register_resources(*ApplicationResource.descendants)
end
```

Restart Rails (or trigger a code reload in dev) and the tool is available.

---

## Step 3 — Write the spec

File: `spec/tools/users/list_tool_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe 'MCP tool: users_list', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account, full_name: 'Jane Operator', email: 'jane@operator.com') }
  let!(:other_user) { create(:user, account: account, full_name: 'Bob Admin', email: 'bob@admin.com') }
  let(:auth_headers) do
    { 'Authorization' => "Bearer #{Users::JsonWebToken.encode_user(user)}",
      'Content-Type' => 'application/json' }
  end

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp/messages', params: mcp_tool_call_body('users_list'),
                            headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'returns all users when no filter is provided' do
      post '/mcp/messages', params: mcp_tool_call_body('users_list'), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to match_array([user.id, other_user.id])
    end

    it 'filters by id, full_name and email' do
      post '/mcp/messages', params: mcp_tool_call_body('users_list', { id: user.id }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([user.id])

      post '/mcp/messages', params: mcp_tool_call_body('users_list', { full_name: 'jane' }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([user.id])

      post '/mcp/messages', params: mcp_tool_call_body('users_list', { email: 'admin.com' }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([other_user.id])
    end

    it 'paginates results' do
      post '/mcp/messages', params: mcp_tool_call_body('users_list', { per_page: 1, page: 1 }), headers: auth_headers
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

### Argument descriptions matter

The LLM reads `description("...")` to decide whether and how to call the tool. Be specific:

```ruby
# Good
optional(:phone).filled(:string).description('Filter by phone in E.164 format, e.g. +5511999999999 (partial match)')

# Bad
optional(:phone).filled(:string)
```

### Returning errors

Use the helpers, not raw hashes:

```ruby
# Good
return unprocessable_error('Provide deal_id or contact_id') if deal_id.blank? && contact_id.blank?

# Bad — duplicates the schema
return { error: 'Provide deal_id or contact_id', status: 'unprocessable_entity' }.to_json
```

### Pagination

Use `paginate(scope, page:, per_page:)` — it returns `[records, pagination_hash]` and clamps `per_page` to `[1, 100]`. It does **not** call Pagy's `pagy_metadata` because that requires a controller `request` object; instead it builds the hash manually from the `Pagy` object's attributes.

### Custom_attributes filter

The standard pattern across list tools:

```ruby
custom_attributes&.each do |key, value|
  scope = scope.where('custom_attributes->>? = ?', key.to_s, value.to_s)
end
```

This translates each key/value pair into a JSONB lookup and ANDs them together.

### Date range filters

Use the suffixes `_from` / `_to` (not `_gteq` / `_lteq` like the REST API), to keep the schema LLM-friendly:

```ruby
optional(:created_from).filled(:string).description('Created on/after this ISO8601 UTC datetime')
optional(:created_to).filled(:string).description('Created on/before this ISO8601 UTC datetime')
```

### When the tool fetches by id

Use `Model.find(id)` (bang version). It raises `ActiveRecord::RecordNotFound`, which `handle_with_exception` turns into a clean `not_found_error('Resource could not be found')` response. Don't use `find_by(id:)` because that returns `nil` and you'd have to handle that manually.

```ruby
def call(id:, **attrs)
  handle_with_exception do
    record = Model.find(id)         # raises if not found, handler catches it
    if record.update(attrs.compact)
      record.to_json
    else
      unprocessable_error(record.errors.full_messages)
    end
  end
end
```
