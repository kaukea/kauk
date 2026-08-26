# The header the tool wrote about itself comes out of .ai.toml

`.ai.toml` is the operator's file. Older versions of the tool wrote a header
into it describing the tool's own syntax and telling the reader not to edit the
file by hand:

```
# managed by kauk — CLI and AGENTS.md driven; do not edit by hand
# Sources live in [sources."<owner>/<repo>"] tables (origin = "URL or local path");
# clones sit at .ai/repositories/<owner>/<repo>/ (gitignored).
# Delivery per role: [dev] [infra] [org], or ["*"] for defaults, with
#   skillname = "exclude" | "copy" | "link" | "local"
```

Every line of it is now wrong: the tables it describes no longer exist, role
delivery was never built, and the file is edited by hand by design. The tool
also no longer writes its own name into anything it produces.

Only a leading comment block that names the tool is removed, and only from the
very top of the file. A comment the operator wrote himself, anywhere, is left
exactly where it is — the block has to start at line one and mention `kauk` or
`kai` to be touched at all.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
cd "$root"

[ -f .ai.toml ] || { echo "  no .ai.toml here"; exit 0; }

head -1 .ai.toml | grep -qi '^#.*\(kauk\|kai\)' || {
  echo "  no tool-written header at the top of .ai.toml"
  exit 0
}

awk '
  BEGIN { drop = 1 }
  drop && /^[ \t]*#/ { next }
  drop && /^[ \t]*$/ { next }
  { drop = 0; print }
' .ai.toml > .ai.toml.kai-new
mv .ai.toml.kai-new .ai.toml
git add -- .ai.toml 2>/dev/null || true
echo "  removed the tool-written header from .ai.toml"
exit 0
```

## Verify

- Before: `.ai.toml` opening with a comment block naming kauk or kai.
- After: that block and the blank lines under it are gone; everything from the
  first real line onward is byte-identical, including any comment the operator
  wrote further down.
- A file whose first line is not a tool-written comment — a `name =` root table,
  a `[[dependency]]`, or the operator's own comment — is untouched, and says so.
- A second run reports there is no tool-written header.
