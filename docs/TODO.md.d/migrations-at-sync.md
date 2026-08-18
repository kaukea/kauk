- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

None.

## Questions

_None open — the spec is ruled._

## Findings

`AGENTS.files.md` §Migrations never specified who executes or when. The watermark is a single global scalar and the pending count is computed against a stale clone.

Decision-055 (2026-08-18) makes this task the owner of migration application and
URGENT: kai owns the applying — each migration a script (or markdown carrying its
script), applied in order, watermark dates set by the tool, identical whichever
agent (or none) is present; agents hold no essential step. Live failure that
forced the ruling: kauk's convention-packages migration never executed in orchard
(no channel), and hand-application drifted from the scripted step (settings.json
destination) — see stale-laid-links and package-migration-reach (cancelled into
this task).

## Proposal

Execute at sync time inside kauk; per-repository watermark; order pull → apply → rebase → write; structured wrapper over existing prose, no rewrite (Decision-022).

The migration's filename date — and with it the derived package version and the
managed plugin `version` — is stamped at push time by the publish step, not at
authoring time (Decision-044). In-branch the date is provisional.

## Testing

Two sources with interleaved dates both migrate correctly; re-running is a no-op; a codified step is asserted twice in a fixture.
