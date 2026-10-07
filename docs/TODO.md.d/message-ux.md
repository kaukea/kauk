- created: 2026-09-06
- created_by: opus-5
- created_during: adapter-and-identity

## Blockers

_None._

## Questions

- Does the proposed register land, or is it still too clipped? Sample, replacing
  the refusal shape with a description of what was found:

  ```
  kaukea/thing has been fetched, but it does not look like a kai package yet —
  a package ships from skills/, agents/, hooks/, tools/, files/ or templates/,
  and none of those are in it. Nothing was laid into your repository, and the
  clone is still there if you want to look at it.
  ```

- Which of the invented words are kept? `lay` in particular is now in
  `AGENTS.md`, the skill descriptions and the documentation, so it is
  established vocabulary even though no comparable tool uses it.

## Findings

Operator, 2026-09-06: the messages are aggressive and need to be empathetic.
Reviewed against git, npm, cargo and apt; four habits produce that reading.

- The tool is the subject and the verb is a refusal — "install does not take",
  "update does not understand", `REFUSED`.
- Judgement words about the user's own setup: a selection "is a trap", a file is
  `DEBRIS`, a clone is an `ORPHAN`.
- The remedy arrives as an order — "Remove the include", "Rename the
  repository", "Create the one you mean to ship from".
- None of them say what state the user is left in, so each reads as a door
  closing.

The register to apply instead: describe what was found rather than what is
forbidden, keep the user out of the accusative, offer the way forward as
available rather than commanded, and say what happened to their files.

Other user-visible defects found in the same pass:

- `REFUSED <path> (a settings JSON is passed at spawn, never laid —
  Decision-061)` prints an internal decision number to a user who cannot read
  that document.
- The status words are grammatically four different things: past participles
  (`LINKED`, `NAMESPACED`, `REFUSED`), imperatives (`PRUNE`, `SKIP`), nouns
  (`DEBRIS`, `ORPHAN`) and a bare adjective (`AMBIGUOUS`). Cargo picks one form
  and never varies from it.
- `migration <id>: FAILED — reported; kai moves on` has the tool narrating
  itself in the third person.
- The `reload:` line fires unconditionally at the end of every run, three
  clauses long, whether or not anything changed.
- "watermark" for the applied-migration marker is invented here; alembic, rails
  and apt all say version or pending.
- Register swings between full sentences and telegraph (`<id>: no clone`).

Additive piece, operator 2026-09-06: `kai init` can write a `name` into the
configuration file so that a user is encouraged to fill one in. Further down
the line, and part of this task rather than its own.

Out of scope here: internal function names and code comments, which were
reviewed in the same pass but are folded into [[claude-adapter-extraction]],
since it renames most of them anyway.

## Proposal

One pass over everything the tool prints: settle the register, apply it to the
existing messages, make the status words one grammatical form, remove internal
references from user-visible output, and have `init` write a `name`.

## Testing

Every message the tool can emit is read against the agreed register, with the
operator reviewing the full set before it lands rather than sampling it. The
existing suites pass unchanged, since none of them assert on message text.
