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
                                              │ 2. application restart
                                              ▼
                                     ┌──────────────────┐
                                     │  Health checks   │
                                     │ (DB, store, mode)│
                                     └──────────────────┘
                                              │
                                              │ 3. promote MODE = standard
                                              ▼
                                     ┌──────────────────┐
                                     │  Plugins build   │
                                     │ download +       │
                                     │ extract +        │
                                     │ compose          │
                                     └──────────────────┘
                                              │
                                              │ 4. write composed files
                                              ▼
                                     ┌──────────────────┐
                                     │  storage/build/  │
                                     └──────────────────┘
                                              │
                                              │ 5. boot
                                              ▼
                                     ┌──────────────────┐
                                     │  Plugins load    │
                                     │ (Rails + Vite    │
                                     │  read from       │
                                     │  storage/build/) │
                                     └──────────────────┘
```

1. The user installs a plugin through the Woofed Store.
2. The application restarts.
3. **Health checks run** (see [Health checks](#health-checks)) — DB and store
   are validated and the persisted mode flag is read. If everything is OK,
   `MODE` is promoted to `standard`; otherwise the app stays in safe mode and
   the plugin is **not** loaded.
4. **Plugins build** (see [Plugins build](#plugins-build)) — the new plugin's
   ZIP is downloaded, extracted into `storage/plugins/{plugin_installation_id}/`,
   and composed with the core into `storage/build/`.
5. **Plugins load** (see [Plugins load](#plugins-load)) — Rails and Vite boot
   reading from `storage/build/` first and falling back to `app/`, so the new
   plugin is now live in the application.


## Boot sequence

Every time WoofedCRM boots, the plugin system runs through a fixed sequence
that reconciles the local installation with the Woofed Store before the
application becomes available.

```
       boot starts
            │
            ▼
   ┌────────────────────────┐
   │ MODE = safe (initial)  │
   └───────────┬────────────┘
               │
               ▼
   ┌──────────────────────────────┐
   │ Health checks                │
   │  • database reachable?       │
   │  • Woofed Store reachable?   │
   │  • read mode flag from DB    │
   └───────────┬──────────────────┘
               │
        ┌──────┴──────────────────────────┐
        │                                 │
   all ok AND DB says standard       failed OR DB says safe
        │                                 │
        ▼                                 ▼
   MODE = standard                   MODE stays safe
        │                                 │
        ▼                                 │  (Plugins build
   ┌────────────────────────────────────┐ │   skipped entirely)
   │ Plugins build                      │ │
   │  • fetch plugin list from store    │ │
   │  • download + extract missing ZIPs │ │
   │  • compose into storage/build/     │ │
   └────────────────┬───────────────────┘ │
                    │                     │
                    └──────────┬──────────┘
                               ▼
   ┌────────────────────────────────────┐
   │ Plugins load                       │
   │ (Rails + Vite boot)                │
   │   • MODE = standard → read from    │
   │     storage/build/ first, then app/│
   │   • MODE = safe     → read from    │
   │     app/ only (storage/build/      │
   │     ignored)                       │
   └────────────────────────────────────┘
