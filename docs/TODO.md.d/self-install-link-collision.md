- created: 2026-07-16
- created_by: fable-5
- created_during: moved from orchids 2026-07-17 (kauk work belongs on kauk's board)

## Blockers
- Parked by operator ruling 2026-07-16: kauk migration work is deferred. Moved here so
  it is parked in the repo that will fix it, not in the one that reported it.

## Questions
- Should the engine skip `link` entries whose resolved src and dst are the same
  repo-relative path in the installing repo, or should the package manifest carry a
  self-install guard? (Engine-side was the original recommendation — one guard fixes it
  for every package, and no package author has to know about the case.)

## Findings
- Reported from orchids, which self-installs (`kauk init` + `install`, orchids commit
  `957fd72`), mirroring kauk Decision-008 dogfooding.
- Skill/agent/hook/tool/settings links are collision-free — src dir differs from dst dir.
- **The two ROOT `link` entries collide under self-install:** `link AGENTS.shared.md
  AGENTS.shared.md` and the same for `AGENTS.files.md` have src == dst when the package
  IS the repo. Migration therefore replaced the canonical SOURCE files with symlinks
  into the gitignored vendored clone. Committing that would ship dangling symlinks to
  every consumer. In orchids the files were restored with `git checkout --` before
  committing.
- **Consequence, ongoing:** every `kauk sync` run inside a self-installed repo
  re-typechanges those root files until the engine or the manifest guards src == dst.
  Orchids' standing workaround: never commit the `T` typechange on AGENTS.shared.md /
  AGENTS.files.md; merge manually if the content changes make sense.
- Related and already filed here: `clone-local-object-leak` also concerns what the
  vendored clone under `.ai/repositories/` really contains.

## Proposal
During link laying (`lay_source`), resolve src and dst; if identical, skip the entry —
the repo IS the package. One-line guard, no manifest change needed.

## Testing
In a self-installed repo (orchids is the live case): run `kauk sync` and confirm
`AGENTS.shared.md` / `AGENTS.files.md` remain regular files, not symlinks, and that
`git status` reports no `T` typechange. Regression: a normal consumer repo still gets
both files laid as links.
