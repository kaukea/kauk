- created: 2026-08-18
- created_by: fable-5 (operator caveat)

## Blockers

None; testing on a real Mac is the operator's hardware call.

## Questions

- Which Mac verifies the pass — the operator runs the suite there, or a
  sanctioned session on that machine?

## Findings

Decision-053. Concrete offenders found by audit: `sed -i` (BSD needs
`-i ''`) in migrations/2026-08-16-defaults-only-aitoml.md and
2026-08-18-kaukea-move.md — outright failure on macOS; `realpath -m` in the
kaukea-move self-guard; `readlink -f` in cmd_init; bash-3.2 compliance
unproven; BSD awk unexercised.

## Proposal

Replace `sed -i` with the portable write-to-temp-and-move pattern, drop
`realpath -m`/`readlink -f` for POSIX equivalents, run the fixture suite
under BSD awk/sed and bash 3.2, fix what breaks. Already-applied migrations
need no retro-fix on Linux consumers; the files themselves are corrected so
a future Mac consumer survives them.

## Testing

The full fixture suite green on macOS (or a faithful BSD-tools environment).

Deferred by the operator (2026-08-18): fixed when they next run on a Mac —
not in the current must-fix launch set.
