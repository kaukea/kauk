# Decisions

Append-only, chronological (oldest top). Grep by `#keyword`; never read whole. A decision
is a RULING, not a state. Format: `## [YYYY-MM-DD HH:MM TZ] Decision-NNN: Title` + a
mandatory `#hashtag` line.

## [2026-07-13 22:46 CEST] Decision-001: Platform name = KAUK; domains kauk.ai + kauk.org
#naming #kauk #kaukai #domain #brand

Decided 2026-07-12 (context: deep-research pass, 102 agents). The package platform is
**KAUK** — brand = command = domain, one 4-keystroke string everywhere, no alias/diminutive.
`kauk.ai` is the brand domain (a hack on the plural *kaukai*, Baltic household wealth-dwarfs);
`kauk.org` is the tooling/config-path domain (canonical `kauk.org/<pkg>`). GitHub org =
`kaukai` (the exact `kauk` username is a dormant account — a username-release ticket is
filed; **fallback stem = `parstuk`** if it fails). Full rationale, rejected rivals, and the
claim set live in `docs/naming.md`. Do not re-litigate.

## [2026-07-13 22:46 CEST] Decision-002: KAUK is a control plane, not a storage backend
#architecture #control-plane #federation #registry

KAUK is a native artifact index (packages, skills, arbitrary files as first-class) PLUS a
federation layer over external registries (npm, PyPI, OCI, GitHub) that the user opts into.
The value is the tooling — one CLI, one grammar, one auth flow — not the bytes. Skills and
arbitrary files are native artifacts; no PyPI/npm wrapper-package trick is needed on the
native index. Addressing is backend-qualified so `install <pkg>` is never ambiguous.

## [2026-07-13 22:46 CEST] Decision-003: Credential custody is client-side, not server-held
#custody #oauth #security #federation #tokens

External-backend publish credentials live on the USER's machine (OAuth device flow). KAUK
holds only the app registration, never a hoard of users' tokens — a server-side token vault
would make KAUK the single richest supply-chain target ("one ring binds them" = Sauron's
design). "Bind the workflow, not the secrets." Server-held tokens require an explicit future
decision and, if ever adopted, are scoped publish-only-this-package / short-lived /
per-backend. Anything KAUK republishes on a user's behalf is signed/attested (npm provenance
/ sigstore).

## [2026-07-13 22:46 CEST] Decision-004: Reserve the `kauk` name via 0.0.0 stub packages
#reservation #pypi #npm #naming #squatting

PyPI and npm have no name-reservation API; the only claim mechanism is publishing. Reserve
`kauk` on both with `0.0.0` placeholder packages (`namespace-reservation/`) that signal
"nothing shipped yet"; real tooling starts at `0.1.0`. Do NOT sequence releases with `+build`
metadata (ignored for ordering; PyPI rejects local `+` versions). This closes the
supply-chain squat window during the GitHub-username wait. Reservations held with genuine
intent (README → kauk.ai) survive PyPI PEP 541 / npm dispute policy.

## [2026-07-13 22:46 CEST] Decision-005: Repo home ~/src/kauk, orchids-managed house style
#repo #orchids #layout #agents

The platform lives at `~/src/kauk` (its own product, not under SafeKeepIt/serialseb),
bootstrapped with `orchids init` — shared agent-rule files + skills vendored as symlinks
under `.ai/`, project-owned `AGENTS.md`/`README`/`ARCHITECTURE`/`docs`. Matches TitanShield /
Panopticon / SignMc. `orchids sync` pulls canonical updates.

*Annotation (2026-07-14): the operator's repo reshuffle moved the checkout to
`~/src/serialseb/kauk`; the house-style ruling stands. The bootstrap wording
(`orchids init`/`orchids sync`) is superseded by Decision-007 — the flow is now
`kauk init` / `kauk sync`.*

## [2026-07-13 22:46 CEST] Decision-006: License = MIT (placeholder, revisit before 0.1.0)
#license #mit

Provisional: MIT, to match the reservation stubs and keep the platform permissive. Sibling
public tooling (signmc, packages.serialseb.net) is GPLv3 — revisit and confirm before the
first real (`0.1.0`) release. Marked so a future reader knows it was a default, not a
deliberated final choice.

## [2026-07-14 10:26 CEST] Decision-007: kauk owns the package-manager code; orchids is data-only
#split #kauk-sync #orchids #cli #packages #stopgap

