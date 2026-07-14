# Changelog

## Work in progress

_base: (root)_

### ✨ New features

- 🚚 `bin/kauk-sync` — the package manager moved here from orchids as a bash stopgap
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
