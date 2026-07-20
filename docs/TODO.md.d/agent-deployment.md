- created: 2026-07-17
- created_by: opus-4.8
- created_during: orchids board work (cross-repo spec handoff)

## Blockers
- The frontmatter syntax is orchids' call and not yet settled (their
  `role-dag-frontmatter`). kauk must parse it, and bash+awk argues hard for flat string
  values — agree it across both boards before either side builds.

## Questions
- Agent→agent dependencies: does an agent depend on other AGENTS, not just skills? The
  real graph has them (orchestrator → architect/housekeeper/ripener; architect →
  builder). orchids' ruling covers agent→skill only. If yes, page 1 needs the same
  greyed-out treatment page 2 has.
- Does `agent` need a role field of its own, or is an agent's role implied by the roles
  of the skills it requires? Simpler if declared; less to keep in step if derived.
- Two pages in a **bash** CLI: what is the interaction model? This is `bin/kauk`
  (396 lines, no TUI). A two-page picker with greyed-out rows may be the thing that
  finally argues for doing it in `cli-mvp` (0.1.0) instead of the stopgap — same
  question `role-aware-delivery` raises. Decide once, for both.
- Migration: existing repos have all 5 agents laid via `link` lines. On upgrade, does
  kauk prune agents the operator did not choose, or leave what is already there?

## Findings
- **Agents are `link` lines today** — `link agents/architect.md
  .claude/agents/architect.md` — which `manifest.conf`'s own header documents as
  "everyone gets it". All 5 install unconditionally into every repo, with no identity,
  no role, and no opt-out. Skills at least have a (dead) role field; agents have nothing.
- `lay_source` (`bin/kauk:114-140`) dispatches on `read -r t a b _rest` and
  warns-and-skips unknown types, so a new `agent` type is additive and
  backward-compatible at the parse layer.
- Unlike `skill` lines (which carry no src/dst — the engine hardcodes
  `skills/<name>/` → `.claude/skills/<name>` at `:122-126`), agents currently must spell
  out both paths because they ride the generic `link` type. An `agent` type would fix
  the layout the same way `skill` does.
- **kauk has no YAML reader at all** (`SKILL.md` is touched only byte-level at `:158`,
  `:269-271`, `:279-280`). Reading `requires:` from agent frontmatter is new capability,
  shared with `role-aware-delivery` — build the reader once.

Operator rulings from orchids, 2026-07-17 (spec — implement, do not relitigate):
- **The package gains an `agents/` folder, symmetric with `skills/`**, linked into place
  from its own location exactly as skills are. Agents are a peer artifact, not a skill
  variant.
- **Each agent declares its required skills in its own frontmatter** — a list of skills
  shipped in the package. External dependencies are explicitly deferred (orchids
  `agent-external-deps`); do not design for them, only avoid precluding them.
- **Install selection is TWO PAGES.** Page 1: choose agents. Page 2: choose skills, with
  the skills required by the page-1 agents shown **greyed out** — visible, already
  selected, not deselectable. Greyed-out rather than hidden is deliberate: the operator
  sees what their agent choice pulled in and why it is not theirs to uncheck.
- Agents come first because an agent is what an operator actually wants; its skills
  follow from it.

## Proposal
1. `agent <name>` manifest line type: `agents/<name>.md` → `.claude/agents/<name>.md`,
   layout in the engine, mirroring the `skill` type.
2. Read `requires:` from agent frontmatter (shared reader with `role-aware-delivery`).
3. Two-page picker at install; resolve page-1 agents' requirements onto page 2 as
   locked, visible rows.
4. Keep the existing `link agents/*.md` lines working until the type ships, so no repo
   regresses mid-migration.

## Testing
Scratch repo: choose one agent on page 1; assert page 2 shows its required skills
greyed out and selected, that they cannot be deselected, and that the laid
`.claude/agents/` + `.claude/skills/` sets are exactly agent + requirements + freely
chosen extras. Assert an unchosen agent is NOT laid — the current behaviour is
"everyone gets all five", so that is the regression to prove gone. Backward compat: a
package still using `link agents/*.md` installs exactly as today.
