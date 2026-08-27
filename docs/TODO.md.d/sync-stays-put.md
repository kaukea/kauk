- created: 2026-08-27
- created_by: opus-5
- created_during: f/sync-stays-put
- completed: 2026-08-27
- completed_during: f/sync-stays-put
- size: s

## Blockers

(none)

## Questions

_None._

## Findings

Result: merged to main on 2026-08-27, preserved under archive/sync-stays-put.
Both defects were found by running a real sync in this repository, not by
reading.

- **A sync reached into another checkout.** `prune_links` walks the whole tree
  and stopped only at `.git` and `.ai`, so a worktree nested beneath the checkout
  looked like more of its own work. Live: a sync here rewrote 74 links belonging
  to the `estate-links-run` worktree and deleted 6 of its tracked files. Every
  link it found there really was dead, because a worktree never receives the
  package store — which is exactly why the walk must not judge them. The walk now
  stops at any directory carrying its own `.git`, which covers a worktree, a
  nested clone and a submodule alike, and is detected rather than matched by
  path: where worktrees are put is a convention of whoever made them. The
  affected worktree was restored to its prior state, tracked files and all.
- **Sync exited non-zero after succeeding.** `apply_pending_migrations` installs
  a `RETURN` trap to remove its temporary file. A `RETURN` trap set inside a
  function stays installed in the caller, so it fired again when `cmd_sync`
  returned, with `done_file` out of scope, and `set -u` ended the run — which is
  why the error named line 1196, `cmd_sync`'s own definition line. Reproduced in
  four lines with nothing but `set -euo pipefail`. Introduced by `87e2a42`, so
  every migration-applying sync since then has reported failure after doing its
  work correctly. The trap now disarms itself once it has run.

Two things that looked like defects and were not:

- The repair reporting "80 store link(s) examined, 0 repointed" while 80 were
  absolute. This repository had no watermark, and absence means every migration
  is pending, so `2026-08-19-02-relative-symlinks` ran earlier in the same pass
  and had already relativized them.
- `2026-08-12-convention-packages` moving the shared rule files into `files/`.
  That is a conversion this repository had never run, doing what Decision-015
  requires of a package. Verified idempotent across three consecutive runs: the
  first converts, the second and third are silent, content intact.

Open question for the operator, not acted on: `.ai.toml` declares this
repository as a dependency of itself by local path. Sync resolves that to the id
`kaukea/kauk` and clones it, so the kai skill arrives twice — once copied in by
self-publishing, once laid from the clone — and collides into `local:kai` and
`kauk:kai`. Both routes work as designed; the self-declaration is what makes the
duplicate.

## Proposal

Stop the dead-link repair at any nested checkout, and make the migration
engine's cleanup trap disarm itself.

## Testing

`tests/store-in-git-folder.sh` gains two cases. The first plants two dead links
in a worktree — one whose tail the source still carries, one whose tail nothing
carries, so both the repair and the removal paths are baited — runs a real sync
in the parent, and asserts both survive untouched, that the worktree is never
mentioned in the output, and that its tree is byte-for-byte as it was. The
second runs a sync that applies migrations and asserts it exits zero with no
unbound variable and nothing shaped like a shell error on the stream. 405
assertions across eight suites at branch HEAD, all green.

## Changelog entry

#### 🐛 `f/sync-stays-put` → `archive/sync-stays-put`

A sync run in one checkout reached into a worktree belonging to another session,
rewrote seventy-four of its links and deleted six of its files: the dead-link
repair walked the whole tree and stopped only at the git and package
directories, and every link it found in the worktree genuinely was dead, because
a worktree never receives the package store. The walk now stops at any directory
carrying its own git folder — worktree, nested clone or submodule — detected
rather than matched by path, since where worktrees are put is a convention of
whoever made them.

The same run ended by reporting an unbound variable after every migration had
applied cleanly. A cleanup installed for one function's own return stays
installed in its caller and fired a second time with its variable out of scope,
so every migration-applying sync since the watermark fix had exited non-zero
after doing its work. The trap now disarms itself.

_Board: `sync-stays-put` · found by running a sync · relates to
`store-in-git-folder`._

## Readme delta

None. Neither fix changes anything a reader of the README would do differently.
