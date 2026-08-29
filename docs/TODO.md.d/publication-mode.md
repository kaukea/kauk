- created: 2026-08-29
- created_by: opus-5
- created_during: f/publication-mode
- completed: 2026-08-29
- completed_during: f/publication-mode
- size: m

## Blockers

(none)

## Questions

_None._

## Findings

Result: merged to main on 2026-08-29, preserved under archive/publication-mode.

- Publishing into your own repository by copy leaves the same file in two places
  with a step between them. It is now a link, like everything else, so editing a
  source file is immediately what runs.
- Copy is REMOVED, not deferred. The operator's reasoning: showing it invites an
  agent to reach for it, and it is not really a copy — it is moving bytes with a
  translator in the middle. No transpiler, no copying, and nothing to discuss
  about a component that does not exist. Nothing could reach the path anyway;
  the mode had a single possible value everywhere.
- `init` declares where kai is published and nothing else. It registered
  whatever path this machine kept the tool at, which is true on one machine and
  false in every clone of the repository that records it. The operator's
  instruction was explicit: from git, full stop, no prettiness and no smartness —
  so it is the literal name, not derived from a remote and with no refusal path.
- The rename that moved two repositories rewrites the retired
  `[sources."owner/repo"]` table syntax only. A repository that reached the
  `[[dependency]]` form before it ran can never be matched by it. Three were
  stranded, one naming `kaukea/orchids`, an identifier that never existed. The
  operator predicted a missing or failing migration from the symptom alone and
  was right.
- One defect of my own, caught by the suites: removing the mode parameter shifted
  `lay_kind`'s positions and the glob still read the old one, so nothing was laid
  at all. 66 assertions failed at once.

## Proposal

Publish by link, delete copy, have `init` declare `kaukea/kauk`, and write the
migration that the rename cannot reach.

## Testing

`tests/convention-reader.sh` asserts a package publishes its own skill by link
into its own source and that editing the source is what runs, plus that `init`
declares the published name and never a path. `tests/migrations-engine.sh`
follows for the self-published case. `tests/migrations-estate-links.sh` gains
eleven cases for the new migration: each retired name, a path matched by its
tail, an unrelated source untouched, comments and root table preserved, clones
under retired names removed, a second run changing nothing, and a repository
naming none of them left alone. 627 assertions across twelve suites, all green.

## Changelog entry

#### ✨ `f/publication-mode` → `archive/publication-mode`

A repository that is a package published into itself by copying, which left the
same file in two places and a step between them. It now publishes the way
everything else does — the runtime directory holds a link into the convention
directory — so editing a source file is immediately what runs. Copy is removed
rather than deferred: nothing could reach it, and a mode left lying about is one
something will try to use. `kai init` now declares `kaukea/kauk` and never a path
on the machine that ran it. `2026-08-29-01-retired-sources-in-dependency-blocks`
covers what the earlier rename cannot see — it matches the retired
`[sources."…"]` table syntax only, so three repositories that reached the
`[[dependency]]` form first were stranded, one naming an identifier that never
existed. The format document loses a `[general]` table that never existed and a
status line calling the format unimplemented two weeks after it was.

_Board: `publication-mode` · relates to `estate-links-run`._

## Readme delta

Applied on the branch: `init [--package]` in the command grammar.