The distribution tool moves out of orchids into this repo as `bin/kauk-sync` — a bash
STOPGAP whose grammar (`init` / `install <owner>/<repo>` / `sync`) the real 0.1.0 CLI
inherits; the command name `kauk` stays reserved for that CLI (Decision-004's
reservations are unaffected). orchids keeps only what it distributes — skills, agents,
hooks, tools, settings, AGENTS files, templates — and *exposes the files and their
grouping* in its `manifest.conf` (typed lines: `skill`/`link`/`template`/`prefix`/
`option`); the engine hardcodes no package layout. The tool is vendored per consumer
repo at `.ai/repositories/serialseb/kauk/` and invoked by relative path; sources are
recorded in `.ai.toml` `[sources."<owner>/<repo>"]` tables. The agent-facing surface is
agent-agnostic (the `kauk` skill + the served install page) — no Claude-specific
commands dir; a plugin only if it later demonstrably enforces the workflow better.

## [2026-07-14 10:26 CEST] Decision-008: kauk is itself a package, pull-only
#packages #pull-only #kauk-sync #dogfood

The kauk repo exposes its own mini-manifest (`option pull-only` + `skill kauk all`), so
the engine installs the tool's skill through the same path as any data package —
dogfooding the source-generic design with a second real source from day one. `pull-only`
means consumer-side edits to the tool package are NEVER pushed back; the tool changes
only in its own repo. A dirty pull-only clone is warned about and skipped at sync.

## [2026-07-14 10:58 CEST] Decision-009: The stopgap script is named `kauk`
#naming #cli #stopgap #kauk

Supersedes the naming half of Decision-007 (operator ruling): the stopgap ships as
`bin/kauk`, not `bin/kauk-sync` — brand = command from day one. The 0.1.0 CLI replaces
the file in place, same name, same grammar; "stopgap" remains a property of the
implementation, not the name.

## [2026-07-17 14:42 CEST] Decision-010: The npm reservation is scoped — `@kauk.ai/kauk`
#npm-namespace #npm #reservation #naming #scoped

npm will not accept the unscoped `kauk`. The registry rejects it deterministically on
its typosquat similarity heuristic, and names the remedy itself:

    npm ERR! code E403
    npm ERR! 403 Forbidden - PUT https://registry.npmjs.org/kauk - Package name too
    similar to existing packages ka23,caduk,vaul,walk; try renaming your package to
    '@kauk.ai/kauk'

This is a heuristic on the bare word, not an ownership conflict — the dormant `kauk`
npm *username* (0 packages) does not hold the name and is not the cause. There is no
flag, appeal-free retry, or version change that gets past it.

Ruling (operator-approved): the npm reservation is the SCOPED `@kauk.ai/kauk`, published
at `0.0.0` under the npm account `kauk.ai` (org `kaukai`). It is live —
`npm view @kauk.ai/kauk version` → `0.0.0`. Scoped packages are private by default, so
publishing this one publicly requires `--access public`; the unscoped instructions that
omitted the flag no longer apply.

Clarification (2026-07-17): this block is **npm-specific**. PyPI has no name-similarity
filter and accepted the bare `kauk` unchanged — published and live at `0.0.0`. The
reservation is therefore asymmetric by necessity: bare `kauk` on PyPI, scoped
`@kauk.ai/kauk` on npm.

This REFINES Decision-004, it does not supersede it: reserve-via-`0.0.0`-stub still
holds on both registries, and the PyPI reservation stays unscoped `kauk`. Only the npm
package identity changes. The brand, the command name, and the PyPI name are untouched —
`@kauk.ai/kauk` is an npm packaging artifact, not a rename (Decision-009's `kauk`
command stands).

Asking npm support to release the bare `kauk` name is a SEPARATE operator follow-up, out
of scope here; if it ever succeeds, the unscoped name becomes an alias to publish
alongside, not a reason to unpick this.

## [2026-07-21 01:45 CEST] Decision-011: manifest.conf is retired — the tree defines the package
#manifest #distribution #kauk-sync #conventions #packages

Operator ruling. The hand-typed `manifest.conf` index was built on a complete
misunderstanding — the concept was a model invention, never an operator design
(see the manifest-by-convention task's findings; its silent-drift failure shipped
nothing to nobody on 2026-07-19). It is to be REMOVED, not derived-and-kept: a
package's payload is defined by its tree, by convention — `skills/<name>/`,
`agents/*.md`, `hooks/*.sh`, `tools/*`, `templates/` — with per-skill roles
already in frontmatter (orchids role-dag-frontmatter). The interim tree-vs-manifest
lint proposed earlier is moot under this ruling: the manifest it would police is
going away; the effort goes into derivation in the reader (`bin/kauk`).

