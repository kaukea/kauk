- created: 2026-08-30
- created_by: opus-5
- created_during: f/one-parser
- completed: 2026-08-30
- completed_during: f/one-parser
- size: m

## Blockers

(none)

## Questions

_None._

## Findings

Result: merged to main on 2026-08-30, preserved under archive/one-parser.

- The operator's diagnosis, which is what prompted the review: an agent tends to
  reproduce whatever is closest to where it is editing, so the codebase drifts
  from its own intent wherever that habit has been at work.
- It had. `.ai.toml` was read by two independent parsers — the real one in
  `bin/kaukea`, and a simplified copy in `bin/kai-hooks.sh` that I wrote myself
  while adding the session-start bootstrap, next to the code that needed it.
- **They had already diverged.** A dependency declaring a type other than
  `package` is ignored by the tool, with a warning, and was cloned by the hook
  regardless. Demonstrated before any change was made.
- The hook also carried its own copies of source resolution, owner/repo
  derivation and the store path, and sourced nothing at all, though the library
  existed and it resolves the binary already.
- Removing the copy exposed what the copy had hidden: the hook must work under a
  `readlink` with no `-f`, which is how this fleet has resolved paths since that
  cost a green suite once before. My first attempt exited silently under it. It
  now resolves the way everything else does and reports a broken install rather
  than vanishing.
- The rig that caught it copied `kai-hooks.sh` with no sibling library — an
  install that cannot exist, since bin and lib travel together by an invariant
  with its own error message. The fixture models a whole install now.
- Two of my own assertions were wrong and the code was right: matching on the
  block marker anywhere flags comments and the function that legitimately writes
  a block, and four dependencies with one excluded is three.

## Proposal

One reader in `lib/aitoml.sh`, sourced by both executables, and a suite that
fails if either grows its own or if the two ever answer differently.

## Testing

New `tests/one-reader.sh`, 12 assertions: the reader exists once, neither
executable defines its own nor matches the block marker inside an awk program,
both source the library, and both ends answer one awkward file alike — a retired
type left out, a source outside any block left out, plain sources and one
carrying a reference and a path all in, and the root table still readable. 749
assertions across fifteen suites.

## Changelog entry

#### 🐛 `f/one-parser` → `archive/one-parser`

`.ai.toml` was read by two independent parsers — the real one in `bin/kaukea` and
a simplified copy in `bin/kai-hooks.sh`, written beside the code that needed it —
and they had already diverged: a dependency declaring a type other than `package`
is ignored by the tool and was cloned by the session-start hook regardless. There
is one reader now, in `lib/aitoml.sh`, sourced by both. Removing the copy exposed
that the hook must keep working under a `readlink` with no `-f`; it now resolves
the way the rest of the fleet does and reports a broken install rather than
exiting silently. `tests/one-reader.sh` fails if either executable grows its own
reader again, or if the two answer the same file differently.

_Board: `one-parser` · follows `one-harness`._

## Readme delta

The `lib/` entry should say it holds the one reader of `.ai.toml` as well as the
name and path arithmetic.
