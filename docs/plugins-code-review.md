# Plugin system — code review tracker

Findings from the review of the plugin system foundation on branch `plugins-part-1`:
`lib/plugins/`, `lib/tasks/plugins.rake`, `app/models/plugin.rb`, and the config
changes in the working tree. Reference design: [`plugins.md`](plugins.md).

This file is the single tracker for the corrections. Tick the checkbox and update the
`Status` line of a finding as it is addressed.

**Status values:** `open` · `in progress` · `fixed` · `wontfix` · `deferred`

## Overall assessment

The foundation is sound: a small DSL, a clear patch / new-file split, fingerprint-based
incremental builds, and DB-first plugin discovery. Tests cover the happy path well.

The serious problems are in four clusters: **tenant isolation** (an example plugin exposes
records across accounts), **boot resilience** (the plan promises that a bad plugin can
never break the boot — today it does), **build determinism** (non-stable ordering,
conflicting priority sources, and non-idempotent writes), and **repo hygiene** (scratch
plugin directories with nested `.git/` about to be committed).

## Suggested order

1. Tenant isolation — [#25](#25--ai-followups-exposes-events-from-other-accounts) — blocks merge.
2. Repo hygiene — [#23](#23--storageplugins-is-versioned-including-nested-git-directories), [#24](#24--the-en_us-i18n-change-does-not-belong-to-this-branch) — blocks merge.
3. Boot resilience — [#02](#02--a-single-broken-patch-anchor-aborts-the-whole-build), [#01](#01--sync-skips-files-when-the-build-output-is-gone-but-the-fingerprint-remains) — these cause outages.
4. Determinism — [#03](#03--sort_by-is-not-stable--tied-priorities-give-non-deterministic-builds), [#05](#05--two-plugins-shipping-the-same-new-file-cause-fingerprint-thrash), [#26](#26--patch-order-has-conflicting-priority-sources).
5. Path safety — [#11](#11--pluginid-becomes-a-filesystem-path-with-no-validation), [#12](#12--symlinks-inside-a-plugin-tree-escape-the-plugin-directory), [#14](#14--name-uniqueness-is-validated-without-a-unique-index).
6. Runtime wiring — [#27](#27--the-generated-build-is-never-loaded-by-the-application).
7. Everything else.

## Index

| # | Title | Severity | Area | Status |
|---|-------|----------|------|--------|
| 01 | `sync!` skips files when the build output is gone but the fingerprint remains | High | Correctness | fixed |
| 02 | A single broken patch anchor aborts the whole build | Critical | Resilience | open |
| 03 | `sort_by` is not stable — tied priorities give non-deterministic builds | High | Determinism | open |
| 04 | `rails plugins:preview` always prints the original file | Medium | Tooling | open |
| 05 | Two plugins shipping the same new file cause fingerprint thrash | High | Determinism | open |
| 06 | A plugin replacing a core file without DSL is silently discarded | Medium | Correctness | open |
| 07 | Fingerprint filenames can collide | Low | Correctness | open |
| 08 | `plugin_dirs` hits the database once per plugin file | Medium | Performance | open |
| 09 | `Plugin.table_exists?` raises when the database is unreachable | Medium | Resilience | open |
| 10 | Vite manifest is written without ensuring the directory exists | Low | Correctness | open |
| 11 | `plugin.id` becomes a filesystem path with no validation | High | Security | open |
| 12 | Symlinks inside a plugin tree escape the plugin directory | High | Security | open |
| 13 | Patch blocks are evaluated twice; no package integrity check | Medium | Security | open |
| 14 | `name` uniqueness is validated without a unique index | Medium | Data integrity | open |
| 15 | `Plugins::Manifest` is unused and diverges from the plan | Medium | Architecture | open |
| 16 | Plugin `config/` files are copied but never loaded | Low | Architecture | open |
| 17 | Plugin migrations are not handled | Low | Gap vs. plan | open |
| 18 | `MODE` / safe mode is not wired into the build | Info | Gap vs. plan | open |
| 19 | The build is not atomic | Medium | Architecture | open |
| 20 | Reading the registry inserts empty entries | Low | Code quality | open |
| 21 | `Plugin#status` should use `enum`, like `Installation` | Low | Consistency | open |
| 22 | Test gaps around the risky paths | Medium | Tests | open |
| 23 | `storage/plugins/` is versioned including nested `.git/` directories | Blocker | Repo hygiene | open |
| 24 | The `en_US` i18n change does not belong to this branch | Blocker | Scope | open |
| 25 | `ai_followups` exposes events from other accounts | Critical | Security | open |
| 26 | Patch order has conflicting priority sources | High | Determinism | open |
| 27 | The generated build is never loaded by the application | Info | Gap vs. plan | open |

---

## Correctness and resilience

### [x] 01 — `sync!` skips files when the build output is gone but the fingerprint remains

- **Severity:** High · **Area:** Correctness · **Status:** fixed
- **Files:** `lib/plugins/build_manager.rb:142`, `lib/plugins/build_manager.rb:155`

**Problem.** `process_patch` and `process_new_file` decide whether to write based only
on the stored fingerprint:

```ruby
return if fingerprint_unchanged?(relative, fingerprint)
```

`storage/build/` and `tmp/plugin_fingerprints/` live in directories with different
lifecycles. In a container deploy `tmp/` is typically ephemeral while `storage/` is a
persisted volume — or the opposite, depending on how volumes are mounted. If one is
wiped without the other, `sync!` concludes "nothing changed" and the application boots
**without the composed files**, silently serving the untouched core.

There is no error, no log, and no self-healing: the fingerprint is still there, so every
subsequent boot repeats the same wrong decision. Only `rails plugins:rebuild` recovers.

**Failure scenario.** A plugin patches `app/models/contact.rb`; `sync!` writes the build
file and its fingerprint. A deploy recreates the container with a fresh `tmp/` while the
`storage/` volume persists (or an operator prunes `storage/build/`). Next boot: the
fingerprint matches, the write is skipped, the patched file is missing, and the app
reports a healthy boot without the plugin's behaviour.

**Fix.** Make the skip conditional on the output actually being present:

```ruby
def process_patch(relative, original)
  target_path = build_dir.join(relative)
  fingerprint = compute_fingerprint(relative, original.read)
  return if fingerprint_unchanged?(relative, fingerprint) && target_path.exist?
  ...
end
```

Same change in `process_new_file`.

**Test.** Run `sync!`, delete the file under `storage/build/` leaving
`tmp/plugin_fingerprints/` intact, run `sync!` again, expect the build file recreated.

**Resolution.** Both call sites now hoist `target_path` and guard on a new private
`up_to_date?(relative, fingerprint, target_path)`, which requires the fingerprint to match
**and** the output to still be on disk. The helper carries a comment explaining the
independent lifecycles of `storage/build/` and `tmp/plugin_fingerprints/`, so the guard is
not simplified away later.

Two regression examples were added under `describe "incremental build"` in
`spec/plugins/build_manager_spec.rb`, one per code path (copied new file, composed patch).
Both were confirmed to fail against the previous implementation and pass against the fix;
the full `spec/plugins/` suite is green (64 examples).

**Related:** #05, #07.

---

### [ ] 02 — A single broken patch anchor aborts the whole build

- **Severity:** Critical · **Area:** Resilience · **Status:** open
- **Files:** `lib/plugins/adapters/text_line.rb:36`, `lib/plugins/build_manager.rb:32`

**Problem.** `find_line_index` raises `Plugins::FilePatch::PatchError` when a
`containing:` anchor is not found, and nothing in `sync!` rescues it. One plugin whose
anchor disappeared after a core update aborts the entire build.

Two consequences:

1. **The boot dies.** This contradicts the central promise of the design — see
   `plugins.md`, "Faulty plugin installation flow": the app is supposed to identify the
   culprit, set its `status` to `failed`, and come back up with every other plugin live.
2. **The build is left half-written.** `sync!` aborts mid-loop, so some files are already
   composed and their fingerprints already saved, while later files were never processed.
   Combined with #01, the next boot does not detect the inconsistency.

**Failure scenario.** The core adds a concern to the `class Contact < ApplicationRecord`
line. A plugin anchored on the old string now raises. Every boot from that point crashes
before Rails finishes initializing, and recovery means manual filesystem surgery —
exactly what safe mode was designed to avoid.

**Fix.** Isolate failures **per plugin**, not per operation:

- Wrap the per-plugin work in `sync!` in `rescue Plugins::FilePatch::PatchError => e`,
  plus a broad `StandardError` guard around `load plugin_file` (which runs arbitrary
  plugin Ruby).
- Collect failures and log them with the plugin id and target file.
- Mark the offending `Plugin` record `status: "failed"` so it is excluded from the next
  build and load.
- Discard that plugin's contribution and finish the build with the remaining plugins.

A failing plugin must not leave partial output behind: composition for a target should be
computed fully in memory and only then written — see #19.

**Test.** `sync!` with two active plugins, one with an unmatched anchor: expect no
exception, the healthy plugin's output present, the broken plugin's record `failed`, and
`sync!` still callable afterwards.

**Related:** #18, #19.

---

### [ ] 03 — `sort_by` is not stable — tied priorities give non-deterministic builds

- **Severity:** High · **Area:** Determinism · **Status:** open
- **Files:** `lib/plugins/file_patch.rb:34`, `lib/plugins/build_manager.rb:230`

**Problem.** Ruby's `sort` / `sort_by` are **not guaranteed stable**. Both ordering sites
sort on `priority` alone:

```ruby
registry[target].sort_by { |entry| entry[:priority] }.map { |entry| entry[:patch] }
```

Two plugins patching the same file with the same `priority` — and the default is `0`, so
this is the common case, not an edge case — can be applied in either order. The composed
output, and therefore the fingerprint, the build file, and the Vite manifest, differ
between runs on identical inputs. This is the class of bug that shows up in production,
on one server, once.

**Fix.** Add an explicit tiebreaker. Insertion order derives from `plugin_dirs`
(`Plugin.active.order(:priority, :id)`), so it is itself deterministic:

```ruby
def patches_for(target)
  registry.fetch(target, [])
    .each_with_index
    .sort_by { |entry, index| [entry[:priority], index] }
    .map { |entry, _| entry[:patch] }
end
```

Apply the same change in `write_vite_patch_manifest!`. Consider also warning at build
time when two plugins patch the same target with equal priority.

**Test.** Two plugins with identical `priority` patching the same target: assert the
composed output matches a specific expected order, and that repeated `sync!` calls
produce identical bytes.

**Related:** #15.

---

### [ ] 04 — `rails plugins:preview` always prints the original file

- **Severity:** Medium · **Area:** Tooling · **Status:** open
- **Files:** `lib/plugins/build_manager.rb:44`, `lib/tasks/plugins.rake:18`

**Problem.** `preview` composes from the patch registry, but the registry is only
populated by `load_all_patch_files!`, which runs inside `sync!`. The rake task builds a
fresh `BuildManager` and calls `preview` directly, so the registry is empty and
`FilePatch.apply` returns the original content untouched (`file_patch.rb:45`).

`rails plugins:preview[app/models/contact.rb]` therefore reports that no plugin patches
the file — for every file, always. A debugging tool that lies is worse than none.

**Why the spec misses it.** `spec/plugins/build_manager_spec.rb:213` calls `manager.sync!`
before `preview`, so the registry happens to be warm. The spec exercises a state the rake
task never reaches.

**Fix.** Make `preview` self-sufficient:

```ruby
def preview(target)
  original_path = root.join(target)
  return nil unless original_path.exist?

  Plugins::FilePatch.clear_registry!
  load_all_patch_files!
  Plugins::FilePatch.apply(target, original_path.read)
end
```

This mutates global registry state; if `preview` is ever called from a running process it
should restore what was there. Making the registry instance-scoped removes the problem
entirely — see #20.

**Test.** Call `preview` on a **fresh** `BuildManager` (no prior `sync!`) and assert the
patched content is returned.

---

### [ ] 05 — Two plugins shipping the same new file cause fingerprint thrash

- **Severity:** High · **Area:** Determinism · **Status:** open
- **Files:** `lib/plugins/build_manager.rb:92`, `lib/plugins/build_manager.rb:151`

**Problem.** `process_all_plugin_files!` guards the patch path with `seen_targets` but
**not** the new-file path:

```ruby
if original.exist?
  process_patch(relative, original) unless seen_targets.include?(relative)
  seen_targets << relative
else
  process_new_file(relative, plugin_file)   # runs for every plugin, unconditionally
  seen_targets << relative
end
```

`spec/plugins/build_manager_spec.rb:143` treats "highest priority wins" as intended, and
the final bytes are indeed the winner's — but the operation is not idempotent:

1. First `sync!`: `low` writes its content and fingerprint; `high` overwrites and saves
   **its** fingerprint. Stored fingerprint = `high`.
2. Second `sync!`: `low` runs first, sees a fingerprint that is not its own, **rewrites
   the file with the losing content**, saves `low`'s fingerprint; then `high` rewrites.

Consequences: the incremental build never converges for these files (every boot rewrites
them); there is a real window where `storage/build/` holds the losing content while the
app serves from that directory; and the conflict — almost certainly a packaging mistake —
is silent.

**Fix.** Resolve the winner before writing. Build a map `relative => winning plugin_file`
in a first pass over `plugin_dirs` (ordered by priority), keeping the last writer, then
write once per `relative`. Log a warning naming both plugin ids whenever two plugins claim
the same new-file path.

**Test.** Two plugins providing the same new file: call `sync!` twice, assert the content
is the higher-priority one after each call and that the second call performs no write
(e.g. unchanged mtime). Assert the conflict is surfaced.

**Related:** #01, #19.

---

### [ ] 06 — A plugin replacing a core file without DSL is silently discarded

- **Severity:** Medium · **Area:** Correctness · **Status:** open
- **Files:** `lib/plugins/build_manager.rb:84`, `lib/plugins/build_manager.rb:101`

**Problem.** Patch files are detected by content:

```ruby
next unless File.read(plugin_file).include?("Plugins::FilePatch.define")
load plugin_file
```

If a plugin ships a file whose path matches an existing `app/` file but whose content is
**not** DSL — for example a full rewritten copy of the core file, a natural thing for an
author to try — then `load_all_patch_files!` skips it, `process_all_plugin_files!` still
takes the patch branch, `process_patch` runs with an empty patch set, and
`storage/build/` receives a byte-identical **copy of the core file**. The plugin's content
is never used and no error is raised: the author sees the plugin install successfully and
do nothing.

Secondary footgun: detection is a plain substring match, so a new file that merely
*mentions* `Plugins::FilePatch.define` in a comment would be `load`ed as executable Ruby
if its path collides with a core file.

**Fix.** Make the two cases explicit rather than inferred. If a path matches a core file
and the content lacks the DSL, raise a validation error naming the plugin and file, routed
through the same per-plugin failure path as #02 (mark `failed`, do not crash the boot).
Also skip writing the pointless identical copy when a target ends up with zero registered
patches. Longer term, require patch files to declare themselves (a header line, or a
manifest-declared list of patch targets) instead of relying on a substring heuristic.

**Test.** A plugin with `app/models/contact.rb` containing a plain class body: assert the
plugin is reported failed and that no copy of the untouched core file is written.

---

### [ ] 07 — Fingerprint filenames can collide

- **Severity:** Low · **Area:** Correctness · **Status:** open
- **Files:** `lib/plugins/build_manager.rb:176`

**Problem.** The encoding is not injective:

```ruby
fingerprint_dir.join(relative.gsub("/", "__") + ".sha256")
```

- `app/models/foo__bar.rb` → `app__models__foo__bar.rb.sha256`
- `app/models__foo/bar.rb` → `app__models__foo__bar.rb.sha256`

Two different build targets share one fingerprint file, so one is wrongly considered up to
date and never rebuilt — the same silent-staleness failure mode as #01. Double underscores
are not exotic in a JS/TSX tree, and plugins control their own file names.

**Fix.** Hash the path instead of escaping it:

```ruby
def fingerprint_path(relative)
  fingerprint_dir.join("#{Digest::SHA256.hexdigest(relative)}.sha256")
end
```

This also makes the `mkdir_p(path.dirname)` in `save_fingerprint` unnecessary. If
human-readable names are worth keeping for debugging, store the relative path inside the
file next to the digest. Changing the encoding invalidates existing fingerprints — safe
(worst case: one full rebuild), but it should land together with #01 so the rebuild
actually happens.

**Test.** `sync!` with two plugin files whose paths collide under the current encoding;
assert both outputs exist and both rebuild when their sources change.

---

### [ ] 08 — `plugin_dirs` hits the database once per plugin file

- **Severity:** Medium · **Area:** Performance · **Status:** open
- **Files:** `lib/plugins/build_manager.rb:66`, `lib/plugins/build_manager.rb:167`

**Problem.** `plugin_dirs` runs a query and directory-existence checks on every call, and
is invoked from `load_all_patch_files!`, `process_all_plugin_files!`, `remove_orphans!`
and — critically — from `compute_fingerprint`, which runs **once per patched file**.

With 20 plugins and a few hundred files that is thousands of queries plus thousands of
`Dir` stats on every boot, on the critical path before the app can serve traffic. The
whole point of the fingerprint mechanism is to make repeat boots nearly free; this undoes
it. `Plugin.table_exists?` also issues a schema query each time.

**Fix.** Memoize for the lifetime of the instance (`@plugin_dirs ||= ...`). A
`BuildManager` is short-lived — one per `sync!` / `rebuild!` / rake invocation — so no
invalidation is needed. While there, `compute_fingerprint` re-reads every patch file that
`load_all_patch_files!` already read; cache the contents in the same pass.

**Test.** Wrap `Plugin` in a query counter and assert `sync!` issues a constant number of
queries regardless of the number of plugin files.

---

### [ ] 09 — `Plugin.table_exists?` raises when the database is unreachable

- **Severity:** Medium · **Area:** Resilience · **Status:** open
- **Files:** `lib/plugins/build_manager.rb:67`

**Problem.**

```ruby
return [] unless defined?(Plugin) && Plugin.table_exists?
```

The guard reads as "degrade gracefully when there is no database", but it does not do
that. With Zeitwerk, `defined?(Plugin)` is effectively always true, and `table_exists?`
raises `ActiveRecord::ConnectionNotEstablished` (or `NoDatabaseError`) when the connection
cannot be opened — it does not return `false`.

`plugins.md` states that the health check phase never crashes the process and that the
worst outcome is a plugin-free application. Today, a database outage during boot takes the
whole process down.

**Fix.**

```ruby
def plugin_dirs
  @plugin_dirs ||= begin
    Plugin.active.order(:priority, :id).filter_map { ... }
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.warn("[plugins] cannot read plugin records: #{e.class}: #{e.message}")
    []
  end
end
```

Pending migrations are the same category of problem: if the `plugins` table does not exist
yet (fresh install, `db:migrate` not run), the build must no-op rather than fail.

**Test.** Stub `Plugin.active` to raise `ActiveRecord::ConnectionNotEstablished` and assert
`sync!` completes without raising and produces no build output.

**Related:** #18.

---

### [ ] 10 — Vite manifest is written without ensuring the directory exists

- **Severity:** Low · **Area:** Correctness · **Status:** open
- **Files:** `lib/plugins/build_manager.rb:239`

**Problem.**

```ruby
manifest_path = root.join("tmp", "plugin_patches_#{Rails.env}.json")
File.write(manifest_path, JSON.pretty_generate(manifest))
```

No `mkdir_p`. `root` is injectable (the specs pass a temp directory), and `tmp/` is not
guaranteed to exist — it is gitignored, wiped by `rails tmp:clear`, and absent in a fresh
container. The result is `Errno::ENOENT` at the very end of `sync!`, after the build files
were already written, which under #02 leaves the build half-committed.

Note that `sync!` already does `mkdir_p` for `build_dir` and `fingerprint_dir`; this path
was simply missed.

**Fix.** `FileUtils.mkdir_p(manifest_path.dirname)` before writing.

**Test.** Call `sync!` with a `root` whose `tmp/` does not exist and assert the manifest is
created.

---

## Security

### [ ] 11 — `plugin.id` becomes a filesystem path with no validation

- **Severity:** High · **Area:** Security · **Status:** open
- **Files:** `lib/plugins/build_manager.rb:70`, `app/models/plugin.rb:29`

**Problem.**

```ruby
dir = root.join("storage", "plugins", plugin.id)
```

`id` is a string primary key that comes from the Woofed Store payload. An id containing
`../../` escapes `storage/plugins/`, and the `relative_path_from(plugin_dir)` computed in
`each_patchable_plugin_file` then propagates `..` into `build_dir.join(relative)` on write.
The same unvalidated id is used by `Plugin#local_path`.

The store is the documented trust boundary, but "we trust the store" should not be the only
thing standing between a serialization bug (or a compromised store, or a future sideload
path) and arbitrary filesystem writes. This is cheap defence in depth at the boundary.

**Fix.**

- Validate the format on the model: `validates :id, format: { with: /\A[a-zA-Z0-9_-]+\z/ }`.
- Independently, verify containment before any I/O: expand the resolved path and assert it
  is a descendant of `storage/plugins/` (and that every write target is a descendant of
  `build_dir`). Reject and mark the plugin `failed` otherwise.

**Test.** A `Plugin` with `id` `"../../etc"` — assert the record is invalid, and that
`BuildManager` performs no I/O outside the plugin root even if such a record exists.

**Related:** #12, #14.

---

### [ ] 12 — Symlinks inside a plugin tree escape the plugin directory

- **Severity:** High · **Area:** Security · **Status:** open
- **Files:** `lib/plugins/build_manager.rb:116`

**Problem.** `each_patchable_plugin_file` uses `Dir.glob` + `File.file?`, both of which
follow symlinks. A plugin package containing `app/models` → `/etc` (or → the Rails root)
makes the build read arbitrary host files and copy them into `storage/build/`, which the
application then serves. `FileUtils.cp` in `process_new_file` copies content, so the
escaped data lands in a directory reachable by the app.

Extraction is not implemented yet, but this is the classic zip-slip / symlink-slip surface
and it should be closed on both sides before the download step lands.

**Fix.**

- In `each_patchable_plugin_file`: `next if File.symlink?(f)`, and reject any resolved path
  that is not a descendant of `plugin_dir` (`File.realpath` + prefix check).
- When ZIP extraction is implemented: reject entries that are symlinks or hard links, and
  reject any entry whose normalized destination escapes the target directory. Do this
  before writing anything to disk.

**Test.** A plugin directory containing a symlink to a file outside the plugin root:
assert it is skipped and never copied into `storage/build/`.

**Related:** #11.

---

### [ ] 13 — Patch blocks are evaluated twice; no package integrity check

- **Severity:** Medium · **Area:** Security · **Status:** open
- **Files:** `lib/plugins/build_manager.rb:86`, `lib/plugins/build_manager.rb:243`

**Problem.** Two separate observations about executing plugin-authored code.

**Arbitrary code execution at boot** (`load plugin_file`) is deliberate and documented in
`plugins.md` — the store is the trust boundary. The gap is that nothing verifies the
package actually came from the store intact: there is no signature or checksum
verification of the downloaded ZIP, so today "trusting the store" reduces to trusting the
network path. Worth designing alongside the download step.

**Blocks are evaluated twice.** `serialize_operation` calls `op.block.call` a second time
to build the Vite manifest, after `apply_to` already called it during composition. A block
with side effects, or one that is simply non-deterministic (reads a timestamp, an env var,
a counter), produces a Vite manifest that diverges from the Ruby-composed output — the
browser and the server then disagree about what the patch is.

**Fix.**

- Evaluate each block once and memoize the resulting string on the `Operation`, so
  composition and serialization consume the same value.
- For the store: verify a checksum or signature on the downloaded package before extracting.

**Test.** A patch whose block returns a different value on each call: assert the composed
build file and the manifest entry contain the same content.

---

### [ ] 14 — `name` uniqueness is validated without a unique index

- **Severity:** Medium · **Area:** Data integrity · **Status:** open
- **Files:** `app/models/plugin.rb:23`, `db/migrate/20260529134930_create_plugins.rb`

**Problem.** `validates :name, presence: true, uniqueness: true` is enforced only in Ruby.
The migration creates an index on `status` but none on `name`. Two concurrent installs of
the same plugin — plausible given installs are triggered by the store and by boot
reconciliation — can both pass the validation and insert duplicates.

Duplicate names matter here beyond tidiness: names are how operators and the store identify
a plugin, and two records with the same name and different ids mean two directories under
`storage/plugins/` both claiming to be the same plugin, patching the same files twice.

**Fix.** `add_index :plugins, :name, unique: true` in a migration, keeping the model
validation for the friendly error message.

**Test.** Model spec asserting the DB rejects a duplicate name (expect
`ActiveRecord::RecordNotUnique` when bypassing validations).

---

## Architecture and gaps vs. the plan

### [ ] 15 — `Plugins::Manifest` is unused and diverges from the plan

- **Severity:** Medium · **Area:** Architecture · **Status:** open
- **Files:** `lib/plugins/manifest.rb`, `lib/plugins/build_manager.rb:66`

**Problem.** Nothing calls `Plugins::Manifest`. `name`, `version` and `priority` all come
from the `Plugin` record in the database, while `plugins.md` ("Plugin manifest") presents
`plugin.rb` as the source of truth for those fields. Nothing reconciles the two, so a
plugin that bumps its `priority` in `plugin.rb` will not change anything until someone
updates the DB row by hand — a confusing failure with no error message.

The parser also fails silently on realistic input, because it is regex-based rather than
evaluated:

- `priority -10` does not match `/priority\s+(\d+)/` and silently becomes `0`.
- A commented-out `# name "old_name"` matches and wins if it appears first.
- `version` written with a heredoc or interpolation is not found and silently becomes
  `0.0.0`.

**Fix.** Pick one authority and make it explicit:

- **DB authoritative** — delete `Plugins::Manifest` and its spec, and update `plugins.md`
  to describe `plugin.rb` as metadata the store reads at packaging time, not something the
  app parses.
- **Manifest authoritative** — call it from the build, validate the fields (raise on a
  missing `name`, a non-integer `priority`, a non-semver `version`), and sync the values
  onto the `Plugin` record on install/update.

Either way the regex parser should go: parse the manifest by evaluating it in a restricted
DSL context (the same shape as `FilePatch.define`), which is consistent with the rest of
the system and cannot silently mis-read.

**Test.** Whichever path is chosen, cover: missing `name`, negative `priority`,
commented-out directives.

**Related:** #03.

---

### [ ] 16 — Plugin `config/` files are copied but never loaded

- **Severity:** Low · **Area:** Architecture · **Status:** open
- **Files:** `lib/plugins/build_manager.rb:127`

**Problem.** `each_patchable_plugin_file` walks `plugin_dir/config/**` (excluding
`routes.rb`), so a plugin's `config/locales/en.yml` is written to
`storage/build/config/locales/en.yml`. But the load design in `plugins.md` only prepends
`storage/build/app/` to the autoload, view and controller paths — nothing adds
`storage/build/config/` to `I18n.load_path` or to any other config lookup.

The locale files in the example plugins under `storage/plugins/ai_features/config/locales/`
are therefore inert: copied on every build, read by nothing.

**Fix.** Decide the scope and make it match:

- If plugin locales are in scope, append `storage/build/config/locales/**/*.yml` to
  `I18n.load_path` in the load stage (and document which other `config/` subpaths, if any,
  are supported).
- If not, stop walking `config/` except for `routes.rb` and document that plugins ship
  translations another way.

**Test.** If supported: a plugin shipping a locale file, asserting the translation resolves
after the build.

**Related:** #17, #24.

---

### [ ] 17 — Plugin migrations are not handled

- **Severity:** Low · **Area:** Gap vs. plan · **Status:** open
- **Files:** `lib/plugins/build_manager.rb:116`

**Problem.** `plugins.md` promises that a plugin can add migrations — create tables, alter
existing ones, modify the core schema — and the documented folder structure includes
`db/migrate/`. The build walks only `app/` and `config/`; `db/` is ignored entirely.

Not a defect for part 1, but `each_patchable_plugin_file` reads as if it covers "everything
a plugin ships", which will mislead the next person. Worth an explicit note in the code and
a design decision recorded before part 2: where plugin migrations are registered
(`migration_paths`), how they are ordered against core migrations, and what happens to them
when a plugin is `failed` or uninstalled (`plugins.md` says data survives uninstall).

**Fix.** For now, a comment in `each_patchable_plugin_file` stating that `db/` is
deliberately out of scope. Then design the migration story as part of the install flow.

**Related:** #18.

---

### [ ] 18 — `MODE` / safe mode is not wired into the build

- **Severity:** Info · **Area:** Gap vs. plan · **Status:** open
- **Files:** `app/models/installation.rb`, `lib/plugins/build_manager.rb`

**Problem.** `Installation#mode` (`safe` / `standard`) exists as an enum, but nothing reads
it. `BuildManager#sync!` runs unconditionally, whereas `plugins.md` specifies that the
entire build stage is skipped in safe mode and that the load stage bypasses
`storage/build/`.

Expected for part 1 — recorded here so the gate is not forgotten, and because several other
findings (#02, #09) assume it as the recovery path.

**Fix (part 2).** Gate `sync!` on the resolved mode; implement the health checks that
promote `safe` → `standard`; make the load stage (autoload paths, view paths, Vite
resolver) mode-aware.

**Related:** #02, #09, #17.

---

### [ ] 19 — The build is not atomic

- **Severity:** Medium · **Area:** Architecture · **Status:** open
- **Files:** `lib/plugins/build_manager.rb:32`, `lib/plugins/build_manager.rb:191`

**Problem.** `sync!` mutates `storage/build/` in place: `process_*` overwrite files one by
one and `remove_orphans!` deletes files, all while the running application may be reading
from that directory (in development, Zeitwerk reloads and the Vite dev server read it
live). A rebuild therefore has a window in which files are missing, partially written, or —
per #05 — hold the wrong plugin's content.

Combined with #02, a mid-build failure leaves the directory permanently inconsistent, with
some fingerprints already saved so the next boot will not repair it.

**Fix.** Compose into a temporary directory and swap:

1. Build into `storage/build.tmp/`.
2. On success, atomically replace `storage/build/` (rename the old aside, rename the new
   in, delete the old).
3. On failure, discard the temp directory and leave the previous build untouched.

This makes #02 much simpler to implement correctly — a failed plugin means "discard and
keep the last good build" rather than "repair a half-written directory". It also makes
orphan removal free (the new directory simply lacks the orphans), removing the
`Dir.empty?` cleanup loop.

Note the interaction with fingerprints: an atomic swap means the incremental path must copy
unchanged files into the temp directory rather than skipping them, or fingerprints must be
swapped in lockstep with the build.

**Test.** Simulate a failure mid-build and assert the previous `storage/build/` content is
intact.

**Related:** #01, #02, #05.

---

## Code quality and consistency

### [ ] 20 — Reading the registry inserts empty entries

- **Severity:** Low · **Area:** Code quality · **Status:** open
- **Files:** `lib/plugins/file_patch.rb:22`, `lib/plugins/file_patch.rb:33`

**Problem.**

```ruby
def registry
  @registry ||= Hash.new { |h, k| h[k] = [] }
end
```

The default block **mutates on read**. `patches_for("anything")` inserts an empty array
into the registry, so a lookup for a file no plugin touches permanently grows the hash.
`write_vite_patch_manifest!` then iterates those empty entries (harmless today only because
of the `unless patches_data.empty?` guard).

More broadly, the registry is global mutable class state on an autoloaded constant. In
development, a Zeitwerk reload discards `Plugins::FilePatch` and the registry with it, so
`preview` after a reload silently returns unpatched content (#04 is the same symptom from a
different cause).

**Fix.**

- Use `registry.fetch(target, [])` in readers and keep `Hash.new { |h, k| h[k] = [] }` only
  for the writer in `define`.
- Consider moving the registry to an instance owned by `BuildManager` and passing it into
  the patch loading, which removes both the global state and the reload sensitivity. The
  class-level API can stay as a thin facade for the DSL used inside plugin files.

**Test.** `patches_for` on an unregistered target returns `[]` and leaves `registry` empty.

**Related:** #04.

---

### [ ] 21 — `Plugin#status` should use `enum`, like `Installation`

- **Severity:** Low · **Area:** Consistency · **Status:** open
- **Files:** `app/models/plugin.rb:20`

**Problem.** `Plugin` declares a string constant plus an inclusion validation plus a
hand-written scope:

```ruby
STATUSES = %w[active inactive failed].freeze
validates :status, inclusion: { in: STATUSES }
scope :active, -> { where(status: "active") }
```

`Installation` — same codebase, same kind of field, added in the same commit — uses
`enum mode: { safe: "safe", standard: "standard" }`. Two conventions for the same thing.

The enum also gives `plugin.failed!` and `plugin.active?` for free, which is exactly the
API #02 needs when marking a plugin failed.

**Fix.** `enum status: { active: "active", inactive: "inactive", failed: "failed" }`,
dropping the manual constant, validation and scope. Check the generated `Plugin.active`
scope still behaves as `plugin_dirs` expects (it does — enums generate a scope per value).

**Test.** Existing `spec/models/plugin_spec.rb` should keep passing; add coverage for
`failed!`.

---

### [ ] 22 — Test gaps around the risky paths

- **Severity:** Medium · **Area:** Tests · **Status:** open
- **Files:** `spec/plugins/build_manager_spec.rb`, `spec/plugins/integration_spec.rb`

**Problem.** Coverage of the happy path and of the adapter's error messages is good. What
is missing is every path where this review found a defect — which is why the defects are
there.

Gaps, in order of importance:

- **Patch failure during `sync!`** (missing anchor) — the critical unimplemented behaviour
  (#02). Nothing exercises it.
- **`sync!` idempotence** — calling `sync!` twice and asserting identical output would catch
  #05 directly.
- **Fingerprint present, build file missing** (#01).
- **Tied priorities** (#03).
- **`preview` on a fresh manager** (#04) — the current spec calls `sync!` first, masking the
  bug.
- **Database unavailable** (#09).
- `Plugins::Manifest` has a spec but no consumer (#15) — a test for dead code.

**Fix.** Add the cases above as each corresponding finding is fixed, so every fix ships with
the regression test that would have caught it.

---

## Repo hygiene and scope

### [ ] 23 — `storage/plugins/` is versioned including nested `.git/` directories

- **Severity:** Blocker · **Area:** Repo hygiene · **Status:** open
- **Files:** `.gitignore`, `storage/plugins/`

**Problem.** The `.gitignore` change adds `!/storage/plugins/`, un-ignoring the whole tree.
Combined with the current working-tree contents, committing would add:

- `storage/plugins/ai_features/.git/`, `storage/plugins/ai_features-old/.git/`,
  `storage/plugins/favorite_contacts/.git/` — nested git repositories that are **not**
  declared submodules. Adding one to the parent repository creates an embedded-repository
  gitlink without a matching `.gitmodules` entry, so a clone of the parent cannot retrieve
  its contents. The nested metadata also confuses tools that walk the working tree.
- `storage/plugins/ai_features-old/` and `storage/plugins/test22/` — development leftovers
  with no place in the branch.

`plugins.md` ("How to create a plugin") says the repository should ship exactly one starter
at `storage/plugins/my_new_plugin/`.

**Fix.**

1. Remove the three scratch plugin directories from the working tree.
2. Version only the starter, and scope the negation to it:

   ```gitignore
   /storage/*
   !/storage/.keep
   !/storage/plugins/
   /storage/plugins/*
   !/storage/plugins/my_new_plugin/
   storage/plugins/**/.git/
   ```

3. Confirm with `git status --short storage/` and `git check-ignore -v` before committing.

**Note.** The rest of the `.gitignore` change (`/storage/build/`, `/tmp/plugin_fingerprints/`,
`/tmp/plugin_patches_*.json`) is correct and should stay.

---

### [ ] 24 — The `en_US` i18n change does not belong to this branch

- **Severity:** Blocker · **Area:** Scope · **Status:** open
- **Files:** `config/initializers/i18n.rb`

**Problem.** Two unrelated things in one change.

**Out of scope.** Adding `en_US` to `available_locales` and `LANGUAGES_CONFIG[40]` has
nothing to do with the plugin system. It looks like a local `LANGUAGE` environment
workaround that leaked into the branch, and it will make the plugin PR harder to review and
to revert.

**Likely a no-op anyway.** Assigning `I18n.fallbacks` directly in an initializer only takes
effect if the backend includes `I18n::Backend::Fallbacks`. In Rails the supported switch is
`config.i18n.fallbacks` in `config/application.rb` (or an environment file), which is what
makes Rails extend the backend. As written, `en_US` is very likely to raise
`I18n::MissingTranslationData` rather than fall back to `en`.

**Fix.** Drop the change from this branch. If `en_US` is genuinely needed, do it separately
via `config.i18n.fallbacks = { 'en_US' => 'en' }` in the application config, with a request
spec asserting a page renders under `LANGUAGE=en_US`.

**Related:** #16 (the other i18n-adjacent item — plugin-shipped locales).

---

## Additional findings

### [ ] 25 — `ai_followups` exposes events from other accounts

- **Severity:** Critical · **Area:** Security · **Status:** open
- **Files:** `storage/plugins/ai_features/app/controllers/accounts/ai_followups_controller.rb:3`, `storage/plugins/ai_features/spec/controllers/ai_followups_controller_spec.rb:9`

**Problem.** The controller starts from the global `Event` relation and never constrains
the query to the authenticated account:

```ruby
ai_events = Event
  .joins(:contact)
  .joins('INNER JOIN deals ON deals.id = events.deal_id')
  .where("events.additional_attributes ->> 'ai_generated' = 'true'")
```

`InternalController` authenticates the user, but it does not apply a tenant scope. `Event`
also has no account default scope. A signed-in user can therefore receive AI-generated
events belonging to contacts and deals from another account. The view renders links and
record data for those foreign objects, making this a cross-tenant confidentiality breach.

The request spec creates data only for the signed-in user's account, so it proves the happy
path while missing the authorization boundary that matters most.

**Fix.** Derive the relation from an account-owned association, or add an explicit join and
account predicate that cannot be influenced by the route's `account_id`. The authenticated
user's account must be the authority; do not trust `params[:account_id]` alone. Apply the
same rule to counts and both pending/done collections.

**Test.** Create AI-generated pending and completed events for two accounts, sign in to one,
request the page using that account's route, and assert that the response, assigned
collections, and counts contain only its records. Also request the route with another
account id and assert access is denied or still scoped to the authenticated account,
according to the application's routing policy.

---

### [ ] 26 — Patch order has conflicting priority sources

- **Severity:** High · **Area:** Determinism · **Status:** open
- **Files:** `lib/plugins/build_manager.rb:69`, `lib/plugins/file_patch.rb:25`, `lib/plugins/file_patch.rb:34`

**Problem.** Plugin directories are ordered by `Plugin#priority` from the database, but
`FilePatch.define` accepts a separate `priority:` value and `patches_for` sorts by that
second value. The manifest declares a third priority value, currently unused (#15).

The existing multiple-plugin specs repeat the same number in the database record and in
the patch DSL, masking the divergence. If the store changes the database priority while a
patch retains a hard-coded DSL priority, the final composition no longer follows the
plugin order advertised by the model or manifest. A later plugin may run before the patch
whose inserted anchor it depends on, causing a build failure (#02).

**Fix.** Establish one plugin-level source of truth. Prefer resolving priority when the
plugin is installed/reconciled, then have `BuildManager` attach that priority and plugin id
to every registered patch. Remove `priority:` from the public patch DSL unless operation-
level ordering is a deliberate, separately named feature. Sort by `[plugin_priority,
plugin_id, operation_index]` so the result is deterministic.

**Test.** Give two database records priorities opposite to values declared in their patch
files and assert the documented authority wins. Then change the authoritative priority and
assert composition order changes without editing plugin source. Avoid duplicating the same
priority in test setup and DSL declarations.

**Related:** #02, #03, #15.

---

### [ ] 27 — The generated build is never loaded by the application

- **Severity:** Info · **Area:** Gap vs. plan · **Status:** open
- **Files:** `lib/plugins/build_manager.rb:32`, Rails initialization and Vite configuration (missing)

**Problem.** The current change can generate files through the manual rake tasks, but no
application code calls `BuildManager#sync!` during boot and no loader consumes its output.
There is no configuration that:

- prepends `storage/build/app/` to Rails autoload and eager-load paths;
- prepends plugin views to controller view paths;
- evaluates active plugin `config/routes.rb` files;
- makes Vite resolve JavaScript from `storage/build/app/javascript/` first; or
- loads the generated Vite patch manifest.

Consequently, a successful `rails plugins:rebuild` produces files that the running
application ignores. #16 covers the narrower locale/config case and #18 covers safe-mode
gating; neither records that the standard-mode runtime loader itself is absent.

This is expected if the branch is intentionally only the persistence/build foundation,
but it must remain tracked so the generated output is not mistaken for an operational
plugin system.

**Fix (part 2).** Add a `PluginLoader` invoked after health checks and before application
classes are loaded. It should run the build only in standard mode, configure Rails and
Vite resolution consistently, load routes/locales, and bypass all generated paths in safe
mode. Define the initialization order explicitly because Zeitwerk paths added after eager
loading are too late.

**Test.** Boot an isolated application with an active plugin and assert a plugin model,
controller, view, route, and frontend module resolve from `storage/build/`. Repeat in safe
mode and assert only core implementations resolve.

**Related:** #16, #18, #19.

---

## Incremental implementation plan

Each step below should be a small, independently reviewable PR. A step should include its
tests and must not enable plugin code in production before the runtime loading steps are
complete.

### Step 0 — Clean the current foundation

- Remove committed plugin worktrees and unrelated changes.
- Fix tenant isolation in the example plugin.
- Covers: #23, #24, #25.

### Step 1 — Persist plugins and installation mode

- Add the `Plugin` model with `active`, `inactive`, and `failed` statuses.
- Add the installation `safe` / `standard` mode used as the operator's persisted choice.
- Add database constraints, id validation, factories, and model specs.
- Covers: #11, #14, #21.

### Step 2 — Define the local plugin contract

- Make the database record the runtime source of truth for id, version, priority, and
  status; keep `plugin.rb` as packaging metadata only.
- Discover only active plugin directories in deterministic order.
- Reject invalid paths and symlinks before reading plugin files.
- Covers: #8, #12, #15, #26 (source of priority).

### Step 3 — Decide the boot mode

- Start every boot in safe mode.
- Check database and store availability, then read the persisted installation mode.
- Promote to standard mode only when every check passes; failures must keep booting in
  safe mode.
- Do not build or load plugins yet.
- Covers: #9, #18 (mode resolution only).

### Step 4 — Reconcile and install packages

- Fetch the installation's plugin list from the store and reconcile local records.
- Download only missing or changed versions, verify their checksum, and extract them
  atomically.
- Prevent zip-slip, symlink, and path traversal during extraction.
- Skip this entire step in safe mode.

### Step 5 — Build a deterministic patch engine

- Implement the patch DSL and define explicit behaviour for patched, new, replaced, and
  conflicting files.
- Use one ordering rule: `[plugin_priority, plugin_id, operation_index]`.
- Evaluate patch blocks once and keep the registry free of read side effects.
- Covers: #3, #5, #6, #13, #20, #26.

### Step 6 — Produce an atomic incremental build

- Compose into a temporary directory and swap it into `storage/build/` only after success.
- Add fingerprints, collision-safe keys, orphan cleanup, and required directory creation.
- Preserve or recreate unchanged output when build and fingerprint storage have different
  lifecycles.
- Covers: #1, #7, #8, #10, #19.

### Step 7 — Isolate plugin build failures

- Attribute load or patch errors to the responsible plugin and mark only that plugin as
  `failed`.
- Discard the failed attempt, rebuild with the remaining active plugins, and let boot
  continue.
- Covers: #2 and completes the build part of #18.

### Step 8 — Load backend plugin code

- In standard mode, load models and services from the build before core files.
- Add plugin view paths, routes, and locale files.
- In safe mode, ignore `storage/build/` even when old output exists.
- Covers: #16 and the Rails part of #27.

### Step 9 — Load frontend plugin code

- Add the Vite resolver and patch manifest for JavaScript and CSS.
- Make development and production resolve plugin files with the same precedence.
- Make `plugins:preview` work without a previous build.
- Covers: #4, #10, and the Vite part of #27.

### Step 10 — Support plugin migrations

- Register plugin migration paths and define ordering relative to core migrations.
- Run migrations only for verified installations; uninstall keeps plugin data by default.
- Define how failed plugins and interrupted migrations are recovered.
- Covers: #17.

### Step 11 — Validate and report the boot

- Check the login page and compiled assets after boot.
- Report mode, checks, and plugin statuses to the store without blocking the application.
- When a newly installed plugin causes degradation, keep the installation in standard mode
  and disable only that plugin; use safe mode when no single culprit can be isolated.

### Step 12 — Add operator tooling and end-to-end coverage

- Finish rebuild, preview, status, enable, disable, and safe-mode commands.
- Cover standard boot, safe boot, install, update, uninstall, failed plugin recovery, and
  repeated deterministic builds through the production data flow.
- Remove example plugin fixtures from production storage and keep purpose-built fixtures
  under specs.
