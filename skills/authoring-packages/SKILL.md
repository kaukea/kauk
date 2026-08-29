---
name: authoring-packages
description: "Read before creating, moving or removing any agent, skill, hook or tool in a repository that is itself a kai package. Left alone an agent writes a new skill into the runtime's own directory, which is the opposite of what a package needs — the source belongs in the package's convention directory and the runtime directory holds a link to it. Covers where each kind of artifact lives and what to run when you add or remove one."
dependencies:
  type: package
---

# Authoring a kai package

A repository that carries `type = "package"` in its `.ai.toml` publishes artifacts for
other repositories to use, and consumes them itself at the same time. That second half
is what makes authoring one different, and it inverts a habit.

## The order this changes

Asked for a new skill, an agent writes it where the runtime keeps skills — for Claude,
`.claude/skills/<name>/SKILL.md`. That is correct in an ordinary repository and wrong
in a package, where it produces an artifact that works locally and ships to nobody:
`.claude/` is where things are *laid*, not where they are *kept*.

In a package the source is the convention directory at the repository root, and the
runtime directory holds a link to it:

```
skills/my-skill/SKILL.md        the artifact — edit this
.claude/skills/my-skill   ->    ../../skills/my-skill
```

Both paths reach the same file, so editing through either is the same act and there is
nothing to keep in step. What matters is which one is real.

## Where each kind lives

| Kind | Source | What it is |
|---|---|---|
| skill | `skills/<name>/` | a folder; `SKILL.md` plus any scripts it needs |
| agent | `agents/<name>.md` | one flat file — a prompt, carrying no payload |
| hook | `hooks/<name>` | a script the runtime fires on an event |
| tool | `tools/<name>` | a script an agent or skill calls |
| anything else | `files/<path>` | placed verbatim at that path in the consumer |

Anything outside those directories is not part of the package. A file added anywhere
else is simply a file in your repository, however useful it looks.

## Adding one

Create the source, then run `kai update`. That is what lays the link, and until it has
run the artifact exists but nothing is using it. Removing one is the same: delete the
source, then update, which takes the link away with it.

This is the one moment that needs a command. Editing an existing artifact needs
nothing, because the link already points at the file you are editing.

## Checking it

`docs/package-format.md` in the kai repository is the contract — what each kind may
carry in its frontmatter, and what makes a repository installable at all. Read it
before shipping something new.

## What you are not told by anything else

This skill declares that it depends on the repository being a package, so it is laid
nowhere else and is selected by `kai init --package`. If you are reading it, this
repository is one.
