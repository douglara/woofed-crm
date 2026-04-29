# Plugin System

## Overview

The plugin system lets us extend WoofedCRM — adding models, views, controllers, JavaScript components, styles, routes, and migrations — **without ever modifying the core codebase**.
A plugin is an independent piece of code, distributed by Woofed Store and load in the application boot time.


## Why it exists

WoofedCRM is meant to be a flexible product. Different customers, niches, and integrations require different features, but baking every feature into the core would make the codebase bloated and hard to maintain.

## What problems it solves

- **Isolation** — plugins can be added or removed without touching the core codebase
- **Composability** — multiple plugins can extend the same file with predictable order
- **Safety** — `storage/build/` is disposable; rebuilding from scratch is always safe
- **Unified mechanism** — one DSL, one build folder, all file types


## Use cases

Plugins are how WoofedCRM grows beyond the core. A few realistic examples:

- **Channel integrations** — WhatsApp, Instagram, Telegram, Email connectors.
- **Industry-specific features** — a plugin for real estate (properties, contracts),
  another for healthcare (appointments, patient records), another for e-commerce
  (orders, abandoned carts).
- **Custom dashboards and reports** — pages with charts and KPIs tailored to a
  customer's workflow.
- **External integrations** — sync with ERPs, payment gateways, marketing
  platforms, or BI tools.
- **Workflow automations** — triggers, custom pipelines, scoring rules.

Anything that would otherwise live as a fork or a hardcoded option in the core
can become a plugin.


## What a plugin can do

A plugin has full access to the application. It can:

- **Add** new models, controllers, views, JavaScript components, and stylesheets.
- **Patch** existing core files (models, views, components, CSS) through the
  Patch DSL — without modifying them on disk.
- **Define routes** under its own namespace.
- **Add migrations** to create new tables, **alter or drop existing tables**,
  and modify the core database schema.
- **Replace core logic** — patches can rewrite entire methods, blocks, or
  files when needed.
- **Declare gem dependencies** in its own `Gemfile`.

> ⚠️ **Power and responsibility.** Because plugins can change the database and
> rewrite core logic, a poorly designed or malicious plugin can corrupt data,
> break workflows, or compromise the application. **Only install plugins that
> have been verified and approved through the Woofed Store.** The store is the
> trust boundary — plugins published there go through review and are trusted to
> behave correctly. Sideloading unverified plugins is strongly discouraged.


## How it works — the flow

```
   ┌──────────┐                       ┌──────────────┐
   │   User   │ ── 1. install ──────> │ Woofed Store │
   └──────────┘                       └──────────────┘
                                              │
                                              │ 2. download ZIP
                                              ▼
                                     ┌──────────────────┐
                                     │ storage/plugins/ │
                                     └──────────────────┘
                                              │
                                              │ 3. application restart
                                              ▼
                                     ┌──────────────────┐
                                     │  Plugin Loader   │
                                     │  + Build Manager │
                                     └──────────────────┘
                                              │
                                              │ 4. build
                                              ▼
                                     ┌──────────────────┐
                                     │  storage/build/  │
                                     └──────────────────┘
                                              │
                                              │ 5. boot
                                              ▼
                                     ┌──────────────────┐
                                     │ Rails + Vite     │
                                     │ (plugin loaded)  │
                                     └──────────────────┘
```

1. The user installs a plugin through the Woofed Store.
2. The system downloads the plugin ZIP and extracts it into `storage/plugins/{plugin_id}/`.
3. The application restarts.
4. The Plugin Loader and Build Manager combine plugin files with the core, producing `storage/build/`.
5. Rails and Vite boot, loading the plugin transparently — the plugin is now live in the application.


## How to create a plugin

Every WoofedCRM installation ships with a starter folder at
`storage/plugins/my_new_plugin/`. It contains a minimal working example —
manifest, a sample patch, and a sample new file — that serves as a starting
point for plugin development.

The development workflow is:

1. **Fork** the WoofedCRM repository.
2. **Implement** your plugin inside `storage/plugins/my_new_plugin/` — use the
   existing files as a reference and adapt them to your feature.
3. **Submit** your plugin to the Woofed Store. The store takes care of
   building the deliverable: it packages your plugin into the proper
   ZIP format that customer installations can download and install.

