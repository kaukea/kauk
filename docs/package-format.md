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

## The root table of `.ai.toml` — declaring that this repository is a package

A repository becomes a package by saying so in the root table of its own `.ai.toml`,
the one configuration file it has (`docs/configuration-files.md`):

```toml
name = "orchard"
type = "package"
```

Both keys are optional: `name` defaults to the repository's own directory name, and
`type` defaults to `project`. That is the whole of a package's identity —
`package.toml`, which used to carry a name, title, description and a pull-only flag,
is gone (`migrations/2026-08-26-01-one-configuration-file.md`).

One repository is one package. A package's `.ai.toml` travels with it, and a consumer
reads its `name` to namespace what it lays; the consumer's own dependency blocks in the
same file are read only in the repository that owns them, never out of a clone.

Any repository may declare itself a package, including one that also consumes packages.

> **Parked:** a package depending on another package. Where that declaration lives is
> undecided (operator, 2026-08-26) and waits on the versioning work, so nothing is
> installed on a package's behalf today — a consumer declares every package it wants
> in its own `.ai.toml`. Cross-package artifact dependencies still resolve across the
> packages a consumer has installed.

## Declaring a package, and publishing into your own repository

A repository declares itself a package by carrying a `[general]` table in its own
`.ai.toml`, the consumer-side file, with `type = "package"`:

```toml
[general]
type = "package"
```

