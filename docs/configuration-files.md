# Configuration files — as currently built

Edit this file directly. Each entry says what the file is TODAY. Correct
anything wrong, delete anything that should not exist, add anything missing —
the corrected version becomes the spec that gets implemented.

## .ai.toml

- Location: repository root, one per repository.
- Contains: what this repository consumes — `[sources."owner/repo"]` (GitHub)
  or `[sources."/full/path"]` (local working tree), each with an optional
  `select = ["category-path", ...]`.


> [!CAUTION] INCORRECT
 `sources` is wrong at this location, you do not consume a source, you consume a series pf packages.
>
> As such the correct syntax is:
> 
> ```toml
> [[dependency]]
> type = package (default value, can be omitted). Otehr values ignored for now.
> source = owner/repo | full uri to repo | / or ./ to 
> ```

> [!IMPORTANT] - MISSING
> Source packages from a git repository can take an optional `@HEAD` or `@branch` or a tag, it's trasmsparent to git operations .
---~

- Written by: the user only. Tooling never writes it.
--
> [!CAUTION] WWRONG
> Absolutely not. A package is installed by the user **OR** kai command as it always did, which can also be called througbh the kai skill.
>
>It is then appended after the last package in the file. The user can also do it manually and call sync. That has always been the specification before you agents took over
--

- User-facing: yes.

## package.toml

> [!CAUTION] BEHAVIOUR BREACH
> You are copying what you learnt from the intrnet. Your rules specify thaty under noo circumnstances shoulod you introduce a new file type without operator's knowledge.
> You do not respect the rules.

- Location: root of a repository that is a package.
> [!IMPORTANT] IMPOSSSIBILITY
> We have implemented multiple features that depend on having folders part of the convention we use. Following this proposal makes it impossible to do so and makes it useless iin any case. Multiple packages in the same repository have never been approved by the operator.

> [!CAUTION] INCORRECT IMPLEMENTATION
> while in the future we may allow some flexibility, we do not at this stage, on purpose. You are again trrying to build a complex system when the system I am building
> must respect KISS and build the smallest composable features possible.
>
> A package is defined in the root table.
> 
> ```toml
> # Beginning of the TOML fiile, all fields are optional
> name = <repoitory name> | <user value>
> tagline = <empty string> | <user value> #example we are not implementing this
> type = package | <defaults to 'project'>
> ```
> That is all.
>

- Contains: package identity — name, title, description, pull-only flag.
> [!CAUTION] INCORRECT IMPLEMENTATION
> No, defined in the root. The pull only flag is only designed for your internal needs and you are trying to make it a feature. Sorry, nope. That is why we have a flag on the command.
- Written by: the package author, once.wf
- User-facing: authored by a human; consumers' users never touch it.
> [OPERATOR]They wont seeing as we're deleting it.

## .ai/ (directory)
<user value>
- Location: repository root, gitignored.
- Contains: `repositories/<owner>/<repo>/` — the vendored clones sync manages.
- Written by: the tool only.
  | Not approved, not useful to anyone
- User-facing: no.

## .git/the-works/ (directory)

- Location: inside .git, uncommittable.
- Contains: `migrated/` per-package migration watermarks, `asks/` steps sync could not finish, workstream logs, MOOD.
  
> [!CAUTION] IINVALID AND INCONSISTENT
> - Migrated is one date, not er package, they need to be committed, this has already been discussed and I approved my design.
> - Asks have beem removed until i have reviewed them and im  not happy with the model, this has already been killed.
> - Mood is an orchard concept and has nothing to do in kauk
> - workstream logs, if they are the internal chatter for features, i'll let it pass
  
- Written by: the tool and agents.
> [OPERATOR] As I'm removing all of this, except your implementation details, feel free. But only for data that is of use and created solely by agents for usage by agents.
- User-facing: no.

## Laid artifacts (.claude/skills|agents|hooks|tools, files/ content)

- Location: `.claude/` and repository root paths, as symlinks/copies into the
  vendored clones.
- Contains: the artifacts the selected packages deliver.
  > [OPERATOR] one package one repository. Thats all.
- Written by: the tool at sync (laying).
- User-facing: visible and usable; not maintained by hand.
> [!CAUTION] IINVALID AND INCONSISTENT
> Users can edit skills there is no reason they would not. You have proven that your skills can be wholefully inadequate: e.g. you do not write strong rules against deviation behaviour because you yourself suffer from it.

## .ai.lock

- Does not exist. Versions, tags, pins deferred whole (Decision-051).

## AGENTS.md

- Location: repository root.
- Contains: the project's own agent rules.
- Written by: the user.
- User-facing: yes.

## AGENTS.shared.md / AGENTS.files.md

- Location: repository root (twoday as laid links).
- Contains: shared rule content shipped by the workflow package.
- Written by: the package; laid by the tool.
- User-facing: read, not edited in place.> 
> [!CAUTION] NOT STUPID BUT THIS SECTION IS
> Users can edit these files if they want. If they have push access the normal behaviour applies, push at the end. If they do not, no push but their changes stays in their repositories. 
