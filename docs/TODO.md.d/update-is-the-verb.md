- created: 2026-08-28
- created_by: opus-5
- created_during: f/update-is-the-verb
- completed: 2026-08-28
- completed_during: f/update-is-the-verb
- size: m

## Blockers

(none)

## Questions

_None._

## Findings

Result: merged to main on 2026-08-28, preserved under archive/update-is-the-verb.

- The collision path was the one place the tool departed from what it does
  everywhere else. `sync_source` already took local changes, committed them, and
  rebased; a collision instead kept both sides under invented names, or refused
  and pointed at a command whose whole purpose was to describe the standoff.
- A laid artifact is a link into its package, so an edit through it is already an
  edit of that repository and needs no copying. That is what makes commit-then-
  rebase apply here at all — an insight from the operator that removed an entire
  adoption mechanism I had written.
- Rebasing supplies the base a merge needs. Without it the tool had the user's
  version and the package's and nothing they diverged from, which is why every
  difference read as irreconcilable rather than merging quietly.
- Naming a side inverts. A rebase replays the user's commit on top of the
  package's, so within it "ours" is the package and "theirs" is the user. Saying
  `mine` therefore takes `--theirs`; getting it backwards silently keeps the
  wrong version, which is why it is asserted both ways round.
- Decision-042, which required namespacing, does not survive contact with the
  operator: "I have no memory of saying anything like this." Its distinction was
  missing the nuance — two artifacts of the same name from two DIFFERENT packages
  are probably different things, but a file of yours colliding with a package you
  have declared and can push to is almost certainly the same thing. Namespacing
  is kept for the first case only. In this estate the two declared packages share
  no names at all, so it has never fired.
- Three defects of my own, each found by running the tool rather than reading it,
  and each invisible to a green suite: the namespace test compared a package's
  NAME against a path built from its ID, so no package ever matched itself;
  `--resolve` checked the index for unmerged entries, which editing a file never
  clears, so it could never succeed; and `readlink -f` answers nothing when an
  intermediate directory is missing, so a package's own dead link looked like a
  stranger's and was renamed out of the dead-link repair's reach.
- A fourth was in the tests: `grep -q` exits on first match, the tool takes
  SIGPIPE, and `pipefail` turns that into a failed assertion. Two checks were
  failing for that reason alone.

## Proposal

Make `update` the verb, keep `sync` as a name for it, and put a collision through
the same commit and rebase as every other change, with the rebase left open as
the mode.

## Testing

New `tests/conflict-mode.sh`, 33 assertions: an edit through a link reaching the
package, the update stopping only when both sides moved, the rebase left open,
asking again repeating itself and offering the ways out, abort restoring exactly
and being harmless twice, resolve refusing while markers remain and carrying on
once they are gone, `mine` and `theirs` each keeping the right side, a side that
is not a side being refused, and an update that does not collide never entering
the mode at all. Twenty-two existing assertions describing the retired model were
rewritten rather than deleted. 496 assertions across nine suites, all green.

## Changelog entry

#### ✨ `f/update-is-the-verb` → `archive/update-is-the-verb`

`update` is now the command that does the work and `sync` is a name for it. A
file of yours where a package has one of its own is no longer a standoff: a laid
artifact is a link into its package, so an edit through it is an edit of that
repository, committed there and rebased onto the package's changes like anything
else. Nothing is copied anywhere and nothing is lost, because every version is in
a commit. When both sides have changed the same lines the rebase is left open —
being unfinished is the state, and git holds it — and `kai update --abort`,
`--automerge` or `--resolve` act on it, the last of which also takes `mine` or
`theirs` if you would rather not edit anything. The separate `resolve` command is
gone. Namespacing survives only for two different packages shipping one name,
which is what it was for.

_Board: `update-is-the-verb` · retires Decision-042 · relates to
`help-that-helps`._

## Readme delta

The layout entry for the tool lists `sync [--pull|--push]`; it should lead with
`update` and note `sync` as the same command, and mention that a collision is
merged by rebase with `--abort` / `--automerge` / `--resolve` rather than
refused.
