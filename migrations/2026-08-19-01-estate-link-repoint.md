# Estate repair: links left dangling by a hand-applied kaukea move

A survey of the estate found ten dangling committed symlinks across five repositories
(fastcut, packages, seb.crash, seb.house, seb.throwy) — root `AGENTS.files.md` and
`AGENTS.shared.md` still pointing into `.ai/repositories/serialseb/orchids/`, a store
that no longer exists. Proven cause: those five carry the `2026-08-18-kaukea-move`
watermark but not its companion `2026-08-18-kaukea-move-links` — the rename was applied
by hand (`.ai.toml` edited directly, old clone removed directly) rather than through
`kai sync`, so the watermark shows the rename but the companion repoint never ran for
them.

Because the hand-edit also deleted the old store directory, `2026-08-18-kaukea-move-links`'s
fixed `kaukea/kauk` / `kaukea/orchard` destinations cannot be assumed here — nothing
proves either is the clone that now carries a given link's tail path, and only the
`orchids` side is evidenced by survey. This migration instead searches every
currently-cloned source under `.ai/repositories/` for whichever one carries the dangling
link's tail, and repoints to that. A tail claimed by no cloned source is not
recoverable from anything checked out, and the link is removed; a tail claimed by more
than one cloned source is ambiguous and is left alone, reported.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
store="$root/.ai/repositories"

found=0
while IFS= read -r l; do
  [ -L "$l" ] || continue
  t=$(readlink "$l")
  case "$t" in
    *".ai/repositories/serialseb/orchids"*|*".ai/repositories/serialseb/kauk"*) ;;
    *) continue ;;
  esac
  found=1

  case "$t" in
    *".ai/repositories/serialseb/orchids"*) tail=${t##*".ai/repositories/serialseb/orchids"} ;;
    *".ai/repositories/serialseb/kauk"*)    tail=${t##*".ai/repositories/serialseb/kauk"} ;;
  esac

  candidates=""
  ncand=0
  if [ -d "$store" ]; then
    for owner in "$store"/*/; do
      [ -d "$owner" ] || continue
      for repo in "$owner"*/; do
        [ -d "$repo" ] || continue
        cand="${repo%/}$tail"
        [ -e "$cand" ] || continue
        candidates="$candidates$cand
"
        ncand=$((ncand + 1))
      done
    done
  fi

  if [ "$ncand" -eq 1 ]; then
    newtarget=${candidates%$'\n'}
    ln -sfn "$newtarget" "$l"
    echo "repointed ${l#"$root"/} -> ${newtarget#"$root"/}"
  elif [ "$ncand" -gt 1 ]; then
    echo "skip ${l#"$root"/} (ambiguous: more than one cloned source carries $tail)"
  else
    rm -f "$l"
    echo "removed ${l#"$root"/} (no cloned source carries $tail; nothing can claim it)"
  fi
done < <(find "$root" -path "$root/.git" -prune -o -path "$root/.ai" -prune -o -type l -print)

[ "$found" = 1 ] || echo "no serialseb-store-targeted links found — nothing to do"
exit 0
```

## Verify

- Before: a consumer with a committed link resolving into
  `.ai/repositories/serialseb/orchids/…` or `.../serialseb/kauk/…`, whether or not that
  old store directory still exists on disk.
- After one run: every such link whose tail path exists under exactly one currently
  cloned source (`.ai/repositories/<owner>/<repo>/…`) repoints there; a link whose tail
  exists under no cloned source is removed and reported; a link whose tail exists under
  more than one cloned source is left alone and reported as ambiguous.
- A second run reports "nothing to do" for every link the first run repointed or
  removed — safe to run twice.
- `.git` and `.ai` are never descended into when searching for links to repair; reads
  under `.ai/repositories/` are existence checks only, never writes.
