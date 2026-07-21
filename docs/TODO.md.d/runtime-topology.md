- created: 2026-07-21
- created_by: fable-5
- created_during: orchestrator board pass (operator directive)

## Blockers

_None._

## Questions

_All answered by the operator, 2026-07-21 (Decision-013):_

- ~~Which runtimes are targets for the first cut?~~ **Claude-only for now** —
  the model is runtime-shaped, nothing opencode-specific rendered yet.
- ~~What is the SOURCE form of a hook?~~ **Packages are declarative**: events
  mapped on one side, what they can trigger on the other, per-runtime
  ADAPTATION LAYERS as the common case, and a runtime-prefixed opt-out
  (`claude:on-...`) for authors shipping runtime-specific behaviour.
- ~~Transpile at sync or install?~~ **Detected at `kauk sync`.**

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

Design the artifact-type × runtime target topology per Decision-012/-013: for
each artifact kind (agent, skill, hook, tool, template, rule file), a
runtime-neutral DECLARATIVE source form, with per-runtime adaptation layers
mapping declared events to what each runtime can trigger, and the
runtime-prefixed opt-out (`claude:on-...`) for deliberately runtime-specific
packages. First cut renders Claude Code only; the runtime is detected at
`kauk sync`. Hooks are the forcing case, replacing the current settings.json
wiring. The extension-point survey task (~extension-point-survey) supplies the
per-runtime capability inventory the adaptation layers are built against.
The operator holds a plan for this task — collect it at scope time before the
architect drafts its own. Output is the model (ARCHITECTURE.md + decision)
plus the reader changes it implies; stopgap-vs-0.1.0 timing shares the
manifest task's question.

## Testing

The same package syncs into a Claude Code repo and (at least in a dry-run
rendering) an opencode repo: agents, skills, and one representative hook land
in each runtime's correct location and format, from one source tree, with no
runtime-specific source edits.
