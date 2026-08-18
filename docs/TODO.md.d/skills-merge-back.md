- created: 2026-08-17
- created_by: fable-5 (operator caveat, estate-sweep go)

## Blockers

None to start; BLOCKS the round-two migration (org move, orchids skill tour):
one codebase first.

## Questions

_None open — the sweep's BLOCKED reports supply the inventory._

## Findings

Operator caveat (2026-08-17): the skills have diverged across the estate —
repos carry local copies that drifted from orchids — and must be merged back
into orchids so there is ONE codebase before the solutions migrate. The
estate sweep's report-and-skip output enumerates every diverged file.

## Proposal

From the sweep's BLOCKED inventory: merge each diverged copy back into
orchids through its own workflow, then re-sync the repo so the link replaces
the copy. kai resolve lists pairs side by side per repo.

## Testing

After the pass, a sweep across the estate reports zero BLOCKED destinations
for orchids-owned artifacts.
