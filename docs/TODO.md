# TODO

Slim index. Badge = `type · status · urgency · readiness · component · gh#`. Prose lives in
sidecars (`TODO.md.d/<id>.md`). Functionality = heading; component = Taxonomy leaf
(`ARCHITECTURE.md`). The board grows as features are specified — this is the near-term seed.

## federation

- `feature · done ·  · complete ·  · gh#1` [Park the kauk name on public registries so nobody squats it](TODO.md.d/reserve-namespaces.md)
  - `feature · done · urgent · complete · backend-pypi · ` [Placeholder package holds `kauk` on PyPI](TODO.md.d/pub-pypi-kauk.md)
  - `feature · done ·  · complete · backend-npm · ` [Placeholder package holds `@kauk.ai/kauk` on npm (bare name refused)](TODO.md.d/pub-npm-kauk.md)
- `feature · todo · low · blocked-on-answers · backend-npm · gh#11` [Ask npm support to let us have the bare `kauk` name](TODO.md.d/npm-support-bare-kauk.md) ~pub-npm-kauk

## projection

- `feature · todo · urgent · queued · pages-deploy · gh#2` [Set up the kaukea GitHub org and serve the kauk.ai site from its Pages](TODO.md.d/kaukai-org.md)

## infra

- `feature · todo · urgent · blocked-on-answers · dns · gh#3` [Decide where kauk.ai is hosted, then stand it up](TODO.md.d/kauk-ai-hosting.md)
- `feature · todo · · blocked-on-answers · dns · gh#13` [Serve a real apt repo at kauk.ai/debian for signmc (route undecided)](TODO.md.d/deb-apt-host.md) ~kauk-ai-hosting

## cli

- `feature · todo · · queued · cli-core · gh#4` [Build the real kauk CLI (0.1.0), replacing the bash stopgap](TODO.md.d/cli-mvp.md)
- `feature · done ·  · complete · cli-core · ` [Interim bash `kauk` CLI that vendors and syncs packages](TODO.md.d/kauk-sync-stopgap.md) ~cli-mvp
- `feature · todo · · blocked-on-answers · cmd-install · gh#5` [Only install the skills that match a repo's role (dev/infra/org)](TODO.md.d/role-aware-delivery.md) ~cli-mvp
- `bug · todo · urgent · plan-ready · cmd-install · gh#6` [Installing from a local path drags in the source repo's leftover git objects](TODO.md.d/clone-local-object-leak.md) ~role-aware-delivery
- `bug · todo · urgent · blocked-on-answers · cli-core · gh#10` [Remove manifest.conf entirely — the package's tree says what it ships](TODO.md.d/manifest-by-convention.md)
- `bug · todo · low · blocked-on-answers · cli-core · gh#7` [kauk installed into its own repo tries to link files onto themselves](TODO.md.d/self-install-link-collision.md)
- `feature · todo · · blocked-on-answers · cli-core · gh#8` [Installer picks agents first, then bundles the skills those agents require](TODO.md.d/agent-deployment.md) ~role-aware-delivery ~cli-mvp

## workflow

- `housekeeping · todo · · blocked-on-answers · agent-rules · gh#12` [Fix the contradictory commit-trailer rules between the rule files (fix lives in orchids)](TODO.md.d/commit-trailer-conflict.md)
