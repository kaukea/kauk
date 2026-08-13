# Packages are read by convention; `manifest.conf` is ignored

kauk no longer reads `manifest.conf`. A package's contents are determined by the
convention directories `skills/ agents/ hooks/ tools/ files/`, and anything outside
them is ignored (Decision-015). Root-level files that a manifest used to place with
a `link` line — `AGENTS.shared.md`, `AGENTS.files.md`, `settings.json` — must move
into `files/`, whose contents mirror to the repository root at their own relative
paths.

Consumers need do nothing but sync. This migration is for repositories that ARE
packages.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
cd "$root"

# 1. Only a package needs converting: one that has convention directories.
ispkg=0
for d in skills agents hooks tools files; do [ -d "$d" ] && ispkg=1; done
[ "$ispkg" = 1 ] || { echo "not a package — nothing to do"; exit 0; }

# 2. Root files that used to be placed by a manifest move into files/.
#    Guarded per file: only move what is actually there and not already moved.
for f in AGENTS.shared.md AGENTS.files.md settings.json; do
  if [ -f "$f" ] && [ ! -e "files/$f" ]; then
    mkdir -p files
    git mv -- "$f" "files/$f" 2>/dev/null || { mkdir -p files; mv -n -- "$f" "files/$f"; }
    echo "moved $f -> files/$f"
  fi
done

# 3. A self-hosting relative link to a file that just moved now dangles. Drop it:
#    a self-published package lays its own artifacts, so the hand-made link is
#    redundant as well as broken.
for l in .claude/settings.json .claude/AGENTS.shared.md .claude/AGENTS.files.md; do
  if [ -L "$l" ] && [ ! -e "$l" ]; then
    git rm -q -- "$l" 2>/dev/null || rm -f "$l"
    echo "removed dangling self-link $l (its target moved into files/)"
  fi
done

# 4. manifest.conf is inert. Remove it if present; nothing reads it.
if [ -e manifest.conf ]; then
  git rm -q -- manifest.conf 2>/dev/null || rm -f manifest.conf
  echo "removed manifest.conf (no longer read)"
fi
```

Judgement step, not scripted: anything else the old `manifest.conf` placed with a
`link` line belongs in `files/` at its destination path. Read the file out of git
history if it is already deleted (`git log --diff-filter=D -- manifest.conf`), and
move each `link <src> <dst>` entry's source to `files/<dst>`.

`template` and `prefix` entries do NOT convert here — templates are a separate kind
with their own frontmatter (Decision-021) and are handled by the templates feature.

## Verify

- `ls files/` lists every root-level artifact the package delivers.
- `manifest.conf` does not exist.
- `find . -xtype l` inside the package finds nothing — no self-hosting link points at
  a file that moved.
- Ordering does not matter and was measured: a consumer synced BEFORE this migration
  keeps working (the package still has the files at its root, so its links resolve),
  and a consumer syncing AFTER has its links silently repointed at `files/`. There is
  no window in which a consumer is broken, so the tool and the packages may convert in
  either order and at any pace.
- In a consuming repository, `kauk sync` reports a link count greater than zero and
  the moved files resolve: `readlink AGENTS.shared.md` points into
  `.ai/repositories/<owner>/<repo>/files/AGENTS.shared.md`.
