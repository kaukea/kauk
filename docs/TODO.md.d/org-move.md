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
