- created: 2026-08-16
- created_by: fable-5 (operator direction)

## Blockers

None.

## Questions

- Where does the background check live — a session-start hook that fetches
  quietly, a timer outside sessions, or both? Operator to rule.

## Findings

Operator direction (Decision-051 round): the "something has been updated"
notice is not the sync command's job — a background check runs from time to
time and displays when an update is available, like a package manager's
badge. Sync stays manual and quiet.

## Proposal

A quiet best-effort fetch on some cadence; when the followed head moved,
display "N incoming on <source> — kai sync" once, without applying anything.

## Testing

To be agreed at build.
