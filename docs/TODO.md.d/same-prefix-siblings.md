- created: 2026-08-26
- created_by: opus-5
- created_during: f/estate-links-run
- completed: 2026-08-26
- completed_during: f/same-prefix-siblings
- size: s

## Blockers

(none)

## Questions

_None._

## Findings

Result: merged to main on 2026-08-26, preserved under
archive/same-prefix-siblings.

- Regression introduced hours earlier by [[migrations-resolve-late]], caught in
  the estate run: advancing the watermark after EVERY migration looked like
  useful resumability, but the older `<date>-<slug>` filenames carry no NN and
  so all reduce to the same `<date>-0` prefix. Applying the first of them moved
  the watermark onto that prefix, and its siblings — which had not run — were
  then indistinguishable from it and skipped for good.
- serialseb/seb.secrets stalled at `2026-08-18-0` because of it, with the two
  2026-08-18 siblings never applied; one of them is the orchids-to-orchard
  rename, so its store was left pointing at a package that no longer exists.
- The watermark now stays where the repository stood on entry for the whole
  pass, and the basenames applied during the pass are remembered separately.
  Both are needed: the prefix says where the repository stood, the list
  sequences within the pass. The watermark advances once, at the end.
- Cost accepted: an interrupted pass restarts from the entry watermark rather
  than resuming mid-stream. Migrations detect for themselves whether they still
  apply, so a re-run is a series of no-ops.

## Proposal

Hold the watermark still for the duration of a pass, and remember what has run
within it.

## Testing

`tests/migrations-engine.sh` gains a package with three migrations on one date
in the old naming form plus one on the next day: all four run, in filename
order, and none re-runs on a resync. 313 assertions across seven suites at
branch HEAD, all green.

## Changelog entry

#### 🐛 `f/same-prefix-siblings` → `archive/same-prefix-siblings`

Migrations named in the older `<date>-<slug>` form carry no NN and so share one
watermark prefix. Advancing the watermark after each migration made the first
of them indistinguishable from its siblings, which were then skipped for good —
one estate repository stalled with the orchids-to-orchard rename never applied.
The watermark now stays where the repository stood on entry for the whole pass,
the basenames applied during the pass are remembered separately, and the
watermark advances once at the end.

_Board: `same-prefix-siblings` · regression from `migrations-resolve-late` ·
found by `estate-links-run`._

## Readme delta

None.
