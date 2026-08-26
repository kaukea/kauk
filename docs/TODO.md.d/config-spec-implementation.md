- created: 2026-08-21
- created_by: fable-5 (operator go: "implement them all")
- completed: 2026-08-26
- completed_during: f/config-spec-implementation

## Blockers

~~Footprint overlap with fleet-settings-wiring in bin/kaukea and .ai.toml
handling.~~ Resolved: that feature merged 2026-08-24 (0bed355) and this one
started from the merged main.

## Questions

_None. The WHAT was the operator's own hand: docs/configuration-files.md
(2026-08-21) plus his spoken answers, all recorded in Findings._

## Findings

- The spec file OUTRANKS decisions/docs it contradicts (committed 5440c43).
- Operator's spoken answers (2026-08-21): (1) the tool never stamps its own
  name on anything — no generated-by headers, no provenance nuggets; (2) the
  migration watermark is a single-date COMMITTED file inside .ai/ (name
  immaterial), as previously existed — .ai/ stays gitignored for clones only;
  (3) `select` renames to `include` — an array of category paths, optional,
  omitted = everything imports.
- Operator's answers at the plan gate (2026-08-26), the three the spec did not
  settle: (1) a source naming anything other than @HEAD is PARKED until the
  versioning work — kai leaves that clone where it is and lays what is there;
  (2) where a package declares its dependencies on OTHER packages is parked
  with the same work; (3) `include` is git-only for now — a local path is a
  development convenience that has to be replaced by its git source before
  publishing, and a selection that does not survive that swap is a can of
  worms.
- The file name `.ai/migrations.toml` (replacing `.ai/lock.toml`) was the
  agent's choice under "name immaterial": the word lock belongs to the
  deferred versioning work and should not mean two things. Not separately
  ratified.
- `include` being git-only leaves no way to test selection from a local
  fixture, so the category fixtures reach their consumer as `file://` URIs.
  That is also the escape hatch for developing locally with a selection.
- Two readers of `.ai.toml` exist and must stay in step: `bin/kaukea` and
  `bin/kai-hooks.sh` (the hook dispatcher parses it itself, because its stdout
  is the harness channel and cannot carry kai's chatter).
  `tests/hook-dispatch.sh` asserts the pair agree on which source forms are
  accepted.
- Dropped behaviour, recorded so it is not mistaken for an oversight: the
  `pull-only` package flag (whether a clone pushes back is decided at the
  command, not by the package), `title`/`description` (never read), the `ref =`
  key (the ref rides the source now), the retired `origin =` key (its table is
  gone), and installing a package's own package dependencies (parked).

Result: merged to main on 2026-08-26 (squash resolves from the tag below).
Seven commits on
f/config-spec-implementation, preserved under archive/config-spec-implementation.

## Proposal

Implement docs/configuration-files.md in full: root-table identity
(`name`, `type = package|project`); `[[dependency]]` tables with `source`
(owner/repo | URI | local path, optional `@HEAD`) and optional `include`;
kai install appends after the last dependency; package.toml deleted everywhere
via shipped migration; committed single-date watermark file in .ai/ replacing
the-works/migrated; asks removed; MOOD out of kauk; no tool-name stamping
anywhere; laid files user-editable (push access → push at end; none → changes
stay local). All steps scripted (Decision-055).

Delivered as proposed, with the three parked items above.

## Testing

Method: fixture suites over throwaway git repositories, run against the real
`bin/kai` — the same method every prior delivery in this repository used —
plus a new suite for the migration itself.

Run 2026-08-26 at f/config-spec-implementation HEAD, all green:

| suite | assertions |
|---|---|
| tests/config-migration.sh | 28 |
| tests/convention-reader.sh | 79 |
| tests/hook-dispatch.sh | 44 |
| tests/migrations-engine.sh | 24 |
| tests/migrations-estate-links.sh | 41 |
| tests/migrations-settings-state.sh | 49 |

The new suite covers a repository carrying every old form at once — source
tables, a `select`, a `ref`, a `package.toml`, a `.ai/lock.toml` — landing on
the specification in one run; a plain consumer gaining no identity it never
had; a second run being byte-identical; and a repository already on the
specification being left alone.

This repository's own converted `.ai.toml` was also read back through the new
reader: identity `kauk`/`package`, both dependencies resolved, config valid.

NOT tested, and outstanding:

- The migration has never run against a real repository, only fixtures. The
  estate run (estate-links-run) is where that happens.
- `kai sync` was not run in this repository: it would rewrite this checkout's
  laid links and its own clone, which belongs to the estate run.
- Nothing was run on macOS. The BSD awk/sed portability task still stands, and
  the new migration is another script it will have to cover.

## Changelog entry

#### ✨ `f/config-spec-implementation` → `archive/config-spec-implementation`

One configuration file per repository, as the operator specified it by hand in
`docs/configuration-files.md`. `.ai.toml` opens with the repository's own
identity in its root table — `name`, defaulting to the directory name, and
`type`, which is `project` unless it says `package` — and continues with one
`[[dependency]]` block per package consumed. The `[sources."owner/repo"]` table
and `package.toml` are both gone.

A dependency's `source` is `<owner>/<repo>` resolved to GitHub, a full git URI,
an absolute path, or a `./` path taken against the repository root, optionally
ending in `@HEAD`. Any other ref is parked with the versioning work: that clone
is left where it is and what is there is laid. `select` is now `include`, and
is accepted on git sources only.

`kai install` appends one dependency block after the last one already in the
file rather than at the end, so trailing tables survive; a file kai creates is
empty, because its contents are the operator's; and nothing kai writes anywhere
stamps the tool's own name. The migration date file is `.ai/migrations.toml`.

`migrations/2026-08-26-01-one-configuration-file.md` carries any other
repository across in one run, and a new suite (`tests/config-migration.sh`,
28 assertions) proves it.

_Board: `config-spec-implementation` · spec: `docs/configuration-files.md` ·
format: `docs/package-format.md`._

## Readme delta

APPLIED ON THE BRANCH, not staged — a deviation from Decision-034, declared
rather than hidden. `README.md`'s description of `bin/kaukea` documented the
retired `[sources."…"]`/`select` syntax and listed `package.toml` as a
repository-level artifact; both were part of the same change and were corrected
in the same commit as `docs/package-format.md` (44951af). Nothing further is
owed at ingest. The README now describes the root table, `[[dependency]]`
blocks, `include` on git sources, and `@HEAD`; the `package.toml` bullet is
replaced by an `.ai.toml` one, and `tests/config-migration.sh` is listed.
