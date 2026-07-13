# Decisions

Append-only, chronological (oldest top). Grep by `#keyword`; never read whole. A decision
is a RULING, not a state. Format: `## [YYYY-MM-DD HH:MM TZ] Decision-NNN: Title` + a
mandatory `#hashtag` line.

## [2026-07-13 22:46 CEST] Decision-001: Platform name = KAUK; domains kauk.ai + kauk.org
#naming #kauk #kaukai #domain #brand

Decided 2026-07-12 (context: deep-research pass, 102 agents). The package platform is
**KAUK** — brand = command = domain, one 4-keystroke string everywhere, no alias/diminutive.
`kauk.ai` is the brand domain (a hack on the plural *kaukai*, Baltic household wealth-dwarfs);
`kauk.org` is the tooling/config-path domain (canonical `kauk.org/<pkg>`). GitHub org =
`kaukai` (the exact `kauk` username is a dormant account — a username-release ticket is
filed; **fallback stem = `parstuk`** if it fails). Full rationale, rejected rivals, and the
claim set live in `docs/naming.md`. Do not re-litigate.

## [2026-07-13 22:46 CEST] Decision-002: KAUK is a control plane, not a storage backend
#architecture #control-plane #federation #registry

KAUK is a native artifact index (packages, skills, arbitrary files as first-class) PLUS a
federation layer over external registries (npm, PyPI, OCI, GitHub) that the user opts into.
The value is the tooling — one CLI, one grammar, one auth flow — not the bytes. Skills and
arbitrary files are native artifacts; no PyPI/npm wrapper-package trick is needed on the
native index. Addressing is backend-qualified so `install <pkg>` is never ambiguous.

## [2026-07-13 22:46 CEST] Decision-003: Credential custody is client-side, not server-held
#custody #oauth #security #federation #tokens

External-backend publish credentials live on the USER's machine (OAuth device flow). KAUK
holds only the app registration, never a hoard of users' tokens — a server-side token vault
would make KAUK the single richest supply-chain target ("one ring binds them" = Sauron's
design). "Bind the workflow, not the secrets." Server-held tokens require an explicit future
decision and, if ever adopted, are scoped publish-only-this-package / short-lived /
per-backend. Anything KAUK republishes on a user's behalf is signed/attested (npm provenance
/ sigstore).

## [2026-07-13 22:46 CEST] Decision-004: Reserve the `kauk` name via 0.0.0 stub packages
#reservation #pypi #npm #naming #squatting

PyPI and npm have no name-reservation API; the only claim mechanism is publishing. Reserve
`kauk` on both with `0.0.0` placeholder packages (`namespace-reservation/`) that signal
"nothing shipped yet"; real tooling starts at `0.1.0`. Do NOT sequence releases with `+build`
metadata (ignored for ordering; PyPI rejects local `+` versions). This closes the
supply-chain squat window during the GitHub-username wait. Reservations held with genuine
intent (README → kauk.ai) survive PyPI PEP 541 / npm dispute policy.

## [2026-07-13 22:46 CEST] Decision-005: Repo home ~/src/kauk, orchids-managed house style
#repo #orchids #layout #agents

The platform lives at `~/src/kauk` (its own product, not under SafeKeepIt/serialseb),
bootstrapped with `orchids init` — shared agent-rule files + skills vendored as symlinks
under `.ai/`, project-owned `AGENTS.md`/`README`/`ARCHITECTURE`/`docs`. Matches TitanShield /
Panopticon / SignMc. `orchids sync` pulls canonical updates.

## [2026-07-13 22:46 CEST] Decision-006: License = MIT (placeholder, revisit before 0.1.0)
#license #mit

Provisional: MIT, to match the reservation stubs and keep the platform permissive. Sibling
public tooling (signmc, packages.serialseb.net) is GPLv3 — revisit and confirm before the
first real (`0.1.0`) release. Marked so a future reader knows it was a default, not a
deliberated final choice.
