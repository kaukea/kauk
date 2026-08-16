# .ai.toml becomes defaults-only: keyed sources, no origin, per-source select

A source table's key now says everything (Decision-047/049): `[sources."<owner>/<repo>"]`
resolves to github.com; `[sources."/full/path"]` is a local working tree whose
`<owner>/<repo>` identity derives from its last two path components. An `origin =` key
is an error the reader refuses. Each table may carry `select = ["<category-path>", …]`;
no select means everything, as before selection existed.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
f="$root/.ai.toml"
[ -f "$f" ] || { echo "no .ai.toml — nothing to do"; exit 0; }
grep -q '^origin[ \t]*=' "$f" || { echo ".ai.toml already defaults-only — nothing to do"; exit 0; }

# Each [sources."<id>"] table with origin = "/full/path" re-keys to the path;
# an origin equal to https://github.com/<id> is simply dropped.
awk '
  /^\[sources\."/ { id=$0; sub(/^\[sources\."/,"",id); sub(/"\].*$/,"",id); cur=id; print; next }
  /^\[/ { cur=""; print; next }
  cur != "" && /^origin[ \t]*=/ {
    v=$0; sub(/^origin[ \t]*=[ \t]*"/,"",v); sub(/".*$/,"",v)
    if (v == "https://github.com/" cur) next          # the default — drop the line
    print "REKEY " cur " " v > "/dev/stderr"; next    # local path — table re-keys
  }
  { print }
' "$f" > "$f.new" 2> "$f.rekeys" || true

while read -r _ id path; do
  [ -n "$id" ] || continue
  sed -i "s|^\[sources\.\"$id\"\]|[sources.\"$path\"]|" "$f.new"
  echo "re-keyed $id -> $path"
done < "$f.rekeys"

mv "$f.new" "$f"; rm -f "$f.rekeys"
echo ".ai.toml converted to defaults-only"
```

## Verify

- `grep -c '^origin' .ai.toml` is 0.
- Every source table key is either `<owner>/<repo>` or a full path that exists.
- `kauk sync` runs without the "origin is retired" refusal and lays the same links
  as before conversion.
