- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

Depends on [[manifest-by-convention]] landing first — the reader must walk the tree.

## Questions

_None open — the spec is ruled._

## Findings

No `files/` directory exists in any package. Its role is currently split across hand-typed root link lines, `tools/` (43 helper scripts, one hardcoded destination) and `templates/`.

## Proposal

Add the `files/` kind: contents placed at their path relative to `files/`, verbatim, no transformation. `tools/` stays a separate kind for tool declarations (Decision-015/032).

## Testing

A package with `files/scripts/x.sh` lays `<repo>/scripts/x.sh`; a package with no `files/` lays nothing extra.
