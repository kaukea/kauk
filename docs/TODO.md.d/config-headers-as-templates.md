- created: 2026-08-11
- created_by: opus-5
- created_during: f/convention-reader

## Blockers

Depends on [[templates-spec]] — there is no template mechanism to ship it with yet.

## Questions

- Does the kauk package ship it, or the package whose file it is? `.ai.toml` is
  written by kauk, so kauk; but the same argument makes every generated header a
  candidate and the boundary needs stating once.

## Findings

- `bin/kauk` hardcodes the `.ai.toml` header text in `ensure_aitoml()`, so changing
  the wording is a code change, and existing files keep whatever wording they were
  born with. That is exactly what happened: the header telling the operator not to
  edit their own file survived in every repo until it was fixed by hand.
- A template is the right shape for it — `type: beginning`, tracked, carrying its
  own `:kauk:` marker so it can be updated in place afterwards.

## Proposal

Ship the `.ai.toml` header as one of the first templates the kauk package provides,
instead of hardcoding it in the script. Generated headers then update themselves
wherever they have already been laid, and their wording stops being a code change.

## Testing

Changing the template's text and syncing updates the header in an existing repo
without touching the operator's own content below it.
