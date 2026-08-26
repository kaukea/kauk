- created: 2026-08-26
- created_by: opus-5
- created_during: f/estate-links-run
- completed: 2026-08-26
- completed_during: f/sweep-needs-declarations
- size: s

## Blockers

(none)

## Questions

_None._

## Findings

Result: merged to main on 2026-08-26, preserved under
archive/sweep-needs-declarations.

- Found in the estate run, after it had already cost two repositories their
  whole vendored store: `sweep_orphan_clones` removes a clone that `.ai.toml`
  no longer declares, when the clone is clean and its head is contained in its
  origin. With an `.ai.toml` still in the retired `[sources."…"]` form, kai
  reads NO declarations, so every clone looks undeclared and every clean one is
  deleted — including the package carrying the migration that would have
  converted the file. The repository is then unrecoverable by sync alone: no
  store, so no migration, so no conversion, so still no declarations.
- serialseb/seb.secrets and serialseb/serialseb.ca both reached that state.
  Both were repaired from the session's backups afterwards.
- The general rule this is an instance of: absent information is not evidence.
  A destructive step must not read "I found nothing" as "there is nothing".

## Proposal

Skip the sweep entirely, saying so, when the configuration file yields no
readable declarations.

## Testing

`tests/migrations-estate-links.sh` gains a consumer whose `.ai.toml` is
rewritten into the retired form after a successful install: its store survives
the next sync and the skipped sweep is announced. 310 assertions across seven
suites at branch HEAD, all green.

## Changelog entry

#### 🐛 `f/sweep-needs-declarations` → `archive/sweep-needs-declarations`

The orphan-clone sweep no longer runs when `.ai.toml` yields nothing readable.
A repository whose configuration is still in the retired form declares nothing
kai can parse, and sweeping on that basis deleted its entire vendored store —
including the package carrying the migration that would have converted the
file, leaving nothing that could ever repair it. Absent information is not
evidence.

_Board: `sweep-needs-declarations` · found by `estate-links-run`._

## Readme delta

None.
