- created: 2026-08-20
- created_by: fable-5 (operator ruling, Decision-061)

## Blockers

(none)

## Questions

_None for the operator — mechanics are the build's to design within D-061._

## Findings

- Decision-061 supersedes Decision-036: no separate package.toml; everything
  about project configuration lives in .ai.toml.
- Current state: kauk carries both files; the reader recognises packages by
  package.toml (self-publishing edge ⊘package-toml); docs/package-format.md
  references it.

## Proposal

Fold package.toml into .ai.toml everywhere: the reader takes package identity
from .ai.toml; kauk's own package.toml content moves in; docs/package-format.md
updated; a shipped migration converts any repository carrying package.toml.
All steps scripted (Decision-055).

## Testing

To be agreed at bloom: a package repo with only .ai.toml is recognised and
consumable; no package.toml remains anywhere in the estate after migration.
