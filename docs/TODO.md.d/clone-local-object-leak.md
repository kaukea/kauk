- created: 2026-07-17
- created_by: opus-4.8
- created_during: orchids board work (cross-repo handoff)

## Blockers
- None. One-flag change; no design needed.

## Questions
- `--no-local` or rewrite local-path origins to `file://`? Both force the pack path.
  `--no-local` is the smaller change (one flag at `bin/kauk:237` and `:215`);
  `file://` also changes what lands in `remote.origin.url`, which `cmd_install` reads
  back at `:210`.
- Does `git fetch`/`pull` against a local-path origin leak the same way on `sync`
  (`bin/kauk:327`, `:340`), or is this clone-only? **Test it** — the same optimisation
  may apply, and a clean clone that leaks on first sync fixes nothing.
- Existing clones under `.ai/repositories/` already carry whatever leaked. Re-clone on
  upgrade, or leave them? They are gitignored and disposable, which argues for re-clone.

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
