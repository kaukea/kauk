# A managed repository declares the package that manages it

The kai package is planted once, when a repository is initialised, and nothing has ever
put it back. Every migration written so far renames a declaration that already exists;
none creates one. A repository that never ran the initialise step, or lost the block
along the way, therefore has no route back to it.

That package carries the skill that launches an agent with the fleet's settings, which
is the only sanctioned way to launch one. Without it the repository cannot start an
agent at all, so this is not a tidiness matter.

This is the first migration that WRITES a declaration rather than rewriting one, into a
file that belongs to the operator. It therefore adds one block and nothing else: it
never reorders, reformats, comments, or removes anything already in the file, and it
does nothing at all when a declaration is already present in any form.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
cd "$root"

f=".ai.toml"
[ -f "$f" ] || { echo "no .ai.toml — this repository is not managed by kai"; exit 0; }

# The kai package does not depend on itself: a package publishes into its own
# repository by copy and is never vendored. Detected by what is here rather than
# by name, since a name is only a claim.
[ -f "bin/kaukea" ] && { echo "this repository IS the kai package — nothing to declare"; exit 0; }

# Already declared? Accept every shape a source can take — "kaukea/kauk", a git
# URI, or a path to a checkout — by comparing the repository half alone. An @ref
# is stripped only when it sits in the LAST path segment, the way bin/kaukea does
# it: a git URI carries an @ in its user part and cutting at that would leave
# "git". A trailing .git goes too. This runs after the migration that renames the
# retired owner, so a repository converted in the same pass is already seen here.
present=0
while IFS= read -r src; do
  [ -n "$src" ] || continue
  case "${src##*/}" in *@*) src=${src%@*} ;; esac
  src=${src%/}
  src=${src%.git}
  case "${src##*/}" in kauk) present=1 ;; esac
done <<EOF
$(awk '
  /^[ \t]*\[\[dependency\]\][ \t]*$/ { indep = 1; next }
  /^[ \t]*\[/                        { indep = 0; next }
  indep && /^[ \t]*source[ \t]*=/ {
    v = $0
    sub(/^[ \t]*source[ \t]*=[ \t]*/, "", v)
    if (substr(v, 1, 1) == "\"") { sub(/^"/, "", v); sub(/".*$/, "", v) }
    else { sub(/[ \t]*#.*$/, "", v); sub(/[ \t]+$/, "", v) }
    if (v != "") print v
  }
' "$f")
EOF

[ "$present" = 1 ] && { echo "the kai package is already declared — nothing to do"; exit 0; }

# Append after the last dependency block, which is where kai itself appends, so a
# repository's own root table and comments stay where the operator put them.
last=$(grep -n '^[ \t]*\[\[dependency\]\][ \t]*$' "$f" | tail -1 | cut -d: -f1)
if [ -z "$last" ]; then
  [ -s "$f" ] && printf '\n' >> "$f"
  printf '[[dependency]]\nsource = "kaukea/kauk"\n' >> "$f"
else
  end=$(awk -v s="$last" 'NR>s && /^[ \t]*\[/ { print NR-1; exit }' "$f")
  [ -n "$end" ] || end=$(wc -l < "$f")
  { head -n "$end" "$f"
    printf '\n[[dependency]]\nsource = "kaukea/kauk"\n'
    tail -n +$((end + 1)) "$f"
  } > "$f.kai-tmp" && mv "$f.kai-tmp" "$f"
fi
echo "declared the kai package — run kai sync to clone it and lay what it carries"
```

## Verify

- Before: `.ai.toml` exists and no `[[dependency]]` block names a source whose repository
  half is `kauk`.
- After one run: exactly one such block exists, `source = "kaukea/kauk"`, placed after the
  last dependency already in the file. The root table, any comments, and every other block
  are byte-for-byte unchanged.
- A repository that already declares it — as `kaukea/kauk`, as a git URI, as a path to a
  checkout, or with an `@ref` suffix — is reported and left alone.
- The kai package itself declares nothing: it is recognised by carrying `bin/kaukea`, and a
  package publishes into its own repository by copy rather than depending on itself.
- A repository with no `.ai.toml` is not managed by kai and is left untouched.
- A second run reports that the declaration is already present and changes nothing.
- The clone is not fetched here. Session start, or the next `kai sync`, brings it in.
