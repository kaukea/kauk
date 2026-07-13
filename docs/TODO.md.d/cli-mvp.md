- created: 2026-07-13
- created_by: opus-4.8
- created_during: f/bootstrap-kauk

## Blockers

Depends on decisions being stable (control-plane shape, client-side custody) — they are
recorded (Decision-002/003). Language/runtime for the CLI not yet chosen.

## Questions

- **Implementation language/runtime for the `kauk` CLI?** (No default set — operator's
  call; must be collision-free as `kauk` in apt/brew/Arch, which it is.)

## Findings

Design is settled at the interface level: one grammar, backend-qualified addressing,
`publish`/`install`/`resolve`, client-side OAuth device-flow auth. Storage is commodity.

## Proposal

Skeleton `kauk` CLI: arg parsing + the three verbs as stubs, backend-qualified name parsing,
and the auth-broker seam (device-flow, tokens local). Real backends land as separate
`federation` features. Target the first real release at `0.1.0`.

## Testing

`kauk --help` lists the verbs; `kauk resolve npm:foo` vs `kauk resolve kauk.org/foo` parse to
the right backend. Test method to be agreed with operator once language is chosen.
