- created: 2026-08-18
- created_by: fable-5 (adoption readiness walk)

## Blockers

None — and deliberately the first task to run THROUGH the orchard topology
in this repository ([[adopt-orchard-here]]).

## Questions

_None open — orchard's own settings.json is the reference; deviations
surface at the plan gate._

## Findings

Readiness walk (2026-08-18): fleet agent defs, dispatch tooling, couriers
and hooks are all laid in kauk; hook wiring currently rides the operator's
machine-wide settings. kauk has no repo-level .claude/settings.json —
orchard's 78-line fleet wiring (permission mode, courier lifecycle,
question broker mounts) has no counterpart here, correctly unshipped per
Decision-019.

## Proposal

Author kauk's own .claude/settings.json from orchard's as the reference,
adapted to this repository; run the work as the first gardener-dispatched
task here.

## Testing

A fleet session in kauk fires its own wiring: courier loads, lifecycle
hooks run, permission mode holds — observed live by the operator.
