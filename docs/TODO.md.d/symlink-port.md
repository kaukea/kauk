- created: 2026-08-28
- created_by: opus-5
- created_during: f/symlink-port
- completed: 2026-08-28
- completed_during: f/symlink-port
- size: m

## Blockers

(none)

## Questions

Still open from `testable-clusters`, and unanswered: whether to carry on into the
git adapter — 51 calls, and the part a .NET implementation would most likely
redo. The operator has said both implementations may live, which makes the
contract cases valuable either way but leaves the shell adapter work undecided.
Not started.

## Findings

Result: merged to main on 2026-08-28, preserved under archive/symlink-port.

- A dead link had no name in the codebase. It was inferred by asking `readlink
  -f`, which answers with nothing when a directory along the path is missing —
  the ordinary state of a link waiting to be repaired. That silence was read as
  an answer. Naming the state is the fix; the rest follows.
- Resolving a link was never wanted anywhere. The raw target is what was
  written, what is committed, and what callers reason about; resolving walks
  through the package store's own link and answers with the git folder.
- Two judgements were tangled with the filesystem calls and are now functions of
  their arguments: what to do about a destination (`place_action`) and what to
  call it (`name_choice`). The second is where the whole same-thing-or-not
  question lives.
- The port needs a filesystem, because that is what it is for, so it has its own
  small test. That is where the defect is actually caught — the decision tests
  would happily pass while the facts were being gathered wrongly, which was a
  real gap in this branch's first draft.
- Measured, by reintroducing the defect deliberately: the port's test catches it
  in 0.118s with nine assertions naming the broken function. The same defect
  reaches a scenario suite as 31 failures 9.158s later, all of them symptoms
  several steps downstream. The three defects that shipped alongside it were not
  reachable by the scenario suites at all.

## Proposal

Make asking the filesystem a port of its own, name a dead link as a state rather
than inferring it, and lift the two placing judgements out into pure functions
with cases of their own.

## Testing

`tests/unit-place.sh` runs `spec/place.cases` — 19 cases, 6 of them regressions,
no filesystem involved. `tests/unit-fs.sh` — 24 assertions against a real
temporary tree, including a link dead through a missing directory, a link that
must not be followed, and a directory that must be replaced rather than landed
inside. The ten existing suites are untouched and still pass: 598 assertions in
total.

## Changelog entry

#### ♻️ `f/symlink-port` → `archive/symlink-port`

A dead link had no name — it was inferred by asking a resolver a question it
answers with silence when a directory along the path is missing, and that
silence was read as an answer, which is how a package's own link came to look
like a stranger's. Asking the filesystem what is there is now `lib/fs.sh`, whose
whole job is to turn what is on disk into facts and to report what a link
carries without following it. The two judgements that were tangled with those
calls — what to do about a destination, and what to call it when something is
already there — are now pure functions in `lib/place.sh` with their own contract
cases. Reintroducing the original defect on purpose is caught in 0.118s by nine
assertions naming the broken function, where a scenario suite takes 9.158s to
report 31 downstream symptoms.

_Board: `symlink-port` · follows `cases-are-the-contract` · relates to `cli-mvp`._

## Readme delta

None. `lib/` and `spec/` are already described; this adds modules within them
rather than anything a reader of the README would do differently.
