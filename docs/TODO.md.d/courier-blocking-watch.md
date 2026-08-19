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

## Proposal

Make the courier's watch block long by default in the orchard courier
definition: one blocking watch, silent rearm on timeout, speak only on real
inbound traffic.

## Testing

An idle courier produces zero parent wake-ups over a long window; an inbound
message still arrives immediately.
