# kauk

**KAUK** is a package platform built as a control plane: a native index for first-class
artifacts — packages, **skills**, and arbitrary files — plus a federation layer that
publishes to and pulls from external registries (npm, PyPI, OCI, GitHub) when you opt in.
One CLI, one grammar, one auth flow over many backends. Brand = command = domain: `kauk`,
served at [kauk.ai](https://kauk.ai).

> Status: **early** — the name and architecture are set; tooling is being built. The name
> is reserved as `0.0.0` placeholders — `kauk` on PyPI, `@kauk.ai/kauk` on npm (npm's
> similarity filter refuses the unscoped `kauk`); the real CLI ships at `0.1.0`.

## Design in one line

Bind the *workflow*, not the *secrets* — one interface reaches every backend, but each
backend's credentials stay on your machine (OAuth device flow), never gathered into one
hoard. See `ARCHITECTURE.md`.

## Layout

- `bin/kauk` — the bash stopgap that vendors and lays file packages until `0.1.0`:
  `init` / `install <owner>/<repo>` / `sync` / `resolve`.
- `docs/package-format.md` — **what a package is.** A package is a repository of files
  that knows nothing about kauk: its contents are the convention directories
  `skills/ agents/ hooks/ tools/ files/`, and anything outside them is ignored. There is
  no manifest to write.
- `package.toml` — declares that a repository *is* a package (name, title, description).
- `namespace-reservation/` — the PyPI + npm placeholder packages that reserve the `kauk`
  name. Publish steps in `namespace-reservation/UPLOAD.md`.
- `site/` — the `kauk.ai` projection (GitHub Pages / static host); one repo serves all
  `kauk.ai/<pkg>` pages.
- `docs/` — the board (`TODO.md` + sidecars), `decisions.md`, and `naming.md`.
- `tests/` — fixture-driven checks; `tests/convention-reader.sh` covers distribution,
  idempotence, pruning, collisions and self-publishing.

## Install

_Not yet published._ The reservation stubs are placeholders only; do not `pip install kauk`
or `npm i @kauk.ai/kauk` expecting functionality until `0.1.0`.
