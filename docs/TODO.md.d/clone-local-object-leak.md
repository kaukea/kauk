- created: 2026-07-17
- created_by: opus-4.8
- created_during: orchids board work (cross-repo handoff)
- completed: 2026-08-18
- completed_during: decision-050-prelaunch

### Why cancelled

Not decided against — FOLDED (operator, 2026-08-18, Decision-050 pre-launch round):
the fix shares `bin/kaukea`'s sync path with the combined sync feature, so its scope
ships as steps of [[migrations-at-sync]] (the carrier) rather than a standalone
feature. Rulings carried over there: `--no-local` (not `file://`), fetch/pull leak
tested in-feature, existing `.ai/repositories/` clones re-cloned on upgrade. The
open questions below are all answered by those rulings.

## Blockers
- None. One-flag change; no design needed.

## Questions
- ~~`--no-local` or rewrite local-path origins to `file://`?~~ Ruled 2026-08-18:
  `--no-local`, the smaller change.
- ~~Does `git fetch`/`pull` against a local-path origin leak the same way on `sync`?~~
  Ruled 2026-08-18: tested inside the combined feature; fixed identically if it leaks.
- ~~Existing clones under `.ai/repositories/`: re-clone on upgrade, or leave?~~ Ruled
  2026-08-18: re-clone on upgrade — gitignored and disposable.

## Findings
**Verified 2026-07-17 against a canary in a scratch repo — not inferred:**

| operation | non-reachable objects travel? |
|---|---|
| `git push <remote> main` (default) | no |
| `git clone --no-local <path>` | no |
| `git clone file://<path>` | no |
| `git clone <local-path>` (plain) | **YES** |
| `git clone --no-hardlinks <path>` | **YES** (does not help) |
| `git push --mirror` | **YES** (expected) |

- A plain local-path clone takes git's **local hardlink/copy optimisation** and copies
  the WHOLE object store, including unreachable objects. Refs do NOT come across (the
  recipient sees only `refs/heads/*`), so the clone looks clean to every ref-based
  check — but the objects are present and **`git fsck --lost-found` surfaces them
  blind, no SHA needed, content fully readable.**
- **kauk does exactly this today.** `bin/kauk:237` — `git clone --quiet "$origin"
  "$clone"` — and real `.ai.toml` origins are local paths (e.g.
  `origin = "/home/sudoku/src/serialseb/orchids"`). Same at `:215` for the self-clone.
- **This already matters, with no new features.** Every vendored clone under
  `.ai/repositories/` carries the source repo's dangling objects: amended-away commits,
  and anything a `pre-publication-cleanup`-style history scrub thought it had removed.
  A source repo that scrubs its history does NOT scrub the clones already made from it.
- **It also blocks an orchids design.** orchids is specifying `refs/sensitive/<id>` —
  sensitive task content on a ref outside `refs/heads/*`, kept off remotes by not being
  pushed. That property is real for push and false for local clone, so kauk must clone
  via the pack path before `refs/sensitive/*` can be trusted. See orchids
  `cross-repo-inbox`.

## Proposal
Clone through the pack path whenever the origin is a local filesystem path: add
`--no-local` at `bin/kauk:237` and `:215` (or normalise such origins to `file://`).
Then test whether `fetch`/`pull` on `sync` has the same exposure and fix it the same way
if so.

## Testing
Reproduce the canary test: source repo with an object reachable only from a non-branch
ref (or an unreachable dangling object); clone it with kauk; assert
`git fsck --lost-found` in the clone surfaces nothing and `git cat-file -e <sha>` fails.
Regression: a normal `kauk install` from a local path still lays every skill correctly —
`--no-local` costs disk (no hardlinks) and must not break the migration/adoption paths
in `cmd_install`.
