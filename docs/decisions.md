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

## [2026-08-10 14:30 CEST] Decision-041: kauk never decides a conflict; the user is offered an assisted merge
#conflicts #merge #user-control #resolve #agents #report-and-skip

Operator ruling. The user is in control and makes the decisions.

kauk cannot tell the difference between a change the user intended and a change
somebody else made, and an agent has no more background to judge it than kauk does.
A destination that already holds a file kauk did not place is therefore a MANUAL
RESOLUTION POINT: nothing is deleted, nothing is merged, nothing is dispatched.

At that point the user is OFFERED, never given, an assisted path:

- `kauk resolve` lists each conflict with the user's file and the package's version
  side by side, and changes nothing.
- `kauk resolve --assist` asks Claude to attempt the merge, under the normal gates —
  it proposes, the user approves, nothing is written or committed. If no simple,
  unambiguous merge exists that loses nothing the user wrote, it says so and stops.
- Resolving it by hand is always the fallback, and is never worse than the offer.

Context: the previous behaviour DELETED the user's divergent file and then dispatched
a headless `claude -p` session automatically, as a side effect of `kauk install`. It
also adopted a consumer's local skill upstream into the package. Both are removed.

NOT affected, and deliberate (operator, same session): the `sync` pull-rebase-push
cycle. Write access to a repository means you are allowed to push to it, so committing
a consumer's edits to a linked file back to its source is on purpose, not a defect.

## [2026-08-10 14:55 CEST] Decision-042: Name collisions are NAMESPACED, not merged
#conflicts #namespaces #collision #skills #agents #tools #user-control

Operator ruling, superseding the merge half of Decision-041.

Two problems make merging the wrong answer. kauk does not know whether the user has
the right to push anywhere, and — more fundamentally — if a package ships a skill and
the consumer already has one of the same name, the odds that they are even about the
same thing are low. Merging assumes an equivalence that is usually false.

So a name collision is resolved by NAMESPACE, not by merge. Both artifacts are kept:

- the user's becomes `local<sep><name>`
- the package's becomes `<package><sep><name>`

If the user dislikes the result they merge them or rename one. kauk decides nothing
and destroys nothing.

**The separator is per runtime.** kauk adopts whatever syntax each agent already uses
for namespacing rather than imposing one; Claude Code writes `plugin:command`, so the
Claude renderer uses `:`.

Namespacing applies to the NAMED kinds — skills, agents, tools — where the name is an
identifier. It cannot apply to `files/`, where the path IS the contract and there is
no alternative name; that kind keeps report-and-skip and `kauk resolve` (Decision-041).

It also does not apply in copy mode: a self-published package's destination is a real
file because kauk put it there, and must never be mistaken for the user's own.

## [2026-08-12 14:42 CEST] Decision-043: Upgrade is the operator's act — a committed pin, moved on explicit update
#sync #update #upgrade #lockfile #pin #mid-session #rename #plugin #notify

Operator ruling, closing the continuous-sync-vs-notify question left open in the
2026-08-10 spec walk. Responsibility for taking an upgrade moves from the project to
the operator — matching what the runtimes themselves do (a Claude plugin pins a
version and refreshes only on an explicit update).

- **Fetch is free, silent, rate-limited, and never applies anything.** `pull` never
  happens implicitly. Offline is silent.
- **The lock (Decision-023) is the pin.** Symlinks resolve through a checkout pinned
  to the locked head. `sync` CONVERGES to the lock — safe at any moment, changes no
  content unrequested. `update` MOVES the lock — the single operator-owned moment at
  which content changes, and the moment pending migrations (Decision-022) run.
- **Mid-session update is allowed.** The operator chooses the moment; the tool does
  not refuse. Measured runtime behaviour (Claude docs, checked 2026-08-12): skills,
  agents, and hooks are file-watched and change live; rule files and plugins are
  session-start-loaded. The sharp edge is a RENAME: dispatch to the old agent name
  fails while the session's in-context roster still carries it.
- **At update time the tool warns, it does not repair**: when the delta renames or
  removes agents/skills and sessions are running, it says so and names them —
  restarting a session is the operator's call.

Context, not ruling: whether a migration can meaningfully mend a RUNNING session's
already-loaded state is doubted by the operator and left to be observed in practice.

