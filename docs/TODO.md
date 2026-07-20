# TODO

Slim index. Badge = `type · status · urgency · readiness · component · gh#`. Prose lives in
sidecars (`TODO.md.d/<id>.md`). Functionality = heading; component = Taxonomy leaf
(`ARCHITECTURE.md`). The board grows as features are specified — this is the near-term seed.

## federation

- `feature · todo · · queued · · gh#1` [Reserve the kauk namespaces on external registries](TODO.md.d/reserve-namespaces.md)
  - `feature · todo · urgent · queued · backend-pypi · ` [Publish PyPI kauk 0.0.0](TODO.md.d/pub-pypi-kauk.md)
  - `feature · todo · urgent · queued · backend-npm · ` [Publish npm kauk 0.0.0](TODO.md.d/pub-npm-kauk.md)

## projection

- `feature · todo · urgent · queued · pages-deploy · gh#2` [Create kaukai org, file username ticket, wire Pages + CNAME](TODO.md.d/kaukai-org.md)

## infra

- `feature · todo · urgent · blocked-on-answers · dns · gh#3` [Stand up kauk.ai hosting (host choice open)](TODO.md.d/kauk-ai-hosting.md)

## cli

- `feature · todo · · queued · cli-core · gh#4` [kauk CLI skeleton (0.1.0 target)](TODO.md.d/cli-mvp.md)
- `feature · done ·  · complete · cli-core · ` [kauk bash stopgap (package manager moved from orchids)](TODO.md.d/kauk-sync-stopgap.md) ~cli-mvp
- `feature · todo · · blocked-on-answers · cmd-install · gh#5` [Role-aware delivery: read roles from frontmatter, filter at install](TODO.md.d/role-aware-delivery.md) ~cli-mvp
- `bug · todo · urgent · plan-ready · cmd-install · gh#6` [Local-path clone leaks the source's unreachable objects](TODO.md.d/clone-local-object-leak.md) ~role-aware-delivery
- `bug · todo · urgent · queued · cli-core · gh#10` [Distribution is a hand-typed index: derive it from the tree, and fail loudly meanwhile](TODO.md.d/manifest-by-convention.md)
- `bug · todo · low · blocked-on-answers · cli-core · gh#7` [Self-install: root link entries collide (src == dst)](TODO.md.d/self-install-link-collision.md)
- `feature · todo · · blocked-on-answers · cli-core · gh#8` [Agent deployment: agents as a first-class type, two-page picker](TODO.md.d/agent-deployment.md) ~role-aware-delivery ~cli-mvp
