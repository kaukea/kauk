- created: 2026-08-29
- created_by: opus-5
- created_during: f/status-and-push
- completed: 2026-08-29
- completed_during: f/status-and-push
- size: s

## Blockers

(none)

## Questions

Carried, from the operator and not yet acted on: a report should answer "good to
go or not" rather than hand back three numbers. Git already says what is
happening, and an update already has the commands to settle a conflict, so what a
report adds is the verdict — conflict, or up to date. It currently prints
incoming, outgoing and uncommitted counts. Left as it is because changing what it
says is a design choice, not a fix.

## Findings

Result: merged to main on 2026-08-29, preserved under archive/status-and-push.

- `--status` promised to report and write nothing, and laid every artifact. It
  ended by calling `lay_source`. Proved by deleting a laid directory, asking for
  a status, and watching it come back. Found by reading the function before
  writing a single test for it.
- Neither `--status` nor `--push` had one assertion against them, and they are
  the two you would want to trust unattended — one is what you consult before
  acting, the other is the only command that writes into a repository other than
  the one it runs in.
- **Seventy-two assertions across nine suites raced.** They pipe a writer into a
  matcher that exits on its first match; the writer takes SIGPIPE, and `pipefail`
  turns that into a failed assertion — intermittently, and looking exactly like
  the code under test is broken.
- That pattern cost three debugging rounds today. Each time the instance was
  fixed and the class was not, so it returned the moment a suite was written from
  scratch — by me, hours after writing a telemetry note about it. A record
  written for the operator is not a mechanism that reaches the agent.

## Proposal

Stop the report writing, cover both commands, and remove the racing class from
the mechanism rather than from seventy-two individual lines.

## Testing

New `tests/status-and-push.sh`, 15 assertions: a report lays nothing while still
reporting what it found, and a real update still lays; a report neither commits a
local edit nor publishes, and says the edit is there; an ordinary update commits
locally and sends nothing; publishing sends exactly what was edited and the
consumer still resolves it; publishing with nothing to send touches nothing; and
taking with giving is refused with nothing published.

The class fix is one line in each suite's shared assertion helper: the assertion
evaluates with `pipefail` off, which is the correct meaning of every one of those
pipelines. 651 assertions across thirteen suites, run twice end to end with
identical results.

## Changelog entry

#### 🐛 `f/status-and-push` → `archive/status-and-push`

`kai update --status` promised to report and write nothing, and laid every
artifact — delete a laid directory, ask for a status, and it came back. It no
longer writes. Neither it nor `--push` had a single assertion against them, and
they are the two commands worth trusting unattended; both are covered now,
including that an ordinary update never publishes however much has changed
locally. Writing those tests surfaced seventy-two assertions across nine suites
that piped a writer into a matcher exiting on first match, so the writer took
SIGPIPE and `pipefail` reported a failure that looked like the code under test —
a pattern that had already cost three debugging rounds the same day. Assertions
now evaluate with `pipefail` off, which is what every one of them meant.

_Board: `status-and-push`._

## Readme delta

None.
