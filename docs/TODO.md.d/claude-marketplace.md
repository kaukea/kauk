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