Context, not ruling: the small non-derivable residue (the kauk package's
`pull-only` nature; template-vs-prefix semantics for the two `templates/` files;
the root-file placements like `settings.json` → `.claude/`) needs a home that is
not a parallel file index — where exactly is design for the implementing task
(board: manifest-by-convention, rescoped by this decision).

Removal spans both package repos: `bin/kauk` (this repo) stops reading the file;
`serialseb/orchids` deletes its `manifest.conf` via its own workflow.

## [2026-07-21 02:05 CEST] Decision-012: Artifacts are runtime-agnostic — agent runtimes are targets
#topology #runtime-targets #hooks #transpile #artifact-model #opencode #claude-code #packages

Operator ruling. People write agents, skills, and hooks ONCE; kauk transpiles
them where needed and lays them according to the agent runtime in use — Claude
Code today, opencode (or another tool) tomorrow. Every design must adapt to
this: the `.claude/` layout, `settings.json` hook wiring, and Claude event
names are ONE target's encoding, never the model. The current approach to
hooks is explicitly flawed — Claude-specific wiring standing in for the
artifact itself; hooks become first-class portable artifacts with per-runtime
transpilation. Skill autoselection per agent (board: agent-deployment) DEPENDS
on this topology model and is gated behind it (the topology task is the more
urgent of the two).

## [2026-07-21 02:20 CEST] Decision-013: Topology first cut — declarative hooks, adaptation layers, runtime detected at sync
#topology #hooks #transpile #runtime-targets #adaptation-layer #claude-code #opencode

Operator rulings on the runtime-topology spec (refining Decision-012):

- **Claude-only for now.** The model stays runtime-shaped, but nothing
  opencode-specific is rendered or shipped in the first cut.
- **Packages are DECLARATIVE.** Hooks (and extension wiring generally) are
  declared runtime-neutrally: EVENTS mapped on one side, what they can TRIGGER
  on the other, with per-runtime ADAPTATION LAYERS bridging the two — that is
  the common case. Authors who want runtime-specific behaviour OPT OUT with
  runtime-prefixed event names (e.g. `claude:on-...`), which bypass adaptation
  and target one runtime only.
- **Runtime is DETECTED at `kauk sync`** (no per-repo target declaration in
  .ai.toml for this).

## [2026-08-10 11:17 CEST] Decision-014: Unspecified state is untrusted — the blanket rule
#trust #provenance #agents #invention #working-rule

Operator ruling. Existing state is NOT evidence of intent. Most of what is in these
repositories was built by agents, not specified by the operator. **If there is no
specific definition by the operator, it is not to be trusted** — do not reason from
it, do not preserve it for consistency, do not cite it as precedent. Ask.

Corollary: agents MUST NOT introduce additions that are not operator-driven.

Context for why this is recorded as a ruling rather than a mood: `manifest.conf`'s
four-verb grammar and its per-file `link` enumeration were authored by a model in
`904a9a0` (orchids, 2026-07-14), together with the very decisions that justified
them, and were then mimicked by later package authors because the reader enforced
them. See Decision-011.

## [2026-08-10 11:17 CEST] Decision-015: The package tree is the contract — five kinds, convention only
#packages #conventions #manifest #kinds #skills #agents #hooks #tools #files

Operator ruling. A package is a repository of files that knows nothing about kauk.
There is no producer-side manifest and none is needed — package contents are
determined BY CONVENTION, and files outside the convention are ignored.

The kinds are **agents, skills, hooks, tools, files**, plus two mechanisms that are
not artifact kinds — `templates/` (applied into a file the consumer owns) and
`migrations/` (executed, not placed).

`files/` places its contents at their path relative to `files/`; no transformation,
no substitution. `tools/` stays separate from `files/` deliberately: a tool
declaration transpiles per runtime and permits specialisations a verbatim file
cannot express. Helper scripts invoked by path are files, not tools.

Full specification: `docs/package-format.md`.

## [2026-08-10 11:17 CEST] Decision-016: Everything is a link; conflicts report and skip
#delivery #links #conflicts #ai-toml #kauk-sync

