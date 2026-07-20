- created: 2026-07-21
- created_by: fable-5
- created_during: board intake of docs/deb-apt-host-bringup.md (pushed from outside this session)

## Blockers

_None to intake; building is gated on the Questions below._

## Questions

- Self-host vs free OSS registry? The spec doc marks this UNDECIDED and owned by
  kauk: self-hosted (GitHub-Releases-backed pool, Cloudflare 302 for `pool/`,
  served at `kauk.ai/debian`) versus a free SaaS registry (Cloudsmith OSS tier,
  GitLab Debian registry, OBS/Launchpad — terms to verify before relying on any).
  The trade is "own it at kauk.ai" vs near-zero infra.
- Sequencing against the kauk.ai hosting decision (~kauk-ai-hosting): does the
  apt host ride whatever host serves kauk.ai, or is it independent (Cloudflare
  redirect layer only)?

## Findings

- Full candidate design lives in `docs/deb-apt-host-bringup.md` (arrived on main
  2026-07-21, commits ec5d406/535e162/5b68889): a real apt repo whose `.deb`
  binaries are GitHub Release assets so git never grows; explicitly marked
  "do not build until the operator picks a route".
- The consumer is signmc (a different project); the host/storage choice is
  kauk's because it lands under `kauk.ai`.

## Proposal

Decide the route (Questions), then stand up `kauk.ai/debian` per the chosen
option — the bring-up doc is the candidate spec for the self-host route and the
option list for the SaaS routes. Scope ends at a working `apt install`/`apt
update` against the published repo.

## Testing

On a clean Debian box: add the repo + key, `apt update`, `apt install <pkg>`,
then publish a bumped version and confirm `apt upgrade` picks it up.
