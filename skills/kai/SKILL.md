---
name: kai
description: "Run whenever the operator says install or sync kai, kauk, orchard, or a package, and at workflow start and end. Keeps the repository's vendored file packages — skills, agents, hooks, tools, shared rule files — converged with their sources through the kai CLI (`kaukea` executable; `kauk` is the backup alias): `kai init` bootstraps a repository and `kai init --package` also declares one that publishes artifacts of its own, `kai install <owner>/<repo> | <path>` adds a package source, `kai update` pulls with rebase and lays what the repository selected, and `kai update --push` publishes local edits back to a source. `sync` is another spelling of `update`."
metadata:
  tags: [kai, kauk, packages, update, sync, install, select, vendoring]
---

# kai (the package command)

The command is `kai`; the executable ships as `kaukea`, and `kauk` remains as
the backup alias. One tool, three names, one behaviour.

## When

- The operator says install, update or sync a package, kai, kauk, or orchard.
- At workflow start and end, so the repository's laid artifacts converge.

## What it does

- `kai init` — bootstrap this repository (creates `.ai.toml`, registers the
  tool's own source, lays).
- `kai install <owner>/<repo> | <path>` — add a source. An `owner/repo` key
  resolves to GitHub; a full path is a local working tree. After an install
  with no selection, kai prints the package's category tree — propose a
  `select` list to the operator based on the repository and the work in play.
- `kai update` — the manual convergence: pull with rebase, run pending
  migrations, warn about removed artifacts, lay by selection. It never
  publishes local edits. `sync` is another spelling of it.
- `kai update --push` — the one deliberate act that publishes local edits back
  to a source (pull-only packages refuse). `--pull` narrows to taking only.
- When an update cannot finish because both sides changed the same lines, it
  stops and waits rather than choosing: `kai update --abort` restores,
  `--automerge` proposes a merge for review, `--resolve` carries on from what
  the operator edited and will take `mine` or `theirs` instead.
- A source carrying `ref = "…"` is never touched — versioning is deferred
  work.

## Rules

- `.ai.toml` is the operator's file: sources and `select` lists, nothing
  else. Never add an `origin` key — the source key itself says where it
  lives.
- Local edits to laid files are edits to the package they came from; they reach
  the source only when the operator asks for `kai update --push`.
- A file of the operator's where a package has one of its own is replaced by the
  link, so editing it becomes an edit of that package. When both sides have
  changed the same lines the update stops and waits: `kai update --abort`,
  `--automerge`, or `--resolve` (optionally `mine` or `theirs`) settle it.