Operator ruling. Everything kauk lays is a **link**. Always was, stays. Editing a
laid file is editing the source — that is the point.

The `.ai.toml` per-skill delivery layer (`exclude | copy | link | local`) was not
designed by the operator and is not a feature; `local` in particular is nonsense. It
is removed, along with `resolve_mode()` and the `copy` / `template` / `prefix`
placement paths in `bin/kauk`.

A destination that already holds a real file, or that two packages both claim, is
**reported and skipped**. Nothing is overwritten and nothing is resolved on the
user's behalf, because the user has made no selection.

Each file inside a skill is linked individually, never as a whole-directory symlink.

## [2026-08-10 11:17 CEST] Decision-017: An agent is a prompt; ownership decides where scripts live
#agents #skills #tools #ownership #payload

Operator ruling. An agent is a **glorified prompt** — a flat file, not a skill
definition and not a container. It carries no payload of its own. Agents CALL tools
or skills.

A script used by a skill lives in that skill's own folder and travels with it. Any
script an agent needs belongs to the tool or the skill that owns it. This matches
every runtime surveyed (2026-08-10): agent = one file, skill = a folder carrying its
own scripts, package = the bundling unit above both.

## [2026-08-10 11:17 CEST] Decision-018: Runtime detection yields a set, not a winner
#runtime-targets #detection #claude-code #placement #install

Operator ruling, refining Decision-013. A repository containing `.claude/` or
`CLAUDE.md` is a Claude repository and artifacts are laid where Claude expects them.

Detection yields a **SET, not a winner**: three or four tools may be in use and all
of them are served. Placement is not a competition and there is no first-match-wins.
Claude is one destination, never *the* destination.

Where nothing is detected, the user is ASKED at initialisation which agent they will
use, rather than the original tool's "you don't currently use an agent, come back
when you do".

Parked: that kauk itself creates `.claude/`, so `.claude/` as a marker can never turn
off. The operator does not consider "uninstalling Claude" a practical scenario.

## [2026-08-10 11:17 CEST] Decision-019: Hooks are declarative artifacts; the transpiler owns the mapping
#hooks #declarative #transpile #settings-json #adaptation-layer #runtime-targets

Operator ruling, implementing Decision-012/013. A hook is `hooks/<event>/index.toml`,
where the directory name IS a runtime-neutral event.

- **`settings.json` is never shipped.** It is one target's rendered output and it
  belongs to the consumer.
- **Matchers are not part of the package vocabulary.** A concept expressed as a
  filter on one runtime gets its own event name (`tool.shell.before`); the transpiler
  renders it as a first-class event or as event-plus-matcher per target.
- **The transpiler owns the mapping**, including fallbacks where a target has no
  native event. Package authors declare the neutral event and never learn any
  runtime.

Basis: a five-runtime survey (Claude Code, opencode, Cursor, Gemini CLI, Codex CLI)
verified against current documentation on 2026-08-10, mapping 44 lifecycle concepts.
Only a handful are single-runtime features nobody else can approximate. orchids
itself wires just five events, so the first adaptation layer is small.

## [2026-08-10 11:17 CEST] Decision-020: Action keys are a closed set; compatibility is one flat list
#hooks #actions #compatibility #toml #vocabulary

Operator ruling.

**Actions** — one action KEY per `[[actions]]` entry, its value carrying the
parameters. The key IS the action name; there is no `action = "<name>"`
discriminator, because the set is CLOSED: every action needs implementation and
documentation in kauk, so an unrecognised key is an error, not an extension point.
New keys are added as they standardise. Whether an action may veto is a documented
property of that action, not a declared flag.

**Compatibility** — the same key and semantics on actions and on skills: ONE FLAT
LIST over one namespace covering hosts and models together (an agent being named
after a model is unlikely enough to ignore). Entries are OR; a dot narrows within one
entry. `["claude.opus-5", "codex.opus-5", "opus-5", "codex"]` means that pairing, or
that pairing, or any host on opus-5, or codex on any model. Omitted = all.

Per-runtime sub-tables (`[actions.<runtime>]`) are NOT used: two renderings are
simply two actions with different `compatibility`.

## [2026-08-10 11:17 CEST] Decision-021: Templates are text with three application types
#templates #injection #markers #provenance #kauk-magic

Operator ruling. A template is text with YAML frontmatter: `name`, `description`,
`type`, `tracked` (default true), and `match` for one type.

