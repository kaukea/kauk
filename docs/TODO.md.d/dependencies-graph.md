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

The stakes rose (operator, 2026-08-15): the message bus moves to its OWN
repository, so orchids' agents depending on courier skills/tools becomes the
live cross-package case — package-level dependencies (Decision-038, build
authorised by the operator's 2026-08-13 go) are what let the bus repo be a
dependency instead of a copy. This is the main work of the current push.

Reference grammar ruled (Decision-047): bare artifact name within the own
package; `<package>/<category>/…/<artifact>` across packages. Flat
`dependencies-*` keys acceptable if the nested map fights the thin parser.
