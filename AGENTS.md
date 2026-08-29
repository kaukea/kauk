# kauk — project rules

Project-specific agent rules. Shared rules: `AGENTS.shared.md` (immutable). File formats:
`AGENTS.files.md`. Taxonomy: `ARCHITECTURE.md`.

## What this is

**KAUK** is a package platform built as a **control plane**, not a storage backend: a
native index for first-class artifacts (packages, **skills**, and arbitrary files) *plus*
a federation layer that lets a user publish to / pull from external registries (npm, PyPI,
OCI, GitHub) when they opt in. The value is the tooling — one CLI, one grammar, one auth
flow over many backends — not the bytes. Brand = command = domain: `kauk` everywhere,
served at `kauk.ai`. See `README.md` for the product view and `ARCHITECTURE.md` for the
Taxonomy.

## Ground truth to reuse (do NOT re-derive)

- **The package format** is SPECIFIED — `docs/package-format.md`. A package is a repository
  of files that knows nothing about kauk; contents are determined by convention and there is
  no producer-side manifest. Kinds: agents, skills, hooks, tools, files (+ `templates/` and
  `migrations/` as mechanisms). Read it before touching delivery, layout, or frontmatter.
- **Unspecified state is untrusted** (Decision-014): most of what is in these repositories
  was built by agents, not specified by the operator. If there is no specific operator
  definition, do not reason from it, preserve it, or cite it as precedent — ask.

- **Naming & domains** are DECIDED — `docs/naming.md`. Platform = KAUK; `kauk.ai` (brand),
  `kauk.org` (tooling/config paths); PyPI/npm `kauk` reserved defensively; gh org
  **kaukea** (repos `kaukea/kauk`, `kaukea/orchard`); the CLI is `kai`
  (Decision-026/052); fallback stem `parstuk`. Do not re-litigate the name.
- **Namespace reservations** are the two placeholder packages in `namespace-reservation/`
  (PyPI + npm, both `0.0.0`). They reserve the name only; real tooling starts at `0.1.0`.
  Upload steps: `namespace-reservation/UPLOAD.md` (operator runs; agent cannot publish).

## Hard constraints

- **Credential custody is client-side by default** (Decision — `#custody` in decisions.md):
  external-backend tokens live on the *user's* machine via OAuth device flow; KAUK holds the
  app registration, never a hoard of users' publish tokens. Server-held tokens require an
  explicit decision and are scoped publish-only / short-lived / per-backend. "Bind the
  workflow, not the secrets." Anything KAUK republishes on a user's behalf is signed/attested.
- **Secrets never enter git** — tokens, publish credentials, signing keys go in gitignored
  `keys/` or deployed config, never in sidecars, decisions, changelog, or commit messages.
- **Version-grammar translation is a first-class concern** — SemVer (npm) ↔ PEP 440 (PyPI):
  build metadata (`+x`) is ignored for ordering; PyPI rejects local (`+`) versions on the
  public index. KAUK is the translator; never assume one grammar across backends.
- **Exactly one settings JSON exists, and it is passed, never laid.**
  `bin/kai.settings.json` is handed to every agent via `claude --settings` at spawn.
  NOTHING configures agents from a JSON file anywhere else — no `.claude/settings.json`,
  no `.claude/settings.local.json`, in the repo root or in any feature worktree.
  Per-agent permissions belong in the agent's own YAML frontmatter (`tools:`), where
  they travel with the agent — see `courier.md`. If you are about to write a settings
  JSON to restrict an agent: don't. Put it in that agent's frontmatter. (Operator,
  2026-08-24, Decision-061; extends Decision-060.)

## Conventions

- Follow the file registry in `AGENTS.shared.md` (docs/TODO.md + sidecars, docs/decisions.md,
  CHANGELOG.md, ARCHITECTURE.md). `main` is immutable; work on `f/<id>` branches; close per
  the `workflow-complete` skill.
- This repo is kai-managed: shared skills and agent files are links into the package
  store; run `kai update` (the `kai` skill) to converge with the sources. `.ai.toml` is
  the **operator's** file — edit it freely. There is no lock file; the store itself is
  the record of what a repository has been given.

## Communication

- **Plain English, always.** Full sentences, ordinary words. Do not use vocabulary an
  agent coined in an earlier session — if a term is not the operator's own, not in these
  rule files, and not a file or command name, say the thing instead of naming it.
  (Operator, 2026-08-26.)
- **Never refer to a GitHub issue by its number alone.** Every mention carries what the
  issue is about, in words, alongside the number. (Operator, 2026-08-26.)
