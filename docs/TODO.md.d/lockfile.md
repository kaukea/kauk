- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

None.

## Questions

- Can a migration meaningfully mend a RUNNING session's already-loaded state? The
  operator doubts it (2026-08-12); observe in practice rather than design for it.

## Findings

`.ai/repositories/` is gitignored, so a fresh clone has nothing to scan and a source that placed no files leaves no trace anywhere.
- Parked here by the operator (2026-08-26, during config-spec-implementation):
  a dependency source may end in `@HEAD`, `@branch` or `@tag`, but only `@HEAD`
  is acted on. Anything else leaves the clone exactly where it is and lays what
  is already there, announcing that it waits for this work. Implemented that
  way in `bin/kaukea` (`dep_ref`, `sync_source`) and covered by
  `tests/convention-reader.sh`; making a branch or tag actually resolve is this
  task's to do.

## Proposal

Write a committed lock recording each repository and its resolved head. The only committed file kauk writes; carries the do-not-edit header `.ai.toml` loses (Decision-023).

The lock is also the upgrade pin (Decision-043): symlinks resolve through a checkout
pinned to the locked head; `sync` converges to the lock and never changes content
unrequested; `update` moves the lock, runs pending migrations (Decision-022), and
warns — without repairing — when the delta renames or removes agents/skills while
sessions are running.

## Testing

Fresh clone plus lock reproduces the same resolved heads; a self-published package records no head.

Deferred whole (Decision-051, 2026-08-16): head-tracking only until the
versioning piece — head vs tags, publish story, pins — is worked as one. A
ref'd source is simply left untouched.

TOML shape for whenever this work runs (operator, 2026-08-16): keyed tables in
the house pattern — `[repositories."<owner>/<repo>"]` — never the old
`[[repositories]]` array-of-tables sketch.
## Result (sync-pin, 2026-08-16)

Shipped on `f/sync-pin` → `archive/sync-pin` as the DEFERRAL's counterpart:
sync stays the manual pull-rebase-and-lay, --push is the explicit publish
(pull-only refuses), --pull narrows to taking, migrations run after a
successful pull with removal warnings, and a ref'd source is left untouched.
No lock exists; this task holds the whole deferred versioning piece. Tested:
fixture suite, 71/71.

## Changelog entry (staged)

#### ♻️ `f/sync-pin` → `archive/sync-pin`

Sync is what sync was; push is deliberate. `kai sync` pulls with rebase, runs
pending migrations (advancing the per-package watermark), warns when an
update removes or renames artifacts, and lays by selection. `--push` is the
one separate act — rebase, then publish local edits to the source; pull-only
packages refuse it. A source carrying `ref` — a version, tag, or commit — is
left entirely untouched until the versioning work exists (Decision-051), and
the "updates available" notice moves to a background check boarded as
update-notify.

_Board: lockfile (deferred whole), update-notify · Decisions 049–051._

## Readme delta (staged)

The README's bin/kauk line gains: `sync [--pull|--push]` — sync pulls with
rebase and lays; --push publishes local edits explicitly; a ref'd source is
never touched.
