# TODO

Slim index. Badge = `type · status · urgency · readiness · component · gh#`. Prose lives in
sidecars (`TODO.md.d/<id>.md`). Functionality = heading; component = Taxonomy leaf
(`ARCHITECTURE.md`). The board grows as features are specified — this is the near-term seed.

## registry

- `feature · todo · urgent · queued · artifact-model · gh#14` [Write agents/skills/hooks once, lay them per runtime (Claude now, opencode next) — includes redoing hooks](TODO.md.d/runtime-topology.md) ~manifest-by-convention ~extension-point-survey
- `feature · todo · · queued · artifact-model · gh#15` [Survey each runtime's extension points (prompt + code injection) and pick kauk's integration model — likely a Claude plugin](TODO.md.d/extension-point-survey.md) ~runtime-topology
- `feature · functional · critical · complete · artifact-model ·` [package.toml: a repository declares what it is](TODO.md.d/package-toml.md) ~self-publishing
- `feature · todo · low · plan-ready · artifact-model · gh#16` [Hooks become declarative artifacts with a per-runtime transpiler](TODO.md.d/hooks-declarative.md) ⊘runtime-detection ~claude-marketplace
- `feature · todo · critical · plan-ready · · gh#17` [Templates: beginning, end, inline, with a tracked marker](TODO.md.d/templates-spec.md)
  - `feature · todo · · blocked-on-answers · artifact-model · gh#18` [Generated config headers ship as templates, not hardcoded strings](TODO.md.d/config-headers-as-templates.md) ⊘templates-spec
