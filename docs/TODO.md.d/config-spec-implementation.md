- created: 2026-08-21
- created_by: fable-5 (operator go: "implement them all")

## Blockers

Footprint overlap with fleet-settings-wiring in bin/kaukea and .ai.toml handling
— launches on that feature's close (standing sequence, no new go needed).

## Questions

_None — the WHAT is the operator's own hand: docs/configuration-files.md
(2026-08-21) plus his three spoken answers, recorded in Findings._

## Findings

- The spec file OUTRANKS decisions/docs it contradicts (committed 5440c43).
- Operator's spoken answers (2026-08-21): (1) the tool never stamps its own
  name on anything — no generated-by headers, no provenance nuggets; (2) the
  migration watermark is a single-date COMMITTED file inside .ai/ (name
  immaterial), as previously existed — .ai/ stays gitignored for clones only;
  (3) `select` renames to `include` — an array of category paths, optional,
  omitted = everything imports.
- Corroboration in the fleet-settings stream: ".ai.toml is the user's, .ai/
  holds ours and is tracked — IS the design."

## Proposal

Implement docs/configuration-files.md in full: root-table identity
(`name`, `type = package|project`); `[[dependency]]` tables with `source`
(owner/repo | URI | local path, optional `@HEAD|@branch|@tag`) and optional
`include`; kai install appends after the last dependency; package.toml
deleted everywhere via shipped migration; committed single-date watermark
file in .ai/ replacing the-works/migrated; asks removed; MOOD out of kauk;
no tool-name stamping anywhere; laid files user-editable (push access →
push at end; none → changes stay local). All steps scripted (Decision-055).

## Testing

To be agreed at the gate: fixture consumer with [[dependency]]+include forms
(GitHub, URI, local, @ref) lays correctly; install appends; a package.toml
repo migrates clean; watermark file committed and advanced by sync; re-sync
no-op.
