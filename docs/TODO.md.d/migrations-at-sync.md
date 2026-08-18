- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

None.

## Questions

_None open — the spec is ruled._

## Findings

`AGENTS.files.md` §Migrations never specified who executes or when. The watermark is a single global scalar and the pending count is computed against a stale clone.

Decision-050 pre-launch bloom (2026-08-18): converged with overall SE 0.68, band
"lower" — the numeric band reflects the operator truncating the question round by
ratifying the drafted plan wholesale, not open disagreement; item parameters are
LLM-assumed, uncalibrated (v1 caveat). Launch sizing recommendation: L, fable-5,
high effort.

Decision-055 (2026-08-18) makes this task the owner of migration application and
URGENT: kai owns the applying — each migration a script (or markdown carrying its
script), applied in order, watermark dates set by the tool, identical whichever
agent (or none) is present; agents hold no essential step. Live failure that
forced the ruling: kauk's convention-packages migration never executed in orchard
(no channel), and hand-application drifted from the scripted step (settings.json
destination) — see stale-laid-links and package-migration-reach (cancelled into
this task).

## Proposal

**Combined launch (operator, 2026-08-18, Decision-050 pre-launch round): this task is
the carrier of ONE feature that also delivers [[stale-laid-links]] (its sidecar keeps
its own scope) and absorbs the former [[clone-local-object-leak]] as steps — one
branch, one close.** The interlock is real: all three edit `bin/kaukea`'s sync path.

Execute at sync time inside kauk; per-repository watermark; structured wrapper
over existing prose, no rewrite (Decision-022).

Application ORDER corrected at launch review (operator, 2026-08-18, replacing
the earlier pull → apply → rebase → write): you apply WHERE EVERYONE IS —
migrations already pending run against the shared state before local work is
replayed; any migration NEWLY ARRIVED with this pull runs AFTER the rebase,
on the rebased result, so every consumer experiences the same sequence.
Applying new migrations before the rebase is inconsistent (local edits made
against pre-migration shapes would replay onto post-migration state). So:
fetch → apply pre-existing pending migrations → rebase local work onto the
new head → apply the newly arrived migrations → write the watermark.

Absorbed clone-leak steps (rulings 2026-08-18, from that task's sidecar):

- Clone through the pack path for local filesystem origins via `--no-local` (the
  smaller change; `file://` normalisation rejected) at both clone sites in `bin/kaukea`.
- Test whether `fetch`/`pull` on sync leaks the same way; fix identically if so.
- Existing clones under `.ai/repositories/` are re-cloned on upgrade (they are
  gitignored and disposable).

The migration's filename date — and with it the derived package version and the
managed plugin `version` — is stamped at push time by the publish step, not at
authoring time (Decision-044). In-branch the date is provisional.

## Testing

Confirmed as drafted (operator, 2026-08-18). Two sources with interleaved dates both
migrate correctly; re-running is a no-op; a codified step is asserted twice in a fixture.
The combined feature also carries [[stale-laid-links]]'s fixture + estate walk and the
clone-leak canary (source repo with an unreachable object; clone via kai; assert
`git fsck --lost-found` in the clone surfaces nothing) plus the regression check that a
normal install from a local path still lays every skill.

## Decision entries

- 2026-08-18 `#launch` `#sync`: migrations-at-sync, stale-laid-links, and the former
  clone-local-object-leak ship as ONE feature (carrier: migrations-at-sync) — they
  interlock in `bin/kaukea`'s sync path. Clone-leak mechanism: `--no-local`; existing
  vendored clones re-cloned on upgrade. (Operator, Decision-050 pre-launch round.)
