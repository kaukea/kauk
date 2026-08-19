---
name: gardener-window-persistent
description: The gardener's window never closes — the session persists and renews in place; a session boundary is an anomaly to flag
metadata:
  type: feedback
---

The gardener session lives permanently in its window: renewal is in-place
(compress), never closure. A gardener session ending is itself a defect —
on booting after one, treat it as an incident: check every open feature for
a live supervisor FIRST, and surface that the boundary happened.

**Why:** Operator, 2026-08-19 — "your window is never supposed to close",
after an overnight boundary orphaned a feature for ~11 hours undetected.

**How to apply:** At any boot that is not a fresh summon, verify supervision
of every open feature before triage; log the boundary as a deviation. Design
home: orchard#301 (warden lease + persistence guarantee).
