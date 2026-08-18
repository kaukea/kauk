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
- Mechanism boundaries, VERIFIED against the harness docs (2026-08-18,
  code.claude.com/docs/en/memory.md): the operator's recollection holds —
  MULTIPLE markdown rule files auto-load natively from `./.claude/rules/*.md`
  (recursive, symlinks supported, optional `paths:` frontmatter scoping), with
  no edit to the project's CLAUDE.md; `@`-imports also exist (4-hop recursive).
  So markdown rules are DROPPED files — prepend is only the fallback had this
  not existed, and the CLAUDE.md include-stub is unnecessary for rules. JSON
  settings remain the adjacent JSON Patch (no additive settings surface).
  Operator refinements (2026-08-18): AGENTS.md — the project-owned rules the
  user edits — stays VISIBLE at repo root, never hidden in `.claude/rules/`;
  the package-shipped AGENTS.shared.md and AGENTS.files.md MAY lay into
  `.claude/rules/` (accepted as a possibility, settled at the scope round).
  And the plugin bound is narrower than the docs' "no rule markdown": plugins
  ship their own hooks and settings, and a plugin hook at startup can ADD the
  rule files/context itself — so rules can ride the plugin channel via its
  hooks (relevant to claude-marketplace gh#22).

## Proposal

Single mechanism (operator, 2026-08-18 — the JSON Patch tier was considered and
DROPPED the same day): every fleet session is a SPAWNED session — dispatched
agents already launch through our own tooling, and the first session enters
through the visible gardener skill that spawns the real session (see
[[fleet-settings-wiring]]). Each spawn carries `claude --settings <file>` with
the package's settings (partial merge, per-invocation). With no session left
that needs the repository file, there is no reason for a JSON Patch: the laid
symlink at `.claude/settings.json` is simply RETIRED via a shipped migration
(link removed; `.claude/settings.json` belongs wholly to the project and the
operator) — all steps scripted (Decision-055). Depends on the spawn-time
settings being wired first, or sessions lose their hooks in the gap. Note for
adjacent tasks: plugin `hooks/hooks.json` is additive across scopes — relevant
to the marketplace task as a hooks channel.

## Testing

To be agreed at bloom. Candidate: consumer fixture with a project-local
`settings.json`; sync; assert the project file survives and fleet settings are
still in effect through the chosen mechanism.
