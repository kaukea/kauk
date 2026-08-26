- created: 2026-08-19
- created_by: fable-5 (operator-ordered close follow-up, migrations-at-sync)

## Blockers

~~Queued behind [[fleet-settings-wiring]]~~ — merged 2026-08-24.

Two prerequisites found by trying the run on 2026-08-26, both now on main:
[[migration-engine-rules]] (a repository that has never run a migration could
not receive one) and [[settings-lay-clobbers]] (the stream would have planted a
settings file in every repository). A consumer receives migrations by pulling
this repository, so both had to land on main BEFORE the estate is touched.

## Questions

_None — scope ruled at the migrations-at-sync close._

## Findings

- Trial runs against SafeKeepIt/SignMc, 2026-08-26, each reverted to a verified
  byte-identical state afterwards: the first died before writing anything; the
  second replayed 22 migrations and converted the configuration file; the third
  replayed 26 and ended with no dangling link and no settings file. Two of the
  shipped migrations (the lock-file drop and the header removal) were still
  unmerged at that point, so their first real exercise is the estate run
  itself. SignMc was left exactly as found and is NOT converged.

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
