# Naming & domains (KAUK)

Moved here from the `domain-naming-map` project memory (durable home; memory left a pointer).
Decided 2026-07-12 via a deep-research pass (102 agents). Ruling recorded as Decision-001.

## The name

**KAUK** — the package platform (the owner's 3rd package manager, after OpenWrap). Baltic
*kaukai*: household wealth-dwarfs. Chosen for: 4 keystrokes, brand = command = domain, one
string everywhere — no alias, no diminutive (dual-naming rejected as bad UX). Consonant
clusters of `parstuk`/`barstuk` felt aggressive by comparison.

> Note: the mythology is **Baltic/Lithuanian**, not Japanese — the owner has recalled it as
> "the Japanese name," but *kaukai* is Baltic.

## Domains & namespaces (verified free 2026-07-12)

- **kauk.ai** — brand domain (= plural *kaukai*, domain hack). **Registered.**
- **kauk.org** — tooling / config-path domain; canonical grammar `kauk.org/<pkg>`
  (slug form NOT taught — the exact `kauk` gh org isn't owned). `kauk.dev` / `kauk.io` also free.
- **PyPI `kauk`** + **npm `kauk`** — reserved defensively (see `namespace-reservation/`).
- **gh org `kaukea`** — ~~`kaukai`~~ **CORRECTED 2026-08-10 (Decision-026)**: GitHub
  refused `kauk` and the username-release ticket for the dormant `github.com/kauk` user
  did not succeed, so the org created and in use is **`kaukea`** —
  https://github.com/kaukea/ — home, since 2026-08-18 (Decision-052), of `kaukea/kauk` and `kaukea/orchard` (orchids renamed as it crossed). It holds the projection repo and, from the same decision,
  the `kauk` repository itself. The brand, `kauk.ai`, and the registry reservations are
  unaffected.
- NOT available: `kauk.com` / `kauk.net`. `github.com/kauk` = a **dormant user** (0 repos,
  idle since 2020); the username-release ticket failed.
- Dead 3-letter routes: `kau.ai` / `kak.ai` taken (`kak` = Afrikaans/Dutch vulgarity).

## Fallback

**`parstuk`** — the full house (incl. the exact gh org, no dependencies) if the `kauk`
username ticket fails. The ≤5-char GitHub namespace is otherwise exhausted (~35 stems checked
2026-07-12, all taken).

## Rejected rivals (why)

`kratt` = Estonia's national AI brand · `aitvaras` = Lithuanian special-forces codename ·
`kłobuk` = hat/Witcher/town · `penates` = PyPI-taken · other wealth-daemons deliver *stolen*
goods (a supply-chain-attack mascot — off-brand for a package manager).

## Grammar & serving

- Cold canonical: `kauk.org/<pkg>`. Warm dialect taught via CLAUDE.md line.
- Org-level GitHub Pages + CNAME serves all `/<pkg>` pages from one repo, **generated at
  publish** (the projection rule). Heavy artifacts later behind `apt.kauk.org`.

## Sibling domains (owner's map, not KAUK — kept in memory)

`safekeep.it` (SafeKeepIt brand) · `sfk.io` (SafeKeepIt shortener) · `owin.org` (orchids/agent
bootstrap) · `packages.serialseb.net` (existing apt repo for signmc) · `graph.store` (generic).

## Naming method (reusable)

Obscure myth/invented words that pass the "Google challenge" (few irrelevant results); check
RDAP + PyPI + npm + GitHub + curse-word test in all languages (`bezdukas` failed: Lithuanian
"little farter").
