- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

Rename lands in orchids via its own workflow; kauk ships the reader.

## Questions

_None open — the spec is ruled._

## Findings

All 19 orchids skills declare `roles:`; none of the 10 agents declare anything. The word is inherited from the retired `dev|infra|org` layer.

## Proposal

Read `categories:` instead of `roles:`, node list unchanged; agents gain the key. Migration carries the rename (Decision-024).

The point of the mechanism (operator, 2026-08-13): token economy — selection by
category is what keeps a project from carrying skills it has no use for (a dev
repo does not load forensics). Nothing in the stopgap selects; sync currently
links everything a package ships, so every consumer pays for every skill.

## Testing

A skill and an agent both declare placements and are selectable by category.

Round of 2026-08-15 (Decision-047): the tree is single-rooted at `general`;
selection semantics inherit the ancestors-own-artifacts rule, so root
artifacts ride every selection. Frontmatter must stay flat-parseable (thin
.NET, no YAML library). `process/workflow` → `process/orchids` is voiced,
not firm.

Round closed 2026-08-15 (Decision-048): general = catch-all (047's root
clause superseded); git → development, authoring-skills → new `writing`
category; read-agents → enforcing-rules, writing → writing-prose;
agent-behaviour rename + writing-prose's category still open (non-blocking);
two-part naming rule; per-target SKILL.<compat>.md variants are FUTURE.
