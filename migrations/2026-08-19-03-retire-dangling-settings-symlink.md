# The settings file that was deleted without a migration

orchard commit `d8f21f1` deleted `files/.claude/settings.json` and restructured `hooks/`
into per-event directories, carrying no migration of its own. Every consumer that had
synced before that commit laid a `.claude/settings.json` symlink pointing at the
package's now-gone file. It still resolves today only because vendored orchard clones
are pinned behind `d8f21f1`; the first consumer to pull past it gets a silently dangling
`.claude/settings.json` — a symlink that no longer resolves to anything, and Claude Code
falls back to no project settings at all with no error surfaced.

A package never ships `settings.json` and never writes one (`docs/package-format.md`
`## hooks/`) — the consumer owns that file. So the correct end state is simply: the
package-laid link is gone. Detection is precise and one-directional: only a *symlink*
whose stored target names a package's `files/.claude/settings.json` is removed. A real,
user-owned `settings.json` — symlink or not, resolving or not — is never inspected for
content and never removed; anything that isn't recognisably the package's own link is
left alone and reported.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
target="$root/.claude/settings.json"

if [ ! -L "$target" ]; then
  echo ".claude/settings.json is not a symlink — nothing to do (absent, or a real file left untouched)"
  exit 0
fi

link_target=$(readlink "$target")
case "$link_target" in
  *".ai/repositories/"*"/files/.claude/settings.json")
    git rm -q -- "$target" 2>/dev/null || rm -f "$target"
    echo "removed dangling package-laid symlink .claude/settings.json -> $link_target"
    ;;
  *)
    echo ".claude/settings.json is a symlink but not the package settings file ($link_target) — left alone"
    ;;
esac
exit 0
```

## Verify

- Before: `.claude/settings.json` is a symlink whose stored target (via plain `readlink`,
  not a resolving `readlink -f`) ends in `.ai/repositories/<owner>/<repo>/files/.claude/settings.json`
  — matched whether or not the target currently exists, since the whole point is a
  target that stopped existing upstream.
- After one run: that symlink is gone. Nothing is written in its place — a package never
  ships `settings.json`, and neither does this migration.
- A real file at `.claude/settings.json` (never a symlink into the package store) is
  untouched, whatever its content, on every run.
- A symlink at `.claude/settings.json` pointing anywhere else (a different package, a
  path outside `.ai/repositories/`, a relative path that happens not to match the
  pattern) is untouched and reported, not guessed at.
- A second run over an already-converted tree reports "not a symlink — nothing to do".
- No path under `.git` or `.ai/repositories` is written; only the consumer's own
  `.claude/settings.json` is ever touched.
