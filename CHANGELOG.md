# Changelog

## Work in progress

_base: (root)_

### ✨ New features

- 🚚 **Two repositories cross to kaukea; orchard takes its name** — kaukea/kauk
  and kaukea/orchard are the homes, checkouts at `~/src/kaukea` with
  compatibility symlinks behind them. Migration `2026-08-18-kaukea-move.md`
  converts every consumer's sources to the GitHub default form, carries
  watermarks across the identity change, and removes the old clones; the estate
  walked the same day. Rides along: the SIGPIPE fix for early-exit source
  lookups.

- ✨ **kai leads; kaukea carries; kauk stands backup** — the executable is
  `bin/kaukea`, `bin/kai` in front, `bin/kauk` the fallback alias; messages and
  the tool's own skill speak kai. Migration: `2026-08-16-command-is-kai.md`.

- ♻️ **Sync is what sync was; push is deliberate** — `kai sync` pulls with rebase,
  runs pending migrations, warns when an update removes artifacts, and lays by
  selection. `--push` is the separate explicit act (pull-only packages refuse it);
  a source carrying `ref` is left untouched until the versioning work
  (Decision-051). The updates-available notice moves to a background check.

- ✨ **The reader lays what you select, and nothing else** — `.ai.toml` becomes
  defaults-only: `[sources."owner/repo"]` resolves to GitHub, a full path is local,
  an `origin` key is refused. Each source carries only the operator's `select` list
  of category paths; laying happens after selection plus dependency closure — flat
  `dependencies-<kind>:` frontmatter keys (or the nested map), agents' `skills:`
  lists, name-rooted `package/…/artifact` references across packages, and
  `package.toml` dependencies pulling their sources in. Sync stops pushing local
  clone edits; that becomes the explicit push verb's job.
  `tests/convention-reader.sh` rewritten, 56 assertions.
  Migration: `migrations/2026-08-16-defaults-only-aitoml.md`.

- 🌳 **kauk reads packages by convention** — `bin/kauk` no longer reads `manifest.conf`.
  A package's contents are its `skills/ agents/ hooks/ tools/ files/` directories and
  nothing else; `files/` mirrors to the repository root at its own relative paths.
  Placement follows runtime detection, which returns a set rather than a winner.
  Delivery is links everywhere — the `exclude|copy|link|local` resolver, and the
  template and prefix placement paths, are gone. A destination already holding a real
  file is reported and skipped; a *name* collision keeps both artifacts under
  namespaces (`local:<name>` and `<package>:<name>`) instead of merging them, with the
  separator taken from each runtime's own syntax. New `kauk resolve [--assist]` lists
  what kauk refused to touch and, only when asked, offers a Claude-assisted merge.
  A repository that is its own source is no longer vendored into itself: its working
  tree is the source and it publishes by copy, so its edits are visible without a push
  — `package.toml` declares that. Verified against live orchids, which has no
  `manifest.conf`: 76 artifacts land where the previous reader would have laid zero and
  then pruned every existing link. `tests/convention-reader.sh`, 37 assertions.
  Migration: `migrations/2026-08-11-convention-packages.md`.

- 📐 `docs/package-format.md` — the package format is specified end to end for the first
  time: a package is a repository of files that knows nothing about kauk, its contents
  determined by convention with no producer-side manifest. Covers the five kinds (agents,
  skills, hooks, tools, files) plus `templates/` and `migrations/`, declarative hooks with
  a transpiler-owned per-runtime mapping, links-everywhere delivery with report-and-skip,
  `:kauk:` provenance nuggets, the three consumer artifacts (`.ai.toml` / lock / cache
  index), categories and dependencies. On the Claude target a package renders as a
  skills-directory **plugin**, which owns its own hook wiring — so `settings.json` is
  never written and kauk touches no file the user owns. Fifteen operator rulings
  recorded as Decision-014 → Decision-028. Nothing is implemented yet — `bin/kauk`
  still reads `manifest.conf`.

- 🚚 `bin/kauk` — the package manager moved here from orchids as a bash stopgap
  (Decision-007/008): source-generic `init` / `install <owner>/<repo>` / `sync` over
  git-vendored packages self-described by `manifest.conf` typed lines; sources recorded
  in `.ai.toml` `[sources]` tables; dead-link pruning. kauk is itself a pull-only
  package shipping the `kauk` skill (`skills/kauk/SKILL.md`) — the agent-facing grammar
  that replaces orchids' `skill-sync`.

