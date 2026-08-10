# The kauk package format

A package is **a repository of files that knows nothing about kauk**. There is no
manifest, no declaration file, no index of contents. What a package ships is decided
entirely by **convention**: the presence of a known directory at the repository root.
Anything outside those directories is ignored.

This document is the contract. A repository that follows it is installable; a
repository that does not is simply a repository.

> Status: specified 2026-08-10, not yet implemented. `bin/kauk` currently reads a
> `manifest.conf` and must be changed to walk the tree. See `docs/decisions.md`
> Decision-014 onward.

---

## `package.toml` — declaring that this repository is a package

A repository becomes a package by carrying `package.toml` at its root:

```toml
[package]
name = "orchids"
title = "Orchids"
description = "The fleet's canonical skills, agents and rule files."
type = "…"
```

`package.toml` is **published** — it travels with the repository and every consumer
reads it. This is deliberately not `.ai.toml`, which is **local**: what this particular
checkout consumes, and nobody else's business. Merging them would ship a consumer's
private selections inside a published artifact.

Any repository may declare itself a package, including one that also consumes packages.

> **Future:** packages depending on packages, which is what makes cross-package
> dependencies possible — an agent in one package depending on a skill in another. The
> package graph resolves first (which sources to fetch), then the artifact graph across
> their union. Not built; whether a package dependency names a package or a location is
> undecided and waits on the native index.

## Publishing into your own repository

A repository that is itself a package is **not vendored**. There is no clone of its own
HEAD under `.ai/repositories/`, because that is what forces you to push in order to see
your own edits — you would be editing the source and the vendored copy at the same time.

Instead:

- the **source is the working tree**, read in place;
- the artifacts are published exactly as they are for any other package — the same
  transformation, taking each convention directory and rendering it into the target's
  layout;
- the publication type changes from link to **copy**: the rendered files are copied back
  into the repository and committed, after which the normal flow works.

Nothing else differs. A self-published package is a package.

---

## Convention directories

| Directory | Kind | Transpiled? |
|---|---|---|
| `skills/<name>/` | skill | placement only |
| `agents/<name>.md` | agent | placement only |
| `hooks/<event>/` | hook | yes — per runtime |
| `tools/<name>/` | tool | yes — per runtime |
| `files/<path>` | file | no — verbatim |
| `templates/<name>` | template | applied into a file the consumer owns |
| `migrations/<date>-<slug>.md` | migration | executed, not placed |

Everything else in the repository — `docs/`, `tests/`, `README.md`, `CHANGELOG.md`,
build files, source — is **ignored**. A package repository is a normal repository
that happens to have some of these directories in it.

---

## skills/

A skill is a directory. Its `SKILL.md` carries YAML frontmatter using the standard
skill convention:

```yaml
---
name: <folder-name>          # MUST equal the directory name
description: <the trigger, then what it does>
categories: [ <slash-path>, … ]
compatibility: [ … ]         # optional; omitted = all
visibility:                  # optional; see Visibility
  user-invocable: true
  model-invocable: true
dependencies:                # optional
  skills: []
  agents: []
  tools: []
---
```

`name` and `description` are the universal pair every runtime understands. Any
further metadata a package author adds is **passed through untouched** — kauk does
not normalise, strip, or validate it beyond the keys it acts on.

A skill may carry supporting files — scripts, references, assets — inside its own
directory. A script used *solely* by one skill lives in that skill's folder and travels
with it, which is also how a Claude plugin packages a skill. A script shared across
artifacts, or invoked by something other than a skill, is a file.

There is **no ownership** between artifacts. What one artifact needs from another is
stated as `dependencies:` — see *Dependencies*.

Each file inside a skill is linked **individually**, never as a whole-directory
symlink, so that a destination can hold rendered content alongside verbatim content.

## agents/

An agent is a **flat file**. It is a glorified prompt — not a skill definition, not a
container, and it carries no payload of its own.

```yaml
---
name: <name>
description: <what it is for>
type: root | child | sibling | background
categories: [ <slash-path>, … ]
compatibility: [ … ]
visibility: { user-invocable: true, model-invocable: true }
dependencies:
  skills: []
  agents: []
  tools: []
---
```

Agents **call** tools or skills. Any script an agent needs belongs to the tool or the
skill it depends on. This matches every runtime surveyed: agent = one file, skill = a
folder that carries its own scripts, package = the unit that bundles both.

**`type`** classifies the subagent's relationship to its launcher and is what a
windowing integration (tmux today) keys off:

| type | meaning |
|---|---|
| `root` | a top-level session, launched by the operator |
| `child` | spawned by, and subordinate to, the agent that launched it |
| `sibling` | spawned alongside its launcher, not under it |
| `background` | runs detached, with no pane of its own |

**`dependencies` is also the restriction.** The declared skills and agents are the ones
this agent may call — the list is a capability boundary, not a hint. An agent cannot
reach a skill or an agent it did not declare.

**Agents are launched by skills, never by hooks.** A hook that autostarts an agent
forecloses the user's choice of workflow; a skill (`/garden` launching the gardener, for
example) lets the user pick. Packages therefore do not ship autostart hooks for agents.

