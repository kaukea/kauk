- created: 2026-08-18
- created_by: fable-5 (adoption readiness walk)

## Blockers

None — and deliberately the first task to run THROUGH the orchard topology
in this repository ([[adopt-orchard-here]]).

## Questions

_None open — direction ruled (operator, 2026-08-18, superseding the same-day
parking): the settings takeover is a NEVER-EVENT, so this wiring does not wait
for the plugin._ The scope: a package-shipped settings file; every fleet
dispatch appends `claude --settings <file>` (partial merge, per-invocation);
the operator's entry is a VISIBLE `/gardener` skill in a plain session that
spawns the real gardener session with `--settings` into its own window and
hands over (a session cannot re-settings itself — subprocess is the only way;
the pattern is the fleet's existing dispatch). The plugin
([[claude-marketplace]]) remains the eventual self-contained delivery; this
wiring is what lets [[settings-lay-clobbers]] retire the laid link NOW.

- ~~Open edge: where the skill comes from on a fresh machine (installing kai vs
  installing orchard)?~~ EXPLICIT VOLUNTARY DEFERRAL (operator ratification,
  2026-08-18, Decision-050 round): settled when a fresh machine is real, not in
  this launch. Neither install path is built here; the skill ships and works on
  the machines that exist today.

## Findings

Readiness walk (2026-08-18): fleet agent defs, dispatch tooling, couriers
and hooks are all laid in kauk; hook wiring currently rides the operator's
machine-wide settings. kauk has no repo-level .claude/settings.json —
orchard's 78-line fleet wiring (permission mode, courier lifecycle,
question broker mounts) has no counterpart here, correctly unshipped per
Decision-019.

## Proposal

Superseding mechanism (operator, 2026-08-18): the fleet launches every agent
itself, and `claude --settings <file>` applies a custom settings file
per-invocation (partial merge — omitted keys keep their file-based values).
So the fleet's hooks and permission wiring ride the SPAWN COMMANDS — dispatch
tooling appends `--settings` pointing at the package's own settings file —
and need not live in the repository's `.claude/settings.json` at all. Author
the package settings file and wire the dispatch paths accordingly; the
repository's own settings.json stays project-owned (see
[[settings-lay-clobbers]] — its JSON Patch shrinks to whatever must affect
the operator's own interactive session, possibly nothing). Run as the first
gardener-dispatched task here.

Sequencing (operator, 2026-08-18, Decision-050 round): SEQUENTIAL — this task
launches now; [[settings-lay-clobbers]] launches only after this one closes
with its live test passed, so the link-retiring migration ships to the estate
only once spawn-time settings are proven.

### Agreed build (operator, 2026-08-19, MAKE IT SO)

The settings wiring is delivered by kai shipping its OWN settings file
(`bin/kai.settings.json`, Decision-060) which every fleet dispatch passes with
`claude --settings`. That much is built. This round closes the defects in that
delivery and the migration machinery it depends on.

kai becomes a real package: the agent-launch skill plus its migrations, and
nothing else — everything else is in the bin, already on PATH from the static
install. Installing the kai package is how a repository subscribes to kai's
migrations, which is what closes the circle a package with no dependencies
currently falls out of.

The migration engine reduces: no self-source, no per-package state, one global
watermark, all packages migrating together.

The estate is carried by migrations, not by hand. The diff between the
operator's takeover of the redesign (2026-08-10) and today IS the migration.

### This round (operator, 2026-08-20, MAKE IT SO)

Two remaining defects closed: (1) the `/garden` skill shipped hardcoded to launch
`gardener` specifically, contradicting the standing scope — kauk ships only a
generic agent-launch skill, no agent name baked in; the gardener-specific launcher
is orchard's own, built there on orchard's own schedule, not this branch's. (2)
main independently shipped its own migrations engine (per-source watermark +
agent-ask escape hatch) via the separate, already-closed migrations-at-sync
feature, ten hours before this branch's later commit implementing the operator's
own subsequent ruling above (global watermark, no ask files). The rebase resolves
in favor of this branch's design; main's non-conflicting additions (`prune_links`
rewrite, orphan-clone sweep) are kept.


## Decision entries

- 2026-08-18 `#settings` `#launch`: the settings pair is sequential —
  fleet-settings-wiring first, settings-lay-clobbers dispatched only after its
  close; the fresh-machine skill-source edge (kai vs orchard install) is an
  explicit voluntary deferral until a fresh machine exists. (Operator,
  Decision-050 pre-launch round.)


## Decision entries

- 2026-08-19 `#migrations` `#packages`: `is_self_source` is DELETED. A
  repository declares itself a package with `[general] type = "package"` in
  `.ai.toml`, and that declaration — not an inferred self-source entry — is
  what makes kai apply the repository's own migrations, use its own agents and
  skills, and symlink its own files. `.ai.toml` is the user's file to manage
  however they like; no behaviour may be inferred from whether they happened to
  declare their own path as a source. The old inference was also a false
  premise: kai installs the kai package, so there is never not a package.
  (Operator, 2026-08-19.)

