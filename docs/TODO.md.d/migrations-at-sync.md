- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

None.

## Questions

_None open — the spec is ruled._

## Findings

`AGENTS.files.md` §Migrations never specified who executes or when. The watermark is a single global scalar and the pending count is computed against a stale clone.

Decision-050 pre-launch bloom (2026-08-18): converged with overall SE 0.68, band
"lower" — the numeric band reflects the operator truncating the question round by
ratifying the drafted plan wholesale, not open disagreement; item parameters are
LLM-assumed, uncalibrated (v1 caveat). Launch sizing recommendation: L, fable-5,
high effort.

Decision-055 (2026-08-18) makes this task the owner of migration application and
URGENT: kai owns the applying — each migration a script (or markdown carrying its
script), applied in order, watermark dates set by the tool, identical whichever
agent (or none) is present; agents hold no essential step. Live failure that
forced the ruling: kauk's convention-packages migration never executed in orchard
(no channel), and hand-application drifted from the scripted step (settings.json
destination) — see stale-laid-links and package-migration-reach (cancelled into
this task).

Close determinations (landscaper, 2026-08-18):

- ARCHITECTURE.md: skipped, evidenced — `grep -i migration ARCHITECTURE.md` is
  empty; the taxonomy never covered migration mechanics and this feature adds no
  new artifact kind or taxonomy concept, only sync behaviour in `bin/kaukea` and
  the `docs/package-format.md` §migrations spec, which was updated on-branch.
- Readme delta: skipped, evidenced — README's sync description ("pulls with
  rebase and lays") remains true, and the invisible-plumbing ruling (Decision
  entry above) forbids user-facing migration vocabulary.
