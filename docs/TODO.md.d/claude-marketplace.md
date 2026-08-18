- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

Depends on [[hooks-declarative]] for the wiring it embeds.

## Questions

_None open — the spec is ruled._

## Findings

Placement into `.claude/` plus `settings.json` edits cannot express hook addition or removal cleanly, and requires the user to learn kauk syntax.

## Proposal

Transform each package to a plugin and publish into a kauk-maintained local marketplace, regenerated as sources change. Nothing is linked on this path; `files/` still lands in the repo (Decision-040).

## Testing

Adding a source regenerates the marketplace; `/plugin marketplace update` takes it; the plugin's hooks fire; removing the source removes the entry.

Operator, 2026-08-18: the docs' "plugins cannot ship rule/memory markdown"
does not bound this path — plugins ship their own hooks and settings, and a
plugin's startup hook can ADD the rule files/context itself. Rules can ride
the plugin channel via its hooks.

Operator insight (2026-08-18), raising this task's stakes: the plugin path
happily solves the UPDATE problem — updating means packaging to the
filesystem under a new id/version and Claude's native update flow does the
rest; notifications become a non-problem (which likely supersedes
[[update-notify]]). Discussion scheduled once kauk is orcharded
([[adopt-orchard-here]]). Hooks refactor is ruled LOW priority and no longer
gates a first cut conversation.
