- created: 2026-08-18
- created_by: fable-5
- completed: 2026-08-26
- completed_during: f/settings-lay-clobbers

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
  leave standing until the mechanism ships. (Duplicate phrasing of the same
  question removed 2026-08-18 — overtaken: the mechanism ships in this launch.)

## Findings

Result: merged to main on 2026-08-26, preserved under
archive/settings-lay-clobbers.

- What the estate run found (2026-08-26), and what actually had to be built:
  the laid symlink is only half the problem. Migration
  `2026-08-19-05-adopt-kai-hooks` COPIES kai's own settings file into any
  consumer that has none, so retiring the link alone leaves a real settings
  file behind in every repository that runs the stream. It does not overwrite
  anything — it fills an empty slot and reports otherwise — but Decision-061
  (2026-08-24, later than that migration) forbids a settings JSON inside a
  consumer at all.
- Migrations are never rewritten, so `2026-08-19-05` stands and the new
  migration is dated after it: the adoption writes the file and the retirement
  takes it back within the same run.
- The refusal to lay belongs in the TOOL, not in each package: orchard's old
  clones across the estate still carry `files/.claude/settings.json`, and a
  package-side removal would only reach a repository after it had already been
  laid once more. `never_laid` in bin/kaukea refuses both
  `.claude/settings.json` and `.claude/settings.local.json` out of any
  package's files/ tree, announcing each refusal.
- Ownership is decided by content, not by position: a real file byte for byte
  identical to the `kai.settings.json` beside the resolved `kai` is kai's and
  goes; one byte of difference makes it the operator's and it stays. A symlink
  is taken back only when it points into `.ai/repositories/`.
- Orchard still ships `files/.claude/settings.json` at source. Removing it
  there is an orchard change and the operator's to make (2026-08-26); the
  tool's refusal makes it harmless in the meantime.
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
operator) — all steps scripted (Decision-055). NEVER-EVENT ruling (operator,
2026-08-18, final): overwriting the user's settings is taking over their code —
this retirement does NOT queue behind the plugin. The carrier is spawn-time
settings ([[fleet-settings-wiring]]): once every fleet session gets its
settings at spawn, the shipped migration removes the laid link and
`.claude/settings.json` returns to the user. The plugin
([[claude-marketplace]]) remains the eventual self-contained delivery and
simply inherits the already-clean state.

Sequencing (operator, 2026-08-18, Decision-050 round): launches only after
[[fleet-settings-wiring]] closes with its live test passed. The `.claude/rules/`
placement of AGENTS.shared.md / AGENTS.files.md is NOT part of this launch — it
stays with the existing [[shared-rules-placement]] task (operator ratification,
same round).

## Testing

Method as drafted (operator, 2026-08-18): a consumer fixture with a
project-local `settings.json`, synced, asserting the project file survives.

Run 2026-08-26, `tests/settings-retirement.sh`, 20 assertions, all green:

- a package shipping BOTH `.claude/settings.json` and
  `.claude/settings.local.json` gets neither laid, on install and on a later
  sync, while its skills and its `files/` tree lay normally; both refusals are
  announced with the reason;
- a project's own settings file survives a sync and the migration, and is
  reported as the operator's;
- a package-laid symlink is removed and the removal staged; a second run has
  nothing to do;
- a symlink pointing anywhere other than the package store survives;
- a file identical to kai's own is taken back; the same file with one byte
  appended is not.

The whole repository's suites at branch HEAD: 285 assertions across seven
files, all green.

Also run against a real repository (SafeKeepIt/SignMc, 2026-08-26): its
package-laid `.claude/settings.json` link was removed, the deletion staged, a
second run reported nothing to take back, and the repository was restored to a
verified byte-identical state afterwards.

NOT tested here: that fleet settings still arrive through spawn-time
`--settings`. That is [[fleet-settings-wiring]]'s live test, which the operator
ran at its close; this feature does not change that path.

## Changelog entry

#### ✨ `f/settings-lay-clobbers` → `archive/settings-lay-clobbers`

`.claude/settings.json` belongs to the project again. Exactly one settings JSON
exists and it is passed at spawn (Decision-061), so kai now refuses to lay
`.claude/settings.json` or `.claude/settings.local.json` out of any package's
`files/` tree, announcing each refusal rather than skipping quietly. The refusal
lives in the tool, so nothing puts one back on a later sync whatever a package
still carries.

`migrations/2026-08-26-04-settings-json-returns-to-the-project.md` takes back
what is already there, and decides ownership by content rather than position: a
symlink into the package store goes, and a real file byte for byte identical to
the `kai.settings.json` beside the resolved `kai` goes — that being exactly what
`2026-08-19-05-adopt-kai-hooks` writes. Anything else is reported and left,
including a file that started as kai's and was then edited.

_Board: `settings-lay-clobbers` · never-event ruling: operator, 2026-08-18 ·
Decision-061._

## Readme delta

None. README.md does not mention settings delivery at all — checked by grep at
close — and this change alters no command, flag or build step a reader of it
would act on. The rule itself lives in AGENTS.md and ARCHITECTURE.md, both of
which already carried it and one of which is updated here.