- 🌱 Bootstrap the KAUK platform repository: orchids house style (vendored shared
  agent-rules + skills), project-owned `AGENTS.md` / `README.md` / `ARCHITECTURE.md`
  (+ Taxonomy), seeded `docs/decisions.md` (naming, control-plane, client-side custody,
  reservations, hosting), the `docs/TODO.md` board + sidecars, `docs/naming.md` (moved
  from the naming memory), and the `kauk.ai` `site/` projection scaffold.
- 📦 Namespace reservations: PyPI + npm `kauk` placeholder packages (`0.0.0`) under
  `namespace-reservation/`, ready for the operator to publish (`UPLOAD.md`).

- ⚙️ **`kai sync` now handles migrations itself** — each package declares
  pending migrations (markdown files carrying scripted and prose steps) with an
  `applied-by` marker on each fence: `shell` (default) for steps kai runs itself
  (inline or via a relative script), `agent` for anything it cannot do. Migrations
  already pending run against the shared state before local work rebases; newly
  arrived migrations run afterward, so every consumer sees the same sequence.
  Failed or agent-only steps are recorded under `.git/the-works/asks/` and
  delivered to the next session as concrete instructions, never as
  "migrations pending" nags. This retires the agent-reads-and-applies model
  (Decision-055). The feature ships `2026-08-18-kaukea-move-links.md`, repointing
  laid links from the retired `serialseb/{kauk,orchids}` clones to `kaukea/{kauk,orchard}`.

- 🔗 **Laid symlinks heal when sources move** — `prune_links` now scans the
  whole tree (not just `.claude/` + root), repoints any dead link whose target
  exists under exactly one currently-cloned source, reports `AMBIGUOUS` when
  several could claim it (touching nothing), and removes only true orphans.
  Relative-target hand-laid links are discovered and rewritten absolute,
  healing their base. The `2026-08-18-kaukea-move-links` migration uses the
  same matching logic, safe to re-run, and never enters `.git` or `.ai`.

- 🧹 **Sync sweeps orphaned clones** — after updating sources, if
  `.ai/repositories/<owner>/<repo>` no longer appears in `.ai.toml`, it is
  removed only when its tree is clean and its HEAD is contained in origin;
  otherwise reported (`ORPHAN`) with the reason, preserving any unpushed work
  and operator-performed clone edits carried through rebase.

- ✅ **tests/migrations-at-sync.sh** — black-box suite for migrations-at-sync
  and stale-laid-links, exercising all ruled behaviours from interleaved-date
  migrations across two sources to link repoint/orphan scan. Eight test cases;
  two check TODO-pending until missing infrastructure lands.

---

#### ✨ `f/reader-select` → `archive/reader-select`

The reader lays what you select, and nothing else. `.ai.toml` becomes
defaults-only — `[sources."owner/repo"]` resolves to GitHub, a full path is
local, an `origin` key is refused — and each source carries only the
operator's `select` list of category paths. Laying happens after selection
plus dependency closure: flat `dependencies-<kind>:` frontmatter keys (or the
nested map), agents' `skills:` lists, name-rooted `package/…/artifact`
references across packages, and `package.toml` dependencies pulling their
sources in. Sync stops pushing local clone edits — that becomes the explicit
push verb's job. Ships `migrations/2026-08-16-defaults-only-aitoml.md`
converting existing files.

_Board: dependency-graph, categories-rename · Decisions 046–049._

#### ♻️ `f/sync-pin` → `archive/sync-pin`

Sync is what sync was; push is deliberate. `kai sync` pulls with rebase, runs
pending migrations (advancing the per-package watermark), warns when an
update removes or renames artifacts, and lays by selection. `--push` is the
one separate act — rebase, then publish local edits to the source; pull-only
packages refuse it. A source carrying `ref` — a version, tag, or commit — is
left entirely untouched until the versioning work exists (Decision-051), and
the "updates available" notice moves to a background check boarded as
update-notify.

_Board: lockfile (deferred whole), update-notify · Decisions 049–051._

#### ✨ `f/cli-kai` → `archive/cli-kai`

kai leads; kaukea carries; kauk stands backup. The executable ships as
`bin/kaukea` with `bin/kai` in front and `bin/kauk` as the fallback alias —
three names, one behaviour. User-facing messages speak kai, and the tool's
skill renames to `kai` with its content rewritten to the current model.
Migration `2026-08-16-command-is-kai.md` cleans consumers' dangling links.

_Board: cli-rename-kai · Decision-026, operator emphasis 2026-08-16._