```

The steps:

1. **Start in safe mode.** Every boot begins with `MODE = safe`. The
   application is only promoted to standard mode after the health checks
   confirm the environment is ready.
2. **Run health checks.** Validate the database, contact the Woofed Store,
   and read the persisted mode flag (see [Health checks](#health-checks)).
   The result decides the value of `MODE` for the rest of the boot.
3. **Plugins build (standard mode only).** Fetch the plugin list from the
   store, download and extract any ZIPs missing locally, and compose the
   files into `storage/build/` (see [Plugins build](#plugins-build)). In
   safe mode this stage is skipped entirely.
4. **Plugins load.** Rails and Vite start (see
   [Plugins load](#plugins-load)). In standard mode they read from
   `storage/build/` first and plugin code is live from the very first
   request. In safe mode they read directly from `app/` and the application
   comes up without any plugin code.

This sequence runs on **every** boot, which is what guarantees the local
installation always converges to whatever the Woofed Store says is correct.
Manually deleted files or DB records are restored automatically. New plugins
or new versions added on the store side are picked up the next time the app
restarts.

---

## Health checks

The application **always starts in safe mode** and only promotes itself to
standard mode after a sequence of health checks proves the environment is in
a state where loading plugins is safe. Health checks are the gate between
"the app is up" and "the app is up **with plugins**".

### What is checked

The boot runs through these checks, in order:

1. **Database reachable** — can the application open a connection to its
   database?
2. **Woofed Store reachable** — can the application contact the store to
   reconcile installed plugins? Without it, the local state cannot be
   trusted to match what the customer actually owns.
3. **Mode flag in the database** — what does the persisted `mode` column
   say? `standard` means the operator allows plugins; `safe` means the
   operator has explicitly pinned the application to safe mode.

### Outcomes

The combination of the checks decides the value of `MODE` for the rest of
the boot:

| DB ok | Store ok | DB mode flag | → Result                            |
|:-----:|:--------:|:------------:|:------------------------------------|
| ✓     | ✓        | `standard`   | promote to standard                 |
| ✓     | ✓        | `safe`       | stay in safe mode (operator pin)    |
| ✓     | ✗        | any          | stay in safe mode (no store)        |
| ✗     | n/a      | n/a          | stay in safe mode (no DB)           |

In every case **the app continues to boot** — the health check phase never
crashes the process. The worst outcome is a plugin-free application, which
is still useful to the operator and to anyone trying to fix the underlying
issue.

### When they run

Health checks run **once per boot**, during the early initialization phase,
before the build runs and before plugin code is loaded. They do **not** run
continuously at request time — once `MODE` is set, it stays fixed until the
next restart.

This keeps the runtime simple: there is no mid-flight switch from standard
to safe (or vice-versa) for an already-booted process. Recovering from a
problem always means restarting, which is fine because the health checks
themselves are cheap and the boot is fast.

### Why this layering matters

Splitting the boot into "health checks first, plugin work second" is what
gives the system its self-healing property:

- A broken database or a network glitch with the store cannot prevent the
  application from coming up.
- A bad plugin cannot break the boot, because the operator can pin safe
  mode in the database and the next restart will skip plugin loading
  entirely.
- The path back to standard mode is always the same: fix the underlying
  cause, restart, let the health checks pass.

---

## Plugins build

The **plugins build** is the stage responsible for taking the plugins listed
in the Woofed Store and turning them into a set of ready-to-serve files on
disk. It runs only when `MODE = standard` and only on boot, install, update,
or manual rebuild.

It has three responsibilities, in order:

1. **Download.** For each plugin the store says should be installed, fetch
   the ZIP at the right `version_id`. Plugins already present locally with
   the matching version are not re-downloaded.
2. **Extract.** Unpack each ZIP into
   `storage/plugins/{plugin_installation_id}/`. After this step the raw
   plugin source is on disk, but the application is not yet using it.
3. **Construct the build files.** The `BuildManager` walks every file under
   `storage/plugins/`, decides whether it is a patch or a new file, applies
   patches in priority order, and writes the composed result to
   `storage/build/`. Fingerprinting makes this incremental — only files that
   actually changed are rewritten. (See [The build process](#the-build-process)
   for the full mechanics.)

When the plugins build finishes, `storage/build/` mirrors the exact set of
files the application is expected to serve next. Nothing in `app/` was
touched.

In safe mode this entire stage is skipped: no download, no extraction, no
build composition. The `storage/build/` folder may still exist from a
previous boot, but the plugins load stage will ignore it.

---

## Plugins load

The **plugins load** is the runtime stage. While the plugins build prepares
files on disk, the plugins load decides **which files Rails and Vite actually
read** when serving requests.

The rule is simple and applies to every layer (Rails autoloader, view
resolver, controller resolver, Vite resolver):

```
   storage/build/{target} exists?
            │
       yes ─┤  → use storage/build/{target}
            │
       no  ─┤  → use app/{target}
