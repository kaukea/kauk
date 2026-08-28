# kauk

**KAUK** is a package platform built as a control plane: a native index for first-class
artifacts — packages, **skills**, and arbitrary files — plus a federation layer that
publishes to and pulls from external registries (npm, PyPI, OCI, GitHub) when you opt in.
One CLI, one grammar, one auth flow over many backends. Brand = command = domain: `kauk`,
served at [kauk.ai](https://kauk.ai).

> Status: **early** — the name and architecture are set; tooling is being built. The name
> is reserved as `0.0.0` placeholders — `kauk` on PyPI, `@kauk.ai/kauk` on npm (npm's
> similarity filter refuses the unscoped `kauk`); the real CLI ships at `0.1.0`.

## Configuring a repository

Every repository that uses kai has one file at its root, `.ai.toml`. It says what the
repository is and what packages it consumes, and it is the only configuration file there
is — no lock file, nothing hidden elsewhere. `kai install` appends a block to it; the
rest of the file is yours.

You can also manually manage your dependencies using the `.ai.toml` file — see
[`docs/ai-toml.md`](docs/ai-toml.md) for what goes in it: naming your project, the shapes
a `source` can take, taking only part of a package, and what turns a repository into a
package other repositories can install.

## Design in one line

Bind the *workflow*, not the *secrets* — one interface reaches every backend, but each
backend's credentials stay on your machine (OAuth device flow), never gathered into one
hoard. See `ARCHITECTURE.md`.

## Layout

- `bin/kaukea` — the bash stopgap that vendors and lays file packages until `0.1.0`, invoked as **`kai`** (`kauk` stays as the backup alias):
  `init` / `install <owner>/<repo> | <uri> | <path>` / `update [--pull|--push]`, also
  spelled `sync`.
  Sync pulls with rebase, applies each package's pending migrations itself (in
  order, watermarked — anything it cannot finish is recorded as an ask for the
  next session, never a nag), heals laid links whose source moved, sweeps clean
  orphaned clones, and lays; `--push` publishes your local edits, explicitly
  and only then; a source naming anything but `@HEAD` is left where it is until
  the versioning work exists. `.ai.toml` is the one configuration file: its root
  table says what the repository is (`name`, `type`), and each `[[dependency]]`
  block says what it consumes — `source` of `owner/repo` (resolved to GitHub), a
  git URI, or a local path, with an optional `include = ["<category-path>", …]`
  on git sources. Without an include, everything installs. Sync converges and
  lays; it never publishes your local edits to a source. You do not have to run
  it to get started: the packages a repository declares are cloned at session
  start, into the git folder rather than the working tree, so a fresh clone or a
  brand-new worktree reaches its packages without a sync. Every worktree shares
  that folder and therefore the same clone; each checkout reaches it through
  `.ai/repositories/`, which is ignored and never committed. A laid artifact is a
  link into the package it came from, so editing one edits that package: your
  change is committed there and rebased onto its updates. When both sides have
  changed the same lines the update stops and waits, and `--abort`, `--automerge`
  or `--resolve` (optionally `mine` or `theirs`) settle it. Nothing is ever lost,
  because every version is in a commit.
- `docs/package-format.md` — **what a package is.** A package is a repository of files
  that knows nothing about kauk: its contents are the convention directories
  `skills/ agents/ hooks/ tools/ files/`, and anything outside them is ignored. There is
  no manifest to write.
- `.ai.toml` — the one configuration file: identity in the root table, `[[dependency]]`
  blocks for what it consumes. Yours to edit; `kai install` only ever appends a block.
  Written up in [`docs/ai-toml.md`](docs/ai-toml.md).
- `namespace-reservation/` — the PyPI + npm placeholder packages that reserve the `kauk`
  name. Publish steps in `namespace-reservation/UPLOAD.md`.
- `site/` — the `kauk.ai` projection (GitHub Pages / static host); one repo serves all
  `kauk.ai/<pkg>` pages.
- `docs/` — `ai-toml.md` (the configuration file), `package-format.md`, the board
  (`TODO.md` + sidecars), `decisions.md`, and `naming.md`.
- `lib/` — the arithmetic of sources, identifiers and link targets, as pure
  functions of their arguments.
- `spec/` — the questions every implementation of kai must answer, as data rather
  than as one language's tests; `tests/unit-names.sh` is the runner for the shell
  one, and needs no repository, package or network.
- `tests/` — fixture-driven checks; `tests/convention-reader.sh` covers distribution,
  idempotence, pruning, collisions and self-publishing, and
  `tests/config-migration.sh` covers the move onto one configuration file.

## Install

_Not yet published._ The reservation stubs are placeholders only; do not `pip install kauk`
or `npm i @kauk.ai/kauk` expecting functionality until `0.1.0`.