- 2026-08-19 `#migrations` `#watermark`: ONE global watermark — the
  `<YYYY-MM-DD>-<NN>` prefix of the last applied migration, one line, committed
  under `.ai/`. Not per package and not per source. Every source's migrations
  plus the repository's own merge into a single stream ordered by that prefix;
  everything above the watermark applies. A same-day set written together for
  one version is ONE migration run, ordered within the day by `<NN>`; a hotfix
  after a release takes the next `<NN>` and reaches anyone still sitting at the
  earlier one. Per-package watermarks made packages apply migrations in strange
  orders relative to each other. Absent watermark = fresh install: run nothing,
  stamp the current datetime. (Operator, 2026-08-19.)

- 2026-08-19 `#migrations` `#naming`: migration files are
  `migrations/<YYYY-MM-DD>-<NN>-<featurename>.md`, one file per feature,
  applied in ASCII order — the usual convention where scripts must be ordered.
  Supersedes the `<YYYY-MM-DD>-<slug>.md` form in `docs/package-format.md`.
  (Operator, 2026-08-19.)

- 2026-08-19 `#migrations` `#errors`: migration errors are REPORTED, not
  handled. No ask files, no blocking, no hand-off of a step to an agent. Kai
  says what failed and moves on. Self-testing migrations may be revisited one
  day. (Operator, 2026-08-19.)

- 2026-08-19 `#migrations` `#tests`: migrations do NOT ship tests to consumers.
  A migration is tested in the repository that ships it. (Operator,
  2026-08-19.)

- 2026-08-19 `#agents` `#reload`: an agent is reloaded by RELOADING ITS
  SESSION, which loads the latest session file — otherwise agents lag behind
  definitions that have already moved. Supersedes the reload clause carried as
  a sub-bullet inside Decision-043, which is a ruling about upgrade being the
  operator's act and does not govern this. (Operator, 2026-08-19.)

- 2026-08-19 `#state` `#durability`: durable state leaves `.git/` and lives in
  `.ai/`, committed. Nothing writes under `.git/` without the operator's
  permission. State worth keeping must survive a clone — a workstream log that
  vanishes when the repository is cloned is the same mistake as any other lost
  state, and committed agent memory is the existing precedent. The operator
  validates both the FORMAT and the EXISTENCE of durable files. The estate does
  not touch `.ai/`, so the move is not disruptive; and any move from `.git/` to
  `.ai/` is carried BY A MIGRATION. (Operator, 2026-08-19.)

- 2026-08-19 `#packages` `#kai`: the kai package contains the agent-launch
  skill and its migrations, and nothing else — everything else is in the bin,
  already present from the static install. Installing the kai package is how a
  repository subscribes to kai's migrations; that subscription is what closes
  the circle for a package that declares no dependencies of its own.
  (Operator, 2026-08-19.)

- 2026-08-19 `#verification` `#close`: a close-gate proof that exercises only
  the arrangement the developer happened to build in is not verification. Where
  two components sit at opposite ends of one path-resolution contract, the gate
  must exercise the DEPLOYED arrangement (a symlinked install, not a repo-local
  one) and must diff the two ends against each other. Live-fired:
  `kai.settings.json` resolved `kai-hooks.sh` with `dirname` alone while
  `dispatch-agent.sh` resolved `kai.settings.json` with `readlink -f`, and the
  suite stayed 13/13 green throughout. (Operator, 2026-08-19.)

- 2026-08-20 `#skills` `#launch` `#carriage`: kauk ships only a GENERIC agent-launch
  skill — no agent name baked in, takes the agent to launch as an argument. The
  gardener-specific launcher (a skill that launches the gardener by name, using
  the generic one underneath) is orchard's, not kauk's — deferred entirely to
  orchard's own choice and schedule, not built or carried on this branch.
  (Operator, 2026-08-20.)

- 2026-08-20 `#migrations` `#rebase` `#carriage`: main independently shipped its
  own migrations engine (per-source watermark files, an `applied-by: agent`
  ask-file escape hatch) via the separate migrations-at-sync feature, landed
  hours before this branch's later commit implementing the operator's own
  subsequent ruling recorded above (one global watermark, no ask files). Operator,
  verbatim, on which survives the rebase: "This branch is the correct approach for
  now because the ask scale and everything else around it can be designed
  correctly once it has been scheduled on the board correctly." This branch's
  design wins the conflict; main's independent, non-conflicting additions
  (`prune_links` rewrite, orphan-clone sweep) are kept. Consequence for whoever
  ingests this at close: main's Decision-057/058 (the `applied-by: agent` ask-file
  format) describe a mechanism this resolution retires — likely stale once this
  branch lands, not struck here since that call belongs to whoever reconciles
  decisions.md at ingest.

## Testing

