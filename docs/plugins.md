# Plugin System — Authoring Guide

## Overview

The plugin system extends Ruby models, ERB views, React/JSX components, and CSS files
**without ever modifying the original files** in `app/`. Every extension is applied at
build time into `storage/build/`, which is gitignored, disposable, and fully
recreatable with a single command:

```bash
rails plugins:rebuild
```

### The fundamental rule

> No file inside `app/` is ever written to. All modifications live in `storage/build/`.

### What problems it solves

- **Isolation** — plugins can be added or removed without touching the core codebase
- **Composability** — multiple plugins can extend the same file with predictable order
- **Safety** — `storage/build/` is disposable; rebuilding from scratch is always safe
- **Unified mechanism** — one DSL, one build folder, all file types

---

## Folder structure

```
storage/plugins/
└── <plugin_name>/
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

Plugins can declare their own gem dependencies in `storage/plugins/<name>/Gemfile`. The main
`Gemfile` automatically evaluates all plugin Gemfiles via `eval_gemfile`. On boot,
`bundle install` runs before the Rails environment loads, ensuring new gems are
available.

```ruby
# storage/plugins/my_plugin/Gemfile
gem "some_gem", "~> 1.0"
```

The `Gemfile` uses standard Bundler syntax — groups, platforms, `source`, etc. all work.

---

## The `storage/build/` folder

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

> **This section is a mandatory instruction for any AI generating plugin code.**
>
> Every plugin you create **must** ship with a complete test suite under
> `storage/plugins/<plugin_name>/spec/`. Tests are not optional and must all pass before the
> plugin is considered complete.

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

## Rake tasks reference

### `rails plugins:boot`

Full plugin boot sequence. This is what runs on every application start:
1. `bundle install` (shell level — before rake) — installs gems from plugin `Gemfile`s
2. `plugins:rebuild` — wipes and rebuilds `storage/build/`
3. `db:prepare` — creates the database if needed and runs all pending migrations (including plugin migrations)
4. `yarn install` + `assets:precompile` (production only, if JS/CSS plugin files exist)

```bash
$ rails plugins:boot
[plugins:boot] Rebuilding storage/build/...
[plugins:boot] Build complete. 3 file(s) in storage/build/
[plugins:boot] Running db:prepare (create + migrate)...
[plugins:boot] Done.
```

### `rails plugins:rebuild`

Wipe `storage/build/` and `tmp/plugin_fingerprints/`, then recreate everything from
scratch.

```bash
$ rails plugins:rebuild
Rebuilding storage/build/...
Done. Files in storage/build/:
  app/models/contact.rb
  app/models/contact_extension.rb
  app/javascript/pages/UserProfile.jsx
```

### `rails plugins:preview[target]`

Print the composed output for a single file after all patches are applied:

```bash
$ rails plugins:preview[app/models/contact.rb]
class Contact < ApplicationRecord
  include Plugins::Example::ContactExtension
  include Devise::JWT
  ...
end
```

### `rails plugins:status`

List all files currently in `storage/build/`:

```bash
$ rails plugins:status
Files in storage/build/ (3):
  app/models/contact.rb
  app/models/contact_extension.rb
  app/javascript/pages/UserProfile.jsx
```

---

## Installing and removing plugins

### `rails plugins:install[url]`

Install a plugin from a public GitHub repository. The task clones the repo into
`plugins/`, validates it has a `plugin.rb` manifest, runs `plugins:boot` (rebuild +
migrate + assets), and restarts the application.

```bash
$ rails plugins:install[https://github.com/user/my-plugin]
[plugins:install] Cloning https://github.com/user/my-plugin into storage/plugins/my-plugin...
[plugins:install] Plugin 'my-plugin' cloned successfully.
[plugins:install] Running boot to activate plugin...
[plugins:install] Done! Plugin 'my-plugin' is now installed and active.
```

### `rails plugins:uninstall[name]`

Remove an installed plugin by name. Deletes the plugin folder, rebuilds `storage/build/`,
and restarts the application. Orphaned files are cleaned up automatically.

```bash
$ rails plugins:uninstall[my-plugin]
[plugins:uninstall] Removing plugin 'my-plugin'...
[plugins:uninstall] Rebuilding without plugin...
[plugins:uninstall] Done! Plugin 'my-plugin' has been removed.
```

> **Note:** `uninstall` does **not** rollback plugin migrations. If the plugin created
> database tables, you may need to drop them manually or write a migration.

---

## Checklist — creating a new plugin

```
[ ] Create storage/plugins/<n>/plugin.rb with manifest (name, version, priority)
[ ] Add Gemfile if the plugin needs extra gems (storage/plugins/<n>/Gemfile)
[ ] For each existing app/ file to extend:
    [ ] Create storage/plugins/<n>/app/<same/relative/path> with FilePatch DSL
[ ] For each new file the plugin needs:
    [ ] Create storage/plugins/<n>/app/<new/path> with normal content
[ ] Create storage/plugins/<n>/spec/ with full test suite
[ ] Add migration if new tables are needed (storage/plugins/<n>/db/migrate/)
[ ] Add routes if new endpoints are needed (storage/plugins/<n>/config/routes.rb)
[ ] Run rails plugins:boot — installs deps, rebuilds storage/build/, runs migrations
[ ] Run rails plugins:preview[<target>] for each patched file — verify output
[ ] Run bundle exec rspec storage/plugins/<n>/spec/ — all tests must pass
[ ] Run yarn vitest storage/plugins/<n>/spec/javascript/ — all tests must pass
```

---

## Removing a plugin

Delete the plugin folder:

```bash
rm -rf storage/plugins/example
```

On the next boot (or `rails plugins:rebuild`), `BuildManager.remove_orphans!` cleans
up any files in `storage/build/` that no longer have a source in any plugin. No manual
cleanup is needed.

---

## Troubleshooting

### `containing:` string not found

Check for typos and leading/trailing whitespace. The `containing:` match uses
`String#include?` — it must be an exact substring of the line.

### Patch file accidentally autoloaded

The patch file must mirror the original path exactly (e.g.,
`storage/plugins/example/app/models/contact.rb` for `app/models/contact.rb`). `BuildManager`
loads it via `load`, not Zeitwerk. If Zeitwerk tries to autoload it, ensure
`storage/build/` is prepended to autoload paths so the composed file takes precedence.

### ActiveRecord macro in a patch file

Move `has_many`, `validates`, `scope`, etc. to an `ActiveSupport::Concern` in a new
file. The patch should only `include` the Concern.

### `storage/build/` out of sync

```bash
rails plugins:boot
```

### Two plugins with the same priority on the same file

Order is non-deterministic. Assign distinct priority values to all plugins that touch
the same file.

### Plugin routes not loading

Ensure the routes file is at `storage/plugins/<name>/config/routes.rb` and contains valid
Rails routing DSL.