```

In other words: **always look in `storage/build/` first, fall back to `app/`
if nothing is there.** This is what makes a plugin "live" — its composed
file in `storage/build/` shadows the original in `app/` without anything in
`app/` ever being touched.

### How each layer participates

- **Rails autoload + eager load** — `storage/build/app/` is prepended to the
  autoload paths, so any patched or new model, controller, or service is
  picked up before the original.
- **View resolver** — `storage/build/app/views/` is prepended to the view
  paths, so patched ERB templates win over their `app/views/` counterparts.
- **Vite resolver** — a custom Vite plugin checks
  `storage/build/app/javascript/` before `app/javascript/`, so JSX/TSX/JS
  patches are served by both the dev server and the production bundle.

### Behavior in safe mode

In safe mode the load stage is **inverted**: `storage/build/` is bypassed
entirely and every layer reads directly from `app/`. The build files might
still exist on disk, but they are simply not consulted. The application
runs as if no plugin had ever been installed — exactly what is expected
from a recovery state.

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


## The build process

The build is what turns the raw plugin files in `storage/plugins/` into the
composed output in `storage/build/` that Rails and Vite actually serve.

### When the build runs

The `BuildManager` runs every time the set of plugin files might have changed:

- On **application boot** — `PluginLoader` calls `BuildManager.sync!` after
  downloading any missing plugins.
- On **install / update / uninstall** — the rake task triggers a rebuild before
  restarting the app.
- On **manual rebuild** — `rails plugins:rebuild` wipes `storage/build/` and
  reruns the whole process from scratch.

### The two paths: patch vs. new file

For every file inside a plugin, the build manager decides what to do based on
the file's relative path:

```
storage/plugins/{plugin_installation_id}/app/models/contact.rb
                                          │
                                          ▼
                              does app/models/contact.rb exist?
                                  │                    │
                              yes (PATCH)         no (NEW FILE)
                                  │                    │
                                  ▼                    ▼
                       run Patch DSL against   copy file as-is
                       the original, write     to storage/build/
                       result to storage/build/
```

- **Patch** — the plugin file contains `Plugins::FilePatch.define ...` DSL.
  The build manager reads the original from `app/`, applies every plugin's
  patches in priority order (lower priority first), and writes the composed
  result to `storage/build/`.
- **New file** — there is no original to merge into; the file is simply copied
  into `storage/build/` at the same relative path so Rails or Vite picks it up.

### Composition order

When **multiple plugins** patch the same file, the build manager applies them
in **ascending priority order** (priority `10` runs before `20`). This is what
lets a later plugin use lines inserted by an earlier plugin as anchors. The
final composed file is written once, after all patches have been applied.

### Incremental builds (fingerprinting)

Rebuilding every file from scratch on every boot would be slow. To avoid that,
the build manager keeps a **fingerprint** for each output file — a SHA256 of
the original content plus the content of every patch that contributes to it.

On rebuild, it recomputes the fingerprint and:

- **Same fingerprint** → file is up to date, skip it.
- **Different fingerprint** → file is rebuilt and the fingerprint is updated.

The result: the first boot after a plugin install rebuilds what changed, and
subsequent boots are essentially free.

`rails plugins:rebuild` ignores fingerprints and rebuilds everything — useful
when something looks out of sync.

### Orphan cleanup

When a plugin is uninstalled or one of its files is removed, the corresponding
output in `storage/build/` no longer has a source. The build manager detects
these **orphans** on every sync and deletes them, so removing a plugin
genuinely removes its footprint from the running application.

### Vite patch manifest

JavaScript and CSS patches need extra coordination with Vite. As part of the
build, the manager writes a small JSON manifest (`tmp/plugin_patches_{env}.json`)
listing every patched JS/JSX/TS/TSX file. The custom Vite resolver reads this
manifest and ensures the composed version under `storage/build/app/javascript/`
is served instead of the original under `app/javascript/`.

### Development vs. production

The build mechanism is the same in both environments — what differs is **how
assets are served** after the build runs.

**In development**

- The build runs on every application boot and on every plugin
  install / update / uninstall.
- Ruby files in `storage/build/` are picked up by Rails on the next request
  (Zeitwerk + class reloading).
- Assets (JS, JSX, CSS) are served by the **Vite dev server** with hot module
  replacement: editing a plugin file refreshes the browser without a full
  restart.
- `assets:precompile` is **not** run — the dev server compiles on the fly.

**In production**

- The build runs as part of the deploy / boot sequence
  (`rails plugins:boot`).
- After plugin files land in `storage/build/`, `yarn install` and
  `assets:precompile` are executed so the patched JS and CSS end up in the
  precompiled asset bundle.
- The application is then restarted; from that point on, served assets are
  static and no Vite dev server is involved.
- A plugin install / update therefore **always implies a rebuild + asset
  recompilation + restart** in production. This is why updates are explicit
  by default — the customer chooses when to take the brief restart.

In short: **dev = live and fast (Vite dev server)**, **prod = baked and stable
(precompiled assets)**. The plugin source code and the Patch DSL are
identical in both — only the asset pipeline behind them changes.

---


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

Safe mode is the recovery mechanism that guarantees a bad plugin can never
permanently brick the system. When active, the application boots **as if no
plugin were installed** — only the original core code runs.

### How it works

Safe mode hinges on the **plugins load** stage: where does Rails / Vite read
source files from?

In standard mode, the plugins load reads from `storage/build/` first and
falls back to `app/`. In safe mode that preference is inverted: the
application **bypasses `storage/build/` entirely** and reads directly from
`app/`. Since `app/` is never modified by plugins, the result is a clean,
plugin-free boot.

The switch is controlled by a single constant — `MODE` — that the rest of the
system reads to decide how to behave:

- The **plugins build** stage is skipped entirely — no download, no
  extraction, no composition into `storage/build/`.
- The **plugins load** stage skips `storage/build/app/` in the Rails autoload,
  view, and controller paths, and `storage/build/app/javascript/` in the Vite
  resolver.

```
   standard mode (MODE = standard)      safe mode (MODE = safe)
   ──────────────────────────────       ─────────────────────────
   plugins load:                        plugins load:
   storage/build/  →  app/              app/  (storage/build/ ignored)
        ▲                                          ▲
        │ patched + new plugin files               │ original core only