## [2026-08-13 20:19 CEST] Decision-044: The version upgrades at push time, not when an agent authors it
#migrations #version #date #push #ordering #watermark #plugin #marketplace

Operator ruling. A package's version derives from its highest migration filename
(`docs/package-format.md` §migrations/), and the marketplace plugin `version`
field kauk manages gates when consumers take an update. Until now the date on a
migration file — and therefore the moment the version moved — was whichever day
the authoring agent happened to write it, mid-branch.

- **The upgrade moment is PUSH time.** A migration's `<YYYY-MM-DD>` is stamped
  when the change is published — the close's push — not when it was authored.
  The in-branch file carries a provisional date until then; the publish step
  finalises it.
- Ordering follows publication: a migration can never enter the stream dated
  behind a consumer's already-applied watermark because it was authored early
  and merged late.
- The plugin `version` kauk manages moves at the same moment, so every derived
  version tells the same story: nothing upgrades because an agent wrote a file;
  things upgrade because the operator's push published it.

Authoring is unchanged (same branch as the structural change, Decision-022's
order still holds); only the date-stamping moment moves.

## [2026-08-13 22:12 CEST] Decision-045: Links remain the path until the hooks+templates transpiler exists; tree and dependencies are the work
#delivery #links #plugin #marketplace #transpiler #hooks #templates #categories #dependencies #cross-package #sequencing

Operator ruling. The switch to the Claude plugin / local-marketplace rendering
(Decision-040) is DEFERRED until the transpiler for hooks and templates is
complete — no partial plugin cut before it. Until then kauk stays on the
link-based delivery path.

The work that starts now, on this path, named by the operator as the massive
part worth starting first: the category tree, the dependencies between agents
and skills, and dependencies across repositories.

## [2026-08-15 10:05 CEST] Decision-046: No enumeration file, ever — artifacts self-declare; links follow selection
#manifest #enumeration #dependencies #frontmatter #globs #selection #links #package-toml

Operator ruling. A file listing the repository's files, skills, or agents is
not supposed to exist and will not be validated — reaffirming Decisions
011/014/015 against the freshly observed resurrection (orchids
f/delivery-restoring carries a regenerated manifest.conf and a
tools/manifest_gen.py; that half of the branch is dead on arrival).

- Skills, agents, and the other artifact kinds DECLARE THEIR OWN dependencies
  in their frontmatter, and their own file lists as GLOBS — enumeration lives
  with the artifact, never centrally, keeping the repository's TOML tidy.
- Links into the runtime (.claude/…) are laid only AFTER selection: the
  operator's per-repo pick plus its dependency closure decides what links,
  which is what ends the everything-installs-everywhere problem.
- Populating the declarations is real work: each agent is investigated for
  the skills it actually requires before its dependencies: block is written.

Context, not ruling: whether the glob file-list lives in each artifact's own
frontmatter or as a tidy globs section of package.toml awaits the operator's
word (asked 2026-08-15).

## [2026-08-15 11:35 CEST] Decision-047: The tree is rooted at general; .ai.toml is defaults-only; the add flow is conversational
> Amended by Decision-048: the general-as-root clause is superseded (general is the catch-all category, the tree is a flat forest). Every other ruling here stands.
#categories #tree #general #root #ai-toml #origin #select #paths #cross-package #add-flow #frontmatter #parsing

Operator rulings, one design round (2026-08-15):

- **`general` is the ROOT of the category tree** — process, development,
  infrastructure, security are its children; otherwise it is not a tree. The
  general artifacts are the root's own. Consequence, via the standing
  ancestors-own-artifacts rule: ANY selection brings the root's artifacts
  along; selecting general itself means importing everything.
- **`.ai.toml` is defaults-only.** A source is `owner/repo` — resolving to
  github.com/owner/repo, an `origin =` key on such a source is WRONG — or a
  full local path. Each source table carries only `select = [...]`,
  package-relative paths ("process/orchids", "development"): a node takes its
  subtree plus closure, a leaf takes the artifact plus closure.
- **Name-rooted paths** (`<package>/<category>/…/<artifact>`) are the
  cross-package reference grammar, used in artifact frontmatter dependencies —
  what lets the message bus live in its own repository and be depended on.
