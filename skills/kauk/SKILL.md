---
name: kauk
description: "Run whenever the operator says install/sync kauk, orchids, or a package, and at workflow start and end. Keeps this repo's vendored file packages (skills, agents, shared rule files) converged with their sources via the stopgap `kauk-sync` CLI: `kauk init` bootstraps the repo, `kauk install <owner>/<repo>` vendors a data package, `kauk sync` converges every installed source. Delivery per skill is tuned in .ai.toml (exclude|copy|link|local). Replaces the retired `skill-sync`/`orchids` flow."
metadata:
  tags: [ kauk, sync, install, skills, drift, package, canonical, orchids, template ]
  share: github
---

# Intent (kauk)

Skills, role agents, hooks, board tools, and shared rule files (`AGENTS.shared.md`,
`AGENTS.files.md`) are **cross-project and agent-tool-agnostic**, shipped as *packages*:
source repos that expose their files and grouping in a `manifest.conf`. Each package is
checked out per-project under `.ai/repositories/<owner>/<repo>/` (only
`.ai/repositories/` is gitignored) and laid into the project as **absolute symlinks** —
absolute so git worktrees resolve them. You CAN write through a symlink: Edit/Write
follow them transparently; edit the skill at the path you loaded it from, never chase
the target into `.ai/repositories/`. `kauk sync` is git doing the magic: local edits are
committed in the checkout, rebased onto the source, pushed back — every project
converges. The tool itself (this package, `serialseb/kauk`) is `pull-only`: tool edits
flow from its repo outward, never back from consumers.

## Checklist

- [ ] `kauk sync` run at workflow start
- [ ] `kauk sync` run at workflow end (before the close)
- [ ] Rebase conflicts resolved with the operator — never silently, in either direction
- [ ] UPDATE/DRIFT notices for `local`/`copy` skills surfaced to the operator
- [ ] Symlink or `.ai.toml` changes committed in this repo like any tracked file

## Commands

The grammar is `kauk <verb>`; the stopgap binary lives in the vendored tool clone
(the real `kauk` CLI ships at 0.1.0 with the same verbs):

```sh
KAUK="$(git rev-parse --show-toplevel)/.ai/repositories/serialseb/kauk/bin/kauk-sync"

"$KAUK" init                               # bootstrap THIS repo: .ai.toml, gitignore, the tool's own package
"$KAUK" install <owner>/<repo> [<origin>]  # vendor + lay a data package (migrates existing real files)
"$KAUK" sync                               # per source: commit local edits → rebase → push back → re-lay
"$KAUK" sync --status                      # readable drift/ahead-behind report per source
```

When the operator says **"install kauk/orchids"** (or "install owin.org"), follow the
served install page at https://owin.org — it vendors the tool, runs `init`, then
`install serialseb/orchids`. On this operator's machines, prefer the local canonicals
(`~/src/serialseb/kauk`, `~/src/serialseb/orchids`) as origins when present.

Errors from `sync` are ignored for the workflow's purposes; it proceeds regardless.

## Delivery config — .ai.toml

Per-repo, at the repo root, written by the CLI (never hand-edited; agents drive it via
this skill). Installed sources are recorded as `[sources."<owner>/<repo>"]` tables with
an `origin`. **Missing or empty role sections = every skill installed as a link.**
Otherwise `[dev]` / `[infra]` / `[org]` / `["*"]` sections with
`skillname = "exclude"|"copy"|"link"|"local"`: `exclude` = not installed · `copy` = real
file, drift reported, never overwritten · `link` = symlink (default) · `local` = the
repo's own version, NEVER sent back to the source, source updates announced at sync. A
skill's role is fixed in its package's `manifest.conf`; `.ai.toml` only tunes delivery.

## Creating a new skill

Author it in the data package — for this fleet, **orchids**
(`~/src/serialseb/orchids/skills/<name>/SKILL.md`) — following the `doing-skills` skill,
add `skill <name> <role>` to that package's `manifest.conf`, then `kauk sync`. Repo-born
skills are adopted into the package automatically by `kauk install` (unless marked
`local`, or the package is `pull-only`).

## Mid-workflow drift

If a sync mid-workflow pulls a changed version of a skill you already loaded, reload it,
then ask the operator whether to apply the change only from here on or to retrofit work
already done. Do not silently retrofit, do not silently ignore.
