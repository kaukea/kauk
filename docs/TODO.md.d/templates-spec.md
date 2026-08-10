- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

None.

## Questions

_None open — the spec is ruled._

## Findings

`templates/` holds three files with three different behaviours and no declared semantics.

## Proposal

Frontmatter with `type: beginning | end | inline`, `match`, `tracked`; one `:kauk:` marker line, no closing marker; no-match reports and skips; interpolation syntax reserved (Decision-021).

## Testing

Each type applies and re-applies idempotently; a missing match is reported and changes nothing.
