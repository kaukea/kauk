- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

None.

## Questions

_None open — the spec is ruled._

## Findings

`kauk` is not memorable and speech-to-text does not transcribe it. `kai` is taken on PyPI and npm, but entry-point names are not registry-scoped.

## Proposal

Executable ships as `kaukea` with a `kai` symlink created at install, reported and skipped if `kai` exists on PATH. `kauk` kept as an alias; rename rides a migration (Decision-026).

## Testing

`kaukea` and `kai` both work; an existing `kai` on PATH is not clobbered.

Operator emphasis (2026-08-16): `kai` is the MAIN command; `kauk` stays as the
backup alias. The Decision-026 mechanics (executable ships as `kaukea`, `kai`
symlinked at install, reported-and-skipped if taken) stand unchanged.

## Result (cli-kai, 2026-08-16)

Shipped on `f/cli-kai` → `archive/cli-kai`: bin/kaukea is the executable,
bin/kai leads, bin/kauk stands backup — three names, one behaviour, the
71-assertion suite passing through bin/kai. Messages speak kai; the tool's
skill renamed kauk → kai with its text brought current. The PATH-level kai
symlink with collision check stays with the future real installer;
serialseb/kauk and the platform name unchanged (Decision-035).

## Changelog entry (staged)

#### ✨ `f/cli-kai` → `archive/cli-kai`

kai leads; kaukea carries; kauk stands backup. The executable ships as
`bin/kaukea` with `bin/kai` in front and `bin/kauk` as the fallback alias —
three names, one behaviour. User-facing messages speak kai, and the tool's
skill renames to `kai` with its content rewritten to the current model.
Migration `2026-08-16-command-is-kai.md` cleans consumers' dangling links.

_Board: cli-rename-kai · Decision-026, operator emphasis 2026-08-16._

## Readme delta (staged)

The README's layout line renames the tool: `bin/kaukea` (invoked as `kai`,
with `kauk` as the backup alias).
