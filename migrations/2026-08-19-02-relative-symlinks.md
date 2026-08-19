# Committed symlinks stop naming a machine's home directory

Every symlink kai lays into `.ai/repositories/<owner>/<repo>/…` is committed to git as
mode `120000` with an **absolute** path as its blob content — roughly eighty per
managed repository, across eleven repositories. An absolute target bakes in one
machine's home directory (`/home/sudoku/…` here); anyone else cloning the repository,
or the same operator with a relocated checkout, gets a broken link the moment the path
stops matching. This migration rewrites every such link relative to the repository
root so the *committed path* survives a clone.

`.ai/repositories/` stays gitignored, so a relativized link is still dangling for
whoever has not cloned the source it points into — that is expected, and is repaired by
their own `kai sync`, not by this migration. What this migration removes is the
absolute path naming this machine; it does not, and cannot, make the target resolve
for someone without the clone.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)

found=0
while IFS= read -r l; do
  [ -L "$l" ] || continue
  t=$(readlink "$l")
  case "$t" in
    /*) ;;
    *) continue ;;
  esac
  case "$t" in
    *"/.ai/repositories/"*) ;;
    *) continue ;;
  esac
  found=1

  target_rel=${t#"$root"/}
  if [ "$target_rel" = "$t" ]; then
    echo "skip ${l#"$root"/} (absolute target is not under this repository: $t)"
    continue
  fi

  linkdir=$(dirname "$l")
  linkdir_rel=${linkdir#"$root"}
  linkdir_rel=${linkdir_rel#/}

  prefix=""
  if [ -n "$linkdir_rel" ]; then
    depth=$(printf '%s' "$linkdir_rel" | awk -F/ '{print NF}')
    i=0
    while [ "$i" -lt "$depth" ]; do
      prefix="../$prefix"
      i=$((i + 1))
    done
  fi

  newtarget="$prefix$target_rel"
  ln -sfn "$newtarget" "$l"
  echo "relativized ${l#"$root"/} -> $newtarget"
done < <(find "$root" -path "$root/.git" -prune -o -path "$root/.ai" -prune -o -type l -print)

[ "$found" = 1 ] || echo "no absolute .ai/repositories links found — nothing to do"
exit 0
```

## Verify

- Before: a committed symlink anywhere outside `.git`/`.ai` whose target is an absolute
  path containing `/.ai/repositories/` — e.g. `/home/sudoku/…/.ai/repositories/<owner>/<repo>/…`.
- After one run: every such link's committed target is relative to the repository root
  (`../`-prefixed by the link's own depth, then `.ai/repositories/<owner>/<repo>/…`);
  the link may still be dangling if that source is not cloned in this checkout — that is
  correct, not a defect this migration owns.
- A link whose target is already relative is left untouched.
- A second run finds nothing left to relativize — safe to run twice.
- `.git` and `.ai` are never descended into when searching for links to rewrite.
