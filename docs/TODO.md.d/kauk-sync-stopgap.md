- created: 2026-07-14
- created_by: fable-5
- created_during: f/kauk-sync-stopgap

## Blockers

~~orchids held both tool and data~~ — resolved 2026-07-14: split executed (Decision-007).

## Questions

- Initial machine-level install UX: is the served install page enough, or does a Claude
  plugin (or brew/apt formula later) demonstrably enforce the workflow better? (Operator:
  "initial install to be discussed (plugin?)".)

## Findings

- `bin/kauk-sync` is the ported, source-generic engine (ex `orchids/bin/orchids`): no
  hardcoded package layout — packages expose `manifest.conf` typed lines
  (`skill`/`link`/`template`/`prefix`/`option pull-only`); sources recorded in `.ai.toml`
  `[sources."<owner>/<repo>"]`; new prune pass removes dead links into
  `.ai/repositories/` (renamed/retired skills no longer linger).
- kauk is itself a pull-only package delivering the `kauk` skill (Decision-008) — the
  engine's second real source from day one.
- Consumers keep their existing data-clone path (`.ai/repositories/serialseb/orchids`),
  so migration only adds the tool clone + `.ai.toml` sources tables.

## Proposal

Shipped: engine + `manifest.conf` + `skills/kauk/SKILL.md`. Remaining follow-ups live
with `cli-mvp` (real CLI) and the operator question above (install UX).

## Testing

Fresh-repo simulation (scratch git repo, served-page steps verbatim, zero broken links,
`.ai.toml` has both sources, CLAUDE.md prefixed, AGENTS.md instantiated); re-sync of the
three real consumers; round-trip skill edit consumer→orchids; pull-only dirty-clone
guard; kauk self-hosting.
