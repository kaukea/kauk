- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

None.

## Questions

_None open — the spec is ruled._

## Findings

All ten `.ai.toml` files carry a "managed by kauk … do not edit by hand" header on the operator's own file, plus three comment lines documenting the retired delivery layer.

## Proposal

Strip the header and the delivery-layer comments; `.ai.toml` becomes sources and selection only (Decision-023). Origins move to remotes once orchids is publishable.

## Testing

Every repo's `.ai.toml` parses, syncs identically, and carries no reference to exclude/copy/link/local.