- **Frontmatter stays parser-trivial** for the thin no-class-library .NET CLI:
  flat inline lists, at most one nesting level; `files:` globs live in the
  artifact's own frontmatter (package.toml stays identity-only,
  Decision-036); the tools dependency section exists but is expected mostly
  empty for agents.
- **The add flow is conversational, no built UX**: at install the in-session
  agent, knowing the repository and the work in play, PROPOSES agents and
  skills; the operator picks; the laying is automatic — the agent driving the
  CLI today, the plugin machinery on the Claude path once Decision-040's
  marketplace exists.
- The tree stays DERIVED — aggregated from artifact declarations under the
  package's name; no stored central enumeration (Decision-046).

Context, not ruling: renaming the node `process/workflow` to `process/orchids`
was voiced as "probably" — an orchids-side vocabulary amendment with its own
migration, held until the operator firms it up.

## [2026-08-15 12:20 CEST] Decision-048: general is the catch-all; five skills re-file; names are two-part; size is a measured ceiling
#categories #general #tree #naming #renames #skills #size #variants #writing #authoring

Operator rulings closing the 2026-08-15 design round; amends Decision-047's
first clause (general is NOT the root — the tree is a flat forest of
categories, and `general` is the catch-all for artifacts that fit nowhere:
a coding-time counter, a token counter).

- **Re-filings and renames** (orchids-side, each rename rides a migration):
  `git` files under the coding bucket (`development` as the tree stands —
  whether that node takes the word "coding" is unasked-for detail left
  as-is); `authoring-skills` files under a NEW `writing` category;
  `read-agents` renames to `enforcing-rules`; `writing` renames to
  `writing-prose`. Open, non-blocking: the `agent-behaviour` rename (must
  carry "agent" in the name; candidates agent-conduct / agent-discipline)
  and writing-prose's category (writing vs general).
- **Two-part names are the rule**: every skill name is two parts — what it
  does to what (board-walking, bloom-tasks, coding-dotnet). A one-word name
  is a lint error. Folds into the authoring-skills contract.
- **Skill size is a real failure mode** (operator observation, recorded as a
  dragon): the bigger the skill, the less likely an agent reads it — it
  summarises via a subagent or ignores it and imitates seen code. A per-model
  size ceiling belongs in the authoring contract, but the number is NOT
  invented (Decision-139): measure which skills get read versus ignored
  across models first, then set ceilings from data.
- **FUTURE, designed-for and not built this iteration**: per-target skill
  variants — `SKILL.md` plus `SKILL.<compatibility>.md` in the same skill
  directory sharing its scripts, suffix drawn from Decision-020's flat
  host/model namespace, most-specific match laid per runtime, override never
  merge. This is also the release valve for the size ceiling (a compact
  variant for a small model) — recorded so nothing precludes it.

## [2026-08-15, addendum to Decision-048] Variant shape blessed; the model axis never resolves at lay time
#variants #skills #model #runtime #links #compatibility

Operator, same day: the in-directory shape is the one — `SKILL.md` beside
`SKILL.claude.md` in the skill's own directory, cleanest in a text editor,
scripts shared. And a constraint on the still-FUTURE mechanism: variants are
laid on the HOST axis only. Models are mutable mid-session (a Fable safety
disengage hands the seat to another model under the same laid link), so a
model-suffixed variant can never be resolved by a symlink at lay time — if
model variants ever exist, the runtime resolves them at load. Still out of
scope this iteration.

## [2026-08-15, second addendum to Decision-048] The node is process/orchard — firm, spelled out
#categories #naming #orchard #process #rename

Operator, same day, spelled letter by letter against the transcription:
`process/workflow` renames to `process/orchard` — o-r-c-h-a-r-d, the fleet
workbench's name, not "orchids". The "probably" from Decision-047's context
note is now firm. Orchids-side vocabulary amendment; the rename rides the
frontmatter pass with its migration.

## [2026-08-15, third addendum to Decision-048] The category is authoring; agent-behaviour keeps its name
#categories #naming #authoring #writing #agent-behaviour

Operator, same day, closing the round's last opens: the writing category is
named **authoring** — what authors do — holding `authoring-skills` and
`writing-prose`. Rejected: copywriting (too specialised), composing (sounds
musical), redacting (carries correcting/censoring). And `agent-behaviour`
KEEPS its name — it already satisfies both the agent-in-the-name and
two-part rules; the rename question dissolves.

