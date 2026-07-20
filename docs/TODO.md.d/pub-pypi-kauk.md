- created: 2026-07-13
- created_by: opus-4.8
- created_during: f/bootstrap-kauk
- completed: 2026-07-17
- completed_during: f/reserve-namespaces

## Blockers

~~Needs a PyPI account + API token (operator-held). Agent cannot publish.~~
Resolved — PyPI account `kauk` created by the operator, 2FA enabled (TOTP + WebAuthn
security device), recovery codes held offline.

## Questions

None.

## Findings

The **bare, unscoped `kauk` is PUBLISHED and live on PyPI** — <https://pypi.org/project/kauk/0.0.0/>.
The original plan worked unchanged: no pivot, no rename, no scoping needed.

**PyPI has no name-similarity filter.** This is the key asymmetry with npm, which rejected
the identical bare word deterministically on its typosquat heuristic (Decision-010). Control
check: `npm view kauk` → E404 — nobody owns `kauk` on npm; the registry simply will not grant
it. Same word, same intent, opposite outcomes, for registry-policy reasons alone. So the
reservation is **asymmetric by necessity**: bare `kauk` on PyPI, scoped `@kauk.ai/kauk` on npm.

Build details, confirmed: hatchling via `python -m build` produced both artifacts; the SPDX
`license = "MIT"` form was accepted exactly as this sidecar predicted; `twine check` passed on
both; `twine upload` succeeded.

Metadata nuance worth knowing for later releases: the SPDX form lands in the JSON API's
`info.license_expression` (`'MIT'`), and the legacy `info.license` field is `null`. Anything
reading the old field will see no license — that is modern-metadata behaviour, not a packaging
defect.

**Open follow-up for the operator (out of scope here):** the first upload necessarily used an
ACCOUNT-scoped token (`kauk-reservation-upload`) because no project existed yet. Now that the
`kauk` project exists, replace it with a PROJECT-scoped token and delete the broad one.

## Proposal

Done. Published bare `kauk 0.0.0` per the original plan. Board, `namespace-reservation/UPLOAD.md`
PyPI section, and a factual clarification on Decision-010 (recording the npm-specific nature of
the block) updated to match published reality. No new decision was made — the plan simply worked.

## Testing

`https://pypi.org/pypi/kauk/json` (agreed method), re-run 2026-07-17. **Passed.** Verbatim:

    name: kauk
    version: 0.0.0
    license: None
    license_expression: MIT
    requires_python: >=3.8
    summary: Reserved namespace for the KAUK package platform (https://kauk.ai).
             Placeholder release — no functionality yet.
    project_urls: {'Homepage': 'https://kauk.ai'}
    files in 0.0.0: 2
      - kauk-0.0.0-py3-none-any.whl   bdist_wheel
      - kauk-0.0.0.tar.gz             sdist

The name is `kauk` (bare), the version is `0.0.0`, and both wheel and sdist are present on the
public index. License is MIT via `license_expression` (see Findings for why `license` is null).

Result: done · branch `f/reserve-namespaces` · what was tested: the PyPI JSON API returned
`name: kauk` / `version: 0.0.0` with 2 files, confirming the unscoped reservation is live on the
public index. Tasks spawned: `npm-support-bare-kauk` (ask npm support to release the bare name)
and `commit-trailer-conflict` (reconcile the trailer rule upstream in `orchids`).

### Docs determination (per-file, evidenced)

- **README.md** — SKIPPED, evidenced. Its PyPI reference is the bare `kauk` (`pip install kauk`),
  which this publish makes *accurate* rather than stale — the file already described the reality
  this task delivered. The npm strings were corrected on the sibling task. Nothing to change.
- **ARCHITECTURE.md** — SKIPPED, evidenced. Checked all four triggers against this diff: no
  application/module responsibility or boundary changed; no component added, removed, or
  repurposed; no wiring or data flow changed; no architectural style or cross-cutting pattern
  changed. The diff is bookkeeping over docs plus two new board tasks — `backend-pypi`'s
  responsibility and boundary are identical before and after. No trigger fired.
- **CHANGELOG.md** — DEFERRED by the operator; deliberately not touched.
