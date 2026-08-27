# `.ai.toml`

Every repository that uses kai has one file, `.ai.toml`, at its root. It says what the
repository is and what it consumes. That is the whole of it — there is no second
configuration file, no lock file to maintain, and nothing hidden anywhere else.

**The file is yours.** You can open it, edit it, reorder it, and comment it however you
like. `kai install` appends a dependency block after the last one and never touches
anything else; nothing else the tool does writes to it. If you would rather write the
block yourself and run `kai sync`, that works exactly the same way.

A minimal one is two lines:

```toml
[[dependency]]
source = "kaukea/orchard"
```

## Naming your project

The top of the file, before any `[[dependency]]` block, describes the repository itself.
Both keys are optional and most repositories leave them out entirely.

```toml
name = "panopticon"
description = "Who touched the evidence store, in plain sentences."
```

- **`name`** — what this repository is called. It defaults to the directory name. It
  matters when two packages you consume happen to ship an artifact with the same name:
  kai keeps both and puts each behind its package's name rather than letting one quietly
  win.
- **`description`** — a sentence for whoever opens the file. Nothing in the tool reads
  it today; it is there so a repository can say what it is.

## What this repository consumes

Each package you use gets a `[[dependency]]` block. Order does not matter.

```toml
[[dependency]]
source = "kaukea/orchard"
```

`source` takes three shapes:

| Shape | Example | Meaning |
|---|---|---|
| `owner/repo` | `"kaukea/orchard"` | resolved to GitHub |
| a git URI | `"git@github.com:kaukea/orchard.git"` | used as given |
| a path | `"/home/you/src/orchard"`, `"./packages/mine"` | a working tree on this machine |

A path is a development convenience: you are pointing at a checkout you are editing, so
kai reads it where it lies and never clones it.

### Taking only part of a package

A package can be large, and you may want a few things from it rather than all of it.
`include` names what to take, by category path:

```toml
[[dependency]]
source = "kaukea/orchard"
include = ["process/workflow", "development"]
```

Without an `include`, everything in the package is installed. Selecting a category
brings its whole subtree, plus anything the selected artifacts declare they depend on —
you never end up with a skill whose helper is missing.

`include` works on git sources only. A local path is a checkout you are about to
replace with its git source, and a selection that would not survive that swap is a trap,
so kai refuses it rather than letting you build on it.

### Asking for a particular version

A source may name a ref after an `@`:

```toml
[[dependency]]
source = "kaukea/orchard@HEAD"
```

`@HEAD` means "follow the source", and is what you get when you name no ref at all.
Anything else — a branch, a tag, a commit — is parsed and understood, but not yet acted
on: kai says so, lays what is already there, and moves nothing. Real version pinning
waits on the versioning work.

## Where the packages actually go

You do not have to manage this, but it helps to know where things are.

A package is cloned into your repository's git folder, at
`<git folder>/kai/repositories/<owner>/<repo>`, and your working tree reaches it through
`.ai/repositories/<owner>/<repo>`. That directory is ignored, so none of it is ever
committed.

Two things follow. Every worktree of your repository shares the git folder, so they all
read the same clone and none of them can drift onto a version of its own. And because
nothing is committed, a fresh clone of your repository starts without any of it — so kai
fetches whatever is declared and missing at the start of each session. You do not need
to run a sync first, and a brand-new worktree costs nothing at all.

Deleting `.ai/repositories/` is safe. The next session puts it back.

## Publishing a package

Most repositories only consume. If you want yours to be something *other* repositories
can install, say so in the root table:

```toml
name = "orchard"
type = "package"
```

`type` defaults to `project`, which is an ordinary repository that consumes packages.
Setting it to `package` changes three things:

- The repository applies its own `migrations/` to itself, the same way a consumer
  applies yours — so you find out immediately when a migration you wrote misbehaves.
- It lays its own agents and skills into itself, by copying rather than linking. A
  package does not keep a clone of itself inside itself; it publishes into its own
  working tree, so your edits are live without pushing first.
- It becomes installable by name, and its own name is what namespaces its artifacts in
  everyone else's repository.

**A package declares nothing about its contents.** There is no manifest to write and no
list to keep in step. What you ship is whatever sits in the convention directories —
`skills/`, `agents/`, `hooks/`, `tools/`, `files/` — and anything outside them is
ignored. `docs/package-format.md` is the full specification, including what each
directory means and how an artifact declares its own categories and dependencies.

A repository can do both at once: `type = "package"` in the root table and
`[[dependency]]` blocks for what it consumes in turn.
