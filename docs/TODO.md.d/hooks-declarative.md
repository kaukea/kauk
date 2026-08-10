- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

Depends on [[runtime-detection]] for the target set.

## Questions

_None open — the spec is ruled._

## Findings

orchids wires five events, two of them as JSON-escaped bash inline in `settings.json` with no artifact behind them. A 44-concept survey across five runtimes shows all five are reachable everywhere.

## Proposal

`hooks/<event>/index.toml` with closed-set action keys and `compatibility`; transpiler owns the per-runtime mapping and the fallbacks. `settings.json` is never written (Decisions 019/020/027/040).

## Testing

orchids' five events render into a generated plugin and fire; no `settings.json` is touched.
