- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

None.

## Questions

_None open — the spec is ruled._

## Findings

`AGENTS.files.md` §Migrations never specified who executes or when. The watermark is a single global scalar and the pending count is computed against a stale clone.

## Proposal

Execute at sync time inside kauk; per-repository watermark; order pull → apply → rebase → write; structured wrapper over existing prose, no rewrite (Decision-022).

## Testing

Two sources with interleaved dates both migrate correctly; re-running is a no-op; a codified step is asserted twice in a fixture.