- Follow-up for the gardener (cross-repo, out of this branch's authority):
  `AGENTS.files.md` and `.claude/hooks/migrations-pending.sh` are symlinks into
  the vendored kaukea/orchard clone — their §Migrations text and the hook still
  carry the retired agent-applies model and could not be edited from this kauk
  branch. The replacement §Migrations content is written in
  `docs/package-format.md` §migrations/ (ready to transplant); the hook rewrite
  is designed: drop the read/apply/advance-watermark instruction, deliver each
  ask file under `.git/the-works/asks/` as "run this step from migration X, then
  rm <path> when done", stay silent when none outstanding.
- Follow-up for the gardener: the clone-local-object-leak task was absorbed into
  this feature at launch and then CANCELLED outright at the plan gate (decision
  entry above) — its board entry should be closed as cancelled, not merged back
  into the backlog.

## Proposal

**Combined launch (operator, 2026-08-18, Decision-050 pre-launch round): this task is
the carrier of ONE feature that also delivers [[stale-laid-links]] (its sidecar keeps
its own scope) and absorbs the former [[clone-local-object-leak]] as steps — one
branch, one close.** The interlock is real: all three edit `bin/kaukea`'s sync path.

Execute at sync time inside kauk; per-repository watermark; structured wrapper
over existing prose, no rewrite (Decision-022).

Application ORDER corrected at launch review (operator, 2026-08-18, replacing
the earlier pull → apply → rebase → write): you apply WHERE EVERYONE IS —
migrations already pending run against the shared state before local work is
replayed; any migration NEWLY ARRIVED with this pull runs AFTER the rebase,
on the rebased result, so every consumer experiences the same sequence.
Applying new migrations before the rebase is inconsistent (local edits made
against pre-migration shapes would replay onto post-migration state). So:
fetch → apply pre-existing pending migrations → rebase local work onto the
new head → apply the newly arrived migrations → write the watermark.

Absorbed clone-leak steps (rulings 2026-08-18, from that task's sidecar):

- Clone through the pack path for local filesystem origins via `--no-local` (the
  smaller change; `file://` normalisation rejected) at both clone sites in `bin/kaukea`.
- Test whether `fetch`/`pull` on sync leaks the same way; fix identically if so.
- Existing clones under `.ai/repositories/` are re-cloned on upgrade (they are
  gitignored and disposable).

The migration's filename date — and with it the derived package version and the
managed plugin `version` — is stamped at push time by the publish step, not at
authoring time (Decision-044). In-branch the date is provisional.

## Testing

Confirmed as drafted (operator, 2026-08-18). Two sources with interleaved dates both
migrate correctly; re-running is a no-op; a codified step is asserted twice in a fixture.
The combined feature also carries [[stale-laid-links]]'s fixture + estate walk and the
clone-leak canary (source repo with an unreachable object; clone via kai; assert
`git fsck --lost-found` in the clone surfaces nothing) plus the regression check that a
normal install from a local path still lays every skill.

## Changelog entry

- `kai sync` now applies every package's pending migrations itself, in a fixed
  order: whatever was already pending runs against the clone's pre-rebase state,
  local work then rebases on top, and only migrations that arrived with that
  pull run afterward — so every consumer experiences migrations in the same
  sequence, and a local edit in flight is respected rather than raced. Each
  migration's fenced steps are routed by an `applied-by` marker: kai executes a
  `shell` step itself (inline, or via a relative script shipped next to the
  migration) and never executes an `agent` step; anything it can't finish
  itself — an agent step, or a shell step that failed — is recorded durably in
  the consuming clone under `.git/the-works/asks/` and handed to the next
  session as a concrete instruction, with no user-facing "migrations pending"
  language anywhere. This retires the old model where an agent read, merged,
  and hand-applied a package's pending migrations and advanced the watermark
  itself (Decision-055). Self-vendored sources now run migrations too.
- A follow-up migration, `2026-08-18-kaukea-move-links`, repoints links that
  consumers laid against the retired `serialseb/{kauk,orchids}` clone paths to
  the `kaukea/{kauk,orchard}` clones, preserving each link's tail path; links
  whose kaukea clone is not yet present are reported and left for a later sync
  to heal. Safe to re-run; never descends into `.git` or `.ai`.
- Laid symlinks now survive a source moving: on sync, `prune_links` scans the
  whole tree (not just `.claude/` and the root), repoints any dead link whose
  tail path exists under exactly one currently-cloned source, removes only true
  orphans with no candidate anywhere, and reports `AMBIGUOUS` — touching
  nothing — when several sources could claim the link.
- `tests/migrations-at-sync.sh` ships as the black-box suite for migrations-at-
  sync and stale-laid-links, in `tests/convention-reader.sh`'s own style,
  exercising all eight ruled behaviours from interleaved-date migrations across
  two sources to the stale-link repoint/orphan scan. Two checks are TODO-visible
  pending (not skipped): the pre-existing-before-rebase half of the migration
  ordering, and recording the outstanding ask of an `applied-by: agent` step.

## Decision entries

- 2026-08-18 `#launch` `#sync`: migrations-at-sync and stale-laid-links ship as ONE
  feature (carrier: migrations-at-sync) — they interlock in `bin/kaukea`'s sync
  path. (Operator, Decision-050 pre-launch round; the clone-local-object-leak steps
  originally absorbed here were cancelled at the plan gate — see the cancellation
  entry below.)
- Decision-NNN 2026-08-18 `#migrations` `#format`: a migration's fenced code blocks
  are its steps, run in order; each fence's info string carries
  `applied-by: shell | agent`, deciding who executes it. `shell` (the default — a
  bare ```sh fence needs no tag, so existing migrations run unrewritten) has kai
  run the fence itself, inline or, when the fence body is a single
  `./relative/path` line, as an external script shipped relative to the migration
  file, cwd at the consumer root. `agent` steps are never run by kai; they are
  structured fenced steps, not loose prose. There is no closed set of step verbs —
  flexibility comes from `applied-by` plus relative scripts. (Operator, plan
  round.)
- Decision-NNN 2026-08-18 `#migrations` `#ux`: migrations are invisible plumbing.
  No user-facing migration vocabulary, no opt-in, no nag. Sync applies pending
  migrations for every source, self-source included, silently. The only surfaced
  thing is a step the tool cannot finish itself — an `applied-by: agent` step or a
  failed `shell` step — recorded under `.git/the-works/asks/<owner>/<repo>/` and
  delivered as a concrete "do this", never as "migrations pending". (Operator,
  plan round.)
- Decision-NNN 2026-08-18 `#sync` `#scope`: the clone-local-object-leak scope is
  cancelled outright — no `--no-local`, no re-clone, no in-place cleanup, no leak
  tests. kauk is not in the business of controlling git at that level, and judged
  from an external party's gain there is none: the clones are a gitignored,
  never-shared cache; hardlinks save disk; reachable history is identical.
  Re-cloning is never done — manual deletion of clones is unsupported, and a
  re-clone would lose the clone's commits. Committed-unpushed clone edits are
  legitimate deliberate work: sync commits them to carry them through the rebase,
  and push stays the separate explicit act. Features are judged from the external
  party's gain, never technical purity. (Operator, plan round, superseding the
  absorbed clone-leak steps recorded at launch.)
