- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

None.

## Questions

_None open — the spec is ruled._

## Findings

Nothing kauk writes outside the clone identifies itself, so an uninstall cannot retract what it placed and the placement record cannot be rebuilt.

## Proposal

Every write outside the clone carries `:kauk:` with origin and sha. Binaries get a committed per-file `<file>.kauk` sidecar. Scope on the Claude path is `files/` only (Decision-040).

## Testing

Delete the placement index; a scan rebuilds every entry. An orphaned sidecar is detected as stale.

### Why cancelled

Operator ruling (2026-08-21): the tool writing its own name on anything
provides no benefit to anyone. No nuggets, no generated-by headers.
- completed: 2026-08-21