## [2026-08-15 13:05 CEST] Decision-049: Writes to sources ride an explicit push verb; the two rounds are set
#push #sync #sources #cli #kai #rounds #sequencing #deployment

Operator rulings:

- **Reversal on write-back**: sync no longer pushes edited linked files back
  to their sources — ever. Publishing local edits to a source becomes an
  EXPLICIT `push` command, symmetric with update: fetch informs, update takes,
  push gives, sync only converges. Amends the deliberate-push-back clause
  recorded in Decision-041 and the sync-time write-back of the stopgap.
- **Round one is kauk's code**: the reader for the new design (defaulted
  sources, per-source select, closure, lay-after-selection), the pin
  (lock/update), the push verb, the deployment across the estate, the CLI
  rename (`kai` command, `kaukea` executable, Decision-026), and the tool's
  own skill updated to match.
- **Round two is the content and the move**: the tour of every orchard skill
  to clean them up (frontmatter pass, renames, sizes), and migrating kauk and
  orchids to the kaukea organisation — the root repo GitHub allows, since
  `kauk` itself was refused.

## [2026-08-16 16:40 CEST] Decision-050: sync is manual and notifies; --pull takes, --push gives, rebase is the default
#sync #pull #push #pin #lock #rebase #cli #notify

Operator ruling, reshaping the verb surface (the semantics of Decision-043
and 049 stand; the shape changes):

- `kai sync` is MANUAL. Bare sync converges to the pin, lays, and NOTIFIES —
  "N incoming on <source>" when the followed branch moved, "local edits" when
  the clone has them. It applies nothing and publishes nothing.
- `--pull` takes the updates: fetch, REBASE local work onto the followed
  branch (the default strategy), move the pin, run pending migrations, warn
  on removals and renames.
- `--push` gives: rebase onto the followed branch first, then publish the
  clone's local edits to the source and move the pin.
- One command, two flags — no separate update or push verbs. Any merge
  storyline beyond the rebase default is explicitly LATER; a rebase that
  conflicts stops and reports, nothing degrades.

## [2026-08-16 18:20 CEST] Decision-051: Head-tracking only; versions, tags and pins are one deferred piece of work
#versioning #head #tags #pin #lock #sync #deferred

Operator ruling, from the top. Two models exist: tracking HEAD (no version
numbers, and publishing local changes needs an explicit publish act), or
tracking TAGS with version numbers (where pushing changes "on top of a
version number" is the unsolved weirdness). Choosing between them — and
everything that follows, locks and pins included — is a whole piece of work,
and it is DEFERRED in one piece.

Until that work: kauk tracks head, plainly. `kai sync` is what sync always
was — the manual command that pulls with rebase and lays. `--pull` and
`--push` narrow it to one direction (push stays explicit, Decision-049). If a
source references a version, a tag, or a specific commit, kauk does NOT touch
that clone — it lays what is there and leaves it alone until the versioning
work exists. The "updates available" notice is a background check displayed
from time to time, not part of the sync command — boarded as its own task.

No `.ai.lock` exists. Decision-023's lock clause and Decision-043's pin
mechanics are DEFERRED with the versioning work, not implemented; Decision-050
is reshaped by this entry (its flag surface stands, its pin does not).

## [2026-08-18 17:10 CEST] Decision-052: The move takes both repositories, and orchids becomes orchard
#naming #kaukea #org-move #orchard #rename #migration

Operator ruling. The kaukea move covers BOTH repositories in one campaign:
serialseb/kauk → kaukea/kauk (name unchanged, Decision-035), and
serialseb/orchids → kaukea/orchard — the repository takes the workbench's
name, matching the process node and the fleet vocabulary. Disk follows
(~/src/kaukea/), every estate .ai.toml source repoints, and the whole thing
ships as the org-move task's fleet-wide migration. The GitHub transfers and
the rename are the operator's own acts; everything after them is the tool's.

## [2026-08-18 18:05 CEST] Decision-053: The stopgap and its migrations stay macOS-portable
#portability #macos #awk #sed #bash #migrations

Operator ruling: be careful with awk — and by extension the whole shell
surface — for macOS compatibility. The stopgap and every shipped migration
must run under BSD awk, BSD sed, and bash 3.2, because consumers live on
Macs too. Known offenders on record at ruling time: `sed -i` without the
BSD backup argument in both shipped migrations, `realpath -m` in the
kaukea-move self-guard, `readlink -f` in init. Boarded as a portability
pass; from here on, new shell code is written to the POSIX subset and
flag use is checked against both implementations, never memory.

## [2026-08-18 17:15 CEST] Decision-054: Renames carry their links — the migration moves what it breaks
#migrations #links #laying #rename #sync #gate

Operator ruling, on the dangling rule-file links (board: stale-laid-links).
Three parts:

- Every move or rename of a laid artifact — package root ↔ `files/`, a
  repository identity change, a path change — ships IN ITS MIGRATION the
  repointing of links already laid in consumers. The kaukea-move migration
  was incomplete for omitting it; the files→root→files oscillation without
  carried migrations should never have happened.
- Sync's historic scan-and-repoint of laid links (in the stopgap until the
  convention-reader rewrite, removed there without a ruling) is restored in
  substance: an update scans links pointing into the repository store and
  repoints them.
