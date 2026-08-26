# The old lock file goes when the migration file has taken over

`2026-08-19-04-migration-state-into-ai-lock.md` folded the per-source watermarks
into `.ai/lock.toml`. `2026-08-26-01-one-configuration-file.md` renamed that file
to `.ai/migrations.toml`, because the word "lock" belongs to the deferred
versioning work and should not mean two things.

A repository that receives both in the same run can end up with both files: the
older migration writes `.ai/lock.toml` after the newer one has already looked
for it, so the rename finds nothing to do and the stale file stays. Its value is
no longer read by anything.

This removes it, but only when `.ai/migrations.toml` is actually there to have
replaced it — a repository that somehow still has only the old file keeps it,
and the rename in `2026-08-26-01` handles that case as it always did.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
cd "$root"

if [ ! -f .ai/lock.toml ]; then
  echo "  no .ai/lock.toml — nothing to do"
  exit 0
fi

if [ ! -f .ai/migrations.toml ]; then
  echo "  .ai/lock.toml is still the only migration file here — left alone"
  exit 0
fi

rm -f .ai/lock.toml
git add -A -- .ai/lock.toml 2>/dev/null || true
echo "  removed the superseded .ai/lock.toml"
exit 0
```

## Verify

- Before: both `.ai/lock.toml` and `.ai/migrations.toml` present, the first
  holding a value nothing reads.
- After: only `.ai/migrations.toml`, its content untouched, and the removal
  staged for the repository's own workflow to commit.
- A repository with only `.ai/lock.toml`, or with neither, is left exactly as it
  was, and says so.
- A second run reports "no .ai/lock.toml — nothing to do".
