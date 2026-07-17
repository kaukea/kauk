# TODO

Slim index. Badge = `type · status · urgency · readiness · component · gh#`. Prose lives in
sidecars (`TODO.md.d/<id>.md`). Functionality = heading; component = Taxonomy leaf
(`ARCHITECTURE.md`). The board grows as features are specified — this is the near-term seed.

## federation

- `feature · todo ·  · queued ·  · ` [Reserve the kauk namespaces on external registries](TODO.md.d/reserve-namespaces.md)
  - `feature · todo · urgent · queued · backend-pypi · ` [Publish PyPI kauk 0.0.0](TODO.md.d/pub-pypi-kauk.md)
  - `feature · done ·  · complete · backend-npm · ` [Publish npm @kauk.ai/kauk 0.0.0 (scoped)](TODO.md.d/pub-npm-kauk.md)

## projection

- `feature · todo · urgent · queued · pages-deploy · ` [Create kaukai org, file username ticket, wire Pages + CNAME](TODO.md.d/kaukai-org.md)

## infra

- `feature · todo · urgent · blocked-on-answers · dns · ` [Stand up kauk.ai hosting (host choice open)](TODO.md.d/kauk-ai-hosting.md)

## cli

- `feature · todo ·  · queued · cli-core · ` [kauk CLI skeleton (0.1.0 target)](TODO.md.d/cli-mvp.md)
- `feature · done ·  · complete · cli-core · ` [kauk bash stopgap (package manager moved from orchids)](TODO.md.d/kauk-sync-stopgap.md) ~cli-mvp
- `feature · todo ·  · blocked-on-answers · cmd-install · ` [Role-aware delivery: read roles from frontmatter, filter at install](TODO.md.d/role-aware-delivery.md) ~cli-mvp
- `bug · todo · urgent · plan-ready · cmd-install · ` [Local-path clone leaks the source's unreachable objects](TODO.md.d/clone-local-object-leak.md) ~role-aware-delivery
- `bug · todo · low · blocked-on-answers · cli-core · ` [Self-install: root link entries collide (src == dst)](TODO.md.d/self-install-link-collision.md)
- `feature · todo ·  · blocked-on-answers · cli-core · ` [Agent deployment: agents as a first-class type, two-page picker](TODO.md.d/agent-deployment.md) ~role-aware-delivery ~cli-mvp
