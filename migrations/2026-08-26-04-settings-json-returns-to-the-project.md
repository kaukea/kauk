# .claude/settings.json returns to the project

Exactly one settings JSON exists, and it is passed, never laid (Decision-061,
2026-08-24): every fleet session is a spawned session, and each spawn carries
`claude --settings` pointing at kai's own file, beside the kai binary. Nothing
needs a settings file inside a consumer repository any more.

Two things put one there anyway, both older than that ruling:

- the package-laid symlink `.claude/settings.json` → the package's
  `files/.claude/settings.json`, which has been shipped since bootstrap and
  imposed the fleet's permissions and hooks on every consumer;
- `2026-08-19-05-adopt-kai-hooks.md`, which copies kai's own settings file into
  a repository that has none, so that a plain non-spawned session keeps its
  hooks. That migration is not rewritten — migrations never are — it simply runs
  before this one and this one takes the file back.

**A settings file the operator wrote is never touched.** Only two things are
removed: a symlink pointing into the package store, and a real file byte for
byte identical to the `kai.settings.json` sitting beside the resolved `kai` —
which is exactly and only what the adoption migration wrote. Anything else is
reported and left, including a file that started as kai's and was then edited:
the moment it differs, it is the operator's.

kai also refuses to lay either `.claude/settings.json` or
`.claude/settings.local.json` from a package's `files/` tree from now on, so
nothing puts one back on the next sync.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
cd "$root"
target=".claude/settings.json"

if [ ! -e "$target" ] && [ ! -L "$target" ]; then
  echo "  no $target here — nothing to take back"
  exit 0
fi

if [ -L "$target" ]; then
  case "$(readlink "$target")" in
    *.ai/repositories/*)
      rm -f "$target"
      git add -A -- "$target" 2>/dev/null || true
      echo "  removed the package-laid $target — settings ride the spawn now"
      exit 0 ;;
    *)
      echo "  $target is a symlink kai did not place — left alone"
      exit 0 ;;
  esac
fi

kai_bin=$(command -v kai 2>/dev/null || true)
if [ -n "$kai_bin" ]; then
  kai_bin=$(readlink -f "$kai_bin" 2>/dev/null || printf '%s' "$kai_bin")
  mine="$(dirname "$kai_bin")/kai.settings.json"
  if [ -f "$mine" ] && cmp -s "$mine" "$target"; then
    rm -f "$target"
    git add -A -- "$target" 2>/dev/null || true
    echo "  removed $target — it was kai's own file, unedited, and settings ride the spawn now"
    exit 0
  fi
fi

echo "  $target is yours — left exactly as it is"
exit 0
```

## Verify

- A consumer whose `.claude/settings.json` is a symlink into
  `.ai/repositories/` loses the link and nothing else; the removal is staged.
- A consumer whose `.claude/settings.json` is a real file identical to kai's own
  loses it too, and says why.
- A consumer whose file differs by so much as one byte keeps it, and is told it
  is theirs. So does a symlink pointing anywhere other than the package store.
- A consumer with no such file at all reports there is nothing to take back.
- A second run reports there is nothing to take back, and changes nothing.
- Nothing under `.ai/repositories/` is read or written, and nothing is committed.