`type` is `beginning` | `end` | `inline`. Beginning and end are positional; inline
locates by `match` and replaces the first group.

A tracked application carries ONE marker line, written as a comment in the
destination's own syntax, stating it is load-bearing and not to be changed, plus its
origin (`:kauk:` … `<owner>/<repo> <sha>`). There is no closing marker: if someone
writes past a line that says do not touch, that is their loss — kauk is not a
caretaker. `inline` needs no end marker because `match` relocates the block each
time.

A `match` that finds nothing is reported and skipped. The comment-syntax-per-filetype
map is an implementation detail, not a spec question. A variable-interpolation syntax
is RESERVED — documented and linted, not implemented.

## [2026-08-10 11:17 CEST] Decision-022: Migrations run at sync, in a fixed order, with a per-repository watermark
#migrations #sync #ordering #watermark #rebase

Operator ruling, answering the who and the when that `AGENTS.files.md` §Migrations
never specified.

- **Migrations run at SYNC TIME**, executed by the tool — not by an agent at an
  arbitrary prompt.
- Content stays NATURAL LANGUAGE, wrapped in a structured format. Existing migrations
  are NOT rewritten. Codified step types (`reload`, `restart`, `rename`, `apply
  skill`) follow the same closed-set pattern as hook actions; host-specific steps are
  transpiler territory.
- Codified steps execute inside kauk deterministically; only the prose residue is
  handed to an agent. That is what makes execution independent of agent behaviour,
  and what makes most of a migration testable.
- **Order: pull → apply migrations → rebase your changes → write your migration.**
  Upstream commits ALREADY contain the migrations their author applied; the consumer
  applies the same ones so both trees are in the same reality before rebasing.
  Rebasing first to obtain easier conflicts invents a tree that does not exist and is
  not permitted.
- **The watermark is PER REPOSITORY.** It always was intended to be; the single
  global scalar in `.git/the-works/migrated` is a defect.

## [2026-08-10 11:17 CEST] Decision-023: Three consumer artifacts — config, lock, and a rebuildable index
#ai-toml #lockfile #index #provenance #kauk-magic #uninstall

Operator ruling.

1. **`.ai.toml`** — USER-OWNED. What was asked for: sources and selection. Its
   "managed by kauk … do not edit by hand" header is removed; so are the comment
   lines documenting the delivery layer retired by Decision-016.
2. **Lock file** — machine-written and COMMITTED. What was got: each repository and
   its resolved head at commit time. The only genuinely non-derivable artifact, since
   `.ai/repositories/` is gitignored and a source that placed no files leaves no
   trace. The only committed file kauk writes, so it carries the do-not-edit header
   `.ai.toml` loses.
3. **Placement index** — uncommitted, rebuildable, FOR SPEED NOT ACCURACY. Never the
   source of truth.

Every write outside the clone carries a self-identifying nugget: the magic token
`:kauk:` plus origin and sha. Links self-identify via `readlink`, templates via their
marker, transpiled output via the same origin and sha carried as data where comments
are impossible. Binaries — which cannot carry an inline nugget — get a COMMITTED
per-file sidecar (`<file>.kauk`); per-file rather than per-directory or root, because
a directory or root sidecar is an index again and indexes drift.

Conflicts are explicitly not the problem this solves.

## [2026-08-10 11:17 CEST] Decision-024: `roles:` becomes `categories:`; `roles` is reserved for agents
#categories #roles #taxonomy #frontmatter #rename #context-economy

Operator ruling. The frontmatter key `roles:` is renamed `categories:`. The node list
and the DAG are unchanged — they are operator-authored (orchids Decision-003) and
stand.

Rationale: orchids Decision-002 already defines the vocabulary as activity nouns
chosen explicitly NOT to be job titles, which is the definition of a category. The
word "role" was inherited from `dev|infra|org|all`, which orchids Decision-003 itself
records as never having been a decision — just an artifact of kauk stamping every
adopted skill `dev`. Calling `coding-dotnet` a role implies someone wears it; calling
it a category says where it files.

`roles:` is FREED and reserved for AGENTS only, in the persona sense, should such a
feature ever be implemented. A skill is a tool expressed in YAML and bears no role.

Agents gain `categories:`, which they do not have today: all 19 orchids skills
declare a placement and none of the 10 agent files do.

## [2026-08-10 11:17 CEST] Decision-025: Categories are browsable; dependencies are a plain graph
#categories #dependencies #install #selection #context-economy

