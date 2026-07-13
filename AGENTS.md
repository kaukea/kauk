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

- **Naming & domains** are DECIDED — `docs/naming.md`. Platform = KAUK; `kauk.ai` (brand),
  `kauk.org` (tooling/config paths); PyPI/npm `kauk` reserved defensively; gh org `kaukai`;
  fallback stem `parstuk`. Do not re-litigate the name.
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
- Commit trailer: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>` on agent commits.
- This repo is orchids-managed: shared skills/agent-files are symlinks under `.ai/`; run
  `orchids sync` to pull canonical updates. Never hand-edit `.ai.toml`'s managed section.