## hooks/

A hook is a directory named after a **runtime-neutral event**, containing
`index.toml`:

```
hooks/
  session.start/
    index.toml
  tool.shell.before/
    index.toml
```

```toml
description = "Announce closed workstreams awaiting ingestion"

[[actions]]
scripts = ["*.sh"]

[[actions]]
inject-context = "…"

[[actions]]
notify = { text = "…", level = "warn" }
compatibility = ["claude"]
```

**Actions.** One action key per `[[actions]]` entry; the key *is* the action name and
its value carries the parameters. There is no `action = "<name>"` discriminator,
because the set is **closed** — every action needs an implementation and
documentation in kauk, so an unrecognised key is an error, not an extension point.
New keys are added as they standardise. Whether an action may veto is a documented
property of that action, not a flag in the file.

`scripts` is the migration affordance and the direction of travel is away from it,
towards named actions kauk maps into the destination host's own language.

**Matchers are not part of the vocabulary.** A concept that one runtime expresses as
a filter on a generic event gets its own event name — `tool.shell.before`, not
"PreToolUse with the string Bash". The transpiler renders it as a first-class event
or as event-plus-matcher, per target.

**The transpiler owns the mapping**, including fallbacks where a target has no native
event. Package authors declare the neutral event and never learn any runtime.

**`settings.json` is never shipped, and never written either.** On the Claude target a
package renders as a **plugin**, which owns its own hook wiring — see *The Claude
target* below.

## tools/

A tool is a declaration with **frontmatter**, and it **transpiles per runtime** — an MCP
server entry for Claude Code, the equivalent for the next runtime.

A tool may be backed by either a **script** or an **MCP server definition**. Both are
tools; the backing is an implementation detail the transpiler resolves per target.

```yaml
---
name: <name>
description: <what it does>
categories: [ <slash-path>, … ]
compatibility: [ … ]
visibility: { user-invocable: true, model-invocable: true }
---
```

`tools/` is kept separate from `files/` deliberately: the two are semantically
distinct, and a declaration permits specialisations a verbatim file cannot express.

Helper scripts invoked by path, with no declaration, are **not** tools. They are files.

## Visibility

Every artifact may declare who is allowed to invoke it:

```yaml
visibility:
  user-invocable: true      # appears in the user's slash list
  model-invocable: true     # the model may auto-invoke it
```

Both default to true. Process machinery — close procedures, handover, session-start
rules — is typically `user-invocable: false`, so a consuming repo's slash list shows
only genuinely operator-facing entries while the model still triggers the rest on their
descriptions. The transpiler renders this into whatever the target calls it; on Claude
that is `user-invocable` / `disable-model-invocation` in the artifact's own frontmatter.

## files/

Files. Placed at their path **relative to `files/`**:

```
files/.gitattributes        →  <repo root>/.gitattributes
files/scripts/build.sh      →  <repo root>/scripts/build.sh
```

No transformation, no substitution, no injection. We do not touch files; we put
files. The path is the author's choice, including a runtime-specific one.

## templates/

A template is **text with YAML frontmatter**, applied into a file the consumer owns.

```yaml
---
name: <name>
description: <what it does>
type: beginning | end | inline
match: <regex>        # inline only; the first group is what is replaced
tracked: true         # default
---
```

- `beginning` — at the start of the destination.
- `end` — at the end.
- `inline` — locate by `match` and replace the first group.

A **tracked** application carries one marker line, written as a comment in the
destination's own syntax, stating that it is load-bearing and not to be changed, plus
its origin:

```
<comment> :kauk: load-bearing — do not edit · kauk <owner>/<repo> <sha>
```

One marker, no closing marker. If someone writes past a line that says do not touch,
that is their loss — kauk is not a caretaker. `inline` needs no end marker because
`match` relocates the block on every application.

A `match` that finds nothing is **reported and skipped**. If the thing to fix is not
there, nothing is done.

A variable-interpolation syntax (`{{ … }}` or similar) is **reserved** — documented
and linted, not implemented.

## migrations/

`migrations/<YYYY-MM-DD>-<slug>.md`, one dated file per structural change. The
package version *is* the highest filename.

- Content stays **natural language**, wrapped in a structured format. Existing
  migrations are not rewritten.
- Codified step types — `reload`, `restart`, `rename`, `apply skill` — follow the
  same closed-set, one-key-per-step pattern as hook actions, and host-specific steps
  are transpiler territory.
- Codified steps execute **inside kauk, deterministically**; only the prose residue
  is handed to an agent. This is what makes execution independent of what any agent
  chooses to do, and what makes most of a migration testable.
- **Migrations run at sync time.**
- A `reload` step is available on any update, not only inside a migration: on the Claude
  target `/reload-plugins` picks up changed components without a restart.
- Every step is guarded by observable state, never by assumed position in a sequence.

**Order, when pulling a source that has migrations pending:**

```
pull  →  apply migrations  →  rebase your changes  →  write your migration
```