That declaration — and nothing inferred from how the operator happens to have set up
their sources — is what makes kai apply the repository's own `migrations/` (merged
into the single migration stream, see *migrations/* below), lay its own `agents/` and
`skills/`, and publish its own `files/` by copy instead of by link. `.ai.toml` is the
user's file; kai infers no behaviour from it beyond what it explicitly says, so a
repository that happens to list its own path as a source carries no special meaning
from that alone. (This replaces an earlier inference that compared a declared source's
resolved path against the repository root — dropped because it read meaning into an
incidental fact, and because it rested on a false premise: kai always installs the kai
package, so a repository consuming anything is never without a package to begin with.)

A repository that is a package this way is **not vendored**. There is no clone of its own
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
| `migrations/<YYYY-MM-DD>-<NN>-<featurename>.md` | migration | executed, not placed |

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

`migrations/<YYYY-MM-DD>-<NN>-<featurename>.md`, one file per feature. The whole
filename is applied in **ASCII order** — the usual convention for anything that has to
run in sequence — so `<NN>` orders same-day files against each other. A same-day set
authored together for one version is one run, ordered within the day by `<NN>`; a
hotfix shipped after a release takes the next `<NN>` and reaches anyone still sitting
at the version before it. This supersedes the earlier `<YYYY-MM-DD>-<slug>.md` form and
the sentence that derived the package version from the highest filename — version
derivation is not specified here any further; see the watermark below for what the
filename now drives instead.

- Content stays **natural language**, wrapped in a structured format. Existing
  migrations are not rewritten.
- There is no closed set of step verbs (operator, 2026-08-18, superseding the
  earlier `reload`/`restart`/`rename`/`apply skill` closed-set sketch). A
  migration's fenced ```sh``` code blocks are its steps, run in order, executed
  **inside kauk, deterministically** — with the consumer root as cwd — rather
  than handed to an agent. This is what makes execution independent of what any
  agent chooses to do, and what makes most of a migration testable.
- **Migrations run at sync time — the tool owns the applying.** No agent reads,
  applies, or advances a watermark by hand (Decision-055).
- A `reload` step is available on any update, not only inside a migration: on the Claude
  target `/reload-plugins` picks up changed components without a restart.
- Every step is guarded by observable state, never by assumed position in a sequence.
- **Errors are reported, not handled.** Kai runs a migration's shell steps and reports
  whichever ones failed, then moves on. There is no hand-off of a failed step to an
  agent, no file that parks a failure for a later session to pick up, and no routing
  that clears a failure by deleting anything. Self-testing a migration — verifying
  that its own effect actually took — is not built and may be revisited later.
- **Migrations do not ship tests.** A migration is tested in the repository that ships
  it, before it is published. Nothing test-shaped is delivered to a consumer.

**Order, when a sync pulls from a source with migrations pending:**

```
fetch  →  apply what was already pending  →  rebase your changes  →  apply what
just arrived  →  watermark
```

The clone applies whatever was already pending against its own pre-rebase content
first, so it lands in the same reality as everyone else *before* its local edits (if
any) replay on top. Rebasing first to obtain easier conflicts invents a tree that
does not exist. Only after the rebase does it apply migrations that arrived with
this pull — because migrations are append-only and never rewritten, that is exactly
the set dated after the pre-rebase watermark. The watermark advances once a
migration's steps have all run, in either pass.

### The watermark

**One watermark, global to the consuming repository** — not per package, not per
source. It is the `<YYYY-MM-DD>-<NN>` prefix of the last applied migration, written as
a single line in a **committed** file, `.ai/migrations.toml`, under a `[migrations]` table.
Nothing about migration state lives under `.git/`: durable state must survive a clone,
and `.git/` does not travel with one.

Every declared source's `migrations/` directory, plus the repository's own
`migrations/` when the repository declares itself a package (see *Declaring a
package*, above), merge into a **single stream**, ordered by the `<YYYY-MM-DD>-<NN>`
prefix regardless of which package a given file came from. Everything above the
watermark applies, in that order, in one run. Packages migrate together — a
per-package watermark let packages apply in strange orders relative to each other,
which is the failure this replaces.

No watermark present means a fresh install: nothing is pending, and the watermark is
stamped at the current date and time rather than replayed from the start.

## The kai package

kai itself ships as a package: `skills/kai/` — the agent-launch skill — plus
`migrations/`, and nothing else. Everything else kai needs is already in `bin/`,
present on `PATH` from the static install; it is not delivered as package content.
Installing the kai package is how a repository subscribes to kai's own migrations —
which is what closes the circle for a package that, by design, declares no
dependencies of its own.

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

The plugin earns its place twice over:

1. **It is the native acquisition path.** Installing a plugin, or adding a marketplace
   and installing from it, is something a user can ask for in plain language and an
   agent can carry out end to end. Nobody has to learn kauk's own syntax; the CLI
   becomes the floor for other runtimes and for CI, not the front door. kauk itself
   bootstraps the same way, which resolves the chicken-and-egg of needing the kauk
   skill in order to ask for packages conversationally.
2. **It is self-contained, so its wiring is regenerated rather than mutated.** Because
   the whole plugin is generated on the filesystem, adding or removing a hook is a
   re-render of the plugin — not a surgical edit to a shared `settings.json` whose other
   tenants have to be reconciled around it. The set of hooks can change freely.

### The flow

1. **Pull** the source. It is in the generic format.
2. **Transform** it into the Claude plugin format.
3. **Publish it into a local marketplace** that kauk maintains on the filesystem and
   that the user added once. The marketplace is regenerated as sources are added or
   updated, so each added repository stays current automatically.
4. Claude installs from it. **Nothing is linked** — everything the package provides is
   embedded in the plugin.

```
<kauk marketplace>/
├── .claude-plugin/marketplace.json     regenerated: one entry per package
└── plugins/<package>/
    ├── .claude-plugin/plugin.json      generated from .ai.toml's root table
    ├── skills/<name>/SKILL.md          ← skills/   (with their own scripts/)
    ├── agents/<name>.md                ← agents/
    ├── hooks/hooks.json                ← hooks/    (transpiled)
    ├── .mcp.json                       ← tools/    (transpiled)
    └── scripts/                        referenced by ${CLAUDE_PLUGIN_ROOT}
```

A local directory is a valid marketplace source (`/plugin marketplace add <path>`), and
plugin entries may use paths relative to the marketplace root. Updates reach the user
through `/plugin marketplace update`; the `version` field on each entry is what gates
when an update is taken, so kauk manages it.

**`files/` is not part of the plugin.** A plugin cannot place a file at an arbitrary
repository path, so `files/` is still delivered directly into the repository — and that
is the only place the link-or-copy question survives on the Claude path.

Constraints on the transpiler:

- Hook commands reference their scripts through `${CLAUDE_PLUGIN_ROOT}`, so nothing in
  a plugin needs an absolute path.
- Changes to `hooks/`, `.mcp.json` or `agents/` need `/reload-plugins`; `SKILL.md` edits
  are live. That is what a migration's `reload` step is for.
- Bundled MCP servers go through per-server approval.

### The link system does not go away

Other runtimes have no plugin mechanism, and may never have one. The existing
link-based delivery remains for them. The plugin is the **clean path where it is
supported** — not a replacement for the model.

---

## Consumer-side artifacts

Three files, three different jobs:

| Artifact | Owner | Committed | Purpose |
|---|---|---|---|
| `.ai.toml` | the user | yes | what this repository IS, and what it consumes |
| `.ai/migrations.toml` | kauk | yes | the last migration applied here |
| placement index | kauk | no | where things went — a cache, for speed |

```toml
# .ai.toml — yours to edit
name = "my-thing"         # optional; defaults to the directory name
type = "package"          # optional; project when absent

[[dependency]]
source = "kaukea/kauk"
include = ["process/orchard"]

[[dependency]]
source = "/home/sudoku/src/some-local-checkout"
```

A `source` is one of four things: `<owner>/<repo>`, which resolves to
`https://github.com/<owner>/<repo>`; a full git URI; an absolute path; or a `./`
relative path, taken against this repository's root. It may end in `@HEAD`. Any other
ref — a branch, a tag, a commit — is parked with the versioning work: kai leaves that
clone where it is and lays what is already there.

`include` is accepted on git sources only. A local path is a development convenience
that has to be replaced by its git source before publishing, and a selection that does
not survive that swap is a trap (operator, 2026-08-26). A dependency's `type` is
optional and only `package` is acted on.

Parsing is **line-oriented**, with one exception: an `include` array may span lines.

```toml
# .ai/migrations.toml — machine-written, do not edit by hand
[migrations]
watermark = "2026-08-19-02"
```

The **index is for speed, not for accuracy**. It is never the source of truth: every
placement can be rebuilt by scanning for nuggets, and selection is explained by
`.ai.toml`. The **lock** is the one genuinely non-derivable artifact —
`.ai/repositories/` is gitignored, so a fresh clone has nothing to scan, and a source
that placed no files leaves no nugget anywhere. Its `[migrations]` table carries the
one global watermark described under *migrations/*, above.

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
