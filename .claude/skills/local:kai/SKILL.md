---
name: kai
description: "Run whenever the operator says install or sync kai, kauk, orchard, or a package, and at workflow start and end. Keeps the repository's vendored file packages — skills, agents, hooks, tools, shared rule files — converged with their sources through the kai CLI (`kaukea` executable; `kauk` is the backup alias): `kai init` bootstraps a repository, `kai install <owner>/<repo> | <path>` adds a package source, `kai sync` pulls with rebase and lays what the repository selected, `kai sync --push` publishes local edits to a source."
metadata:
  tags: [kai, kauk, packages, sync, install, select, vendoring]
---

# kai (the package command)

The command is `kai`; the executable ships as `kaukea`, and `kauk` remains as
the backup alias. One tool, three names, one behaviour.

## When

- The operator says install, sync, or update a package, kai, kauk, or orchard.
- At workflow start and end, so the repository's laid artifacts converge.

## What it does

- `kai init` — bootstrap this repository (creates `.ai.toml`, registers the
  tool's own source, lays).
- `kai install <owner>/<repo> | <path>` — add a source. An `owner/repo` key
  resolves to GitHub; a full path is a local working tree. After an install
  with no selection, kai prints the package's category tree — propose a
  `select` list to the operator based on the repository and the work in play.
- `kai sync` — the manual synchronisation: pull with rebase, run pending
  migrations, warn about removed artifacts, lay by selection. It never
  publishes local edits.
- `kai sync --push` — the one deliberate act that publishes local edits to a
  source (pull-only packages refuse). `--pull` narrows to taking only.
- A source carrying `ref = "…"` is never touched — versioning is deferred
  work.

## Rules

- `.ai.toml` is the operator's file: sources and `select` lists, nothing
  else. Never add an `origin` key — the source key itself says where it
  lives.
- Local edits to laid files are edits to the clone; they reach the source
  only when the operator asks for `kai sync --push`.
- A BLOCKED destination (a real file kai did not place) is the operator's to
  resolve — offer `kai resolve`, never overwrite.
