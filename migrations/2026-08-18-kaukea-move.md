# The kaukea move: sources become kaukea/kauk and kaukea/orchard

Both repositories live in the kaukea organisation, and orchids is renamed
orchard (kauk Decision-052). Every consumer's `.ai.toml` source — whether a
local path into `~/src/serialseb/` or an old `serialseb/…` id — becomes the
GitHub default form: `kaukea/kauk`, `kaukea/orchard`. Clones re-key, links
retarget on the next sync, and each package's migration watermark moves with
its identity so nothing re-runs.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
f="$root/.ai.toml"
[ -f "$f" ] || { echo "no .ai.toml — nothing to do"; exit 0; }

# A path source that IS this repository stays a PATH — self-publishing needs
# the working tree, never a clone. Resolve each path key (old-path symlinks
# included) against the MAIN checkout and re-key matches to it, first.
maindir=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
grep -o '^\[sources\."/[^"]*"\]' "$f" | sed 's/^\[sources\."//;s/"\]$//' | while read -r p; do
  rp=$(realpath -m "$p" 2>/dev/null || echo "$p")
  if [ "$rp" = "$(realpath "$maindir")" ]; then
    sed -i "s|^\[sources\.\"$p\"\]|[sources.\"$maindir\"]|" "$f"
  fi
done

sed -i \
  -e 's|^\[sources\."/home/[^"]*/serialseb/orchids"\]|[sources."kaukea/orchard"]|' \
  -e 's|^\[sources\."serialseb/orchids"\]|[sources."kaukea/orchard"]|' \
  -e 's|^\[sources\."/home/[^"]*/serialseb/kauk"\]|[sources."kaukea/kauk"]|' \
  -e 's|^\[sources\."serialseb/kauk"\]|[sources."kaukea/kauk"]|' \
  "$f"

gcd=$(git rev-parse --git-common-dir)
case "$gcd" in /*) ;; *) gcd="$root/$gcd" ;; esac
wm="$gcd/the-works/migrated"
if [ -d "$wm/serialseb" ]; then
  mkdir -p "$wm/kaukea"
  [ -f "$wm/serialseb/orchids" ] && mv "$wm/serialseb/orchids" "$wm/kaukea/orchard" && echo "watermark: orchids -> kaukea/orchard"
  [ -f "$wm/serialseb/kauk" ] && mv "$wm/serialseb/kauk" "$wm/kaukea/kauk" && echo "watermark: kauk -> kaukea/kauk"
  rmdir "$wm/serialseb" 2>/dev/null || true
fi

for old in "$root/.ai/repositories/serialseb/orchids" "$root/.ai/repositories/serialseb/kauk"; do
  [ -d "$old" ] && rm -rf "$old" && echo "removed old clone ${old#$root/}"
done
rmdir "$root/.ai/repositories/serialseb" 2>/dev/null || true
echo "converted — run kai sync to clone from kaukea and retarget the links"
exit 0
```

## Verify

- `.ai.toml` names only `kaukea/kauk` and `kaukea/orchard` (plus any unrelated
  sources); no `serialseb/` source and no local path to the moved repos remains.
- After `kai sync`, every laid link resolves into `.ai/repositories/kaukea/…`.
- The pending-migration notice reports nothing (the watermark travelled).
