- created: 2026-08-29
- created_by: opus-5
- created_during: f/kai-is-self-contained
- completed: 2026-08-29
- completed_during: f/kai-is-self-contained
- size: m

## Blockers

(none)

## Questions

_None._

## Findings

Result: merged to main on 2026-08-29, preserved under archive/kai-is-self-contained.

- kai shipped `skills/orchard/`, telling every repository that installed it that
  an agent must be launched through `.claude/tools/dispatch-agent.sh` and that
  work launched any other way was invalid. kai ships no `tools/` and no
  `agents/`. Installing kai into an empty repository produced the instruction and
  not the file — the operator's assessment: "one is pretty bad".
- It also inverted the dependency direction: orchard builds on kai, never the
  reverse. The `agent` skill and its launcher script carried the same reference
  three more times.
- Three frontmatter keys were declared in the format document and defined
  nowhere. `compatibility` is the list of agents and models an artifact works
  with, so the wrong skill can one day be refused rather than found wrong in use
  — recovered from the operator and written down because it had been forgotten
  once already, and because five orchard skills fill it with prose
  (`compatibility: Requires git`) that names neither an agent nor a model.
  `visibility` was our own nesting of two ideas the one supported runtime already
  has keys for; it is gone in favour of `user-invocable` and
  `disable-model-invocation`. `pull-only` was never implemented and is retired:
  a source you do not want to publish back to is one you do not push to.
- `--pull` reads nothing and does nothing, which is correct — an update never
  publishes. It exists so "take, publish nothing" can be said rather than
  assumed, and it now says so instead of being silently ignored.
- Removing `KAUK_ORIGIN` made it impossible to reach the working tree's package
  contents through `init`, since `init` always declares `kaukea/kauk` and fetches
  that. Tests that need the local build install it by path instead.

## Proposal

Withdraw the skill, strip every reference to another package's launcher, define
the frontmatter that was declared and never explained, and retire what was never
built.

## Testing

`tests/convention-reader.sh` gains nine assertions: a repository installing kai
alone gets no skill about another package, still gets the agent skill, that skill
names no privileged launcher, it launches any agent by name, and nothing it ships
is missing; plus `--pull` publishing nothing, keeping the edit local, and being
refused alongside `--push`. The withdrawal migration is exercised by hand against
a laid link, a link from a different package that must survive, and a second run.
629 assertions across twelve suites, all green.

## Changelog entry

#### ✨ `f/kai-is-self-contained` → `archive/kai-is-self-contained`

kai shipped a skill telling every repository that installed it that agents must be
launched through a script kai does not ship, and that work launched any other way
was invalid — verified by installing kai into an empty repository and getting the
instruction without the file. It is withdrawn, along with every reference to that
launcher in the `agent` skill and its script, and a migration removes the laid
link from consumers rather than leaving a dangling one behind. Any agent can be
launched by calling the CLI with the right parameters; there is no privileged
launcher. `compatibility` is now defined as the agents and models an artifact
works with; `visibility` gives way to the keys the runtime actually reads; and
`pull-only`, never implemented, is retired. `--pull` says "take, publish nothing"
rather than being silently ignored.

_Board: `kai-is-self-contained` · relates to `runtime-topology`._

## Readme delta

None.