- `feature · functional · critical · plan-ready · · gh#19` [`roles:` becomes `categories:` — reader shipped; orchard's declarations remain](TODO.md.d/categories-rename.md)
  - `feature · functional · critical · plan-ready · resolver · gh#20` [Dependencies: reader closure shipped; declarations and boundary enforcement remain](TODO.md.d/dependency-graph.md) ⊘categories-rename

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
- `housekeeping · functional · critical · complete · hosting ·` [Move the repository to the kaukea organisation](TODO.md.d/org-move.md)

## cli

- `feature · todo · · queued · cli-core · gh#4` [Build the real kauk CLI (0.1.0), replacing the bash stopgap](TODO.md.d/cli-mvp.md)
- `feature · done ·  · complete · cli-core · ` [Interim bash `kauk` CLI that vendors and syncs packages](TODO.md.d/kauk-sync-stopgap.md) ~cli-mvp
- `feature · todo · · blocked-on-answers · cmd-install · gh#5` [Only install the skills that match a repo's role (dev/infra/org)](TODO.md.d/role-aware-delivery.md) ~cli-mvp
- `bug · cancelled · · complete · cmd-install · gh#6` [~~Installing from a local path drags in the source repo's leftover git objects~~](TODO.md.d/clone-local-object-leak.md) ~role-aware-delivery ~migrations-at-sync
- `bug · functional · critical · complete · cli-core · gh#21` [Stale laid links survive layout changes — heal shipped; estate walk past the SignMc pilot outstanding](TODO.md.d/stale-laid-links.md) ~estate-converge ~migrations-at-sync
- `bug · done · critical · complete · cmd-install · gh#90` [NEVER-EVENT: the laid settings.json takes over the user's — retire it behind spawn-time settings](TODO.md.d/settings-lay-clobbers.md) ⊘fleet-settings-wiring ~claude-marketplace
- `bug · functional · critical · complete · · gh#10` [Remove manifest.conf entirely — the package's tree says what it ships](TODO.md.d/manifest-by-convention.md) ~files-kind ~ai-toml-cleanup
  - `feature · functional · critical · complete · cmd-install ·` [The `files/` kind: contents placed verbatim at their path](TODO.md.d/files-kind.md) ⊘manifest-by-convention
  - `housekeeping · functional · critical · complete · cli-core ·` [.ai.toml goes back to being the operator's file](TODO.md.d/ai-toml-cleanup.md)
  - `feature · functional · critical · complete · cmd-install ·` [Detect the runtimes in use, as a set rather than a winner](TODO.md.d/runtime-detection.md)
- `feature · todo · critical · plan-ready · cmd-install · gh#22` [Publish each package as a plugin into a kauk-maintained local marketplace](TODO.md.d/claude-marketplace.md) ⊘hooks-declarative
- `feature · functional · critical · complete · cmd-install ·` [A package publishes into its own repository instead of vendoring itself](TODO.md.d/self-publishing.md) ⊘package-toml
- `feature · done · critical · complete · cli-core ·` [The migration engine reaches a repository that has never run it](TODO.md.d/migration-engine-rules.md) ~estate-links-run ~migrations-at-sync
- `bug · done · critical · complete · cli-core ·` [A migration that moves the store stranded every migration after it](TODO.md.d/migrations-resolve-late.md) ~estate-links-run ~migration-engine-rules
- `bug · done · critical · complete · cli-core ·` [The orphan sweep deleted whole stores when it could not read the declarations](TODO.md.d/sweep-needs-declarations.md) ~estate-links-run
- `bug · done · critical · complete · cli-core ·` [Migrations sharing one watermark prefix were skipped after the first](TODO.md.d/same-prefix-siblings.md) ⊘migrations-resolve-late ~estate-links-run
- `housekeeping · functional · critical · complete · cli-core ·` [Document `.ai.toml` for the people who write it](TODO.md.d/ai-toml-doc.md) ~store-in-git-folder
- `bug · functional · critical · complete · cli-core ·` [The package store moves into the git folder, and a laid link is counted from its own repository](TODO.md.d/store-in-git-folder.md) ~stale-laid-links ~estate-links-run
- `feature · todo · critical · queued · cli-core · gh#98` [Estate run: sync every consumer once the settings feature lands](TODO.md.d/estate-links-run.md) ⊘fleet-settings-wiring ~stale-laid-links ~estate-converge
- `feature · todo · critical · queued · cli-core · gh#99` [Failed and agent-owed migrations: the ask-file lifecycle end to end](TODO.md.d/migration-asks-lifecycle.md) ~migrations-at-sync
- `completion · todo · · queued · cli-core · gh#100` [Verification pass over the migrations delivery — the operator doubts it is whole](TODO.md.d/migrations-verification-pass.md) ~migrations-at-sync
- `bug · todo · · queued · agent-rules · gh#101` [The courier's watch polls instead of blocking, waking its parent every idle minute](TODO.md.d/courier-blocking-watch.md)
- `feature · done · critical · complete · cli-core · gh#23` [Migrations run at sync, in order, per repository — kai owns the applying (D-055)](TODO.md.d/migrations-at-sync.md) ~stale-laid-links
- `feature · cancelled · · complete · cli-core · gh#24` [~~Provenance: every write outside the clone carries a `:kauk:` nugget~~](TODO.md.d/provenance-nuggets.md)
- `feature · done · critical · complete · cli-core ·` [Configuration matches the operator's spec — one .ai.toml, dependencies, no invented files](TODO.md.d/config-spec-implementation.md) ⊘fleet-settings-wiring ~migrations-at-sync
- `feature · todo · · blocked-on-answers · cli-core · gh#25` [A committed lock records each repository and its resolved head — deferred whole (D-051)](TODO.md.d/lockfile.md)
- `feature · todo · · queued · cli-core · gh#26` [Background update check displays when a source moved](TODO.md.d/update-notify.md)
- `bug · todo · critical · plan-ready · cli-core · gh#27` [macOS portability: BSD awk/sed, bash 3.2 — migrations fail on Macs today](TODO.md.d/macos-portability.md)
- `feature · todo · · queued · ci · gh#28` [macOS suite in CI — visibility route is the open call](TODO.md.d/ci-macos.md) ~macos-portability
- `housekeeping · todo · critical · queued · · gh#29` [kauk adopts orchard — the plugin discussion is gated on it](TODO.md.d/adopt-orchard-here.md) ~takeover-inflight
  - `feature · done · critical · complete · · gh#30` [Fleet settings ride every spawn: --settings + the visible /gardener skill](TODO.md.d/fleet-settings-wiring.md) ~claude-marketplace
- `housekeeping · functional · · complete · cli-core ·` [The command becomes `kai`; the executable is `kaukea`](TODO.md.d/cli-rename-kai.md) ~org-move
- `feature · todo · idea · blocked-on-answers · cmd-install · gh#31` [kauk installs itself alongside the first package](TODO.md.d/bootstrap-with-first-package.md) ~claude-marketplace
- `feature · todo · · plan-ready · cmd-install · gh#92` [Shared rule markdown lands in .claude/rules/ — AGENTS.md stays visible at root](TODO.md.d/shared-rules-placement.md) ~runtime-topology ~stale-laid-links
- `bug · todo · low · blocked-on-answers · cli-core · gh#7` [kauk installed into its own repo tries to link files onto themselves](TODO.md.d/self-install-link-collision.md)
- `feature · todo · · blocked-on-answers · cli-core · gh#8` [Installer picks agents first, then bundles the skills those agents require](TODO.md.d/agent-deployment.md) ⊘runtime-topology ~role-aware-delivery ~cli-mvp

## workflow

- `feature · functional · critical · complete · ·` [Converge the estate: 11 repos to current orchids, forensic skills fall away](TODO.md.d/estate-converge.md) ~lockfile ~migrations-at-sync
- `feature · todo · · blocked-on-answers · · gh#32` [Register the usage: committed lock + per-repo category selection across the estate](TODO.md.d/usage-register.md) ⊘lockfile ⊘categories-rename ~estate-converge
- `housekeeping · todo · · queued · · gh#33` [Take over the in-flight branches: Valve, delivery-restoring, kauk's stale f/*](TODO.md.d/takeover-inflight.md) ~estate-converge
- `housekeeping · todo · critical · queued · · gh#34` [Merge diverged skill copies back into orchids — one codebase before round two](TODO.md.d/skills-merge-back.md) ~estate-converge
- `bug · todo · · blocked-on-answers · agent-rules · gh#93` [tmux layout contract: window per feature, right column stacked — dispatch mis-renders it](TODO.md.d/tmux-layout-contract.md)
- `housekeeping · todo · · blocked-on-answers · agent-rules · gh#12` [Fix the contradictory commit-trailer rules between the rule files (fix lives in orchids)](TODO.md.d/commit-trailer-conflict.md)
- `feature · cancelled · · complete · agent-rules · gh#35` [~~Applying migrations is the agent's job — encode the duty in the workflow rules~~](TODO.md.d/package-migration-reach.md) ~migrations-at-sync
