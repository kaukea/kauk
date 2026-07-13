- created: 2026-07-13
- created_by: opus-4.8
- created_during: f/bootstrap-kauk

## Blockers

Needs a PyPI account + API token (operator-held). Agent cannot publish.

## Questions

None.

## Findings

Package at `namespace-reservation/pypi/` (hatchling, name=kauk, version=0.0.0, MIT). `python
-m build` fetches a current hatchling so the SPDX `license = "MIT"` form is accepted.

## Proposal

`cd namespace-reservation/pypi && python -m build && twine check dist/* && twine upload
dist/*`. First upload uses an account-scoped token; then create a project-scoped token for
`kauk` and delete the broad one.

## Testing

`pip index versions kauk` lists 0.0.0 from pypi.org.
