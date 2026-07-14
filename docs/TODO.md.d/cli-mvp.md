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

2026-07-14: the bash stopgap `bin/kauk-sync` shipped (Decision-007/008 — the package
manager moved here from orchids). It fixes the file-package half of the grammar the
0.1.0 CLI inherits: `init` / `install <owner>/<repo> [<origin>]` / `sync [--status]`,
sources in `.ai.toml`, packages self-described by `manifest.conf` typed lines. The
0.1.0 CLI is unblocked from it (language still the operator's call); it supersedes
the stopgap when it lands.

## Proposal

Skeleton `kauk` CLI: arg parsing + the three verbs as stubs, backend-qualified name parsing,
and the auth-broker seam (device-flow, tokens local). Real backends land as separate
`federation` features. Target the first real release at `0.1.0`.

## Testing

`kauk --help` lists the verbs; `kauk resolve npm:foo` vs `kauk resolve kauk.org/foo` parse to
the right backend. Test method to be agreed with operator once language is chosen.
