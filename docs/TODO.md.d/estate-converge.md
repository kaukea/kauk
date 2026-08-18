- created: 2026-08-15
- created_by: fable-5 (operator direction)

## Blockers

None. Mirrors surveyed clean 2026-08-15 (no local edits, nothing ahead) — the
push-back contamination risk is empty.

## Questions

- Push each repo's convergence commit to its origin during the sweep
  (recommended), or commit locally and batch pushes later?

## Findings

Nine repos pinned at orchids 76ee635 (2026-07-24, bus era, forensic skills
included); SignMc at 2440d9c; packages near-current. forensics EXCLUDED
(Decision-145 + its mirror is the orphaned forensic corpus's only home).

## Proposal

Per repo (11): run current bin/kauk sync (mirrors to head, relink by
convention, prune dead links — forensic + renamed-away artifacts drop off),
convert the watermark per-package (Decision-143 guarded script), record
orchids current, one convergence commit on the repo's main. BLOCKED conflicts
reported to the operator, never resolved. This is the ground the message-bus
fix stands on: every consumer running current transport code.

## Testing

Post-sweep, each repo's .claude links resolve into a mirror at orchids head;
no forensic skill links remain outside forensics; migrations-pending reports
nothing.

## Result (2026-08-18)

Nine repos converged on their mains with the finished kai tool — mirrors
pulled to orchids 7ece187 / kauk current, all pending package migrations run
through the per-package watermark, .ai.toml converted to defaults-only,
bus-era and forensic links pruned, one scoped commit each: SignMc fe91d1c,
dns 088ec97, Panopticon a8cf874, TitanShield a8e4d00, fastcut 822512e,
packages f596cae, seb.crash 94cd6d7, seb.house aeadc70, seb.throwy 14c1eaa.
Pushed: SignMc, TitanShield, fastcut, packages, seb.house. Local-only (no
origin remote exists): dns, Panopticon, seb.crash, seb.throwy. Exceptions
for the operator: kmscon-pi was checked out on feat/console-launcher (its two
convergence commits sit there, main untouched); serialseb.voice on
f/jabra-gnp-map, not swept. forensics untouched by design.

The BLOCKED inventory came back EMPTY across all nine — the diverged skill
copies the merge-back task expects do not collide at laid names; finding them
needs a diff of committed real files against orchids, its own pass.
