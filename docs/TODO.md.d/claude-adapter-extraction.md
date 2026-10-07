- created: 2026-09-06
- created_by: opus-5
- created_during: adapter-and-identity

## Blockers

_None._ It is a restructure of shipped behaviour and does not wait on the
neutral source form that [[runtime-topology]] designs.

## Questions

- The adapter's two entry points need names. The operator proposed
  `lay_repository` and `lay_dev_package`; the pair is uneven, because one names
  where the files land and the other names what kind of thing is being laid.
- Does the self-publishing selection come into this task or stay with
  [[runtime-topology]]? A package's own tree splits three ways — artifacts it
  uses while developing, artifacts it ships, and artifacts that are both — and
  `publish_own` currently lays all of them unfiltered (Operator, 2026-09-06).
  That is a gap in the model, not only in the extraction.
- Do the internal names get corrected in the same pass? Most of the functions
  this touches are renamed by it anyway.

## Findings

- The seam already half-exists: `detect_runtimes` returns a set, and both
  `lay_source` and `publish_own` select the renderer with an identical `case`
  over it, whose other arm reports that a runtime has no renderer.
- Claude-specific code sitting in the generic layer:
  - `prune_deselected` (`bin/kaukea:659`) globs `.claude/skills/*` and
    `.claude/agents/*` directly.
  - `lay_one_artifact` (`:469-471`) builds `.claude/skills`, `.claude/agents`
    and `.claude/tools` destinations itself and never consults
    `detect_runtimes` at all — so the adapter is chosen in two places and
    bypassed in a third.
  - `never_laid` (`:581`) hardcodes the refused settings paths.
  - `lay_source` (`:609`) prints a sentence in one runtime's vocabulary.
  - `NS_SEP` is set by the adapter but consumed by `namespace_for`, which is
    generic, so the separator has to be passed rather than left as a global.
- Runtime-free and staying in the generic layer: the package-contents check,
  `pkg_namespace`, `build_selection` (the include list and its dependency
  closure, computed from artifact frontmatter with no destination involved), and
  `lay_files`, which places `files/<path>` at the repository root with no
  runtime involved.
- `publish_own` calls the adapter with the repository as its own source —
  `lay_claude "$root" "$root" "$ns"` — so the adapter entry is identical to a
  consumed package's today, and nothing in the adapter branches on
  `type = "package"`.
- Operator rulings, 2026-09-06: kai does not read a runtime's data except to
  verify an install, and any runtime-specific validation belongs after
  transpiling, inside the adapter. An adapter contract with two named entry
  points is preferred over a single generic one, so that no adapter author
  routes both cases through one call without noticing there are two.
- Shape agreed 2026-09-06: the adapter is handed the selection and returns a
  plan — for each artifact, where it lands and under what filename, with
  whatever separator that runtime uses. The generic layer executes the plan:
  place, count, report, and prune anything it previously placed that is no
  longer in the plan. This is what makes `prune_deselected` generic again, and
  makes post-transpile verification a check that the plan was realised.
- Rejected 2026-09-06: giving each adapter its own `lay_source`. Every adapter
  would then reimplement the package check and the selection closure.

## Proposal

Extract the Claude renderer into its own component behind a fixed adapter
contract, doing exactly what is done today and no more, so that a second runtime
can be added without touching the generic layer. Behaviour-preserving: no
neutral source form, no new artifact kinds, no change to what is laid or where.

## Testing

The laid tree is byte-identical before and after, for a repository consuming a
package and for a package publishing into itself. A unit suite beside the new
component, matching the existing `unit-fs.sh` / `unit-names.sh` /
`unit-place.sh` shape. The full suite passes unchanged.
