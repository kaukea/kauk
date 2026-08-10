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