```

### Boot flow with safe mode

The application **always starts in safe mode** and only promotes itself to
standard mode after the health checks pass. The desired execution mode is
also persisted in the database, so an operator can pin the application to
safe mode across restarts when needed.

```
       boot starts
            │
            ▼
   ┌────────────────────────┐
   │ MODE = safe (initial)  │
   └───────────┬────────────┘
               │
               ▼
   ┌──────────────────────────────┐
   │ Health checks                │
   │  • database reachable?       │
   │  • Woofed Store reachable?   │
   │  • read mode flag from DB    │
   └───────────┬──────────────────┘
               │
        ┌──────┴──────┐
        │             │
   all checks      something
   ok AND DB       failed OR
   says standard   DB says safe
        │             │
        ▼             ▼
   MODE = standard   MODE stays safe
   (run plugins      (skip plugins
   build, then       build entirely;
   plugins load)     plugins load
        │             reads from app/)
        │             │
        └──────┬──────┘
               ▼
        continue boot
        (Rails + Vite start)
```

The flow is the **same** in both branches — the only difference is the value
of `MODE` once the health check phase ends. The downstream stages (plugins
build, plugins load) read `MODE` and adapt: in standard mode the build runs
and the load reads from `storage/build/`; in safe mode the build is skipped
and the load reads from `app/`.

### When safe mode is kept

- **Health checks failed** — the database is unavailable, migrations are
  pending, or the Woofed Store cannot be reached. The app stays in safe mode
  so it can still come up while the operator investigates.
- **Pinned by the operator** — the mode flag in the database has been set to
  `safe`. This is useful when an installed plugin is misbehaving: the
  operator pins safe mode, restarts, fixes or removes the plugin through the
  Woofed Store, and only then unpins to return to standard mode.

### Leaving safe mode

Safe mode is purely a runtime decision — nothing on disk is changed while
it is active. To return to standard mode:

1. Make sure the underlying issue is fixed (DB reachable, store reachable,
   bad plugin removed or updated).
2. Set the mode flag in the database back to `standard` (if it was pinned).
3. Restart the application.

On the next boot the health checks pass, `MODE` is promoted to `standard`,
the build runs, and the previously installed plugins become live again.
