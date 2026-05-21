# Testing MCP tools and resources

The MCP test suite exercises the full HTTP stack — controller, Doorkeeper, MCP SDK dispatch, tool/resource code, serialization — using **request specs**. This document explains the setup and shows how to write a new spec.

---

## Table of contents

1. [Overview](#overview)
2. [Test helper: `McpRequestHelpers`](#test-helper-mcprequesthelpers)
3. [Spec template](#spec-template)
4. [Patterns for common assertions](#patterns-for-common-assertions)
5. [What we are NOT testing](#what-we-are-not-testing)

---

## Overview

All MCP specs are RSpec request specs (`type: :request`). They:

1. Build a JSON-RPC request body with one of the helpers.
2. `POST /mcp` with an opaque Doorkeeper access token in the `Authorization` header.
3. Read the JSON-RPC response from `response.body` via `mcp_response` / `mcp_result` / `mcp_text`.
4. Assert on the returned data **and** on DB side-effects.

Each describe block has two contexts:

- `when it is an unauthenticated user` — asserts `401`.
- `when it is an authenticated user` — asserts behaviour.

Because the Streamable HTTP transport replies in the same HTTP response body, there is **no SSE stub** anymore — `response.body` already contains the JSON-RPC envelope.

---

## Test helper: `McpRequestHelpers`

File: [spec/support/mcp_request_helpers.rb](../../spec/support/mcp_request_helpers.rb)

| Helper | Purpose |
|---|---|
| `mcp_tool_call_body(name, args)` | Builds the JSON body for `tools/call`. |
| `mcp_resource_read_body(uri)` | Builds the JSON body for `resources/read`. |
| `mcp_auth_headers(user)` | Issues a Doorkeeper access token bound to the test base_url and returns the headers (`Authorization: Bearer …` + JSON Content-Type). |
| `mcp_response` | Parses the response body as JSON and returns the JSON-RPC envelope. Use for asserting on the top-level `error` field. |
| `mcp_result` | Returns the parsed JSON content from `result.content[0].text` (tools) or `result.contents[0].text` (resources). Raises if the tool returned `isError: true`. |
| `mcp_text` | Returns the raw text from `result.content[0].text` (or `contents[0].text`). Use for error-path specs where the body is human-readable, not JSON. |

The token issued by `mcp_auth_headers` has `resource: 'http://www.example.com/mcp'`, matching the default `request.base_url` in Rails request specs, so `McpController#validate_token_audience!` accepts it.

---

## Spec template

```ruby
require 'rails_helper'

RSpec.describe 'MCP tool: contacts_list', type: :request do
  let!(:account) { create(:account) }
  let!(:user)    { create(:user, account: account) }
  let(:auth_headers) { mcp_auth_headers(user) }

  let!(:john) { create(:contact, full_name: 'John Doe') }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_tool_call_body('contacts_list'),
                   headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'returns all contacts when no filter is provided' do
      post '/mcp', params: mcp_tool_call_body('contacts_list'), headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(mcp_result['data'].pluck('id')).to include(john.id)
    end
  end
end
```

For a resource spec, use `mcp_resource_read_body`:

```ruby
post '/mcp', params: mcp_resource_read_body("woofed:///contacts/#{john.id}"), headers: auth_headers
payload = mcp_result   # parsed contact JSON
```

---

## Patterns for common assertions

### Happy path with DB state

```ruby
it 'creates a contact with all submitted attributes' do
  expect do
    post '/mcp', params: mcp_tool_call_body('contacts_create', arguments), headers: auth_headers
  end.to change(Contact, :count).by(1)
  expect(Contact.last).to have_attributes(full_name: 'Tim Maia', email: 'tim@maia.com')
end
```

### Error from the tool (validation, not-found, custom guard)

The new tools return text responses on error paths, so assert on `mcp_text`:

```ruby
it 'returns not found when the contact does not exist' do
  post '/mcp', params: mcp_tool_call_body('contacts_update', { id: 99_999, full_name: 'x' }),
               headers: auth_headers
  expect(mcp_text).to match(/Couldn't find/i)
end

it 'returns validation errors when the contact is invalid' do
  post '/mcp', params: mcp_tool_call_body('contacts_create', invalid_args), headers: auth_headers
  expect(mcp_text).to include('Validation failed')
end
```

### JSON-RPC level error

If the tool raises an unhandled exception, the SDK returns a top-level `error` field in the JSON-RPC envelope. `mcp_result` raises in that case, so the spec fails clearly:

```
MCP tool returned error: Error: undefined local variable...
```

Use this to detect bugs in the tool itself.

### Schema validation (missing required arg)

The SDK validates inputs against `input_schema` before reaching `self.call`:

```ruby
it 'returns a schema validation error when name is missing' do
  post '/mcp', params: mcp_tool_call_body('pipelines_create', {}), headers: auth_headers
  expect(mcp_response.dig('result', 'isError')).to eq(true)
  expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/name/i)
end
```

### Pagination

```ruby
it 'paginates results' do
  post '/mcp', params: mcp_tool_call_body('contacts_list', { per_page: 1, page: 1 }),
               headers: auth_headers
  expect(mcp_result['data'].size).to eq(1)
  expect(mcp_result['pagination']).to include('count' => 2, 'pages' => 2)
end
```

### Date range filters

`updated_at` cannot be set at create time the same way `created_at` can. Update it explicitly:

```ruby
it 'filters by updated_at range' do
  john.update!(updated_at: 1.day.ago)
  post '/mcp', params: mcp_tool_call_body('contacts_list', { updated_from: 2.hours.ago.iso8601 }),
               headers: auth_headers
  expect(mcp_result['data'].pluck('id')).to eq([jane.id])
end
```

---

## What we are NOT testing

| Not tested | Reason | Mitigation |
|---|---|---|
| Server-streaming GET /mcp | Not used today; reserved for future SSE upgrades. | When/if used, add an integration spec with a real Puma process. |
| Cross-thread `Current.user` isolation | Hard to simulate in single-threaded Rack::Test. McpController no longer relies on `Current.user` — `server_context` is per-request and passed explicitly. | N/A — design avoids the problem. |
| Doorkeeper internals (scope checks, expiry validation, rotation) | Covered by Doorkeeper's own test suite. We rely on its public API. | Trust the gem. |
