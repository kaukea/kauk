- created: 2026-08-26
- created_by: opus-5
- created_during: f/estate-links-run
- completed: 2026-08-26
- completed_during: f/migration-engine-rules

## Blockers

(none)

## Questions

_None — the rules are the operator's, given while the work ran._

## Findings

Result: merged to main on 2026-08-26, preserved under
archive/migration-engine-rules.

- Found by trying to run the estate, not by reading: `kai sync` in a repository
  configured the old way died with "no dependencies in .ai.toml" before it ever
  reached the migration pass. The migration that converts .ai.toml is delivered
  BY the sync that could not read .ai.toml.
- Second, larger: no estate repository had a watermark file at all, and the
  engine's fresh-install rule (absent watermark = replay nothing, stamp to the
  newest on disk) meant every one of them would have declared itself current
  and skipped every migration, silently.
- The operator's rules, given at that point: do not special case anything; an
  absent marker is not a date to invent; the marker's default is the install
  date, and its absence means every migration runs.
- Consequence taken: the engine no longer knows anything about the retired
  grammar. Migrations run before .ai.toml is read, migrations are collected
  from the packages present in the store rather than from what the file
  declares, and sync operates on the union of the declared list and the store.
  A package a repository has been given is a fact of the store.
- Two follow-up migrations came out of the same run: a repository receiving
  both the watermark fold (2026-08-19-04) and the rename (2026-08-26-01) in one
  pass ends up with both .ai/lock.toml and .ai/migrations.toml, because the
  older migration writes the file after the newer one has already looked for
  it; and every estate .ai.toml opens with five comment lines an older kauk
  wrote about itself, describing tables that no longer exist and instructing
  the reader not to edit their own file.
- Split out of [[estate-links-run]] deliberately: consumers receive migrations
  by pulling this repository, so this work has to be on main BEFORE the estate
  is run at all. The estate run keeps its own task and follows.

## Proposal

Make the migration engine able to reach a repository that has never run it,
without teaching kai the retired configuration grammar and without a special
case for the estate.

## Testing

Fixture suites over throwaway git repositories against the real bin/kai, plus
three real runs against SafeKeepIt/SignMc, each reverted to a verified
byte-identical state (same HEAD, clean tree, identical .ai.toml, identical 117
links).

Run 2026-08-26 at branch HEAD, all green: config-migration 39,
convention-reader 79, hook-dispatch 44, migrations-engine 29,
migrations-estate-links 41, migrations-settings-state 49,
settings-retirement 20 — 301 assertions.

The real runs: the first died as described above and wrote nothing; the second
replayed twenty-two migrations from two packages in order, every one detecting
correctly, and converted the configuration file; the third, after the settings
retirement landed on main, replayed twenty-six and ended with no dangling link,
no settings file, and the configuration converted.

NOT tested: the two follow-up migrations have only run against fixtures. A
consumer receives them by pulling this repository, so the first real exercise
of both is the estate run itself.

## Changelog entry

#### ✨ `f/migration-engine-rules` → `archive/migration-engine-rules`

The migration engine can now reach a repository that has never run it. An
absent watermark no longer means "fresh install, replay nothing" — it means
every migration is pending, and each detects for itself whether it still
applies. No date is invented to stand in for the absence; a repository gets its
real marker at install, stamped with the install date, so installing today does
not replay history.

Migrations are collected from the packages present under `.ai/repositories`
rather than from what `.ai.toml` declares, and `kai sync` applies what was
already pending BEFORE it reads that file — the order `docs/package-format.md`
already described. A migration that rewrites `.ai.toml` has therefore already
run by the time `.ai.toml` is read, so kai never has to understand the retired
grammar. Sync works on the union of the declared list and the store.

Two migrations ride along: one drops `.ai/lock.toml` once `.ai/migrations.toml`
exists, and one removes the header an older kauk wrote at the top of every
`.ai.toml` about itself.

_Board: `migration-engine-rules` · follows `config-spec-implementation` ·
precedes `estate-links-run`._

## Readme delta

None. README.md describes the commands and the configuration file, neither of
which changes here; the watermark and the migration stream are described in
`docs/package-format.md`, which already states the order this work restores.