The developer never has to worry about the deliverable format, packaging
rules, or distribution mechanics — that is entirely handled by the store at
submission time. The fork is the only environment a plugin author needs.

---

## The `storage/build/` folder

No file inside `app/` is ever written to. All modifications live in `storage/build/`.
`storage/build/` is the single output folder for the plugin system. It is:

- **Generated on boot** — `PluginLoader` runs `BuildManager.sync!` on startup
- **Gitignored** — never committed to version control
- **Disposable** — `rails plugins:rebuild` wipes and recreates it from scratch
- **Incremental** — only rebuilds files whose fingerprint has changed

### Resolution rule

Every layer (Rails autoloader, view resolver, Vite) checks `storage/build/` first:

```
storage/build/{target} exists?  →  yes → use storage/build/
→  no  → use app/ (original)
```

Rails is configured with `storage/build/app/` prepended to autoload paths, view paths,
and controller paths. Vite uses a custom resolver plugin that checks
`storage/build/app/javascript/` before `app/javascript/`.

---

## Folder structure

```
storage/plugins/
└── <plugin_installation_id>/
    ├── plugin.rb                    ← plugin manifest (required)
    ├── Gemfile                      ← plugin gem dependencies (optional)
    ├── app/                         ← all plugin files live here
    │   ├── models/
    │   │   ├── contact.rb           ← PATCH: same path as app/models/contact.rb
    │   │   ├── contact_extension.rb ← NEW FILE: no match in app/
    │   │   └── new_model.rb         ← NEW FILE: no match in app/
    │   ├── controllers/
    │   │   └── example_controller.rb ← NEW FILE
    │   ├── views/
    │   │   ├── users/
    │   │   │   └── show.html.erb    ← PATCH: same path as app/views/users/
    │   │   └── example/
    │   │       └── _badge.html.erb  ← NEW FILE
    │   ├── javascript/
    │   │   ├── pages/
    │   │   │   └── UserProfile.jsx  ← PATCH: same path as app/javascript/pages/
    │   │   └── components/
    │   │       └── ExampleBadge.jsx ← NEW FILE
    │   └── assets/stylesheets/
    │       └── app.css              ← PATCH: same path as app/assets/stylesheets/
    ├── config/
    │   └── routes.rb                ← plugin routes (optional)
    ├── db/
    │   └── migrate/                 ← plugin migrations (optional)
    └── spec/                        ← plugin tests (required)
        ├── models/
        ├── requests/
        ├── patches/
        └── javascript/
```

---

## Plugin manifest (`plugin.rb`)

Every plugin must have a `plugin.rb` at its root with at least a `name`:

```ruby
# storage/plugins/my_plugin/plugin.rb
name    "my_plugin"
version "1.0.0"
priority 10
```

### Fields

| Field      | Required | Default | Description |
|------------|----------|---------|-------------|
| `name`     | Yes      | —       | Unique plugin identifier |
| `version`  | No       | `0.0.0` | Semantic version string |
| `priority` | No       | `0`     | Controls patch order — lower numbers run first |

### Priority

When multiple plugins patch the same file, priority determines the order.
Plugin with priority `10` runs before priority `20`. A later plugin can use
lines inserted by an earlier plugin as anchors.

---

## Plugin Gemfile (optional)

Plugins can declare their own gem dependencies in `storage/plugins/<plugin_installation_id>/Gemfile`. The main
`Gemfile` automatically evaluates all plugin Gemfiles via `eval_gemfile`. On boot,
`bundle install` runs before the Rails environment loads, ensuring new gems are
available.

```ruby
# storage/plugins/my_plugin/Gemfile
gem "some_gem", "~> 1.0"
```

The `Gemfile` uses standard Bundler syntax — groups, platforms, `source`, etc. all work.

---


## New files vs patches — the path rule

There is no `patches/` folder. The file path inside the plugin is the signal:

- **Same relative path as a file in `app/`** → **patch** — file contains `FilePatch`
  DSL, loaded via `require`, result written to `storage/build/`
- **No matching file in `app/`** → **new file** — copied as-is to `storage/build/`,
  loaded normally by Rails or Vite

### Example: patch file

```
storage/plugins/example/app/models/contact.rb       ← PATCH (app/models/contact.rb exists)
```

Content is `FilePatch` DSL, not a Ruby class:

