- created: 2026-08-28
- created_by: opus-5
- created_during: f/cases-are-the-contract
- completed: 2026-08-28
- completed_during: f/cases-are-the-contract
- size: s

## Blockers

(none)

## Questions

_None._

## Findings

Result: merged to main on 2026-08-28, preserved under archive/cases-are-the-contract.

- The operator intends to keep this implementation and build a second one in
  .NET alongside it. That changes what the unit cases are: they stop being tests
  of a shell library and become the definition both implementations answer to.
- Expressed as calls into shell functions, only one implementation could ever run
  them, and the other would be free to diverge silently. They are now data, and
  the runner holds no knowledge of what is being asked.
- A real trap, found by it failing: `read` with tab in IFS collapses runs of
  tabs, because tab is IFS whitespace. An empty column therefore vanishes and the
  next one is read in its place — three cases appeared to fail when the library
  was correct. An empty expected value is now spelled `<empty>`. A contract must
  not depend on how one language happens to split a line.
- Thirteen of the fifty-nine cases record answers that were wrong in a shipped
  version. The format says they are never removed.

## Proposal

Move the cases out of the shell test into `spec/names.cases`, and reduce the
shell test to a runner over that file.

## Testing

`tests/unit-names.sh` reads `spec/names.cases` and passes 59/59. The nine
scenario suites are untouched and still pass — 555 assertions in total. The count
is one lower than before only because two cases asked the same question of
`owner_repo` and were consolidated.

## Changelog entry

#### ♻️ `f/cases-are-the-contract` → `archive/cases-are-the-contract`

With a second implementation planned in .NET, the unit cases for the name
arithmetic stop being tests of the shell library and become the contract both
implementations answer to. They move into `spec/names.cases` as data — question,
arguments, expected answer, and what is being asked — so a runner in any language
reads the same file; `tests/unit-names.sh` is now a thirty-line runner that knows
nothing about what it is testing. Thirteen of the fifty-nine cases record answers
that were wrong in a shipped version and are marked so they are never dropped. An
expected value of nothing is written out rather than left blank, because a reader
treating tab as whitespace collapses runs of them and reads the next column
instead.

_Board: `cases-are-the-contract` · follows `testable-clusters` · relates to
`cli-mvp`._

## Readme delta

The layout list mentions `lib/`; it should mention `spec/` beside it — the
questions every implementation answers, read by the runner in `tests/`.
