# Changelog

## Work in progress

_base: (root)_

### ✨ New features

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
