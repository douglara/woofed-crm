# Architecture

This document describes the architecture of the Woofed CRM MCP server: how the layers fit together, how an HTTP request flows from the client to a tool/resource, and how the SSE transport delivers responses.

---

## Table of contents

1. [Layers](#layers)
2. [Middleware stack](#middleware-stack)
3. [Request lifecycle — Tools](#request-lifecycle--tools)
4. [Request lifecycle — Resources](#request-lifecycle--resources)
5. [SSE transport in depth](#sse-transport-in-depth)
6. [Error handling](#error-handling)
7. [File layout](#file-layout)

---

## Layers

The MCP integration is split into clearly separated layers. Each layer has a single responsibility:

```mermaid
flowchart TB
    subgraph Transport["Transport (fast-mcp gem)"]
        SSE[GET /mcp/sse<br/>Server-Sent Events stream]
        MSG[POST /mcp/messages<br/>JSON-RPC inbound]
    end

    subgraph Middleware["Application middleware"]
        JWT[Mcp::JwtAuthenticator<br/>config/middleware/mcp/jwt_authenticator.rb]
    end

    subgraph Server["MCP server (fast-mcp)"]
        Dispatcher[FastMcp::Server#handle_request]
    end

    subgraph App["App-level Ruby"]
        AT[ApplicationTool<br/>app/tools/application_tool.rb]
        AR[ApplicationResource<br/>app/resources/application_resource.rb]
        Concern[Mcp::Concerns::RequestExceptionHandler<br/>app/tools/mcp/concerns/]
    end

    subgraph Domain["Domain models"]
        M[(Contact, Deal, Event, Pipeline,<br/>Product, Apps::Chatwoot,<br/>Apps::EvolutionApi)]
    end

    Transport --> Middleware
    Middleware --> Server
    Server --> AT
    Server --> AR
    AT --> Concern
    AT --> M
    AR --> M
```

| Layer | Responsibility |
|---|---|
| **Transport** | HTTP + SSE wire protocol. JSON-RPC framing. Provided by `fast-mcp`. |
| **Middleware** | JWT validation, sets `Current.user`, short-circuits unauthorized requests with `401`. |
| **MCP server** | Routes the JSON-RPC method (`tools/call`, `resources/read`, etc.) to the right handler. |
| **App-level Ruby** | Business logic. Tools/resources call into models, builders, and use cases. |
| **Domain models** | ActiveRecord models. Same models used by the REST API and the web UI. |

---

## Middleware stack

The Rails middleware stack, ordered top-down (request flow), looks like this after our initializer runs:

```
…
Rack::Runtime
ActionDispatch::Executor
ActionDispatch::Static
…
Mcp::JwtAuthenticator             ← inserted by config/initializers/fast_mcp.rb
FastMcp::Transports::RackTransport
…
Routes (Rails router, never reached for /mcp/*)
```

Two things to note:

1. **`Mcp::JwtAuthenticator` is inserted via `insert_before`**, ensuring it runs *before* `FastMcp::Transports::RackTransport`:

    ```ruby
    Rails.application.config.middleware.insert_before(
      FastMcp::Transports::RackTransport,
      Mcp::JwtAuthenticator,
      path_prefix: '/mcp'
    )
    ```

2. **The middleware class is `require`d explicitly** at the top of the initializer because it lives outside Rails' autoload paths (in `config/middleware/`):

    ```ruby
    require Rails.root.join('config/middleware/mcp/jwt_authenticator').to_s
    ```

    This avoids a chicken-and-egg problem: Zeitwerk's main loader isn't fully set up by the time `config/initializers/*.rb` runs, so referencing an autoload-only constant from the initializer fails. Placing the file in `config/middleware/` (not autoloaded) and `require`ing it makes the constant available immediately.

---

## Request lifecycle — Tools

A typical tool call goes through the following sequence:

```mermaid
sequenceDiagram
    autonumber
    participant C as MCP Client
    participant J as Mcp::JwtAuthenticator
    participant T as FastMcp::Transports::RackTransport
    participant S as FastMcp::Server
    participant Tool as ApplicationTool (e.g. Contacts::ListTool)
    participant H as Mcp::Concerns::RequestExceptionHandler
    participant M as Models (Contact)

    C->>J: POST /mcp/messages<br/>Authorization: Bearer JWT<br/>body: {"method":"tools/call",...}
    J->>J: ActionController::HttpAuthentication::Token<br/>.token_and_options(request)
    J->>J: Users::JsonWebToken.decode_user(token)
    alt invalid / missing JWT
        J-->>C: 401 Unauthorized<br/>{ jsonrpc, error: { code: -32001, message: "Unauthorized" } }
    end
    J->>J: Current.set(user: user) do
    J->>T: app.call(env)
    T->>S: handle_request(json_str, headers: ...)
    S->>S: case method == "tools/call"
    S->>Tool: tool.new(headers:).call_with_schema_validation!(**args)
    Tool->>H: handle_with_exception do
    H->>M: Contact.all.where(...).order(...)
    M-->>H: ActiveRecord::Relation
    H-->>Tool: { data: [...], pagination: {...} }.to_json
    Tool-->>S: result (JSON string)
    S->>S: send_formatted_result(result, id, metadata)
    S->>T: send_message({ jsonrpc, result: { content: [{ type:"text", text: "<json>"}]}})
    T-->>C: stream the message via /mcp/sse
    T-->>J: rack response [200, {Content-Type:application/json}, []]
    J->>J: Current.reset (via Current.set block)
    J-->>C: 200 OK (empty body — actual payload arrived via SSE)
```

**Why does the POST return an empty body?** The legacy MCP HTTP+SSE transport (which fast-mcp implements) sends the actual response over the SSE channel — not in the POST response. The POST `/mcp/messages` simply acknowledges receipt with `200 OK`. The client reads the response from its open `GET /mcp/sse` stream.

This split has direct implications for testing — see [testing.md](testing.md#why-tests-stub-send_message).

---

## Request lifecycle — Resources

Resources follow a similar flow but use a different JSON-RPC method (`resources/read`):

```mermaid
sequenceDiagram
    autonumber
    participant C as MCP Client
    participant J as Mcp::JwtAuthenticator
    participant T as FastMcp::Transports::RackTransport
    participant S as FastMcp::Server
    participant R as ContactsResource

    C->>J: POST /mcp/messages<br/>{"method":"resources/read","params":{"uri":"woofed:///contacts/42"}}
    J->>T: (passes after JWT check)
    T->>S: handle_request(json_str)
    S->>S: case method == "resources/read"
    S->>R: ContactsResource.initialize_from_uri("woofed:///contacts/42")
    R->>R: params[:id] == "42"
    R->>R: content (returns JSON string)
    R-->>S: JSON.generate(contact.as_json(include: %i[deals events]))
    S->>T: send_message({ jsonrpc, result: { contents: [{ uri, mimeType, text }]}})
    T-->>C: via SSE
```

Resources use `contents` (plural) instead of `content`, per the MCP spec.

---

## SSE transport in depth

The full picture of how request/response interleave on the wire:

```mermaid
sequenceDiagram
    participant C as Client
    participant Rails as Rails app

    Note over C,Rails: 1. Establish SSE stream (long-lived)
    C->>Rails: GET /mcp/sse<br/>Authorization: Bearer JWT
    Rails-->>C: 200 OK<br/>Content-Type: text/event-stream<br/>(connection stays open)

    Note over C,Rails: 2. Client sends a request
    C->>Rails: POST /mcp/messages<br/>Authorization: Bearer JWT<br/>{"jsonrpc":"2.0","id":1,"method":"tools/call",...}
    Rails-->>C: 200 OK (empty body — ack only)

    Note over C,Rails: 3. Server pushes response via SSE
    Rails-->>C: data: {"jsonrpc":"2.0","id":1,"result":{...}}\n\n

    Note over C,Rails: 4. Multiple in-flight requests are<br/>correlated by JSON-RPC "id"
    C->>Rails: POST /mcp/messages<br/>{"id":2,"method":"tools/call",...}
    C->>Rails: POST /mcp/messages<br/>{"id":3,"method":"resources/read",...}
    Rails-->>C: data: {"id":3,"result":...}\n\n
    Rails-->>C: data: {"id":2,"result":...}\n\n
```

Implementation notes:

- The SSE stream is implemented in [`FastMcp::Transports::RackTransport`](https://github.com/yjacquin/fast-mcp/blob/main/lib/mcp/transports/rack_transport.rb), specifically `handle_sse_request` and `setup_sse_connection`. Rack hijacking is used to keep the connection open.
- The server keeps a `@sse_clients` map of connected streams. When a tool/resource finishes, `send_message(message)` writes `data: <json>\n\n` to every connected stream.
- If no SSE client is connected (as in `Rack::Test`), `send_message` writes to nothing — the response is dropped. That's why the test suite stubs `send_message` (see [testing.md](testing.md)).

---

## Error handling

Exceptions raised inside a tool are caught by `Mcp::Concerns::RequestExceptionHandler` (included in `ApplicationTool`). The pattern mirrors `Api::Concerns::RequestExceptionHandler` from the REST API, but returns JSON strings instead of rendering HTTP responses.

```mermaid
flowchart TD
    Call[tool.call &rarr; handle_with_exception block] --> Yield[yield]
    Yield -->|happy path| Ok[return JSON string]
    Yield -->|ActiveRecord::RecordNotFound| NF[not_found_error<br/>'Resource could not be found'<br/>status: not_found]
    Yield -->|ActiveRecord::RecordInvalid| RI[record_invalid_error<br/>full_messages<br/>status: unprocessable_entity]
    Yield -->|ActionController::ParameterMissing| PM[unprocessable_error<br/>e.message<br/>status: unprocessable_entity]
    Yield -->|ArgumentError| AE[unprocessable_error<br/>'Invalid arguments: ...'<br/>status: unprocessable_entity]
    NF --> Reset[ensure: Current.reset]
    RI --> Reset
    PM --> Reset
    AE --> Reset
    Ok --> Reset
```

All branches converge on `ensure: Current.reset` so that thread-local state doesn't leak between requests on the same thread (relevant for multi-threaded Puma).

Return shapes:

| Helper | Shape |
|---|---|
| `not_found_error('msg')` | `{ "error": "msg", "status": "not_found" }` |
| `unprocessable_error(msg)` | `{ "error": msg, "status": "unprocessable_entity" }` |
| `record_invalid_error(e)` | `{ "error": [...full_messages], "attributes": [...], "status": "unprocessable_entity" }` |

`msg` may be a string or an array. Arrays are typically `record.errors.full_messages`.

---

## File layout

```
woofed-crm/
├── config/
│   ├── initializers/
│   │   └── fast_mcp.rb              ← mounts MCP, inserts middleware
│   └── middleware/
│       └── mcp/
│           └── jwt_authenticator.rb ← Rack middleware (NOT autoloaded)
├── app/
│   ├── tools/
│   │   ├── application_tool.rb      ← base class, paginate helper
│   │   ├── mcp/
│   │   │   └── concerns/
│   │   │       └── request_exception_handler.rb
│   │   ├── contacts/
│   │   │   ├── list_tool.rb
│   │   │   ├── create_tool.rb
│   │   │   └── update_tool.rb
│   │   ├── deals/
│   │   │   ├── list_tool.rb
│   │   │   ├── create_tool.rb
│   │   │   ├── update_tool.rb
│   │   │   ├── mark_won_tool.rb
│   │   │   └── mark_lost_tool.rb
│   │   ├── pipelines/list_tool.rb
│   │   ├── products/list_tool.rb
│   │   ├── events/
│   │   │   ├── create_note_tool.rb
│   │   │   ├── create_activity_tool.rb
│   │   │   ├── send_chatwoot_message_tool.rb
│   │   │   └── send_whatsapp_message_tool.rb
│   │   └── apps/
│   │       ├── chatwoots/list_tool.rb
│   │       └── evolution_apis/list_tool.rb
│   ├── resources/
│   │   ├── application_resource.rb  ← base class
│   │   ├── contacts_resource.rb
│   │   ├── deals_resource.rb
│   │   └── products_resource.rb
│   └── models/
│       └── current.rb               ← Current.user added here
├── spec/
│   ├── support/
│   │   └── mcp_request_helpers.rb   ← test stub for SSE
│   ├── middleware/mcp/
│   ├── tools/
│   └── resources/
└── docs/
    └── mcp/                         ← this folder
```

The split between `config/middleware/` (manually `require`d) and `app/tools/` (autoloaded by Zeitwerk) is intentional — see [authentication.md § Loading the middleware](authentication.md#loading-the-middleware) for the rationale.
