- created: 2026-08-15
- created_by: fable-5 (operator direction)

## Blockers

Needs the pin and per-repo selection landed ([[lockfile]],
[[categories-rename]]) — the artifacts this task rolls out.

## Questions

_None open — rulings of 2026-08-14 apply (pin moves only on operator update;
categories offered per repo at add time)._

## Findings

Operator direction (2026-08-15): "register the usage" — each consuming repo
carries a committed record of what it consumes and at which head.

## Proposal

Roll the committed lock and the per-repo category selection across the
estate: each repo's .ai.lock pins its sources' heads; each .ai.toml carries
the operator-picked categories for that repo, chosen from the offered list at
add/rollout time.

## Testing

A fresh clone of any estate repo plus its lock reproduces its resolved heads;
selections visibly trim what lays.
