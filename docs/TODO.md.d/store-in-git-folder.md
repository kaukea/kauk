- created: 2026-08-27
- completed: 2026-08-27
- completed_during: f/store-in-git-folder
- created_by: opus-5
- created_during: f/store-in-git-folder
- size: m

## Blockers

(none)

## Questions

_None._

## Findings

Result: merged to main on 2026-08-27, preserved under
archive/store-in-git-folder. 396 assertions across eight suites green at branch
HEAD, plus an end-to-end run against a fresh clone of this repository.

- The reported defect was real: `link_one` wrote the absolute target it was
  handed and the dead-link repair repointed absolute too, so every sync undid
  `migrations/2026-08-19-02-relative-symlinks.md`, which sits below the
  watermark and cannot re-run.
- The five-step targets found in the field did NOT come from a home directory.
  Both that migration's `find` and `prune_links`' own prune only `.git` and
  `.ai`, so each descends into `.claude/worktrees/<id>/`. A link there is five
  directories below the outer checkout's root and two below its own, so it was
  written with five, resolved where it was written, and was wrong the moment its
  branch squashed onto main. Reproduced live: either pattern returned 82 links
  inside this repository's own worktree.
- git does nothing to symlinks when creating a worktree. A symlink is a blob
  whose content is the target string, and checkout writes it back verbatim.
- git has no built-in way to share untracked or ignored files between worktrees,
  and no hook that runs after `git worktree add`. Worktrees share the object
  database, refs under `refs/`, and `config`; nothing else. Every tool in this
  space parks the files under the git folder and links them in by hand.
- No single committed relative target can reach one store from both the main
  checkout and a nested worktree — no relative path resolves to the same place
  from two different places. It stops mattering once the link to the store is
  itself uncommitted, which it is, because the directory holding it is ignored.
- A worktree's `.git` may be replaced by a symlink to its own gitdir and git
  carries on normally, branch and status intact. Not needed by what shipped.
- This repository's own committed links were absolute and named the operator's
  home directory. A fresh clone of it carried 82 links, 76 of which resolved
  only by accident of being on the same machine.
- The six links that were dead in this repository's worktree are hooks orchard
  no longer ships at all — `courier-init.sh`, `courier-end.sh`,
  `courier-only-transport.sh`, `migrations-pending.sh`,
  `question-notification-backstop.sh`, `question-input-activity.sh`. Unrelated to
  depth, untouched by this work, and they disappeared once the store was cloned
  fresh.
- `AGENTS.files.md` §Migrations still describes a per-package watermark under
  `the-works/migrated/<owner>/<repo>`. The shipped engine uses one global
  watermark at `.ai/migrations.toml`, per the operator's 2026-08-19 ruling. The
  document is stale; not corrected here because it was not in scope.

## Dead ends

- Ignoring the laid links so they stop being committed — the operator requires
  them committed.
- A link into the store conjured per worktree by kai, a clone per worktree, or
  copying the files instead of linking. Rejected: machinery that must appear
  every time a worktree exists, or two versions in two worktrees.
- Pointing a worktree's `.git` at the shared git folder. The store resolves and
  git then reports the branch as `main` — the worktree loses its identity and
  commits would land on main.
- Committing a README inside the store directory so git creates it in every
  checkout. Works, but requires a commit before the tool can run, and kai has
  never written to a user's history.

## Proposal

Move the store into the git folder, which every worktree shares, and reach it
from each checkout through a link that is never committed. Count a laid link's
target from the nearest `.ai.toml` above it. Bootstrap the whole arrangement
from a session-start hook so a fresh checkout needs no sync.

## Testing

`tests/store-in-git-folder.sh`, 83 assertions: a checkout that has never had the
store, a worktree sharing the one clone, idempotent re-runs, a deleted store
directory, a local-path source, a hand-placed clone left alone, an unreachable
source, laid depth in a checkout and in a worktree, dead-link repair, and both
migrations against a repository carrying the exact damage seen in the field.
396 assertions across eight suites at branch HEAD, all green.

Also exercised end to end against a real fresh clone of this repository, which
is what caught a defect the fixtures could not: the repair matched a link's
absolute target against the root it was running in, so in a clone made anywhere
else it skipped every link that needed repairing — eighty of them, reported as
zero. After the fix that clone repointed all eighty, kept no absolute target,
cloned orchard into its git folder at session start, and finished with zero dead
links where it began with six.

## Changelog entry

#### ✨ `f/store-in-git-folder` → `archive/store-in-git-folder`

The directory holding a repository's packages is ignored, so git never puts it
in a checkout: a fresh clone and every new worktree began with all of their
committed links pointing at nothing, and the only way out was knowing to run a
sync. The store moves into the git folder, which every worktree of a repository
shares, so one clone serves all of them; each checkout reaches it through a link
that is never committed and so may differ per checkout. Session start clones
whatever a repository declares and does not yet have, which is what lets a fresh
checkout work on its own.

That also settles what the committed links carry. Their targets were absolute,
naming the machine that wrote them, which quietly reverted the relative-symlink
migration at every sync; and when laid or repaired from inside a worktree they
were counted from the outer checkout, so links needing two steps were written
with five and broke the moment their branch landed on main — one repository lost
all of its agents, skills, tools and hooks that way in a single squash. The
count now comes from the nearest `.ai.toml` above the link, which sits at a fixed
place whichever checkout you are standing in.

Two migrations carry existing repositories across: one repairs the committed
links, descending into no other checkout, and one moves the clones already on
disk into the git folder without downloading anything again.

_Board: `store-in-git-folder` · reported from Panopticon · relates to
`stale-laid-links`._

## Readme delta

In the `bin/kaukea` bullet, after the sentence describing what sync does, note
that packages a repository declares are cloned at session start into the git
folder rather than the working tree, so a fresh clone or a new worktree reaches
its packages without a sync being run first, and that each checkout reaches the
store through a link that is never committed.
