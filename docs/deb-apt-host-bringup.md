# Stand up `kauk.ai/debian` — the signmc apt repository (host bring-up)

## Why this exists
The sibling project **signmc** ships its `.deb` from **`kauk.ai/debian`**, served by
**GitHub Pages** out of **this repo (`serialseb/kauk`)**, at path **`/debian`**
(signmc Decision-037). A **SoftHSM-held OpenPGP key** signs the apt metadata, and a signmc
CI workflow **pushes** the built `.deb` + metadata into this repo (signmc Decision-038 —
kauk is a passive Pages *target*, not a participant).

As of writing, the host does **not** serve: `kauk.ai` has no DNS record and Pages is not
enabled here. Standing this up is **kauk's own work**; it gates signmc's `apt-metadata`
and `deploy` tasks from outside signmc's board.

## Done =
A user's `deb [signed-by=…] https://kauk.ai/debian <suite> main` source works, and
`apt install signmc` fetches **and verifies** the package.

## Steps

### 1. DNS — registrar action (apex domain)
`kauk.ai` is an apex domain, so it needs **A/AAAA** records to GitHub Pages (a CNAME is not
valid at the apex):
- **A:** `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153`
- **AAAA:** `2606:50c0:8000::153`, `2606:50c0:8001::153`, `2606:50c0:8002::153`, `2606:50c0:8003::153`

### 2. GitHub Pages — this repo
- Enable Pages on `serialseb/kauk` (source: `main`, root — or a dedicated publishing dir).
- Add a `CNAME` file containing `kauk.ai`.
- Let GitHub verify the domain, provision the HTTPS cert, and **enforce HTTPS**.
- Add `.nojekyll` so the served tree (incl. `dists/`/`pool/` dot-free paths and any
  metadata) is published verbatim.

### 3. apt layout under `/debian` — generated, not hand-written
Generate with **aptly** (signmc's `apt-metadata` task owns this). Standard Debian layout:
- `dists/<suite>/…` — `Release` + `InRelease` + `Release.gpg` (signed) and per
  component/arch `Packages`(+`.gz`).
- `pool/<component>/…` — the actual `.deb` files.
Two channels per signmc Decision-028/038: the **untrusted/continuous** suite (the only one
in scope now) and a deferred **release** suite. Name the untrusted suite so it *reads* as
untrusted.

### 4. Signing
`Release` is signed by the **SoftHSM-held OpenPGP key** (signmc Decision-038 — no operator
hardware in any build/publish path). Publish `InRelease` / detached `Release.gpg`, and
serve the signing public key so the installer can pin it with `signed-by=`.

## The `.deb`: in the repo, or just a link?
**The `.deb` file must be served under this repo's base URL, in `pool/`.** apt does not
accept a link to a binary hosted elsewhere: it reads `Filename:` from `Packages` — a path
**relative to the `deb <url>` base** — and downloads `https://kauk.ai/debian/<Filename>`.
So on the Pages host the `.deb` is **committed/published into this repo** under
`/debian/pool/…` and Pages serves it (per-file limit ~100 MB — fine for signmc's `.deb`).

The only way to keep the binary **out** of git is to change the **host** — serve `/debian`
from object storage (S3/R2) or a redirecting front — which is **outside** the Pages
stopgap (Decision-037). Until that's revisited, plan on the `.deb` living in `pool/`.

## Boundaries
- kauk documents are **not** an input to signmc's design (signmc Decision-038); this file
  describes kauk's **host** obligations only, nothing about signmc's package contents.
- Distribution/deploy actions (DNS, Pages, pushes) are **operator-gated**.
