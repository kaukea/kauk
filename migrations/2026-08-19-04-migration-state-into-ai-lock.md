# Durable state leaves .git and lives in .ai

Ruled 2026-08-19: nothing writes under `.git/` without the operator's permission, and
state worth keeping must survive a clone. Migration state — which migrations a
repository has already applied — was living at `.git/the-works/migrated/<owner>/<repo>`,
one gitignored file per source, invisible to a fresh clone and invisible to review.

Ruled the same day: the watermark also stops being per-source. One global watermark —
the `<YYYY-MM-DD>-<NN>` prefix of the last applied migration — now lives as a single
line, committed, at `.ai/lock.toml`:

```toml
[migrations]
watermark = "2026-08-19-04"
```

This migration performs the one-time move for a single consumer: read whatever
per-source watermark files exist under the git common dir, fold them into the one new
value, write it, and remove the old files. It never invents a watermark for a source
that never had one, and it never touches `.ai/repositories/` or anything else under
`.git/`.

## Reconciliation rule (why this isn't just "take the highest file")

Per-source watermarks are known to lie low. A watermark can record an old migration
while every migration after it in that source has already been physically applied —
observed directly in orchard, whose watermark file said `2026-08-10-arborist-to-beekeeper`
while all fifteen of its migrations, up to `2026-08-18-skill-tour`, were already applied
to every consumer that had it cloned. Committing the naive highest *recorded* value
across sources would still commit that lie, and the new engine would re-run fourteen
migrations that already ran.

So each source contributes the higher of two numbers, not just its recorded one:

1. **Recorded** — the content of its `the-works/migrated/<owner>/<repo>` file, if any.
2. **Evidence** — the highest migration filename physically present in that source's
   own vendored clone, `.ai/repositories/<owner>/<repo>/migrations/*.md`, if the clone
   exists locally. A migration file only ships once a source has published it, and
   `kai sync` always applies pending migrations immediately after pulling to a new head
   (`docs/package-format.md` §migrations/, "pull → apply migrations → …") before
   anything else touches the tree — so a migration's presence in a clone that is already
   checked out this repository's history is treated as evidence it was offered and run,
   even when the recorded watermark itself fell behind (write failures, hand-applied
   syncs, or the same kind of drift the orchard case exposed).

The reconciled value for a source is the lexicographically greater of the two; the new
global watermark is the greatest reconciled value across every source that had a
recorded watermark at all. A source with no recorded watermark contributes nothing —
this migration does not scan clones that were never tracked, so it cannot manufacture a
watermark where the old engine kept none.

This is a one-time, one-directional correction. It only ever raises a value that
disagreed with the evidence in the direction of "already applied", matching the
concrete case that was found; it does not attempt to detect the opposite failure (a
watermark recorded higher than what was actually applied), which was not observed and
is not what "prefer the evidence" was ruled on.

Scope note: this migration reconciles *existing* per-source watermarks only. It does
not address a repository applying its own migrations to itself (`[general] type =
"package"` self-application) — that path has no prior watermark to reconcile because
the old engine never drove it, and is out of this step's scope.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
cd "$root"

target="$root/.ai/lock.toml"
if [ -f "$target" ] && grep -q '^\[migrations\]' "$target" 2>/dev/null; then
  echo ".ai/lock.toml already carries [migrations] — nothing to do"
  exit 0
fi

gcd=$(git rev-parse --git-common-dir)
case "$gcd" in /*) ;; *) gcd="$root/$gcd" ;; esac
wmdir="$gcd/the-works/migrated"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

if [ -d "$wmdir" ]; then
  find "$wmdir" -type f | while IFS= read -r wf; do
    rel=${wf#"$wmdir"/}
    recorded=$(cat "$wf" 2>/dev/null || true)
    [ -n "$recorded" ] || continue
    printf '%s\n' "$recorded" >> "$tmp"

    clone="$root/.ai/repositories/$rel/migrations"
    [ -d "$clone" ] || continue
    newest=$(LC_ALL=C ls "$clone" 2>/dev/null | sed -n 's/\.md$//p' | LC_ALL=C sort | tail -n1)
    [ -n "$newest" ] || continue
    printf '%s\n' "$newest" >> "$tmp"
    if [ "$newest" \> "$recorded" ]; then
      echo "  evidence: $rel's clone carries $newest, ahead of recorded $recorded — trusting the clone"
    fi
  done
fi

watermark=$(LC_ALL=C sort "$tmp" 2>/dev/null | tail -n1)

if [ -n "$watermark" ]; then
  mkdir -p "$root/.ai"
  {
    [ -f "$target" ] && cat "$target"
    printf '[migrations]\nwatermark = "%s"\n' "$watermark"
  } > "$target.new"
  mv "$target.new" "$target"
  git add -- "$target" 2>/dev/null || true
  echo "wrote .ai/lock.toml [migrations] watermark = $watermark"
else
  echo "no per-source watermarks found — leaving .ai/lock.toml without a [migrations] table (fresh-install rule applies)"
fi

if [ -d "$wmdir" ]; then
  rm -rf "$wmdir"
  echo "removed old per-source watermarks under .git/the-works/migrated"
fi
exit 0
```

## Verify

- Before: zero or more files under `.git/the-works/migrated/<owner>/<repo>`, each
  holding one migration basename; no `.ai/lock.toml`, or one without a `[migrations]`
  table.
- After one run: `.ai/lock.toml` carries exactly one `[migrations]` table with one
  `watermark` line, set to the lexicographically greatest value across every source's
  recorded watermark and (when a local clone exists) that source's own newest present
  migration filename. `.git/the-works/migrated` no longer exists. Any other content
  already in `.ai/lock.toml` is preserved, not overwritten.
- The lying-watermark case: a source recorded behind its clone's actual newest migration
  file ends up contributing its clone's newest filename, not its stale record, and the
  override is printed.
- A second run reports "already carries [migrations] — nothing to do" and changes
  nothing.
- Nothing is written under `.git/` (only removed) and nothing is written under
  `.ai/repositories/` — only `.ai/lock.toml` at the consumer's own root.
