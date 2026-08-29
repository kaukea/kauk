# Architecture

KAUK is a **control-plane** package platform: a thin, client-side tool + a native artifact
index that federates over external registries. Storage is commodity; the broker is the
product. This document is the seed skeleton — components are filled in as features land.

## Contents

- [registry](#registry) — the native KAUK index
- [federation](#federation) — the broker over external backends
- [cli](#cli) — the `kauk` command
- [projection](#projection) — the `kauk.ai` site
- [infra](#infra) — hosting & DNS
- [workflow](#workflow) — the agent operating model (meta)

## Taxonomy

The controlled vocabulary for `docs/TODO.md` (functionality = heading; component = leaf
badge field). Agents do not invent values; extend this table deliberately when a real
feature needs a new term.

| functionality | components |
|---|---|
| **registry** | index-store · artifact-model · resolver |
| **federation** | auth-broker · version-translate · backend-npm · backend-pypi · backend-oci · backend-github |
| **cli** | cli-core · cmd-publish · cmd-install |
| **projection** | site-generator · pages-deploy |
| **infra** | hosting · dns |
| **workflow** | agent-rules · tooling |

## registry

The native index for first-class artifacts — packages, skills, and arbitrary files.
Addressing is backend-qualified (`kauk.org/<pkg>` native vs `npm:<pkg>` / `pypi:<pkg>`)
so `install <pkg>` is never ambiguous across backends. Skills and arbitrary files are
native artifacts here — no PyPI/npm wrapper-package trick needed. *(components pending
first feature.)*

## federation

The broker that publishes to / pulls from external registries on opt-in. Holds the
per-backend adapters, the **auth-broker** (client-side OAuth device flow — tokens stay on
the user's machine), and **version-translate** (SemVer ↔ PEP 440). Republished artifacts
are signed/attested. *(components pending first feature.)*

## cli

The `kauk` command — one grammar over the registry and federation. `publish`, `install`.
*(components pending first feature.)*

Until 0.1.0, `bin/kaukea` is the shipped **bash stopgap** (component `cli-core`),
invoked as `kai`: the file-package half of the grammar — `init [--package]` /
`install <owner>/<repo>` / `update`, also spelled `sync` — over git-vendored packages
(`.ai/repositories/`), declared as
`[[dependency]]` blocks in the repository's one configuration file, `.ai.toml`, whose
root table also carries the repository's own identity (`docs/ai-toml.md`).
The real CLI inherits the grammar and replaces it.

**The clones live in the git folder; the working tree only points at them.** A package
is cloned to `<git-common-dir>/kai/repositories/<owner>/<repo>`, and each checkout
reaches it through `.ai/repositories/<owner>/<repo>`, a link that is ignored and so
never committed. Every worktree of a repository shares the git folder, so one clone
serves all of them and none can drift onto a version of its own; and because the link is
uncommitted it may differ from checkout to checkout, which is what allows a laid link to
carry one short target that is correct in every one of them. A laid link's target is
counted from the nearest `.ai.toml` at or above it — never from a home directory, never
from wherever the command was run. Session start clones whatever a repository declares
and does not yet have, so a fresh checkout or a new worktree reaches its packages
without a sync.

**A package declares nothing.** Its contents are determined by convention — the
directories `skills/ agents/ hooks/ tools/ files/` — and anything outside them is
ignored (Decision-015; full specification in `docs/package-format.md`). This replaces
the `manifest.conf` index a package used to carry, which was never an operator design
and whose omissions failed silently.

Two cross-cutting rules follow from it, and both hold everywhere in the tool:

- **kauk decides nothing on the user's behalf.** A destination already holding a file
  kauk did not place is reported and skipped; a *name* collision keeps both artifacts
  under namespaces (`local:<name>` and `<package>:<name>`) rather than merging them
  (Decisions 016, 041, 042).
- **Placement is per detected runtime, and detection yields a set.** `.claude/` is one
  target's encoding, never the model; a repository may be served by several runtimes at
  once (Decisions 012, 018).

A repository that is itself a package is not vendored into itself: its working tree is
the source, and it publishes into itself the same way anything else is published — the
runtime directory holds a link into the convention directory. Editing the source is
immediately what runs, with no second copy and nothing to keep in step.

**kai's static install** (`bin/kai.settings.json` + `bin/kai-hooks.sh`, beside the `kai`
executable, never laid or vendored into a consumer) is the one settings file: it maps
Claude's events to neutral names and passes them to `kai-hooks.sh`, which runs whatever
`hooks/<event>/index.toml` each installed package exposes (`docs/package-format.md`
`## hooks/`). Every fleet dispatch (`tools/dispatch-agent.sh` et al., in the `orchard`
package) resolves `kai` on PATH and threads `--settings <resolved kai.settings.json>`
into the launch, guarded on the file's existence. A package therefore never ships or
writes a `settings.json` of its own (Decisions 019/060/061), and kai enforces that at
delivery rather than trusting each package to have stopped: `.claude/settings.json` and
`.claude/settings.local.json` are refused out of any package's `files/` tree, and a
shipped migration takes back the ones placed before the rule existed. Migrations ride the same
static install: one global watermark (`.ai/migrations.toml`), every installed
package's `migrations/` plus the repository's own (when the root table of its
`.ai.toml` says `type = "package"`) merged into one ordered stream, applied by
`kai sync`.

## projection

Generates the `kauk.ai/<pkg>` pages from one repo at publish time (the projection rule),
served as static Pages. Heavy artifacts route to `apt.kauk.org` later. Lives in `site/`.

## infra

Hosting and DNS for `kauk.ai` (and `apt.kauk.org`). Static host is either GitHub Pages
(zero-cost MVP) or AWS S3 + CloudFront + Route 53 + ACM — see `#hosting` in decisions.md.

## workflow

The agent operating model (managed by the orchard package): shared agent-rule files, skills, hooks, and
the workflow/branch/close machinery. Lives in `.claude/` + the `AGENTS*.md` files.
