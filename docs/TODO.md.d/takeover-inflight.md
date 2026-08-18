- created: 2026-08-15
- created_by: fable-5 (operator direction)

## Blockers

None to assess; landing anything rides the owning repo's own workflow.

## Questions

- f/decision-making (Valve + DIRECTIVES, ~9400 lines): land in orchids first,
  or extract the kauk-facing half (valve installed per repo via kauk,
  Decision-141.3) and let the rest follow?
- f/delivery-restoring: content unknown to this board — assess before ruling.

## Findings

Operator direction (2026-08-15): take over the work other agents left in
flight on this codebase's turf. Unmerged in orchids worktrees:
f/decision-making (5e93de4), f/delivery-restoring (30b1be3), f/inbox-outbox
(5bd76b7 — stays with the message bus, which fixes itself once the rest is
fixed). kauk's own f/adopt-kauk-sync, f/fix-self-origin, f/kauk-sync-stopgap,
f/script-name-kauk are July-era, superseded by the convention reader —
disposition (archive-tag close vs keep) is the operator's.

## Proposal

Assess each branch against current main, report what survives, land the
survivors through their own repos' workflows, close the dead with the
archive-tag cancellation so the board stops carrying ghosts.

## Testing

Every listed branch ends either merged (its own workflow's gates) or
archive-tagged closed; none left untagged-and-forgotten.

Flag from the migrations-at-sync launch (beekeeper, 2026-08-18): Valve — the
judging role — exists only on orchard's unmerged f/decision-making branch, so
feature pipelines run without it wired; part of this takeover's scope.
