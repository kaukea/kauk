# Retired sources are renamed in dependency blocks too

The migration that moved `serialseb/kauk` and `serialseb/orchids` to `kaukea/kauk` and
`kaukea/orchard` rewrites the retired `[sources."<owner>/<repo>"]` table syntax. A
repository that reached the `[[dependency]]` form before that rename ran is therefore
never matched by it: the header it looks for no longer exists in the file, and its
sources keep naming repositories that moved.

Three repositories are in that state, and one of them names `kaukea/orchids`, an
identifier that never existed — orchard has only ever been `kaukea/orchard`.

This renames the same set in the form the file actually has now.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
cd "$root"

f=".ai.toml"
[ -f "$f" ] || { echo "no .ai.toml — nothing to rename"; exit 0; }

before=$(cat "$f")

# Only `source =` values inside dependency blocks, and only the retired names.
# A path is matched wherever it lives: what identifies it is its last two
# components, not the home directory in front of them.
sed -i \
  -e 's|^\([ \t]*source[ \t]*=[ \t]*"\)serialseb/kauk\(@[^"]*\)\?"|\1kaukea/kauk\2"|' \
  -e 's|^\([ \t]*source[ \t]*=[ \t]*"\)serialseb/orchids\(@[^"]*\)\?"|\1kaukea/orchard\2"|' \
  -e 's|^\([ \t]*source[ \t]*=[ \t]*"\)kaukea/orchids\(@[^"]*\)\?"|\1kaukea/orchard\2"|' \
  -e 's|^\([ \t]*source[ \t]*=[ \t]*"\)[^"]*/serialseb/kauk\(@[^"]*\)\?"|\1kaukea/kauk\2"|' \
  -e 's|^\([ \t]*source[ \t]*=[ \t]*"\)[^"]*/serialseb/orchids\(@[^"]*\)\?"|\1kaukea/orchard\2"|' \
  "$f"

if [ "$before" = "$(cat "$f")" ]; then
  echo "no retired source named in a dependency block — nothing to do"
  exit 0
fi

echo "renamed retired sources:"
diff <(printf '%s\n' "$before") "$f" | grep '^[<>]' | sed 's/^/    /' || true

# The clones under the old identifiers can no longer be reached by any
# declaration, so they are removed and fetched again under the new ones.
for old in \
  "$root/.ai/repositories/serialseb/kauk" \
  "$root/.ai/repositories/serialseb/orchids" \
  "$root/.ai/repositories/kaukea/orchids"
do
  [ -d "$old" ] && rm -rf "$old" && echo "    removed the clone at ${old#"$root"/}"
done
rmdir "$root/.ai/repositories/serialseb" 2>/dev/null || true

echo "run kai update to fetch them under the names they now have"
```

## Verify

- Before: `.ai.toml` carries a `[[dependency]]` block whose `source` is
  `serialseb/kauk`, `serialseb/orchids`, `kaukea/orchids`, or a path ending in
  `serialseb/kauk` or `serialseb/orchids`.
- After one run: every one of those reads `kaukea/kauk` or `kaukea/orchard`. Any `@ref`
  suffix is carried across unchanged. Every other line of the file — the root table,
  comments, include lists, other dependencies — is byte-for-byte as it was.
- No clone remains under a retired identifier; the next update fetches them under the
  names they now have.
- A repository naming none of them is reported and left alone.
- A second run finds nothing to rename.
- The earlier migration that renames the `[sources."…"]` table syntax still does its
  own job; this one covers the form that migration cannot see.
