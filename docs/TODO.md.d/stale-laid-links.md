- created: 2026-08-18
- created_by: fable-5

## Blockers

(none)

## Questions

- ~~Where does the fix live?~~ Resolved by Decision-054 and the shipped migration
  itself: orchard applies the convention conversion (done, orchard 6733c8c), sync
  regains its link scan, and rename migrations carry link repointing.
- ~~Interim manual repoint?~~ Overtaken: `kai sync` heals the links itself once the
  package ships them from `files/` — verified live in this repo.

## Findings

- Root cause chain: orchard never received kauk's `2026-08-12-convention-packages`
  migration (no delivery channel — see package-migration-reach), so its root
  deliverables never moved into `files/`; consumers' stopgap-era links kept
  resolving to orchard's root copies until the kaukea move (Decision-052) renamed
  the vendor path and left them dangling estate-wide (kauk and fastcut verified).
- `settings.json`'s manifest destination was `.claude/settings.json`, so it belongs
  at `files/.claude/settings.json` — the migration's scripted step alone would have
  mis-laid it at the repo root; the judgement step (recovered manifest) governs.
- Sync's historic scan-and-repoint of laid links (stopgap `bin/kauk` f24f698:289,
  `find "$root" -maxdepth 1 -type l` + `.claude/`) disappeared in the
  convention-reader rewrite (54ca042) with no ruling on record — unratified removal
  (Decision-014).
- VERIFIED: `kai sync` overwrites a dangling laid link when the artifact is
  deliverable again — kauk's three links healed on plain sync after the orchard
  conversion (readlink resolves into `.ai/repositories/kaukea/orchard/files/…`).
- Applied so far (2026-08-18): orchard conversion committed/pushed (6733c8c, with
  relative self-links at the old paths for orchard's own sessions); kauk healed and
  committed; orchard's watermark store converted to per-package and kauk's
  watermark recorded there.

## Proposal

Remaining work, per Decision-054:

1. Restore sync's scan of laid links pointing into the repository store — repoint
   ones whose target moved, remove true orphans nothing lays any more (`bin/kaukea`).
2. Rename/move migrations carry their consumer link repointing: amend
   `2026-08-18-kaukea-move.md` (or ship a follow-up dated migration) so a consumer
   that syncs is guaranteed no link still points at a pre-move path.
3. Estate walk: run `kai sync` in every consumer (fastcut confirmed dangling; check
   the rest) and verify no dangling laid link remains anywhere.

GATE (Decision-054): done before kauk is used by any project.
Decision-055: every essential step above is SCRIPTED (bin/kaukea code and shipped
migration scripts) — no agent-performed step in the repair or its verification.

## Testing

Scratch consumer laid under the old layout + old vendor path; apply the rename and
sync; assert every laid link resolves and no orphan remains. Estate: `find` for
dangling symlinks into `.ai/repositories/` across consumers returns nothing. Method
to be confirmed at bloom.