Operator ruling. Importing a repository can bring thirty or forty skills, and that
payload is expensive. Categories group skills and agents into a browsable tree: on
add, the consumer picks individual artifacts, or a whole category and everything
inside it.

Dependencies are a plain graph, and deliberately no more than this:

- an agent may depend on agents or skills
- a skill may depend on skills
- agents and skills may depend on tools

No other scenario is needed. References carry a one-letter kind prefix (`a/<name>`,
`s/<name>`, `t/<name>`) since names are unique within a kind. Selection is a request;
the installed set is its dependency closure.

## [2026-08-10 11:17 CEST] Decision-026: The command is `kai`; the binary is `kaukea`; the org is kaukea
#naming #cli #kai #kaukea #github #rename #migration

Operator ruling, superseding the gh-org half of `docs/naming.md`.

- **The GitHub organisation is `kaukea`** — https://github.com/kaukea/ exists.
  GitHub refused `kauk`, so the `kaukai` org and the dormant-user release ticket
  recorded in `docs/naming.md` are dead. The platform name, `kauk.ai`, and the
  registry reservations are unaffected.
- **The command is `kai`.** Rationale: memorability — the operator cannot recall
  `kauk` most of the time, so nobody else will, and speech-to-text transcribes `kai`
  correctly first time. Collisions with other tools named `kai` are ACCEPTED;
  developers can alias.
- **The executable ships as `kaukea`, with `kai` as a symlink to it**, created at
  install and reported-and-skipped if `kai` already exists on PATH. This makes a
  collision the user's to resolve while the tool stays reachable.
- The distribution name and the command name are independent: PyPI keeps the `kauk`
  distribution and npm keeps `@kauk.ai/kauk`, both declaring the `kaukea` entry
  point. `kai` is taken on both registries (checked 2026-08-10) and nothing needs to
  be registered.
- `kauk` is kept as an alias for compatibility; the rename ships as a migration.

## [2026-08-10 11:52 CEST] Decision-027: The Claude target is a plugin, not files plus settings.json
#claude-code #plugin #transpile #runtime-targets #settings-json #hooks #mcp

Operator ruling, superseding the placement half of Decision-018/019: `settings.json`
does not merely stop being *shipped* — it stops being *written*. On the Claude target
a package renders as a **Claude Code plugin**, which owns its own hook wiring, so kauk
never edits a file the user owns.

The rendering is a **skills-directory plugin**: a folder under a skills directory
containing `.claude-plugin/plugin.json` loads as `<name>@skills-dir` on the next
session — discovered in place, no marketplace, no install step, and no uninstall step
(removing the folder removes the package).

The plugin layout maps onto the kinds almost one-to-one (verified against Claude Code
plugin documentation, 2026-08-10):

    <repo>/.claude/skills/<package>/
      .claude-plugin/plugin.json    generated
      skills/<name>/SKILL.md        <- skills/  (carrying their own scripts/)
      agents/<name>.md              <- agents/
      hooks/hooks.json              <- hooks/   (transpiled)
      .mcp.json                     <- tools/   (transpiled)
      scripts/                      referenced via ${CLAUDE_PLUGIN_ROOT}

`files/` is NOT part of the plugin: its contents go into the repository at their own
paths, which is the point of that kind.

Constraints this puts on the transpiler:

- Hook commands reference scripts through `${CLAUDE_PLUGIN_ROOT}` — no absolute paths
  anywhere in a plugin.
- Project-scope `@skills-dir` plugins load only from the `.claude/skills/` of the
  directory Claude started in; they do NOT walk up to the repository root.
- `SKILL.md` edits are live; `hooks/`, `.mcp.json` and `agents/` changes need
  `/reload-plugins` or a restart — which is what a migration's `reload` step is for.
- At project scope the plugin sits behind the workspace trust gate, bundled MCP servers
  take per-server approval, and background monitors do not load.

The plugin is Claude's encoding, never the model. Other runtimes get their own
rendering.

## [2026-08-10 11:52 CEST] Decision-028: A skill-exclusive script lives in the skill; shared scripts are files
#skills #scripts #ownership #files #tools

Operator ruling, refining Decision-017. A script used SOLELY by one skill lives in that
skill's folder and travels with it — which is also exactly how a Claude plugin packages
a skill (`skills/<name>/scripts/`). A script shared across artifacts, or invoked by
something other than a skill, is a FILE. Nothing script-shaped belongs in `tools/`,
which carries tool declarations only.

