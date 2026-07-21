- created: 2026-07-21
- created_by: fable-5
- created_during: orchestrator board pass (operator directive)

## Blockers

_None._

## Questions

- Which runtimes are targets for the first cut? Claude Code is live; opencode is
  the named second. Is opencode a build target now, or only a design constraint
  the model must not preclude?
- What is the SOURCE form of a hook? Today a hook is a bash script plus
  Claude-specific `settings.json` wiring (event names, matchers). A portable
  hook needs a runtime-neutral declaration (event, filter, action) that
  transpiles to each runtime's mechanism — settings.json entries for Claude,
  whatever opencode uses natively. How much of today's hook inventory fits a
  neutral event vocabulary, and what is irreducibly runtime-specific?
- Does transpile-and-lay happen at `kauk sync` time (per-repo, per-runtime
  detection) or at install time (explicit target choice in `.ai.toml`)? How is
  the runtime detected/declared per repo?

## Findings

- Operator directive (2026-07-21): the goal is write-once agents/skills/hooks,
  transpiled if needed and moved based on which agent runtime is in use — "we're
  in Claude but we could be in opencode". Designs must adapt; the current
  approach to hooks is VERY FLAWED (Decision-012).
- Current state, all Claude-hardcoded: payloads lay into `.claude/skills|agents|
  hooks|tools`; hook activation rides `settings.json` (Claude event names:
  SessionStart, UserPromptSubmit, Stop) linked wholesale as `link settings.json
  .claude/settings.json`; agents are Claude `--agent` markdown. None of it has a
  runtime-neutral source form.
- Skill autoselection per agent (agent-deployment, gh#8) depends on this model —
  the operator gates it behind this task explicitly.
- Related reshaping in flight: Decision-011 removes manifest.conf (the tree
  defines the package) — the topology model decides where each artifact type
  LANDS per runtime; the tree decides WHAT ships. The two must compose.

## Proposal

Design the artifact-type × runtime target topology: for each artifact kind
(agent, skill, hook, tool, template, rule file), define its runtime-neutral
source form in the package and the per-runtime transformation + destination
(Claude Code first, opencode as the proving second target). Hooks are the
forcing case: a neutral hook declaration transpiled into each runtime's wiring,
replacing the current Claude-specific settings.json approach. Output is the
model (documented in ARCHITECTURE.md + a decision) plus the reader changes it
implies; implementation may land in the stopgap or wait for the 0.1.0 CLI per
the same question the manifest task carries.

## Testing

The same package syncs into a Claude Code repo and (at least in a dry-run
rendering) an opencode repo: agents, skills, and one representative hook land
in each runtime's correct location and format, from one source tree, with no
runtime-specific source edits.
