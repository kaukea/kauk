- created: 2026-07-21
- created_by: fable-5
- created_during: orchestrator board pass (operator directive)

## Blockers

_None._

## Questions

_None open — the runtime list is "the agents we want to support" (Claude Code
now, opencode named next, per Decision-012/-013); the deliverable is itself a
decision the operator gates._

## Findings

- Operator directive (2026-07-21): collect, from each agent runtime we want to
  support, which EXTENSION POINTS it offers — both prompt injection (getting
  content into the model's context: rule files, skills, slash commands, memory)
  and code injection (getting code executed: hooks, plugins, MCP servers,
  tools) — then decide a model for how kauk builds on them. Expected outcome,
  operator-stated: kauk's Claude integration probably ships as a **Claude Code
  plugin** (plugins bundle skills, agents, hooks, and MCP servers in one
  installable unit — one vehicle instead of loose file laydown).
- Known Claude Code surface to seed the survey: skills (`.claude/skills`),
  agents (`.claude/agents`), hooks (settings.json events), slash commands, rule
  files (CLAUDE.md/AGENTS import), MCP servers (.mcp.json), plugins
  (marketplace, bundling all of the above), output styles.
- The runtime-topology task's adaptation layers are built AGAINST this
  inventory — this survey is its input.

## Proposal

Produce the extension-point matrix: runtime × extension point, each entry
noting what can be injected (prompt content vs executable), when it fires, and
how it is installed/activated. Cover Claude Code fully; cover opencode to the
depth needed to prove the adaptation-layer model holds. Then propose kauk's
integration model per runtime — evaluating "kauk as a Claude Code plugin" as
the leading candidate — and park it as a decision for the operator.

## Testing

The matrix names every extension point the topology task ends up using (no
adaptation layer built on an unsurveyed mechanism), and the integration-model
proposal is reviewed and decided by the operator.
