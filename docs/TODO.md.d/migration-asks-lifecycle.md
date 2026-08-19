- created: 2026-08-19
- created_by: fable-5 (operator order at the migrations-at-sync close)

## Blockers

(none)

## Questions

_None open — scope ruled at the close._

## Findings

- orchard's `.claude/hooks/migrations-pending.sh` and `AGENTS.files.md`
  §Migrations still carry the retired agent-applies model (they are symlinks
  into the vendored orchard clone — out of the kauk branch's authority, which
  is why the feature could not fix them). Replacement §Migrations text is
  READY in kauk's `docs/package-format.md` §migrations/.
- Hook rewrite is designed: deliver only outstanding ask files under
  `.git/the-works/asks/` ("run this step from migration X, then rm the ask
  file when done"), stay silent when none outstanding.

## Proposal

The ask-file lifecycle end to end (cross-repo: orchard hook + rule text, kauk
engine policy): rewrite migrations-pending.sh per the design above; transplant
the ready §Migrations text into AGENTS.files.md; define and implement the
policy for a shell step that keeps failing (retry? ask? halt the watermark?).
Subsumes the cross-repo hook-rewrite follow-up from migrations-at-sync.

## Testing

Fixture: a migration with an applied-by:agent step produces exactly one ask
file; the hook surfaces it once and is silent otherwise; rm of the ask ends
the surfacing; a repeatedly failing shell step follows the ruled policy.
