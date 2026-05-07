# AGENTS.md — Woofed CRM: Architecture & Patterns for AI Agents

## Stack

- **Ruby on Rails**
- **PostgreSQL**
- **RSpec** for testing
- **WebMock** for HTTP request stubbing in specs
- **Frontend (legacy):** Hotwire (Turbo + Stimulus) — used throughout most of the existing application
- **Frontend (new):** Inertia.js + TypeScript (React) — the standard for all new pages and significant UI features; prefer this over Hotwire for any new work
- **Sidekiq** — background job processing for short async tasks
- **GoodJob** — job processing for long-running or scheduled jobs; prefer GoodJob over Sidekiq when a job needs scheduling, retries with delay, or is expected to run for an extended duration

## Testing

Tests are documentation. A reader must be able to understand what the code does by reading the spec
alone, without looking at the implementation. Every `describe` / `it` block should read as a sentence
describing observable behaviour, not internal implementation.

### General rules (backend and frontend)

- **No duplicate tests.** Check whether the behaviour is already covered at another layer before adding
  a new spec. Prefer the highest-level test that still exercises the behaviour — e.g. triggering a
  service through a model callback (`save!`) rather than calling the service directly, because the
  integrated test also covers the wiring between layers.
- **Group related assertions in one example.** If multiple `expect` calls verify different facets of
  the same outcome, keep them in a single `it` block. Only split into separate examples when the
  setup or teardown is meaningfully different.
- **100% code coverage is the target.** Every branch, edge case, and error path must be exercised.
  Use coverage reports to find gaps; do not ship untested code.
- **Test behaviour, not implementation.** Assert on outputs (return values, emitted events, HTTP
  responses, database state) — not on internal variables, private methods, or call counts unless
  there is no other observable signal.
- **Describe the "what", not the "how".** Favour names like
  `"returns empty array when conditions is null"` over `"calls normalizeConditionValues"`.
- **Edge cases to always cover:** explicit `null` for optional arrays, a single-item boundary (e.g.
  `showQueryOperator` when there is exactly one condition), and an "add to existing" case to confirm
  that spread/concat appends rather than replaces.

---

### Backend (RSpec)

```ruby
# Good — one example, multiple related assertions, reads as documentation
it "preserves all backend fields and appends the new condition" do
  result = subject.call
  expect(result[:conditions]).to have(3).items
  expect(result[:if_rule_id]).to eq(10)
  expect(result[:else_rule_id]).to eq(11)
end

# Bad — three separate examples testing the same operation
it "has 3 conditions" ...
it "keeps if_rule_id" ...
it "keeps else_rule_id" ...
```

- Use `described_class` instead of repeating the class name.
- Use `let` / `let!` for shared setup; avoid `before` blocks for data that belongs to a single example.
- Stub HTTP with WebMock (`stub_request`); never make real network calls in specs.
- Prefer `have_attributes` and `include` matchers over manual field access for complex objects.

---

### 100% patch coverage

Every line and branch introduced in a PR must be exercised by at least one test.
Codecov enforces patch coverage on each PR — aim for 100% on changed files.
When a conditional branch (e.g. `return unless …`, `if … else`) is only partially
covered, add a focused example for the missing path rather than removing the guard.

### Use factories, not inline `create` chains

Prefer FactoryBot factories and traits over long inline `create(…)` chains.
When the same setup pattern appears in more than one example, extract it into a
trait or a `let` helper so the intent stays readable and the setup stays DRY.

The `:with_if_else_sub_rules` trait on `:automation_rule` is the canonical way to
build a parent rule with two sub-automations in specs. It accepts transient options
(`if_actions`, `else_actions`, `if_conditions`, `extra_actions`) to customise each
branch; all have sensible defaults so a minimal `create(:automation_rule, :with_if_else_sub_rules)`
already produces a realistic fixture.

### Test behaviour that reflects production

Tests should exercise the same data flow that happens in production — using the
real HTTP stack (request specs), real DB writes, and real callbacks — not mocked
internals. A test that passes only because callbacks are stubbed gives no
confidence that the feature works end-to-end.

---

## Language

- **All code comments and documentation must be written in English.**

---

