- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

Depends on [[categories-rename]] for the selection tree.

## Questions

_None open — the spec is ruled._

## Findings

Cross-artifact needs are undeclared everywhere today.
- Parked here by the operator (2026-08-26, during config-spec-implementation):
  a package declaring a dependency on ANOTHER package has no home any more.
  `package.toml` carried `dependencies = ["<owner>/<repo>"]` and that file is
  deleted, so `kai` no longer installs anything on a package's behalf — a
  consumer must declare every package it wants in its own `.ai.toml`. Whether
  the declaration returns as an ordinary `[[dependency]]` block in the
  package's own file, or as something else, waits for this work. The
  cross-package ARTIFACT closure is unaffected and still resolves across the
  packages a consumer has installed.

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

## Result (reader-select, 2026-08-16)

The kauk half shipped on `f/reader-select` → `archive/reader-select`:
dependency closure over flat `dependencies-<kind>:` keys and the nested map,
agents' `skills:` counted, bare names in-package, name-rooted paths across
packages, package.toml dependencies auto-installing their sources. Tested:
fixture suite rewritten for the model, 56/56. Remaining on this task: the
capability-boundary ENFORCEMENT (transpiler territory, Decision-030) and the
orchids-side declarations (round two).

## Changelog entry (staged)

#### ✨ `f/reader-select` → `archive/reader-select`

The reader lays what you select, and nothing else. `.ai.toml` becomes
defaults-only — `[sources."owner/repo"]` resolves to GitHub, a full path is
local, an `origin` key is refused — and each source carries only the
operator's `select` list of category paths. Laying happens after selection
plus dependency closure: flat `dependencies-<kind>:` frontmatter keys (or the
nested map), agents' `skills:` lists, name-rooted `package/…/artifact`
references across packages, and `package.toml` dependencies pulling their
sources in. Sync stops pushing local clone edits — that becomes the explicit
push verb's job. Ships `migrations/2026-08-16-defaults-only-aitoml.md`
converting existing files.

_Board: dependencies-graph, categories-rename · Decisions 046-049._

## Readme delta (staged)

The README's usage section still documents `kauk install <owner>/<repo>
[<origin>]` and an origin-keyed `.ai.toml`. It needs: the two source-key
forms, the `select` key with category paths, and the note that sync never
publishes local edits.
