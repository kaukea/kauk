- created: 2026-09-06
- created_by: opus-5
- created_during: adapter-and-identity

## Blockers

_None._

## Questions

- What positive signal decides that a fetched repository is a kai package? The
  present test is the presence of a convention directory, which ordinary
  repositories satisfy by accident. A repository's own `.ai.toml` root table is
  readable from a clone today (`root_field` takes a clone, and `pkg_namespace`
  already reads `name` that way), so `type = "package"` is available as a
  positive declaration — but requiring it changes what makes a repository a
  package, which is the operator's ruling to make, not a defect fix.
  Recommendation: read `type` from the source and treat a convention directory
  alone as insufficient.
- Should the sync path report the same thing install now reports? The operator
  scoped this round to install and to the self-publishing case; `lay_source` was
  deliberately left as it is.

## Findings

- `is_package` (`bin/kaukea:231`) returns true when a tree holds any directory
  named skills, agents, hooks, tools, files or templates. Four of those six are
  ordinary names in unrelated projects.
- Reproduced 2026-09-06: an ordinary git repository containing only `README.md`,
  `src/main.c` and a `tools/` directory was accepted by `kai install` and its
  `tools/` content was laid into the consumer's `.claude/tools/`. The run
  reported `link: 1 laid/verified`. No warning of any kind was emitted.
- So the live risk is a wrong ACCEPT, not a wrong reject. An error message does
  not reach it, because no error fires.
- `lay_source` (`bin/kaukea:603`) still reports only `<id>: no package contents
  — nothing to lay` and returns success, so a package that stops carrying
  contents degrades silently on sync. Install and self-publishing were rewritten
  on 2026-09-06; this path was not.
- `validate_config` (`bin/kaukea:129`) runs before any work in both install and
  update and caches nothing, so a check placed there re-evaluates every run. It
  uses `die`, which is wrong for this class: `kai init --package` legitimately
  declares `type = "package"` on a repository with nothing in it yet, and
  aborting an unrelated `kai install` over that would be a regression.

## Proposal

Decide the positive signal that makes a fetched repository a kai package, and
apply it where a package is taken in, so that an ordinary repository is not
adopted by accident. Keep whatever refuses a source non-fatal to unrelated
commands: report, lay nothing, leave the clone in place.

## Testing

An ordinary repository carrying a `tools/` directory and nothing else is
refused, with nothing laid into the consumer. A real package still installs
unchanged. `kai init --package` on an empty repository followed by
`kai install <a real package>` completes without the install being aborted.
