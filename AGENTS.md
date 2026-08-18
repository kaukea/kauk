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

## Conventions

- Follow the file registry in `AGENTS.shared.md` (docs/TODO.md + sidecars, docs/decisions.md,
  CHANGELOG.md, ARCHITECTURE.md). `main` is immutable; work on `f/<id>` branches; close per
  the `workflow-complete` skill.
- This repo is kauk-managed: shared skills/agent-files are symlinks under `.ai/`; run
  `kauk sync` (the `kauk` skill) to converge with the sources. `.ai.toml` is the
  **operator's** file — edit it freely; kauk writes the lock file, not this one
  (Decision-023).
