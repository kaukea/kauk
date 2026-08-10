- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

None.

## Questions

_None open — the spec is ruled._

## Findings

`.ai/repositories/` is gitignored, so a fresh clone has nothing to scan and a source that placed no files leaves no trace anywhere.

## Proposal

Write a committed lock recording each repository and its resolved head. The only committed file kauk writes; carries the do-not-edit header `.ai.toml` loses (Decision-023).

## Testing

Fresh clone plus lock reproduces the same resolved heads; a self-published package records no head.
