- created: 2026-08-19
- created_by: fable-5 (tool defect recorded at the migrations-at-sync close)

## Blockers

(none)

## Questions

_None._

## Findings

- The courier agent's default monitor polls roughly every minute instead of
  blocking, waking its parent on every idle stop. The migrations landscaper
  worked around it live (single blocking watch, silent rearm on timeout,
  speak only on a real inbound message) — the workaround is the design.

- Workaround insufficient (gardener, 2026-08-19, live): even after switching
  the courier to a 300s blocking watch, EVERY rearm stops the subagent and the
  harness fires a task-notification at the parent regardless — the wake comes
  from the agent stopping, not from what it says. The fix must keep the
  courier continuously alive across waits (a persistent monitor primitive),
  not a loop that stops and rearms.

## Proposal

Make the courier's watch block long by default in the orchard courier
definition: one blocking watch, silent rearm on timeout, speak only on real
inbound traffic.

## Testing

An idle courier produces zero parent wake-ups over a long window; an inbound
message still arrives immediately.
