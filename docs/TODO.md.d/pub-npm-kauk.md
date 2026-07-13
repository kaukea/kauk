- created: 2026-07-13
- created_by: opus-4.8
- created_during: f/bootstrap-kauk

## Blockers

Needs an npm account (operator-held). Agent cannot publish.

## Questions

None.

## Findings

Package at `namespace-reservation/npm/` (kauk@0.0.0, MIT, files: index.js + README).
Unscoped public — no `--access` flag needed. `index.js` loads clean.

## Proposal

`cd namespace-reservation/npm && npm publish --dry-run && npm publish`. OTP prompt if
2FA-on-publish is enabled.

## Testing

`npm view kauk version` returns 0.0.0.
