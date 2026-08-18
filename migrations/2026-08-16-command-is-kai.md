# The command is kai; the executable is kaukea; kauk stays as the alias

Decision-026, executed: `bin/kauk` is now `bin/kaukea`, with `bin/kai` and
`bin/kauk` as symlinks to it. The tool's skill renamed `kauk` → `kai`. Every
consumer keeps working — the old invocation path resolves through the alias.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
# Consumers: a laid skill link named kauk repoints to kai on the next sync;
# nothing to convert by hand. Only a repository carrying its own hardcoded
# calls to a vendored bin/kauk needs nothing either — the alias resolves.
old="$root/.claude/skills/kauk"
if [ -L "$old" ] && [ ! -e "$old" ]; then
  rm "$old"
  echo "removed dangling kauk skill link (renamed to kai; next sync lays it)"
fi
exit 0
```

## Verify

- `bin/kai`, `bin/kauk`, and `bin/kaukea` all run and print the same usage.
- The laid skill is `kai`, not `kauk`, after a sync.
