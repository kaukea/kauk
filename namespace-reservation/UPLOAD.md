# Uploading the `kauk` namespace reservations

Two placeholder packages that reserve the name `kauk` on PyPI and npm.
Both are version `0.0.0` (unmistakable "nothing shipped yet"); the real
tooling starts at `0.1.0`. I can't upload these — you do it.

Status: **npm is done** (`@kauk.ai/kauk@0.0.0`, scoped — see below).
**PyPI is still to do.**

Re-confirm the PyPI name is still free before you build (last checked 2026-07-12):
- PyPI: <https://pypi.org/project/kauk/> should 404.

---

## PyPI (`pypi/`)

Needs: a PyPI account + an API token (Account settings → API tokens).
First upload uses an **account-scoped** token; after it exists, create a
**project-scoped** token for `kauk` and delete the broad one.

```sh
cd pypi
python -m pip install --upgrade build twine     # once
python -m build                                  # -> dist/kauk-0.0.0.tar.gz + .whl
twine check dist/*                               # sanity
twine upload dist/*                              # user: __token__  pass: pypi-...
```

## npm (`npm/`) — DONE, published as `@kauk.ai/kauk`

Already live; nothing to run here. Kept for the record.

The unscoped `kauk` is **not obtainable**: npm's typosquat similarity filter
rejects the bare word deterministically —

```
403 Forbidden - PUT https://registry.npmjs.org/kauk - Package name too similar to
existing packages ka23,caduk,vaul,walk; try renaming your package to '@kauk.ai/kauk'
```

So the reservation is the scoped `@kauk.ai/kauk@0.0.0`, published under the
`kauk.ai` npm account. A scoped package is **private by default** — publishing
it publicly needs `--access public`, unlike the unscoped case:

```sh
cd npm
npm publish --dry-run             # shows exactly what ships (index.js, README.md, package.json)
npm publish --access public       # scoped => --access public is REQUIRED
```

If you have 2FA-for-publish on, it'll prompt for an OTP.

---

## Notes

- **License** is set to MIT as a neutral placeholder — change it in
  `pyproject.toml` / `package.json` if you want something else before upload.
- **No email** is baked into either package (avoids leaking a personal
  address); add a contact if you want one public.
- **This is a reservation, not squatting** — both registries (PyPI PEP 541,
  npm dispute policy) can force-transfer a name held with no genuine intent.
  The README's link to kauk.ai and the stated plan are your defense; ship
  something real before too long and you're fine.
- Once live, the first real release is `0.1.0` (bump `version` in both
  manifests). Don't use `+build` metadata to sequence — it's ignored for
  ordering on both registries.
