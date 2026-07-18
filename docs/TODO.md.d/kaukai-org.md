- created: 2026-07-13
- created_by: opus-4.8
- created_during: f/bootstrap-kauk

## Blockers

Org creation + the GitHub username-release ticket are operator actions (GitHub UI).

## Questions

None (org name re-settled: `kaukea` — orchids Decision-012, 2026-07-18. `kaukai`
turned out to be held by a dormant 2022 user account; a release request can be
filed like the `kauk` one, and an org rename later redirects cleanly).

## Findings

The org's literal name is invisible to end users: pages are served via the `kauk.ai` CNAME,
so `github.com/<org>` never shows. If the `kauk` username releases later, renaming the org
auto-installs redirects — nothing published under `kaukai` breaks. Precedent for the
Pages+CNAME+served-tree pattern already exists: `~/src/serialseb/packages`
(packages.serialseb.net).

## Proposal

1. Create the `kaukea` GitHub org.
2. Push `site/` as the org Pages repo (org-level Pages → `kauk.ai`); enable Pages, set the
   custom domain to `kauk.ai` (the `site/CNAME` carries it), keep `.nojekyll`.
3. Keep the username-release tickets open (`kauk`; optionally file `kaukai`); on
   grant, rename the org — redirects cover it.

## Testing

`https://kauk.ai` serves `site/index.html`; a sample `https://kauk.ai/<pkg>/` resolves.
