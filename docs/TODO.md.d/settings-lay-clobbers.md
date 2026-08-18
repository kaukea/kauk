- created: 2026-08-18
- created_by: fable-5

## Blockers

(none)

## Questions

- ~~How do shared fleet settings compose with per-project Claude settings?~~
  Operator ruling (2026-08-18): two routes, picked by a documentation fact, not a
  further decision. (1) If Claude Code supports ADDITIONAL settings files that
  merge alongside the project's `settings.json`, the package lays its fleet
  settings as such an added file and the project keeps its own. (2) If it does
  not: prepend blocks are for MARKDOWN (the CLAUDE.md → AGENTS.md include case) —
  a marker block cannot live inside JSON. For settings the fallback is an
  ADJACENT PATCH FILE (operator, 2026-08-18): the package lays a settings patch
  file next to the project-owned `settings.json`, and the sync script merges it
  in — idempotent, kai-owned per Decision-055. VERIFIED 2026-08-18 (docs:
  code.claude.com/docs/en/settings.md, hooks.md, plugins.md): route (1) does not
  exist — settings levels override WHOLESALE (Managed > CLI > Local > Project >
  User); the only additive surfaces are hooks (collected from all scopes,
  plugin-shippable via hooks/hooks.json) and per-key env merging. Route (2) is
  therefore the design, and the operator names the mechanism: a **JSON Patch**
  document laid adjacent, applied to the project-owned `settings.json` by the
  kai sync script. The package stops owning `.claude/settings.json`.
- ~~Immediate relief (detach the laid link in consumers now)?~~ Operator: no —
  leave standing until the mechanism ships.
- Immediate relief wanted in consumers now (un-lay / detach the link in kauk and
  the estate until the design lands), or leave standing since it has been the
  laid state since bootstrap?

## Findings

- The design predates today: kauk has tracked `.claude/settings.json` as a link to
  the shared package settings since bootstrap (e69c6f3); the manifest era placed it
  (`link settings.json .claude/settings.json`) and the convention era relays it
  from `files/.claude/settings.json`. The kaukea move left it dangling; the
  2026-08-18 heal re-attached it, re-arming the overwrite.
- What the package currently imposes on every consumer: `permissions.defaultMode:
  auto`, fleet hooks (courier transport, prompt hooks). A consumer cannot carry
  its own project-level `settings.json` at all.
- Orchard's own `.claude/settings.json` was and remains a self-link — no content
  was lost there.
- Mechanism boundaries (operator, 2026-08-18): prepend is the CLAUDE.md
  mechanism — and even CLAUDE.md composes from multiple files via `@` imports
  (this repo's CLAUDE.md does exactly that), so prepend's job there is only the
  minimal project-owned stub carrying the imports. JSON settings get the
  adjacent JSON Patch; markdown gets @-imports with prepend for the stub.

## Proposal

The package ships its fleet settings as a JSON Patch document laid adjacent to the
consumer's `.claude/settings.json`; the kai sync script applies it to the
project-owned file, idempotently (re-sync converges, never duplicates). The laid
symlink at `.claude/settings.json` goes away; a shipped migration converts
consumers (link removed, project file created/patched) — all steps scripted
(Decision-055). Note for adjacent tasks: plugin `hooks/hooks.json` is additive
across scopes per the docs — relevant to claude-marketplace (gh#22) and
fleet-settings-wiring (gh#30) as a hooks-only channel, but the patch mechanism
covers permissions and the rest uniformly.

## Testing

To be agreed at bloom. Candidate: consumer fixture with a project-local
`settings.json`; sync; assert the project file survives and fleet settings are
still in effect through the chosen mechanism.
