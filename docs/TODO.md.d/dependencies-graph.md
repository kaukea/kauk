- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

Depends on [[categories-rename]] for the selection tree.

## Questions

_None open — the spec is ruled._

## Findings

Cross-artifact needs are undeclared everywhere today.

## Proposal

`dependencies: {skills, agents, tools}` in artifact metadata; selection is a request and the installed set is its closure. For an agent the same list is its capability boundary (Decisions 029/030).

## Testing

Selecting one skill pulls its closure and reports the additions; an agent cannot call an undeclared skill.