Upstream commits already contain the migrations their author applied. The consumer
applies the same ones so both trees are in the same reality *before* rebasing.
Rebasing first to obtain easier conflicts invents a tree that does not exist.

The watermark is **per repository**.

---

## Delivery

**Everything is a link.** Always was, stays. Editing a laid file is editing the
source — that is the point. There is no copy mode, no local mode, and no per-skill
delivery layer.

**Conflicts report and skip.** A destination that already holds a real file, or that
two packages both claim, is left alone and reported. Nothing is overwritten and
nothing is resolved on the user's behalf, because the user has made no selection.

**Every write outside the clone carries a nugget** — the magic token `:kauk:` with
origin and sha. Links self-identify through `readlink` into
`.ai/repositories/<owner>/<repo>/…`; templates through their marker; transpiled
output through the same origin and sha carried as data where comments are
impossible.

Artifacts that cannot carry an inline nugget — binaries — get a **committed per-file
sidecar** alongside: `<file>.kauk`. Per-file rather than per-directory or root,
because a directory or root sidecar is an index again, and indexes drift.

---

## Runtime detection

A repository containing `.claude/` or `CLAUDE.md` is a Claude repository, and
artifacts are laid where Claude expects them.

Detection yields a **set, not a winner**. Three or four tools may be in use and all of
them are served; placement is not a competition. Claude is one destination, never
*the* destination.

Where nothing is detected, the user is asked at initialisation which agent they will
use.

---

## The Claude target — a plugin

A package renders to Claude Code as a **plugin**, not as loose files scattered through
`.claude/` plus edits to the user's `settings.json`. The plugin owns its own wiring, so
kauk never touches a file the user owns.

Specifically, kauk renders a **skills-directory plugin**: any folder under a skills
directory containing `.claude-plugin/plugin.json` is loaded as `<name>@skills-dir` on
the next session — discovered in place, no marketplace, no install step, and no
uninstall step either. Removing the folder removes the package.

```
<repo>/.claude/skills/<package>/
├── .claude-plugin/plugin.json      generated from the package
├── skills/<name>/SKILL.md          ← skills/       (with their own scripts/)
├── agents/<name>.md                ← agents/
├── hooks/hooks.json                ← hooks/        (transpiled)
├── .mcp.json                       ← tools/        (transpiled)
└── scripts/                        hook scripts, referenced by ${CLAUDE_PLUGIN_ROOT}
```

`files/` is **not** part of the plugin — its contents go into the repository at their
own paths, which is the whole point of the kind.

Notes that constrain the transpiler:

- Hook commands reference their scripts through `${CLAUDE_PLUGIN_ROOT}`, so nothing
  in a plugin needs an absolute path.
- Project-scope `@skills-dir` plugins load only from the `.claude/skills/` of the
  directory Claude was started in — they do not walk up to the repository root the way
  plain skills do.
- Edits to a `SKILL.md` are live; changes to `hooks/`, `.mcp.json` or `agents/` need
  `/reload-plugins` or a restart. That is what a migration's `reload` step is for.
- At project scope the plugin loads behind the workspace trust gate, bundled MCP
  servers take per-server approval, and background monitors do not load at all.

Other runtimes get their own rendering. The plugin is Claude's encoding, never the
model.

---

## Consumer-side artifacts

Three files, three different jobs:

| Artifact | Owner | Committed | Purpose |
|---|---|---|---|
| `.ai.toml` | the user | yes | what was asked for — sources and selection |
| lock | kauk | yes | what was got — each repository and its resolved head |
| placement index | kauk | no | where things went — a cache, for speed |

```toml
# .ai.toml — yours to edit
[sources."kaukea/kauk"]
origin = "https://github.com/kaukea/kauk"
```

```toml
# lock — machine-written, do not edit by hand
[[repositories]]
id = "kaukea/kauk"
origin = "https://github.com/kaukea/kauk"
head = "<sha>"
```

The **index is for speed, not for accuracy**. It is never the source of truth: every
placement can be rebuilt by scanning for nuggets, and selection is explained by
`.ai.toml`. The **lock** is the one genuinely non-derivable artifact —
`.ai/repositories/` is gitignored, so a fresh clone has nothing to scan, and a source
that placed no files leaves no nugget anywhere.

---

## Categories and dependencies

**Categories** group skills and agents into a browsable tree so that adding a
repository of forty skills does not force forty skills on the consumer. Both skills
and agents declare `categories:` — one or more slash-paths in a multi-parent DAG. The
consumer picks individual artifacts, or a whole category and everything inside it.

The vocabulary is defined in exactly one place and declared against, never restated.

**Dependencies** are a plain graph, declared in the artifact's own metadata:

```yaml
dependencies:
  skills: []
  agents: []
  tools: []
```

- an agent may depend on agents, skills or tools
- a skill may depend on skills or tools

That is the whole model. There is no ownership relation between artifacts — only
declared dependencies.

For an **agent**, the declaration doubles as a **capability boundary**: the agent may
call the skills and agents it names, and nothing else.

Selection is a request; the installed set is its dependency closure, and the consumer is
told what was pulled in beyond what they picked.