## [2026-08-10 12:20 CEST] Decision-029: No ownership between artifacts — only declared dependencies
#dependencies #metadata #frontmatter #skills #agents #tools

Operator ruling, superseding the "ownership decides location" framing in Decision-017
and Decision-028. There is NO ownership relation between artifacts. What one artifact
needs from another is declared in its own metadata:

    dependencies:
      skills: []
      agents: []
      tools: []

An agent may depend on agents, skills or tools; a skill may depend on skills or tools.
A script used solely by one skill still lives in that skill's directory and travels
with it — that is packaging, not ownership.

## [2026-08-10 12:20 CEST] Decision-030: An agent's declared dependencies are its capability boundary
#agents #dependencies #restriction #capability #frontmatter #security

Operator ruling. An agent's `dependencies:` are not a hint — they are the set of skills
and agents that agent is PERMITTED to call. An agent cannot reach a skill or an agent it
did not declare. The restriction is derived from the frontmatter, so the declaration and
the boundary can never drift apart.

## [2026-08-10 12:20 CEST] Decision-031: Subagents carry a type — root, child, sibling, background
#agents #subagents #type #tmux #windowing #frontmatter

Operator ruling. An agent declares `type: root | child | sibling | background`,
classifying its relationship to whatever launched it. This is what a windowing
integration keys off (tmux today):

- `root` — a top-level session, launched by the operator
- `child` — spawned by, and subordinate to, its launcher
- `sibling` — spawned alongside its launcher, not under it
- `background` — detached, with no pane of its own

## [2026-08-10 12:20 CEST] Decision-032: Tools carry frontmatter and may be a script or an MCP definition
#tools #mcp #frontmatter #categories #transpile

Operator ruling. A tool is a DECLARATION with frontmatter — `name`, `description`,
`categories`, `compatibility`, `visibility` — and it transpiles per runtime. Its backing
may be either a SCRIPT or an MCP server definition; both are tools, and which one the
target receives is the transpiler's business.

A helper script invoked by path, carrying no declaration, is not a tool. It is a file.

## [2026-08-10 12:20 CEST] Decision-033: Visibility is declared per artifact
#visibility #user-invocable #slash-list #context-economy #frontmatter

Operator ruling. Every artifact may declare who may invoke it:

    visibility:
      user-invocable: true      # appears in the user's slash list
      model-invocable: true     # the model may auto-invoke it

Both default to true. Process machinery is typically `user-invocable: false`, so a
consuming repo's slash list shows only operator-facing entries while the model still
triggers the rest from their descriptions. The transpiler renders this into the target's
own vocabulary; on Claude that is `user-invocable` / `disable-model-invocation`.

