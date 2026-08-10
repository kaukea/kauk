- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

None.

## Questions

_None open — the spec is ruled._

## Findings

No repository can state what it is; identity is inferred from the directory name.

## Proposal

`package.toml` at the root: name, title, description, type. Published, unlike `.ai.toml` which stays local (Decision-036).

## Testing

A repo with `package.toml` is recognised as a package; one without is an ordinary repository.