```ruby
Plugins::FilePatch.define target: "app/models/contact.rb" do
  after_line containing: "class Contact < ApplicationRecord" do
    "  include Plugins::Example::ContactExtension"
  end
end
```

### Example: new file

```
storage/plugins/example/app/models/contact_extension.rb  ← NEW FILE (no match in app/)
```

Content is a normal Ruby module:

```ruby
module Plugins
  module Example
    module ContactExtension
      extend ActiveSupport::Concern

      included do
        has_many :example_records
      end

      def example_method
        "extended"
      end
    end
  end
end
```

---

## Patch DSL — complete reference

The same DSL works for any file type (`.rb`, `.erb`, `.css`, `.js`, `.jsx`, `.ts`, `.tsx`).

### `after_line`

Insert content after the first line matching `containing:`.

```ruby
after_line containing: "class Contact < ApplicationRecord" do
  "  include MyExtension"
end
```

**Before:**
```ruby
class Contact < ApplicationRecord
  belongs_to :account
end
```

**After:**
```ruby
class Contact < ApplicationRecord
  include MyExtension
  belongs_to :account
end
```

### `before_line`

Insert content before the first line matching `containing:`.

```ruby
before_line containing: "belongs_to :account" do
  "  has_many :things"
end
```

**Before:**
```ruby
class Contact < ApplicationRecord
  belongs_to :account
end
```

**After:**
```ruby
class Contact < ApplicationRecord
  has_many :things
  belongs_to :account
end
```

### `replace_line`

Replace the entire matching line with a new string.

```ruby
replace_line containing: "ROLES = %w[admin user]",
             with: "  ROLES = %w[admin user example_role]"
```

**Before:**
```ruby
ROLES = %w[admin user]
```

**After:**
```ruby
ROLES = %w[admin user example_role]
```

### `replace_block`

Replace everything between two marker lines (inclusive).

```ruby
replace_block from: "<%# plugin:example:start %>",
              to:   "<%# plugin:example:end %>" do
  <<~ERB
    <section class="example-panel">
      <%= render "example/panel" %>
    </section>
  ERB
end
```

**Before:**
```erb
<%# plugin:example:start %>
<%# plugin:example:end %>
```

**After:**
```erb
<section class="example-panel">
  <%= render "example/panel" %>
</section>
```

### `append_to_file`

Append content at the end of the file.

```ruby
append_to_file do
  <<~CSS
    .example-badge { color: purple; }
  CSS
end
```

### `prepend_to_file`

Prepend content at the beginning of the file.

```ruby
prepend_to_file do
  "# Extended by example plugin"
end
```

---

## Extension markers

Place extension markers in base application files to provide robust anchors for
`replace_block`. Markers are more reliable than `containing:` anchors because they
are explicit and unlikely to change.

### ERB markers

```erb
<%# plugin:example:start %>
<%# plugin:example:end %>
```

### JSX markers

```jsx
{/* plugin:tabs */}
{/* plugin:tab-content */}
```

### CSS markers

```css
/* plugin:example:start */
/* plugin:example:end */
```

### Why markers are more robust

- They are comments — no effect on rendering or behavior
- They are unique — unlikely to be duplicated or refactored away
- They are explicit — clearly signal that plugins are expected to extend this area
- They survive code reformatting and linting

---

## ActiveRecord macros in plugins

`has_many`, `belongs_to`, `validates`, `scope`, and other ActiveRecord macros must
live in an `ActiveSupport::Concern` as a **new file** (not in a patch). The patch
only injects the `include`.

### Why

ActiveRecord macros must execute inside the class body at class load time. Putting
them in a patch file (which contains DSL, not class code) would fail. The Concern
pattern ensures macros run correctly when the patched class loads.

### Full example

**New file** — the Concern (`storage/plugins/example/app/models/contact_extension.rb`):

```ruby
module Plugins
  module Example
    module ContactExtension
      extend ActiveSupport::Concern

      included do
        has_many :example_records, dependent: :destroy
        validates :example_field, presence: true
        scope :with_examples, -> { where(example_active: true) }
      end

      def example_method
        "extended"
      end
    end
  end
end
```

**Patch file** — injects the include (`storage/plugins/example/app/models/contact.rb`):

```ruby
Plugins::FilePatch.define target: "app/models/contact.rb" do
  after_line containing: "class Contact < ApplicationRecord" do
    "  include Plugins::Example::ContactExtension"
  end
end
```

---

