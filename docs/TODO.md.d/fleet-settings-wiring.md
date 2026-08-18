- created: 2026-08-18
- created_by: fable-5 (adoption readiness walk)

## Blockers

None — and deliberately the first task to run THROUGH the orchard topology
in this repository ([[adopt-orchard-here]]).

## Questions

- Bootstrap of the FIRST session (tentative operator direction, 2026-08-18 —
  confirm at the scope round): `--settings` covers every fleet-SPAWNED agent,
  but the session the operator starts by hand cannot re-settings itself — a
  subprocess is the only way. Proposed shape: no `--agent gardener` at the
  door; instead a VISIBLE `gardener` skill in a plain claude session that
  spawns the real gardener session with `--settings` (and the agent def) into
  its own window and hands over — the same dispatch pattern the fleet already
  uses for landscapers and sowers. Open edge: where the skill comes from on a
  fresh machine (installing kai vs installing orchard — undecided). Relates to
  orchard's summon-restarting design, which the operator ruled is designed
  with him — this is that design starting.

## Findings

Readiness walk (2026-08-18): fleet agent defs, dispatch tooling, couriers
and hooks are all laid in kauk; hook wiring currently rides the operator's
machine-wide settings. kauk has no repo-level .claude/settings.json —
orchard's 78-line fleet wiring (permission mode, courier lifecycle,
question broker mounts) has no counterpart here, correctly unshipped per
Decision-019.

## Proposal

Superseding mechanism (operator, 2026-08-18): the fleet launches every agent
itself, and `claude --settings <file>` applies a custom settings file
per-invocation (partial merge — omitted keys keep their file-based values).
So the fleet's hooks and permission wiring ride the SPAWN COMMANDS — dispatch
tooling appends `--settings` pointing at the package's own settings file —
and need not live in the repository's `.claude/settings.json` at all. Author
the package settings file and wire the dispatch paths accordingly; the
repository's own settings.json stays project-owned (see
[[settings-lay-clobbers]] — its JSON Patch shrinks to whatever must affect
the operator's own interactive session, possibly nothing). Run as the first
gardener-dispatched task here.

## Testing

A fleet session in kauk fires its own wiring: courier loads, lifecycle
hooks run, permission mode holds — observed live by the operator.
