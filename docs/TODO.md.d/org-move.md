- created: 2026-08-10
- created_by: opus-5
- created_during: package-conventions spec walk

## Blockers

Sequenced after the spec work; the GitHub transfer is the operator's.

## Questions

_None open — the spec is ruled._

## Findings

GitHub refused `kauk`; the org is `kaukea`. Transfer leaves redirects, so remotes keep working. Only kauk's own 45 links carry the absolute prefix; other repos link into their own clone directories.

## Proposal

Transfer `serialseb/kauk` to `kaukea`, move to `~/src/kaukea/kauk`, rewrite kauk's own link targets. Repository name unchanged (Decision-035).

## Testing

Remote resolves after transfer; every link in kauk resolves after the move; other repos are untouched.

Scope expanded (Decision-052, 2026-08-18): both repositories move, and
orchids RENAMES to orchard in the same campaign — kaukea/kauk +
kaukea/orchard. Estate .ai.toml sources repoint; disk paths follow.

## Result (org-move, 2026-08-18)

Executed on `f/org-move` → `archive/org-move`. GitHub: kaukea/kauk and
kaukea/orchard live (transfers + rename the operator's). Disk:
~/src/kaukea/{kauk,orchard}, compatibility symlinks at the old serialseb
paths, orchard's three live worktrees repaired. Remotes repointed. The
estate migration converts every consumer's sources to the GitHub defaults,
moves watermarks with the identities, removes old clones — self-source
guard resolving paths, proven idempotent on kauk itself. Estate sweep at
close.

## Changelog entry (staged)

#### 🚚 `f/org-move` → `archive/org-move`

Two repositories cross to kaukea, and orchard takes its name. kaukea/kauk
and kaukea/orchard are the homes; checkouts live at ~/src/kaukea with
compatibility symlinks behind them. Migration `2026-08-18-kaukea-move.md`
converts every consumer's `.ai.toml` sources to the GitHub default form,
carries each package's migration watermark across the identity change, and
removes the old clones; the next `kai sync` in each repository clones from
kaukea and retargets every link.

_Board: org-move · Decisions 026, 035, 052._

## Readme delta (staged)

No README change needed: it names no GitHub URL or org — evidenced by grep;
the layout section already speaks kaukea-neutral paths.
