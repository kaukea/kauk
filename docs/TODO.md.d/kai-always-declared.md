- created: 2026-08-28
- created_by: opus-5
- created_during: f/kai-always-declared
- completed: 2026-08-28
- completed_during: f/kai-always-declared
- size: s

## Blockers

(none)

## Questions

_None._

## Findings

Result: merged to main on 2026-08-28, preserved under archive/kai-always-declared.

- Nothing had ever added a dependency. The kai package is planted once by
  `install_source` during `kai init`, and every migration written until now
  renames a declaration that already exists. A repository that never ran the
  initialise step, or lost the block, had no route back.
- What that costs is not cosmetic. The kai package carries the `agent` skill,
  which is the only sanctioned way to launch an agent with the fleet's settings,
  so a repository without the declaration cannot start an agent at all.
  (Operator, 2026-08-28.)
- Two corrections to an estate survey made earlier in the session, both of which
  had over-reported the damage:
  - `~/src/serialseb/kauk` and `~/src/serialseb/orchids` are SYMLINKS into
    `~/src/kaukea/`, left as shims when the repositories moved. A survey reading
    `.ai.toml` through them reports the target's file as if it belonged to a
    separate repository. The local paths still in judada and kmscon-pi resolve
    through those shims, which is why nothing has broken.
  - `serialseb/forensics` does declare the kai package. It is still on the
    retired `[sources."<owner>/<repo>"]` format with an `origin` key, which a
    survey grepping for `source =` does not match.
- Replaying the real chain over the oldest configuration in the estate —
  `2026-08-18-kaukea-move`, then `2026-08-26-01`, then `-03`, then this one —
  lands `kaukea/kauk` and `kaukea/orchard`, and this migration reports the
  declaration already present. So against the estate as it stands it is a
  guarantee rather than a repair.
- Retiring the two shims is one `rm` each, but it breaks judada, kmscon-pi and
  seb.tv until they have been synced, so it belongs after the estate run rather
  than before it. Not done here.

## Proposal

A migration that adds the kai package declaration when no declaration names it,
in any shape, and does nothing otherwise.

## Testing

`tests/store-in-git-folder.sh` gains nineteen assertions: a consumer that lost
the block gets exactly one back, placed after the last dependency, with its root
table, its comment and its other dependency untouched; a second run changes
nothing; the four shapes a source can take are each recognised and left alone;
the tool's own repository declares nothing; a repository with no `.ai.toml` is
untouched; and a repository with a root table but no dependencies at all gets a
valid one. 425 assertions across eight suites at branch HEAD, all green.

One defect found by those tests rather than by reading: stripping an `@ref` from
the whole source string cut a git address at the `@` in its user part, leaving
`git`, so `git@github.com:kaukea/kauk.git` was not recognised and would have been
given a duplicate. It now strips a reference only from the last path segment, the
way `bin/kaukea` does, and drops a trailing `.git`.

## Changelog entry

#### ✨ `f/kai-always-declared` → `archive/kai-always-declared`

A repository is given the kai package once, when it is initialised, and nothing
ever put it back — every migration until now renames a declaration that already
exists rather than creating one. The package carries the skill that launches an
agent with the fleet's settings, which is the only sanctioned way to launch one,
so a repository that lost the declaration cannot start an agent at all.
`2026-08-28-01-kai-package-is-always-declared` adds the block when nothing names
it, in any shape a source can take, and does nothing otherwise. It is the first
migration that writes a declaration into a file that belongs to the operator, so
it adds one block after the last dependency and changes nothing else.

_Board: `kai-always-declared` · relates to `estate-links-run`._

## Readme delta

None. The declaration is something the tool maintains; nothing a reader of the
README would do changes.
