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

The `kauk` command — one grammar over the registry and federation. `publish`, `install`,
`resolve`. *(components pending first feature.)*

Until 0.1.0, `bin/kauk` is the shipped **bash stopgap** (component `cli-core`,
Decision-007): the file-package half of the grammar — `init` / `install <owner>/<repo>`
/ `sync` — over git-vendored sources (`.ai/repositories/`, `.ai.toml`), each package
self-described by its `manifest.conf`. The real CLI inherits the grammar and replaces it.

## projection

Generates the `kauk.ai/<pkg>` pages from one repo at publish time (the projection rule),
served as static Pages. Heavy artifacts route to `apt.kauk.org` later. Lives in `site/`.

## infra

Hosting and DNS for `kauk.ai` (and `apt.kauk.org`). Static host is either GitHub Pages
(zero-cost MVP) or AWS S3 + CloudFront + Route 53 + ACM — see `#hosting` in decisions.md.

## workflow

The agent operating model (orchids-managed): shared agent-rule files, skills, hooks, and
the workflow/branch/close machinery. Lives in `.claude/` + the `AGENTS*.md` files.
