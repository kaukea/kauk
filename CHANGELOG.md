# Changelog

## Work in progress

_base: (root)_

### ✨ New features

- 📐 `docs/package-format.md` — the package format is specified end to end for the first
  time: a package is a repository of files that knows nothing about kauk, its contents
  determined by convention with no producer-side manifest. Covers the five kinds (agents,
  skills, hooks, tools, files) plus `templates/` and `migrations/`, declarative hooks with
  a transpiler-owned per-runtime mapping, links-everywhere delivery with report-and-skip,
  `:kauk:` provenance nuggets, the three consumer artifacts (`.ai.toml` / lock / cache
  index), categories and dependencies. Thirteen operator rulings recorded as
  Decision-014 → Decision-026. Nothing is implemented yet — `bin/kauk` still reads
  `manifest.conf`.

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
