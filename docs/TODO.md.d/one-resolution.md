- created: 2026-08-30
- created_by: opus-5
- created_during: f/one-resolution
- completed: 2026-08-30
- completed_during: f/one-resolution
- size: s

## Blockers

(none)

## Questions

_None._

## Findings

Result: merged to main on 2026-08-30, preserved under archive/one-resolution.

- The audit the operator asked for — the same job done more than one way —
  turned up the path-resolution contract written **nine times**: five identical
  copies inline in the settings JSON, three in `bin/kaukea`, two in
  `bin/kai-hooks.sh`, three in the launcher script.
- Most of those are forced. Resolving where the tool lives is what you must do
  *before* you can source anything, so the settings JSON, the executable, the
  hook dispatcher and the standalone launcher each have to do it unaided. The
  five in the JSON are already policed by a test that they are identical.
- Three in `bin/kaukea` were not forced, and **were not the same**. One carried
  the fleet's fallback; two did not.
- The two without a fallback do not fail where `readlink -f` is unsupported —
  they print nothing, `dirname ""` is `.`, and the path becomes `./../lib`
  relative to the working directory. Demonstrated: run from a directory with a
  sibling `lib/`, under such a resolver, and a stranger's library is sourced. A
  silent substitution, not an error.
- The third was `script_repo` in `cmd_init`, which decides whether a repository
  is the kai package itself. Wrong there means `init` misjudges that.

## Proposal

Resolve once at the top, with the fallback, made absolute, and reuse it.

## Testing

`tests/one-reader.sh` gains five assertions: resolved once in the executable and
not recomputed, with a fallback, the hook resolving the same way, and — the one
that matters — a stranger's library never sourced when the tool is run from a
directory with a sibling `lib/` under a resolver lacking the option. 754
assertions across fifteen suites, run twice.

## Changelog entry

#### 🐛 `f/one-resolution` → `archive/one-resolution`

Finding the library beside the executable was written three times in `bin/kaukea`
in three different forms, two of them without the fallback the rest of the fleet
uses. Those two do not fail where `readlink -f` is unsupported — the path becomes
`./../lib`, relative to the working directory, and a stranger's library is
sourced silently. It is resolved once now, made absolute, and reused;
`tests/one-reader.sh` pins that, including that no stranger's library can be
sourced under such a resolver.

_Board: `one-resolution` · follows `one-parser`._

## Readme delta

None.
