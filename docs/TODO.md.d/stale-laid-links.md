- created: 2026-08-18
- created_by: fable-5

## Blockers

(none)

## Questions

- Where does the fix live? (a) orchard ships AGENTS.shared.md / AGENTS.files.md /
  settings.json under a laid kind (`files/`) so the reader lays them again, (b) kai
  learns to garbage-collect links it laid under a previous layout when a sync no
  longer produces them, or (c) both — the GC is arguably needed regardless.
  Recommendation: (c).
- Interim manual repoint of the three dangling links in this repo (to the vendored
  `.ai/repositories/kaukea/orchard/` copies) — do it now, or leave broken until the
  real fix lands? Recommendation: repoint now; every session's rule-loading is broken
  meanwhile.

## Findings

- Repo-root `AGENTS.shared.md`, `AGENTS.files.md` and `.claude/settings.json` are
  dangling symlinks dated 2026-07-14 (stopgap-era laydown), pointing at
  `~/src/serialseb/kauk/.ai/repositories/serialseb/orchids/…` — dead since the
  kaukea move + orchids→orchard rename (Decision-052) renamed the inner vendor path.
- `kai sync` (2026-08-18) laid/verified 78 links for kaukea/orchard but neither
  re-laid nor removed these three: the convention reader lays only
  `skills/ agents/ hooks/ tools/ files/`, and orchard carries these files at its
  package ROOT, so nothing lays them any more; sync has no orphan-GC either.
- Consequence: `CLAUDE.md`'s `@AGENTS.shared.md` include fails in every session in
  this repo — the mandatory rule files load only if an agent finds the vendored copy
  by hand. `.claude/settings.json` (shared harness settings) is silently absent.
- The `2026-08-18-kaukea-move.md` migration repointed sources but did not touch
  stopgap-era laid links.

## Proposal

Restore the laying of the shared rule files and settings, and stop stale laid links
from surviving layout changes. Scope pending the Questions above: likely orchard
publishing its root rule files via a laid kind, plus an orphan-GC in `kai sync` for
links that point into `.ai/repositories/` (or its pre-move path) but are no longer
produced by the current laydown. Out of scope: versioning/pins (Decision-051).

## Testing

To be agreed at bloom. Candidate: in a scratch consumer repo, lay with the old
layout, apply the rename, run `kai sync`, assert no dangling symlink remains and
`AGENTS.shared.md` resolves; plus this repo's three links fixed as the live case.
