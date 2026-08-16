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
