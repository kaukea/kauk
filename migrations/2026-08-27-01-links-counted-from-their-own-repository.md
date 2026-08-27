# Committed links are counted from the repository they sit in

A link laid or repaired while the command was standing somewhere other than the link's
own repository was counted from there. In practice that meant worktrees: a link inside
`.claude/worktrees/<id>/` is five steps below the outer checkout's root and two below its
own, so it was written with five, resolved where it was written, and became wrong the
moment its branch landed on the main branch. One repository lost all of its agents,
skills, tools and hooks that way in a single squash. Links naming an absolute path are
repaired by the same pass, since they carry a home directory that is meaningless in any
other clone.

This migration rewrites every committed link into the package store so its target is
counted from the root of the repository the link actually sits in. It descends into no
other checkout: a directory carrying its own `.git` — a worktree, a nested clone, a
submodule — belongs to somebody else and is left entirely alone. That restraint is the
point; its absence is what caused the damage being repaired.

A relativized link is still dangling for anyone who has not yet been given the store.
That is expected and is repaired at their next session start, not here.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
cd "$root"

changed=0
seen=0
while IFS= read -r l; do
  [ -L "$l" ] || continue
  t=$(readlink "$l")

  # Only links into the package store are ours to touch, whatever base they claim.
  case "$t" in
    /*)
      case "$t" in
        "$root"/*) rest=${t#"$root"/} ;;
        *) continue ;;
      esac ;;
    *".ai/repositories/"*)
      rest=".ai/repositories/${t##*".ai/repositories/"}" ;;
    *) continue ;;
  esac
  case "$rest" in
    .ai/repositories/*) ;;
    *) continue ;;
  esac
  seen=$((seen + 1))

  linkdir=${l%/*}
  linkdir=${linkdir#./}
  if [ "$linkdir" = "." ] || [ "$linkdir" = "$l" ]; then
    depth=0
  else
    depth=$(printf '%s' "$linkdir" | awk -F/ '{print NF}')
  fi

  prefix=""
  i=0
  while [ "$i" -lt "$depth" ]; do
    prefix="../$prefix"
    i=$((i + 1))
  done

  want="$prefix$rest"
  [ "$t" = "$want" ] && continue
  ln -sfn "$want" "$l"
  printf 'repointed %s -> %s (was %s)\n' "${l#./}" "$want" "$t"
  changed=$((changed + 1))
done < <(
  find . -mindepth 1 \( -name .ai -o -name .git \) -prune \
       -o -type d -exec test -e '{}/.git' ';' -prune \
       -o -type l -print
)

printf '%s store link(s) examined, %s repointed\n' "$seen" "$changed"
exit 0
```

## Verify

- Before: a committed link into `.ai/repositories/` whose target is either an absolute
  path, or a relative path whose leading `../` count does not equal the number of
  directories between the link and the root of the repository it sits in.
- After one run: every such link's target is exactly that count of `../` followed by
  `.ai/repositories/…`. A link at the repository root carries no `../` at all; one at
  `.claude/agents/` carries two.
- No file under a directory holding its own `.git` is touched — worktrees, nested clones
  and submodules are left exactly as they were, including their links.
- Nothing under `.git` or `.ai` is descended into.
- A link already carrying the right count is left untouched, so a second run reports
  nothing repointed and is safe.
- A link may still be dangling afterwards if this checkout has not been given the store
  yet. That is correct, and session start repairs it.
