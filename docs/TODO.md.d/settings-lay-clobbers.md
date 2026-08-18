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
  not, this is exactly what templates-with-prepend were designed for
  (templates-spec, gh#17): `settings.json` becomes a project-OWNED file carrying
  an idempotent, marker-tracked fleet block kept up to date at sync — the same
  mechanism that lets CLAUDE.md include AGENTS.md. Doc verification of route (1)
  in flight; whichever holds, the package stops owning `.claude/settings.json`.
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

## Proposal

Stop the shared settings file from owning consumers' `.claude/settings.json`;
replace with a composition mechanism per the answered Question. Essential steps
scripted (Decision-055) — the migration that moves consumers off the current
layout ships with the change.

## Testing

To be agreed at bloom. Candidate: consumer fixture with a project-local
`settings.json`; sync; assert the project file survives and fleet settings are
still in effect through the chosen mechanism.