Supersedes the orchids board item `skill-slash-visibility` (gh#9) as the general rule —
that task becomes the per-skill judgement pass against this key.

## [2026-08-10 12:20 CEST] Decision-034: Agents are launched by skills, never by autostart hooks
#agents #hooks #launch #workflow #garden #user-choice

Operator ruling. A hook that autostarts an agent forecloses the user's choice of
workflow. An agent is launched by a SKILL instead — `/garden` launching the gardener,
for example — so the user picks which workflow runs. Packages do not ship autostart
hooks for agents.

## [2026-08-10 12:20 CEST] Decision-035: The repository name stays `kauk`; only the organisation moves
#naming #github #kaukea #repo #migration

Clarifying Decision-026: the repository is and remains `kauk`. Only its GitHub
organisation changes, `serialseb` -> `kaukea`, and its path on disk follows
(`~/src/kaukea/kauk`). Nothing renames the repository itself.

## [2026-08-10 12:45 CEST] Decision-036: `package.toml` declares a package; `.ai.toml` stays local
#package-toml #ai-toml #packages #identity #publishing

Operator ruling. A repository becomes a package by carrying `package.toml` at its root,
holding the package's identity — name, friendly title, description, type.

This is deliberately a separate file from `.ai.toml`, and not merely for explicitness:
the two have different audiences. `package.toml` is PUBLISHED — it travels with the
repository and every consumer reads it. `.ai.toml` is LOCAL — what this checkout
consumes, and nobody else's business. Merging them would ship a consumer's private
selections inside a published artifact.

Any repository may declare itself a package, including one that also consumes packages.

## [2026-08-10 12:45 CEST] Decision-037: A package publishes into its own repository by copy, never by vendoring itself
#self-source #vendoring #publishing #copy #orchids #decision-122

Operator ruling. A repository that is itself a package is NOT vendored: there is no
clone of its own HEAD under `.ai/repositories/`. Vendoring your own HEAD is what forces
a push in order to see your own edits, because you are editing the source and the
vendored copy at the same time.

Instead the SOURCE IS THE WORKING TREE, read in place; the artifacts are published by
exactly the same transformation as any other package; and the publication type changes
from link to COPY — the rendered files are copied back into the repository and
committed, after which the normal flow works.

Nothing else differs. A self-published package is a package.

Context: orchids already does this by hand (`ceca7ae`, "Remove vendoring entirely: this
repository runs its own files") and orchids Decision-122 forbids kauk in orchids until
this exists.

## [2026-08-10 12:45 CEST] Decision-038: Packages depending on packages — deferred, and it is what enables cross-package artifact dependencies
#packages #dependencies #cross-package #future #index

Operator ruling: a FUTURE feature, recorded so it is designed for and not built now.

Package-level dependencies are the layer above artifact dependencies: a package
dependency says "you also need this source", an artifact dependency says "this skill
needs that skill". The package graph resolves first — which sources to fetch — and the
artifact graph then resolves across their union. This is what makes cross-package
dependencies possible, an agent in one package depending on a skill in another.

Undecided and waiting on the native index: whether a package dependency names a PACKAGE
or a LOCATION. A name needs an index to resolve it; a location resolves itself but
hardcodes where a thing lives today.

Context for why it is wanted: cross-package needs already exist undeclared — orchids'
skills reference the `kauk` skill, and `serialseb.voice`'s `voice-setup` was written
against orchids' grammar.

## [2026-08-10 13:05 CEST] Decision-039: The plugin exists for two reasons — native acquisition, and regenerable wiring
#claude-code #plugin #hooks #install #natural-language #marketplace #cli

Operator ruling, extending Decision-027. The plugin is not a packaging convenience; it
earns its place twice:

1. **Native acquisition.** Installing a plugin — or adding a marketplace and installing
   from it — is something a user asks for in PLAIN LANGUAGE and an agent carries out end
   to end. Nobody learns kauk's own syntax. The `kai` CLI becomes the floor for other
   runtimes and for CI, not the front door. kauk itself bootstraps this way, which
   resolves the chicken-and-egg of needing the kauk skill in order to ask for packages
   conversationally. At least on Claude; other runtimes have no equivalent yet.
2. **Regenerable wiring.** Because the whole plugin is GENERATED on the filesystem,
   adding or removing a hook is a re-render of the plugin, not a surgical edit to a
   shared `settings.json` whose other tenants must be reconciled around it. The set of
   hooks can change freely and the wiring simply follows.

Reading recorded pending correction: kauk GENERATES the plugin into the repository, so
it is project-scoped and travels with a clone; a marketplace is how kauk itself is
acquired, not how each package lands.

## [2026-08-10 13:25 CEST] Decision-040: Claude delivery is a kauk-maintained LOCAL MARKETPLACE, and nothing is linked
#claude-code #plugin #marketplace #delivery #links #transpile #install

Operator ruling, superseding the skills-directory-plugin rendering recorded in
Decision-027.

The flow is: PULL the source in the generic format -> TRANSFORM it to the Claude plugin
format -> PUBLISH it into a LOCAL MARKETPLACE that kauk maintains on the filesystem and
the user added once -> Claude installs from it. The marketplace is regenerated as
repositories are added or updated, so every added source stays current automatically.

**Because everything the package provides is embedded in the plugin, NOTHING IS
LINKED** on the Claude path.

Mechanics verified against current documentation (2026-08-10): a local directory is a
valid marketplace source (`/plugin marketplace add <path>`); `.claude-plugin/marketplace.json`
at the marketplace root lists plugins whose `source` may be a path relative to that root;
users refresh with `/plugin marketplace update`; the per-entry `version` field gates when
an update is taken, so kauk manages it.

`files/` is NOT part of the plugin — a plugin cannot place a file at an arbitrary
repository path — so `files/` is still delivered directly into the repository. That is
the only place the link-or-copy question survives on the Claude path.

**The link system does not go away.** Other runtimes have no plugin mechanism and may
never have one; link-based delivery remains for them. The plugin is the clean path
WHERE SUPPORTED, not a replacement for the model.
