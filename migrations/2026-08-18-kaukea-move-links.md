# The kaukea move, part two: links already laid in consumers

`2026-08-18-kaukea-move` re-keyed `.ai.toml` sources from `serialseb/*` to
`kaukea/{kauk,orchard}` but did not repoint links a consumer had already laid
against the old `.ai/repositories/serialseb/…` clones. Its watermark has since
passed estate-wide, so it will not run again for anyone (Decision-054: the
migration that moves something also moves what it broke). This follow-up finds
and repoints those stale links directly, independent of the rename migration's
watermark.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
oldkauk="$root/.ai/repositories/serialseb/kauk"
oldorchids="$root/.ai/repositories/serialseb/orchids"
newkauk="$root/.ai/repositories/kaukea/kauk"
neworchard="$root/.ai/repositories/kaukea/orchard"

found=0
while IFS= read -r l; do
  [ -L "$l" ] || continue
  t=$(readlink "$l")
  case "$t" in
    "$oldkauk"|"$oldkauk"/*)
      tail=${t#"$oldkauk"}
      newtarget="$newkauk$tail"
      ;;
    "$oldorchids"|"$oldorchids"/*)
      tail=${t#"$oldorchids"}
      newtarget="$neworchard$tail"
      ;;
    *) continue ;;
  esac
  found=1
  if [ -e "$newtarget" ]; then
    ln -sfn "$newtarget" "$l"
    echo "repointed ${l#"$root"/} -> ${newtarget#"$root"/}"
  else
    echo "skip ${l#"$root"/} (kaukea target not present yet: ${newtarget#"$root"/})"
  fi
done < <(find "$root" -path "$root/.git" -prune -o -path "$root/.ai" -prune -o -type l -print)

[ "$found" = 1 ] || echo "no serialseb-targeted links found — nothing to do"
exit 0
```

## Verify

- Before: a consumer with a laid link resolving into
  `.ai/repositories/serialseb/kauk/…` or `.../serialseb/orchids/…`.
- After one run: every such link that has a kaukea clone repoints into
  `.ai/repositories/kaukea/kauk/…` or `.../kaukea/orchard/…`, preserving its
  tail path; a link whose kaukea clone is not present yet is left alone and
  reported as skipped (a later sync or a re-run heals it).
- A second run reports "nothing to do" for every link the first run repointed
  — safe to run twice, and safe to run alongside `2026-08-18-kaukea-move` in
  either order.
- `.git` and `.ai` are never descended into, so clone internals and the tool's
  own bookkeeping are untouched.