A fleet session in kauk fires its own wiring: courier loads, lifecycle
hooks run, permission mode holds — observed live by the operator.

### Live test run (2026-08-24, HEAD 099155d, operator watching)

Operator ruling going in: do NOT repoint `~/.local/bin/kai` / `~/.local/bin/kauk`
to this worktree. Run as-is, wherever `kai` naturally resolves; a path/directory
resolution oddity is a wanted finding, not a blocker.

Dispatched a real agent through `.claude/tools/dispatch-agent.sh` exactly as any
fleet agent is launched (agent `claude`, name `live-test-fsw`, this worktree's cwd).
Verified by reading the actual running process, not by trusting output:

- `cat /proc/<pid>/cmdline` on the spawned `claude` process:
  `claude --agent claude --name live-test-fsw <prompt>` — **no `--settings` flag
  present.**
- Reason, confirmed by hand-running dispatch-agent.sh's own resolution: `command -v
  kai` → `~/.local/bin/kai` → `readlink -f` → `/home/sudoku/src/kaukea/kauk/bin/kaukea`
  (MAIN's checkout) → candidate `/home/sudoku/src/kaukea/kauk/bin/kai.settings.json`.
  That candidate does not exist on disk — `bin/kai.settings.json` and
  `bin/kai-hooks.sh` exist only on this branch's worktree, unmerged into main. The
  existence guard behaved exactly as designed: no file, no flag, no crash, no bogus
  path passed.
- Consequence, confirmed by asking the spawned session directly and by reading
  `~/.claude/settings.json`: it ran under the machine-wide settings file only (hooks:
  `claudetui`, `voice-dictate-ensure`, `claude-queue`, pane-title — all pre-existing,
  none of them this feature's). This worktree carries NO repo-level
  `.claude/settings.json` (removed by this feature's own design, confirmed
  `ls .claude/settings.json` → not found). No courier-only-transport guard, no
  courier-init hook, no permission-mode pin from `kai.settings.json` were in force
  for that session — none of kai's fleet wiring engaged.

**Read plainly**: the code is correct and safe (the guard does exactly what it was
built to do), but the live test as run **could not positively demonstrate** "courier
loads, lifecycle hooks run, permission mode holds" via the NEW wiring, because that
wiring only activates once `kai` (as resolved on PATH) actually has
`bin/kai.settings.json` + `bin/kai-hooks.sh` beside it — i.e. once this branch reaches
wherever `kai` resolves from (main, today). That is inherent to testing an unmerged
branch against a statically-installed PATH tool, per the operator's own framing, not a
defect in the branch.

Test pane (%19) was my own throwaway dispatch — killed cleanly after observation, not
an orphaned predecessor pane.

## Operator requests

Ledger of items given mid-build, recorded as received.

- 2026-08-19 — "bugs that should not have been allowed at close of the
  features … a lack of care, a verification that is part of the orchard
  process specifically". The `--settings` wiring shipped with a green suite
  while the two ends of its path-resolution contract disagreed. Fix the defect
  AND audit the delivered surface for others of the same family; do not bring
  repair work to him as a decision. — IMPLEMENTED AND VERIFIED: the
  resolution-mismatch fix (e72c6c8), the self-source fixture fix (8ad30bc/
  3a1051c) and the watermark fixture fix (099155d) are three successive finds
  of the same defect family across three sessions, each fixed and each
  re-verified by a fresh landscaper independently running the suites rather
  than trusting the fixing session's word. All five suites green, 229/229,
  as of 099155d.
- 2026-08-19 — "after install kai is a shared cli so of course it is used to
  install packages": kai's presence on PATH is a given of a static install,
  not an open design question for this feature. — ACCEPTED. SUPERSEDED
  2026-08-24: the operator has since ruled the live test runs with `kai`
  resolving wherever it naturally resolves on this machine (main's checkout,
  which lacks this branch's files) — explicitly NOT "making it true on this
  machine before the live test" as this line originally anticipated. See
  ## Testing → Live test run.
- 2026-08-19 — "there is an issue with kai packages like orchard. THey may
  have no package dependencies, but they have migrations, that they need to
  apply to themselves, this requires resolving now". A package repository is
  also a consumer of itself: orchard declares no sources, so nothing drives
  its own `migrations/` over its own working tree. Recorded as received;
  under discovery. — IMPLEMENTED on this branch (`is_package_repo`/
  `[general] type = "package"`, built pre-this-session); verification pending
  the rebase and a full suite re-run this session, not yet independently
  confirmed end to end against orchard's own working tree.
- 2026-08-19 — RULING on the above: "if .ai.toml has a general section with
  type=package section any call to sync applies migrations and reloads agents
  at the end of migrations (which should happen anyway for any project)".
  So: a new `[general]` table with `type = "package"`; sync applies the
  repo's own migrations when it is set; and the agent reload becomes
  unconditional at the end of every sync, package or not. — RECORDED
