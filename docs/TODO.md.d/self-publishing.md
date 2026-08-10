- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

Depends on [[package-toml]].

## Questions

_None open — the spec is ruled._

## Findings

Vendoring a repository's own HEAD forces a push in order to see local edits. orchids already unvendored itself by hand and forbids kauk until this exists (its Decision-122).

## Proposal

A repository that is itself a package is not vendored: source is the working tree, publication is by copy, rendered files are committed back (Decision-037).

## Testing

kauk runs inside orchids without a clone of orchids; edits are live without pushing.