- GATE: this is fixed before kauk is actually used by any project.

## [2026-08-18 17:55 CEST] Decision-055: kai owns migration application — scripted, ordered, agent-independent
#migrations #kai #script #watermark #urgent

Operator ruling, superseding the same-day "applying migrations is the
agent's job" reading (package-migration-reach). Migrations are technical in
nature: each ships as a script (or markdown carrying its script), and the
APPLYING is owned by a kai script — applied in order, watermark dates set by
the tool, identical behaviour whichever agent (or none) is present. Agents
hold no essential step: everything essential in the migration path (and in
the stale-links repair) is scripted. gh#35 is cancelled into gh#23
(migrations-at-sync), which becomes URGENT — this class of failure is judged
really bad and is solved before anything leans on migrations again.

Same ruling, second part: the shared fleet settings.json laid over consumers'
.claude/settings.json OVERWRITES per-project Claude settings — not acceptable.
Boarded as settings-lay-clobbers; composition design is the open question.

## [2026-08-18 17:15 CEST] Decision-056: migrations-at-sync and stale-laid-links deliver as one feature
#launch #sync #migrations #links

Migrations-at-sync and stale-laid-links ship as one feature (carrier: migrations-at-sync) 
— they interlock in `bin/kaukea`'s sync path. The clone-local-object-leak steps originally 
absorbed into this task were cancelled at the plan gate (see Decision-059 below).
(Operator, Decision-050 pre-launch round.)

## [2026-08-18 17:15 CEST] Decision-057: Migration wrapper format — applied-by marker routes execution
#migrations #format #scripting

