# The package store moves into the git folder

The store sat in the working tree, in an ignored directory, so git never put it in a
checkout: a fresh clone had none of it and neither did a new worktree, and every
committed link pointed at nothing until someone knew to run a sync. It moves into the
git folder, which every worktree of a repository shares — one clone then serves all of
them and none can drift onto a version of its own — and each checkout reaches it through
a link inside the ignored directory, which is never committed and so may differ from
checkout to checkout.

This migration moves the clones a repository already has, and leaves a link behind in
their place, so nothing has to be downloaded again. Anything still missing afterwards is
cloned at the next session start.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
cd "$root"

common=$(git rev-parse --git-common-dir)
case "$common" in /*) ;; *) common="$root/${common#./}" ;; esac
store="$common/kai/repositories"

[ -d "$root/.ai/repositories" ] || { echo "no store in the working tree — nothing to move"; exit 0; }

moved=0
linked=0
for d in "$root"/.ai/repositories/*/*/; do
  [ -d "$d" ] || continue
  slot=${d%/}
  id=${slot#"$root/.ai/repositories/"}

  # already a link into the store: nothing to do
  [ -L "$slot" ] && continue
  # only a real clone is ours to move
  [ -d "$slot/.git" ] || continue

  dest="$store/$id"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ]; then
    printf 'kept %s where it is: the git folder already holds a clone for it\n' "$id"
    continue
  fi
  mv -n "$slot" "$dest"
  moved=$((moved + 1))
  ln -sfn "$dest" "$slot"
  linked=$((linked + 1))
  printf 'moved %s into the git folder\n' "$id"
done

# a clone that was already in the git folder but has no link here yet
for d in "$store"/*/*/; do
  [ -d "$d" ] || continue
  slot=${d%/}
  id=${slot#"$store/"}
  link="$root/.ai/repositories/$id"
  if [ -e "$link" ] || [ -L "$link" ]; then
    continue
  fi
  mkdir -p "$(dirname "$link")"
  ln -sfn "$slot" "$link"
  linked=$((linked + 1))
  printf 'linked %s from the git folder\n' "$id"
done

printf '%s clone(s) moved, %s link(s) in place\n' "$moved" "$linked"
exit 0
```

## Verify

- Before: `.ai/repositories/<owner>/<repo>` is a real directory holding a clone, and the
  git folder holds no `kai/repositories`.
- After one run: every clone lives at `<git-common-dir>/kai/repositories/<owner>/<repo>`,
  and `.ai/repositories/<owner>/<repo>` is a link to it. The committed links resolve
  exactly as before, through that link.
- A worktree of the same repository resolves the same clone, because it shares the git
  folder. No second copy exists anywhere.
- Nothing new is committed: `git status` is unchanged by the move, since the whole
  directory was ignored before and still is.
- A clone the git folder already holds is left where it is and reported, never
  overwritten.
- A second run finds every entry already a link and moves nothing.