## Multi-plugin patches and priority

When two plugins patch the same file, `priority` controls order. Lower priority
runs first.

### Example

Plugin `alpha` (priority 10) adds an import:

```ruby
# storage/storage/plugins/alpha/app/javascript/pages/UserProfile.jsx
Plugins::FilePatch.define target: "app/javascript/pages/UserProfile.jsx",
                           priority: 10 do
  after_line containing: 'import Avatar from "@/components/Avatar"' do
    'import AlphaBadge from "@/components/AlphaBadge"'
  end
end
```

Plugin `beta` (priority 20) uses the line inserted by `alpha` as its anchor:

```ruby
# storage/storage/plugins/beta/app/javascript/pages/UserProfile.jsx
Plugins::FilePatch.define target: "app/javascript/pages/UserProfile.jsx",
                           priority: 20 do
  after_line containing: 'import AlphaBadge from "@/components/AlphaBadge"' do
    'import BetaBadge from "@/components/BetaBadge"'
  end
end
```

This only works because `beta` runs after `alpha` (priority 20 > 10).

---

## Routes

Plugins can define routes in `storage/plugins/<name>/config/routes.rb`. These are
automatically loaded and drawn into the main Rails router on boot.

```ruby
# storage/plugins/example/config/routes.rb
namespace :example do
  resources :widgets, only: [:index, :show]
end
```

The routes file uses the same DSL as `config/routes.rb` — it is `instance_eval`'d
inside the Rails router draw block.

---

## Testing requirements

