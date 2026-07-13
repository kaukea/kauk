- created: 2026-07-13
- created_by: opus-4.8
- created_during: f/bootstrap-kauk

## Blockers

None — the two placeholder packages are written and validated.

## Questions

None.

## Findings

PyPI and npm have no reservation API; publishing a package is the only way to claim a name
(Decision-004). Stubs are `0.0.0` in `namespace-reservation/{pypi,npm}`; both manifests parse
and load. Names last verified free 2026-07-12 — re-check at upload (`npm view kauk` → 404,
pypi.org/project/kauk → 404).

## Proposal

Spanning parent over the two publish leaves (`pub-pypi-kauk`, `pub-npm-kauk`). Operator runs
both uploads per `namespace-reservation/UPLOAD.md`; the agent cannot publish. Done when both
`0.0.0` packages are live.

## Testing

`pip index versions kauk` shows 0.0.0; `npm view kauk version` returns 0.0.0.
