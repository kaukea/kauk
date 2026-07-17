- created: 2026-07-13
- created_by: opus-4.8
- created_during: f/bootstrap-kauk
- completed: 2026-07-17
- completed_during: f/pub-npm-kauk

## Blockers

~~Needs an npm account (operator-held). Agent cannot publish.~~
Resolved — published by the operator under the npm account `kauk.ai` (org `kaukai`).

## Questions

None.

## Findings

The unscoped `kauk` is **unobtainable on npm**. The registry rejects it deterministically
on its typosquat similarity heuristic and names the remedy itself:

    npm ERR! code E403
    npm ERR! 403 Forbidden - PUT https://registry.npmjs.org/kauk - Package name too
    similar to existing packages ka23,caduk,vaul,walk; try renaming your package to
    '@kauk.ai/kauk'

A heuristic on the bare word, not an ownership conflict — the dormant `kauk` npm
*username* (0 packages) does not hold the name and is not the cause. No flag or retry
gets past it; do not re-attempt the unscoped publish.

Pivoted (operator-approved) to the SCOPED `@kauk.ai/kauk@0.0.0` — **published and live**.
Scoped packages are private by default, so the public publish needed `--access public`
(the old unscoped "no `--access` flag needed" note was wrong and is corrected in
`namespace-reservation/UPLOAD.md`). Ruling recorded as Decision-010, which refines
Decision-004 rather than superseding it: reserve-via-`0.0.0`-stub stands, PyPI stays
unscoped `kauk`, only the npm identity changed.

Follow-up left for the operator, out of scope here: asking npm support to release the
bare `kauk` name.

## Proposal

Done. `namespace-reservation/npm/package.json` renamed to `@kauk.ai/kauk`; UPLOAD.md npm
section, README npm-install strings, Decision-010, and the board updated to match the
published reality.

## Testing

`npm view @kauk.ai/kauk version` → `0.0.0` (exit 0), run 2026-07-17. **Passed.**

Result: done · branch `f/pub-npm-kauk` · what was tested: `npm view @kauk.ai/kauk
version` returned `0.0.0`, confirming the scoped reservation is live on the public
registry. No tasks spawned. The parent task `reserve-namespaces` stays open — the PyPI
sibling (`pub-pypi-kauk`) is still todo.

### Docs determination (per-file, evidenced)

- **README.md** — EDITED. It carried two now-false npm install strings (`npm i kauk`,
  and the status note claiming `kauk` is reserved on npm); both corrected to
  `@kauk.ai/kauk`. PyPI side deliberately untouched — still unscoped `kauk`.
- **ARCHITECTURE.md** — SKIPPED, evidenced. Checked all four triggers against this diff:
  no application/module responsibility or boundary changed; no component added, removed,
  or repurposed; no wiring or data flow changed; no architectural style or cross-cutting
  pattern changed. The diff renames one placeholder package's npm identity string and
  updates docs — the `backend-npm` component's responsibility and boundary are identical
  before and after. No trigger fired.
- **CHANGELOG.md** — DEFERRED by the operator; deliberately not touched.
