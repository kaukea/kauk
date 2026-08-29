- created: 2026-08-29
- created_by: opus-5
- created_during: f/authoring-skill
- completed: 2026-08-29
- completed_during: f/authoring-skill
- size: m

## Blockers

(none)

## Questions

_None._

## Findings

Result: merged to main on 2026-08-29, preserved under archive/authoring-skill.

- The operator's diagnosis, which is the whole reason this exists: an agent left
  alone writes a new skill into the runtime's own directory, because that is how
  agents are built. A package needs the opposite — source in the convention
  directory, a link in the runtime one. Kai changes the natural order and nothing
  was telling anyone.
- Neither watching nor a scheduled pass fixes that. A session can run for a long
  time, so laying at session start helps only the next session, not the one that
  just wrote the file. What was missing was the telling, not a mechanism.
- The kai package now ships two skills: driving the CLI from an agent, and
  authoring a package. The second is laid only into repositories that are
  packages, and is selected by `kai init --package`.
- An artifact declaring who it is for uses a scalar, and no reader existed for
  one — `fm_list` handles inline lists and dash blocks only, so the declaration
  was ignored and the skill was laid everywhere. Found by testing the behaviour
  rather than the code.
- `artifact_file` takes three arguments; calling it with one produced an unbound
  variable under `set -u`. Also found by running it.
- Declaring a repository a package changes what its existing sources should lay,
  so `init --package` lays them again. Without that the repository is correct
  only after the next update — the same remember-to-run-it problem the skill
  exists to remove.

## Dead ends

- Laying at session start (rejected by the operator): buys almost nothing,
  because the long session that created the artifact is exactly the one it
  misses.
- A watcher on the convention directories: a daemon that fails by being silently
  absent, which is the failure mode this codebase keeps meeting.

## Known limit, left unbuilt

A repository that STOPS being a package keeps the authoring skill it was given.
Removing it would need machinery for a transition nobody has made, and the stale
artifact says something untrue rather than doing something wrong.

## Proposal

Ship the telling as a skill, laid only where it applies, selected by the command
that declares a package.

## Testing

`tests/convention-reader.sh` gains twelve assertions: an ordinary skill laid
everywhere and a package-only one laid nowhere else; `init --package` writing the
root table, naming the repository, and saying what it did; the skill appearing
when a repository is declared a package later; declaring twice leaving the
declaration alone; an unknown flag refused. 610 assertions across twelve suites,
all green.

## Changelog entry

#### ✨ `f/authoring-skill` → `archive/authoring-skill`

An agent asked for a new skill writes it where the runtime keeps skills, which is
right everywhere except a package — where the source belongs in the convention
directory and the runtime directory holds a link to it. Nothing said so. The kai
package now carries a second skill that does, laid only into repositories that
declare themselves packages and selected by the new `kai init --package`, which
writes the root table saying what the repository is. An artifact may now declare
who it is for with `applies-to:` in its own frontmatter; reading a scalar value
there is new, since the reader handled only lists.

_Board: `authoring-skill` · answers part of `package-authoring-skill` · relates
to `runtime-topology`._

## Readme delta

The `bin/kaukea` bullet lists `init`; it should mention `init --package` for a
repository that publishes as well as consumes.
