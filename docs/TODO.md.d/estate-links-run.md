- created: 2026-08-19
- created_by: fable-5 (operator-ordered close follow-up, migrations-at-sync)

## Blockers

Queued behind [[fleet-settings-wiring]] (operator sequencing order, 2026-08-18:
"sorted first before we touch any repository anymore").

## Questions

_None — scope ruled at the migrations-at-sync close._

## Findings

- OPERATOR ORDER (2026-08-20): reset all repositories from manual changes now
  implemented by migrations — the estate must reach its state THROUGH the
  shipped migrations, never through hand fixes that mask whether they work.
  Applied: SignMc's hand-deleted debris links reverted (restored dangling, for
  the migrations + DEBRIS ruling to handle by script). Judged not-manual and
  left standing: kauk's own link heal (performed by kai sync itself), the kai
  PATH symlink (direct operator order), orchard's files/ conversion
  (source-side package structure, not consumer state — its hand application
  is already the Decision-055 grievance on record).
- SignMc pilot already ran clean (engine correct no-ops, 82 links laid); its two
  stopgap DEBRIS links were deleted BY HAND on the operator's direct order
  2026-08-19 — the run's scripted delete step is already satisfied for SignMc.
- kauk itself proven: branch binary clean over main, pending migration applied
  by sync at ingest, watermark advanced, no asks.

## Proposal

Run `kai sync` (shipped engine) across every remaining consumer repository —
stale-laid-links step 3. Verify per repo: no dangling laid link, no orphan
clone unreported, migrations applied, watermark advanced. DEBRIS findings are
reported for a ruling, never auto-deleted.

## Testing

Per-repo: `find` for dangling links into .ai/repositories returns nothing;
watermark files current; sync re-run is a no-op.
