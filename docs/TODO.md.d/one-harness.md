- created: 2026-08-30
- created_by: opus-5
- created_during: f/one-harness
- completed: 2026-08-30
- completed_during: f/one-harness
- size: s

## Blockers

(none)

## Questions

_None._

## Findings

Result: merged to main on 2026-08-30, preserved under archive/one-harness.

- The operator's question, which is the whole reason this exists: "how do we
  prevent you from ever doing that again?" A rule in a document had not, and a
  telemetry note had not — the note is a record for him and reaches nobody
  writing the next test.
- Ten suites each carried their own copy of the same three assertion helpers.
  That is why the same defect could be corrected in its instances three times and
  return each time: there was no single place to correct.
- One helper now, in `tests/harness.sh`, sourced by all thirteen suites.
- `tests/suites-are-sound.sh` is the mechanism: it fails if a test file defines
  its own assertion helper, re-initialises the counters, or does not source the
  shared one, and it pins the helper's own guard and the comment explaining what
  that guard cost — so the line is not tidied away by someone who does not know.
- Verified by writing a suite the old way and watching five assertions fail,
  naming each thing it did wrong, then deleting it.
- One of my own along the way, and the operator caught it: a regex run across
  thirteen files ate half of a two-line function, and I found out by running it
  rather than by reading what the transformation would produce. His standing rule
  from 2026-08-04 says to read a script end to end before running it. It applies
  to a transformation over files exactly as much as to a script handed over.

## Proposal

One assertion helper, sourced everywhere, and a suite that fails when a test file
does not use it.

## Testing

`tests/suites-are-sound.sh`, 80 assertions over the other thirteen suites. The
whole set run twice end to end: 731 assertions, no failures, identical both
times.

## Changelog entry

#### ♻️ `f/one-harness` → `archive/one-harness`

Ten suites each carried their own copy of the same assertion helpers, which is
how one defect in them could be corrected three times and return each time. There
is one copy now, in `tests/harness.sh`, sourced by every suite — and
`tests/suites-are-sound.sh` fails if a test file defines its own helper,
re-initialises the counters, or does not source the shared one. Written the old
way, a new suite fails immediately and is told which of those it did. It also
pins the helper's `pipefail` guard and the comment explaining what that guard
cost, so neither is tidied away by someone who does not know.

_Board: `one-harness` · follows `status-and-push`._

## Readme delta

The `tests/` entry should mention that suites share one assertion helper and that
`suites-are-sound.sh` enforces it.
