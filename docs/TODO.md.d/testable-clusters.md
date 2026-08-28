- created: 2026-08-28
- created_by: opus-5
- created_during: f/testable-clusters
- completed: 2026-08-28
- completed_during: f/testable-clusters
- size: m

## Blockers

(none)

## Questions

One, for the operator, recorded rather than acted on: `bin/kaukea` is a declared
stopgap with "Build the real kauk CLI (0.1.0), replacing the bash stopgap" on the
board. Restructuring all of it into ports and adapters is work that 0.1.0 would
redo. This branch therefore did only the half that survives either future — the
unit tests encode behaviour the real CLI must satisfy too. Whether to carry on
into the git adapter, or to stop and let 0.1.0 inherit the tests, is the
operator's call.

## Findings

Result: merged to main on 2026-08-28, preserved under archive/testable-clusters.

- The measurements that shaped the split: 1434 lines, 90 functions, 12 informal
  sections. The coupling is lopsided — 51 `git` calls against a small filesystem
  surface (6 `readlink`, 4 `ln -s`, a handful of `mkdir`/`rm`/`cp`/`mv`/`find`)
  and a single `claude`. So there are three ports, and the one where every defect
  of the day lived is the smallest.
- Roughly a third of the functions are already pure arithmetic over names and
  paths. They needed extracting, not restructuring — which is why this was worth
  doing before any adapter work.
- `rel_target` was the seam in miniature: pure arithmetic except for finding the
  declaration file above the link. Split into `link_target` (given an anchor) and
  a caller that goes looking. The decision is now testable; the touching is not
  its business.
- All four defects of 2026-08-28 are now cases in `tests/unit-names.sh`, marked
  REGRESSION, each written as the question that should have preceded the code.
- Verified in the DEPLOYED arrangement per Decision-071, not just the repo-local
  one: the library resolves through one install symlink and through two hops, and
  a missing library fails with a legible message and a non-zero status rather
  than a raw sourcing error.

## Proposal

Extract the name and path arithmetic into a library that is a pure function of
its arguments, unit-test it directly, and have the executable source it so there
is one implementation rather than two.

## Testing

New `tests/unit-names.sh`, 60 assertions, no repository or network involved: the
two meanings of `@` in a source, the repository half of every shape a source can
take, the identifier a package is stored under versus the name it calls itself,
absolute and collapsed paths including ones that do not exist and ones reached
through a missing directory, containment, depth, what a laid link carries from
every position including inside a worktree, and migration filename arithmetic
including a leading zero that must not be read as octal.

The nine scenario suites are unchanged and all still pass — 556 assertions in
total — which is what says the extraction moved code without changing behaviour.

## Changelog entry

#### ♻️ `f/testable-clusters` → `archive/testable-clusters`

Four defects shipped in a day, all invisible to a green suite and all found by
running the tool against a real repository. Each was arithmetic over a name or a
path — a name compared against an identifier, a reference cut at the wrong
character, a depth counted from the wrong root, a link resolver asked a question
it answers with silence — and none of them needed a repository to be wrong. That
arithmetic now lives in `lib/names.sh` as pure functions of their arguments, with
sixty unit cases asking every question that has ever been got wrong here, the
regressions among them marked as such. `bin/kaukea` sources the library rather
than carrying its own copy, locates it through whatever symlink it was invoked
by, and says so legibly if the two ever travel apart.

_Board: `testable-clusters` · first step of modelling the tool as a library ·
relates to `cli-mvp`._

## Readme delta

The layout list should mention `lib/` — the name and path arithmetic, unit-tested
without a repository — alongside `bin/` and `tests/`.
