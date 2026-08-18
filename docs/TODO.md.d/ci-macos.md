- created: 2026-08-18
- created_by: fable-5 (operator direction)

## Blockers

The repository is PRIVATE (Decision-013: private until scrubbed). GitHub's
free macOS runners are for public repositories; on private ones macOS
minutes bill at 10x. Going public first means the pre-publication scrub
gate. Operator picks the route.

## Questions

- Public-after-scrub (free macOS runners), pay private minutes, or a local
  Mac runner? Windows is skipped on purpose — WSL exists (operator ruling).

## Findings

Operator (2026-08-18): a test suite on macOS is wanted to hold
Decision-053's portability floor — the fixture suite green under BSD
awk/sed and bash 3.2 on every push.

## Proposal

A workflow running tests/convention-reader.sh on macos-latest, gated on the
visibility decision; the portability fixes ([[macos-portability]]) land
first or with it.

## Testing

The suite green on a real macOS runner.
