# kauk

**KAUK** is a package platform built as a control plane: a native index for first-class
artifacts — packages, **skills**, and arbitrary files — plus a federation layer that
publishes to and pulls from external registries (npm, PyPI, OCI, GitHub) when you opt in.
One CLI, one grammar, one auth flow over many backends. Brand = command = domain: `kauk`,
served at [kauk.ai](https://kauk.ai).

> Status: **early** — the name and architecture are set; tooling is being built. The
> `kauk` name is reserved on PyPI and npm as `0.0.0` placeholders; the real CLI ships at
> `0.1.0`.

## Design in one line

Bind the *workflow*, not the *secrets* — one interface reaches every backend, but each
backend's credentials stay on your machine (OAuth device flow), never gathered into one
hoard. See `ARCHITECTURE.md`.

## Layout

- `namespace-reservation/` — the PyPI + npm placeholder packages that reserve the `kauk`
  name. Publish steps in `namespace-reservation/UPLOAD.md`.
- `site/` — the `kauk.ai` projection (GitHub Pages / static host); one repo serves all
  `kauk.ai/<pkg>` pages.
- `docs/` — the board (`TODO.md` + sidecars), `decisions.md`, and `naming.md`.

## Install

_Not yet published._ The reservation stubs are placeholders only; do not `pip install kauk`
or `npm i kauk` expecting functionality until `0.1.0`.
