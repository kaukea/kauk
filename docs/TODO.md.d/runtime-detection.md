- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

None.

## Questions

_None open — the spec is ruled._

## Findings

`.claude/` is hardcoded in six places in `bin/kauk`; there is no seam where a second target attaches.

## Proposal

Detect by `.claude/` or `CLAUDE.md`, yielding a SET of targets rather than a winner. Ask at init where nothing is detected (Decision-018).

## Testing

A repo with both markers detects once; a repo with neither prompts; a hypothetical second target is addable without touching placement.