A migration's fenced code blocks are its steps, run in order. Each fence's info string 
carries `applied-by: shell | agent`, deciding who executes it. `shell` (the default — a 
bare ```sh fence needs no tag, so existing migrations run unrewritten) has kai run the 
fence itself, inline or, when the fence body is a single `./relative/path` line, as an 
external script shipped relative to the migration file, cwd at the consumer root. `agent` 
steps are never run by kai; they are structured fenced steps, not loose prose. There is 
no closed set of step verbs — flexibility comes from `applied-by` plus relative scripts.
(Operator, plan round.)

## [2026-08-18 17:15 CEST] Decision-058: Migrations are invisible plumbing — no vocabulary, opt-in, or nag
#migrations #ux #plumbing

Migrations are invisible plumbing. No user-facing migration vocabulary, no opt-in, no nag. 
Sync applies pending migrations for every source, self-source included, silently. The 
only surfaced thing is a step the tool cannot finish itself — an `applied-by: agent` 
step or a failed `shell` step — recorded under `.git/the-works/asks/<owner>/<repo>/` and 
delivered as a concrete "do this", never as "migrations pending". (Operator, plan round.)

## [2026-08-18 17:15 CEST] Decision-059: clone-local-object-leak scope cancelled — not in scope
#scope #sync #clone #cancelled

The clone-local-object-leak scope is cancelled outright — no `--no-local`, no re-clone, 
no in-place cleanup, no leak tests. kauk is not in the business of controlling git at 
that level, and judged from an external party's gain there is none: the clones are a 
gitignored, never-shared cache; hardlinks save disk; reachable history is identical. 
Re-cloning is never done — manual deletion of clones is unsupported, and a re-clone 
would lose the clone's commits. Committed-unpushed clone edits are legitimate deliberate 
work: sync commits them to carry them through the rebase, and push stays the separate 
explicit act. Features are judged from the external party's gain, never technical purity.
(Operator, plan round, superseding the absorbed clone-leak steps recorded at launch.)

## [2026-08-19 13:05 CEST] Decision-060: We ship our settings.json so no one else does
#settings-json #hooks #ownership

Operator, verbatim, three sentences assembled from the same exchange
(2026-08-19, replacing this entry's two earlier mis-recordings by the
gardener): "We ship our settings.json so no one else does, so we call the
hooks that are defined by packages." "It has nothing to do in .claude." "We
call agents through passing our settings file for this to happen."

## [2026-08-24 21:30 CEST] Decision-061: One settings JSON, passed not laid; per-agent permissions live in YAML
#settings-json #permissions #ownership #agents

Extends Decision-060. There is exactly ONE settings JSON — `bin/kai.settings.json`,
passed via `claude --settings` at spawn. No JSON configures agents from anywhere
else, in any repository or worktree.

Per-agent permission belongs in the agent definition's YAML frontmatter
(`tools:`), not in a settings file: it travels with the agent, and the passed
settings file is shared by every agent so it cannot express per-agent rules
(a board deny there would break the gardener, whose job is the board).

Occasion: the beekeeper brief instructed writing `.claude/settings.local.json`
into each feature worktree to deny the landscaper the board. Operator: that file
should not exist. Fixes: strike the instruction from the beekeeper brief; express
the landscaper's board denial as `tools:` in `landscaper.md` (both in orchard).

## [2026-08-18 00:00 CEST] Decision-062: settings pair is sequential
#settings #launch

The settings pair is sequential — fleet-settings-wiring first, settings-lay-clobbers dispatched only after its close; the fresh-machine skill-source edge (kai vs orchard install) is an explicit voluntary deferral until a fresh machine exists. (Operator, Decision-050 pre-launch round.)

## [2026-08-19 00:00 CEST] Decision-063: is_self_source is DELETED
#migrations #packages

`is_self_source` is DELETED. A repository declares itself a package with `[general] type = "package"` in `.ai.toml`, and that declaration — not an inferred self-source entry — is what makes kai apply the repository's own migrations, use its own agents and skills, and symlink its own files. `.ai.toml` is the user's file to manage however they like; no behaviour may be inferred from whether they happened to declare their own path as a source. The old inference was also a false premise: kai installs the kai package, so there is never not a package. (Operator, 2026-08-19.)

## [2026-08-19 00:00 CEST] Decision-064: ONE global watermark
#migrations #watermark

ONE global watermark — the `<YYYY-MM-DD>-<NN>` prefix of the last applied migration, one line, committed under `.ai/`. Not per package and not per source. Every source's migrations plus the repository's own merge into a single stream ordered by that prefix; everything above the watermark applies. A same-day set written together for one version is ONE migration run, ordered within the day by `<NN>`; a hotfix after a release takes the next `<NN>` and reaches anyone still sitting at the earlier one. Per-package watermarks made packages apply migrations in strange orders relative to each other. Absent watermark = fresh install: run nothing, stamp the current datetime. (Operator, 2026-08-19.)

## [2026-08-19 00:00 CEST] Decision-065: migration file naming
#migrations #naming

Migration files are `migrations/<YYYY-MM-DD>-<NN>-<featurename>.md`, one file per feature, applied in ASCII order — the usual convention where scripts must be ordered. Supersedes the `<YYYY-MM-DD>-<slug>.md` form in `docs/package-format.md`. (Operator, 2026-08-19.)

## [2026-08-19 00:00 CEST] Decision-066: migration errors are REPORTED, not handled
#migrations #errors

Migration errors are REPORTED, not handled. No ask files, no blocking, no hand-off of a step to an agent. Kai says what failed and moves on. Self-testing migrations may be revisited one day. (Operator, 2026-08-19.)

## [2026-08-19 00:00 CEST] Decision-067: migrations do NOT ship tests
#migrations #tests

Migrations do NOT ship tests to consumers. A migration is tested in the repository that ships it. (Operator, 2026-08-19.)

## [2026-08-19 00:00 CEST] Decision-068: agent is reloaded by RELOADING ITS SESSION
#agents #reload

An agent is reloaded by RELOADING ITS SESSION, which loads the latest session file — otherwise agents lag behind definitions that have already moved. Supersedes the reload clause carried as a sub-bullet inside Decision-043, which is a ruling about upgrade being the operator's act and does not govern this. (Operator, 2026-08-19.)

## [2026-08-19 00:00 CEST] Decision-069: durable state lives in .ai/, committed
#state #durability

Durable state leaves `.git/` and lives in `.ai/`, committed. Nothing writes under `.git/` without the operator's permission. State worth keeping must survive a clone — a workstream log that vanishes when the repository is cloned is the same mistake as any other lost state, and committed agent memory is the existing precedent. The operator validates both the FORMAT and the EXISTENCE of durable files. The estate does not touch `.ai/`, so the move is not disruptive; and any move from `.git/` to `.ai/` is carried BY A MIGRATION. (Operator, 2026-08-19.)

## [2026-08-19 00:00 CEST] Decision-070: the kai package contains agent-launch skill and migrations
#packages #kai

The kai package contains the agent-launch skill and its migrations, and nothing else — everything else is in the bin, already present from the static install. Installing the kai package is how a repository subscribes to kai's migrations; that subscription is what closes the circle for a package that declares no dependencies of its own. (Operator, 2026-08-19.)

## [2026-08-19 00:00 CEST] Decision-071: close-gate proof must exercise DEPLOYED arrangement
#verification #close

A close-gate proof that exercises only the arrangement the developer happened to build in is not verification. Where two components sit at opposite ends of one path-resolution contract, the gate must exercise the DEPLOYED arrangement (a symlinked install, not a repo-local one) and must diff the two ends against each other. Live-fired: `kai.settings.json` resolved `kai-hooks.sh` with `dirname` alone while `dispatch-agent.sh` resolved `kai.settings.json` with `readlink -f`, and the suite stayed 13/13 green throughout. (Operator, 2026-08-19.)

## [2026-08-20 00:00 CEST] Decision-072: kauk ships only GENERIC agent-launch skill
#skills #launch #carriage

Kauk ships only a GENERIC agent-launch skill — no agent name baked in, takes the agent to launch as an argument. The gardener-specific launcher (a skill that launches the gardener by name, using the generic one underneath) is orchard's, not kauk's — deferred entirely to orchard's own choice and schedule, not built or carried on this branch. (Operator, 2026-08-20.)

## [2026-08-20 00:00 CEST] Decision-073: this branch's migration design wins the rebase conflict
#migrations #rebase #carriage

Main independently shipped its own migrations engine (per-source watermark files, an `applied-by: agent` ask-file escape hatch) via the separate migrations-at-sync feature, landed hours before this branch's later commit implementing the operator's own subsequent ruling recorded above (one global watermark, no ask files). Operator, verbatim, on which survives the rebase: "This branch is the correct approach for now because the ask scale and everything else around it can be designed correctly once it has been scheduled on the board correctly." This branch's design wins the conflict; main's independent, non-conflicting additions (`prune_links` rewrite, orphan-clone sweep) are kept. Consequence for whoever ingests this at close: main's Decision-057/058 (the `applied-by: agent` ask-file format) describe a mechanism this resolution retires — likely stale once this branch lands, not struck here since that call belongs to whoever reconciles decisions.md at ingest. (Operator, 2026-08-20.)
## [2026-08-27 00:00 CEST] Decision-074: the package store lives in the git folder
#store #worktrees #links #delivery #cli-core

The clones a repository consumes live at `<git-common-dir>/kai/repositories/<owner>/<repo>`, and each checkout reaches them through `.ai/repositories/<owner>/<repo>`, a link inside the already-ignored directory. Every worktree of a repository shares the git folder, so one clone serves all of them and none can drift onto a version of its own. Because the link is never committed it is free to differ from checkout to checkout, and that is precisely what allows one committed relative target to be correct in every one of them — an arrangement that is otherwise impossible, since no relative path resolves to the same place from two different places. Rejected on the way here: ignoring the laid links so they stop being committed (they must stay committed); a link conjured per worktree; a clone or a copy per worktree (two versions in two worktrees); and pointing a worktree's `.git` at the shared folder, which resolves the store but makes git report the branch as `main`. (Operator, 2026-08-27.)

## [2026-08-27 00:00 CEST] Decision-075: session start makes the declared sources present
#hooks #bootstrap #store #cli-core

A hook shipped in the kai package walks the sources a repository declares at the start of every session and clones any that are missing. That is what lets a fresh clone, or a brand-new worktree, reach its packages without anyone knowing to run a sync first — the directory holding them is ignored, so git never checks it out. It clones only: it never fetches, pulls, rebases, or lays. (Operator, 2026-08-27.)

## [2026-08-27 00:00 CEST] Decision-076: the store's README is written, never committed
#store #bootstrap #readme

`.ai/repositories/README.md` explains what the directory is and that losing it is harmless. The hook writes it and it stays ignored. Committing it was considered, since a committed file would make git create the directory in every checkout, and rejected: it would require a commit before the tool could run, or a commit made on the user's behalf, and kai has never written to a user's history. A directory that goes unexplained to someone browsing the repository is the smaller cost. (Operator, 2026-08-27.)

## [2026-08-27 00:00 CEST] Decision-077: a laid link is counted from the nearest .ai.toml
#links #laying #worktrees #cli-core

The `../` count in a laid link's target is taken from the nearest `.ai.toml` at or above the link — never from a home directory, never from the process working directory. A symlink target resolves relative to the directory holding the link, so the count belongs to the link's own position in its own repository; `.ai.toml` sits at a fixed place in a repository whichever checkout you are standing in, which makes it the one reliable landmark. Counting from where the command happened to be standing is what wrote five-step targets into links that needed two, correct inside the worktree that wrote them and wrong the moment the branch landed on main. (Operator, 2026-08-27.)

## [2026-08-27 00:00 CEST] Decision-078: docs/configuration-files.md was an example, not a spec
#config #ai-toml #docs #authority

That file was an agent invention; the operator annotated it only so there would be a worked example of the shape he wanted. It was never a specification and carries no authority — a stored note telling future sessions it outranked every decision and document contradicting it was wrong and is retired with it. The file is deleted. `docs/ai-toml.md` is where the configuration file is explained to the people who write it. (Operator, 2026-08-27.)

## [2026-08-27 00:00 CEST] Decision-079: description in .ai.toml is free text
#config #ai-toml

The root table's `description` is a sentence for whoever opens the file. Nothing in the tool reads it today, and it is documented as such rather than as behaviour; it may be used later. `name` and `type` remain the only root-table keys anything acts on. (Operator, 2026-08-27.)

## [2026-08-28 00:00 CEST] Decision-080: a collision is merged by rebase, not kept apart
#conflicts #rebase #collision #update #cli-core

Supersedes Decision-042, which the operator does not recognise as his: "I have no memory of saying anything like this." Its reasoning missed the distinction that matters. Two artifacts of the same name coming from two DIFFERENT packages say nothing about being about the same subject, and both are kept under the name of the package that brought them — that case, and only that case, is what keeping them apart was ever for. A file of your own colliding with a package you have declared and can publish back to is almost certainly the same file, and is treated as such.

A laid artifact is a link into the package it came from, so an edit through it is already an edit of that repository. Nothing is copied anywhere. A real file standing where a link belongs is replaced by the link, and the version that stood there stays in the repository's own history. From then on the change is committed into the package and rebased onto whatever the package does next, which is what supplies the base a merge needs: without it the tool held two versions and nothing they had diverged from, and every difference read as irreconcilable.

Where both sides changed the same lines the rebase is LEFT OPEN. Being unfinished is the state — git holds it, and kai asks rather than keeping a record of its own. `kai update --abort` restores, `--automerge` proposes, `--resolve` carries on from what the user edited and will take `mine` or `theirs` instead. Nothing is lossy at any point, because every version is in a commit. (Operator, 2026-08-28.)

## [2026-08-28 00:00 CEST] Decision-081: update is the verb; sync is a name for it
#cli #naming #update #sync

`update` is the command that brings declared packages up to date and lays them. `sync` remains as another spelling of the same command; nothing distinguishes them. The separate `resolve` command is retired — what it described now happens inside `update`, where the work is. (Operator, 2026-08-28.)
