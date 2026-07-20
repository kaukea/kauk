- created: 2026-07-17
- created_by: opus-4.8
- created_during: f/reserve-namespaces

## Blockers

The fix does not land in this repo — it belongs upstream in `serialseb/orchids`, which is a
separate workstream. This task tracks the reconciliation; it cannot be closed from `kauk`.

## Questions

- Which trailer survives — `Co-authored-by: <model> <junie@serialseb.com>`, or no trailer at
  all? The operator has already ruled the `Co-Authored-By: Claude Opus 4.8 …` line out of
  `AGENTS.md` as added in error. *Recommendation:* decide whether that ruling is
  kauk-specific or fleet-wide before editing the shared skill — the skill is shared by every
  orchids-managed repo, so an edit there changes them all.

## Findings

Two rules mandated **different** commit trailers:

- `AGENTS.md` (this repo) required `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
  **Deleted on `f/reserve-namespaces`** per operator ruling — added in error.
- The `git-commit` skill still mandates `Co-authored-by: <model> <junie@serialseb.com>`
  (SKILL.md L18 "Trailers present (`Branch:`, `Co-authored-by:`)", L53, L57 "the email
  address in brackets is fixed").

Deleting the `AGENTS.md` line removed the *conflict*, leaving the skill's rule standing alone
and unreviewed — the operator's ruling was about the erroneous line, not necessarily an
endorsement of the skill's trailer. That is what needs settling upstream.

**Path correction** (the brief for this task carried a stale path): the skill is NOT a symlink
into `.ai/repositories/serialseb/orchids/skills/git-commit` — that directory does not exist in
this repo. `.claude/skills/git-commit/SKILL.md` is an untracked local **copy**, and `.ai.toml`
resolves the source `serialseb/orchids` to the local clone `/home/sudoku/src/serialseb/orchids`.
Verified byte-identical (`diff -q`, no output) against
`/home/sudoku/src/serialseb/orchids/skills/git-commit/SKILL.md`. Editing the copy would be
silently reverted by the next `kauk sync` — the upstream repo is the only durable target.

## Proposal

Settle the trailer question with the operator (see `## Questions`), then make the edit in
`serialseb/orchids` at `skills/git-commit/SKILL.md` — L18, L53, and L57 all reference the
trailer and must move together. Land it there on its own branch, per that repo's workflow.
Afterwards `kauk sync` propagates it here; no `kauk`-side edit is needed or wanted.

## Testing

`grep -n -i 'co-authored-by' /home/sudoku/src/serialseb/orchids/skills/git-commit/SKILL.md`
reflects the settled ruling across L18/L53/L57, and `kauk sync` in this repo leaves
`.claude/skills/git-commit/SKILL.md` matching upstream (`diff -q` clean).