> ⚠️ **Tests are part of the plugin contract.**
>
> Every plugin published on the Woofed Store **must ship with tests**. Tests
> are the primary mechanism the store uses to verify a plugin during review,
> and they are also what the [compatibility check](#compatibility-checks)
> re-runs locally on the customer's server every time the core or the plugin
> is updated.
>
> A plugin without tests cannot be approved on the Woofed Store. A plugin
> whose tests start failing after a core update will be flagged and the
> update blocked until compatibility is restored.

### Why tests matter so much

Plugins have full access to the application — they can change the database,
rewrite core logic, and ship their own UI. The test suite is what gives the
store, the customers, and the operators confidence that a plugin actually
does what it claims and keeps doing it as the surrounding code evolves.

Concretely, tests are used to:

- **Verify the plugin during store review** — the store runs the suite as part
  of the approval process. A plugin with missing or failing tests will not be
  published.
- **Guard compatibility on every update** — when WoofedCRM or the plugin gets
  a new version, the customer's server runs the plugin's tests against the
  new combination. If they fail, the update is blocked.
- **Document expected behavior** — tests are executable documentation of what
  the plugin guarantees, useful both for reviewers and for future maintainers.
- **Catch regressions early** — a small change in the core can ripple into a
  patched plugin file; the test suite makes that visible immediately.

### What good coverage looks like

Tests **do not need to reach 100% coverage**, but they do need to be **good
quality** and cover **everything the plugin changes or adds** to the CRM. In
practice this means:

- Every **new model, controller, route, or React component** the plugin ships
  has tests around its behavior.
- Every **patch** to a core file has a test asserting the composed output is
  correct.
- Every **change to existing behavior** — overrides, replacements, new
  validations, new fields — has a test that demonstrates the new behavior
  works as intended.
- Code paths that are untouched by the plugin do not need to be re-tested by
  the plugin.

The goal is meaningful coverage of the plugin's surface area, not chasing a
percentage.

### Ruby — RSpec + FactoryBot

Cover every model, every Concern (tested on the host model), every controller
(request specs), and every patch file (assert the composed output is correct AND
that the original in `app/` was not modified).

```ruby
# storage/plugins/example/spec/patches/contact_patch_spec.rb
require "rails_helper"

RSpec.describe "Contact patch" do
  let(:original) { Rails.root.join("app/models/contact.rb").read }

  before { Plugins::FilePatch.clear_registry! }
  after  { Plugins::FilePatch.clear_registry! }

  it "adds the include line" do
    load Rails.root.join("storage/storage/plugins/example/app/models/contact.rb")
    result = Plugins::FilePatch.apply("app/models/contact.rb", original)

    expect(result).to include("include Plugins::Example::ContactExtension")
  end

  it "does not modify the original file" do
    original_content = Rails.root.join("app/models/contact.rb").read
    expect(original_content).not_to include("ContactExtension")
  end
end
```

### JavaScript — Vitest + React Testing Library

Cover every React component:

```bash
yarn vitest storage/plugins/<plugin_name>/spec/javascript/
```

### Factories

One FactoryBot factory per model defined by the plugin:

```ruby
# storage/plugins/example/spec/factories/example_records.rb
FactoryBot.define do
  factory :example_record do
    contact
    name { "Example" }
  end
end
```

### Running tests

Tests must be runnable in isolation:

```bash
bundle exec rspec storage/plugins/<plugin_name>/spec/
yarn vitest storage/plugins/<plugin_name>/spec/javascript/
```

---

## Installing and removing plugins

**All installation and removal happens through the Woofed Store** — never by
editing files manually. The store is the central registry where plugins are
published, versioned, and distributed as ZIPs.

- **Install** — registers the plugin in the database and downloads the ZIP into
  `storage/plugins/{plugin_installation_id}/`. The application then rebuilds
  `storage/build/` and restarts so the plugin becomes live.
- **Uninstall** — must be done through the Woofed Store. The store is the
  source of truth for which plugins are installed. If the local files or
  database records are removed by hand, the next application restart will
  re-download and re-install the plugin from the store.

### Data on uninstall

Uninstalling a plugin removes its **code** from the application — but it does
**not** automatically remove the **data** the plugin created. Tables added by
plugin migrations stay in the database, and any rows in core tables created or
modified by the plugin remain untouched.

This is intentional: it lets a customer reinstall a plugin later without
losing history. If the data really should be wiped, it has to be done
explicitly — either by the plugin itself (offering a "purge data" action) or
manually by an operator.

---

## Versioning and updates

Each plugin version is identified by a `version_id` (the commit ID of the
release in the Woofed Store). When a new version is published, the customer
sees an update available in the store and chooses when to apply it.

Updates follow the same flow as installs:

1. The customer triggers the update in the Woofed Store.
2. The new ZIP is downloaded and replaces the previous one in
   `storage/plugins/{plugin_installation_id}/`.
3. The application rebuilds `storage/build/` and restarts.
4. The new version is live.

Updates are **explicit by default** — the customer stays in control of when
changes go live. The exception is **security updates**: when the Woofed Store
flags a release as a security fix, it can be **applied automatically** without
waiting for manual confirmation, so vulnerabilities are not left running on
customer systems.

---

## Compatibility checks

WoofedCRM itself evolves, and so do the plugins running on top of it. Whenever
the core is updated **or** a plugin has a new version, compatibility between
the two needs to be verified before the change is applied.

The check runs **locally on the customer's WoofedCRM server** — not on the
Woofed Store — so it reflects the exact state of that installation:

1. **`git diff` / `git merge`** — the new version is dry-run merged against the
   current state to detect conflicts in patched files. If patch anchors no
   longer exist or files have moved, the conflict is surfaced before anything
   is applied.
2. **Automated test suite** — each plugin ships with its own tests
   (`storage/plugins/{plugin_installation_id}/spec/`). The compatibility check
   runs these tests against the new combination of core + plugin to confirm the
   plugin still behaves correctly.

If the merge succeeds and the tests pass, the update is considered safe and
proceeds. If anything fails, the update is blocked and the operator is
notified, so the application stays on the last known-good combination.

---

## Who publishes plugins

The Woofed Store is the **trust boundary** of the plugin ecosystem. Only
plugins published through the store are considered safe to install.

Publishing a plugin involves:

1. Forking WoofedCRM and developing inside `storage/plugins/my_new_plugin/`.
2. Submitting the plugin to the Woofed Store.
3. The store reviews the plugin — checking for security issues, malicious
   behavior, and compliance with platform guidelines — before making it
   available to customers.

This review step is what makes the store a trusted source. Customers who
install only verified plugins benefit from this guarantee; sideloading bypasses
it and exposes the application to the full risk surface described in
[What a plugin can do](#what-a-plugin-can-do).

---

## Safe mode

If a faulty plugin breaks the application, WoofedCRM can be started in **safe
mode**. In this mode every plugin is automatically disabled — the core boots
without applying any plugin code, giving the operator a clean state to remove
or fix the offending plugin through the Woofed Store.

Safe mode is the recovery mechanism that guarantees a bad plugin can never
permanently brick the system.
