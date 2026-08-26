- created: 2026-08-26
- created_by: opus-5
- created_during: f/estate-links-run
- completed: 2026-08-26
- completed_during: f/migrations-resolve-late
- size: s

## Blockers

(none)

## Questions

_None._

## Findings

Result: merged to main on 2026-08-26, preserved under
archive/migrations-resolve-late.

- Found by running the estate, not by testing: the whole migration stream was
  collected up front, as file paths. `2026-08-18-kaukea-move` moves the store
  from `serialseb/<repo>` to `kaukea/<repo>`, so every path after it in the
  collected list pointed at a directory that no longer existed and awk failed
  to open it.
- The damage that follows is the part that matters: a failed migration still
  advances the watermark (errors are reported, not handled), so a repository
  ends up recorded as fully migrated while carrying the retired configuration
  syntax and dozens of dangling links, with nothing left that would make it try
  again. Five estate repositories reached that state before it was caught:
  orphan (11 failures, 34 dangling), judada (11, 79), kmscon-pi (11, 82),
  seb.tv (9, 24), serialseb.ca (9). A sixth, seb.secrets, stalled at watermark
  2026-08-18-0 for the same reason.
- All six were restored from backup and re-run after the fix.
- The watermark now advances after each migration rather than once at the end,
  so an interrupted run resumes where it stopped.

## Proposal

Locate each migration when its turn comes, against the store as it stands, and
advance the watermark after each one.

## Testing

`tests/migrations-engine.sh` gains a fixture whose middle migration moves its
own clone to another owner mid-stream: the migration before it, the move, and
the one after it all run, nothing reaches a stale path, and the watermark
reaches the last one. 306 assertions across seven suites at branch HEAD, all
green. Confirmed afterwards against the six real repositories that had been
damaged.

## Changelog entry

#### 🐛 `f/migrations-resolve-late` → `archive/migrations-resolve-late`

A migration is free to move the store — the kaukea rename does exactly that —
and the whole stream used to be collected as file paths before the first one
ran. Everything after such a migration then pointed at a directory that no
longer existed, was reported as FAILED, and still advanced the watermark, so a
repository could end up recorded as fully migrated while carrying the retired
configuration syntax and dozens of dangling links.

The stream is now re-read before every step, the watermark advances after each
one so an interrupted run resumes where it stopped, and a migration whose file
has genuinely gone from the store is skipped out loud rather than failed.

_Board: `migrations-resolve-late` · found by `estate-links-run`._

## Readme delta

None. Nothing a reader of README.md acts on changes.
