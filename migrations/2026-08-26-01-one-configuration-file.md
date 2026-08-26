# One configuration file: package.toml folds into .ai.toml

The operator wrote the configuration specification by hand on 2026-08-21
(`docs/configuration-files.md`). A repository has ONE configuration file,
`.ai.toml` at its root, and that file says both what the repository is and what
it consumes:

```toml
name = "orchard"
type = "package"

[[dependency]]
source = "kaukea/orchard"
include = ["process/orchard", "development"]
```

Three things change for a repository that was configured the old way:

- `[sources."<owner>/<repo>"]` tables become `[[dependency]]` entries carrying
  `source = "…"`. A `ref = "x"` key, which used to sit beside the source, joins
  the source itself as `source = "…@x"`.
- `select` is called `include`.
- `package.toml` is deleted. Its `name` becomes the root-table `name` of
  `.ai.toml`, and the repository declares itself with `type = "package"` there.
  Its `title`, `description` and `pull-only` keys are dropped: the first two
  were never read for anything, and whether a clone pushes back is a decision
  taken at the command, not a property of the package.

The file recording which migrations have already run also changes name, from
`.ai/lock.toml` to `.ai/migrations.toml`, with its content untouched. Versions,
tags and pins are deferred whole and the word "lock" belongs to that work; the
file only ever held the migration date.

Nothing here touches `.ai/repositories/`, and nothing is committed — the
rewritten files are staged, and the repository's own workflow commits them.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
cd "$root"

changed=0

if [ -f .ai/lock.toml ] && [ ! -f .ai/migrations.toml ]; then
  mv .ai/lock.toml .ai/migrations.toml
  git add -A -- .ai/migrations.toml .ai/lock.toml 2>/dev/null || true
  echo "  migration date file moved to .ai/migrations.toml"
  changed=1
fi

pkgname=""
ispkg=0
if [ -f package.toml ]; then
  pkgname=$(sed -n 's/^name[[:space:]]*=[[:space:]]*"\(.*\)".*/\1/p' package.toml | head -1)
  ispkg=1
fi

needs_rewrite=0
if [ -f .ai.toml ]; then
  grep -q '^[[:space:]]*\[sources\."' .ai.toml && needs_rewrite=1
  grep -q '^[[:space:]]*\[general\]' .ai.toml && needs_rewrite=1
  [ "$ispkg" = 1 ] && needs_rewrite=1
fi

if [ "$needs_rewrite" = 1 ]; then
  awk -v PKGNAME="$pkgname" -v ISPKG="$ispkg" '
    BEGIN { sect = "root" }

    NR == 1 && /^# Yours to edit/ { drop = 1; next }
    drop && /^#/                  { next }
    { drop = 0 }

    cont {
      line = line "\n" $0
      if ($0 ~ /\]/) { dinc[nd] = line; cont = 0 }
      next
    }

    /^[[:space:]]*\[general\][[:space:]]*$/ { sect = "general"; next }

    /^[[:space:]]*\[sources\."/ {
      s = $0
      sub(/^[[:space:]]*\[sources\."/, "", s)
      sub(/"\].*$/, "", s)
      nd++
      dsrc[nd] = s
      sect = "dep"
      next
    }

    /^[[:space:]]*\[/ { sect = "other"; other[++no] = $0; next }

    sect == "root"    { root[++nr] = $0; next }
    sect == "other"   { other[++no] = $0; next }

    sect == "general" {
      if ($0 ~ /^[[:space:]]*type[[:space:]]*=/ && $0 ~ /package/) gpkg = 1
      next
    }

    sect == "dep" {
      line = $0
      if (line ~ /^[[:space:]]*origin[[:space:]]*=/) next
      if (line ~ /^[[:space:]]*ref[[:space:]]*=/) {
        v = line
        sub(/^[^=]*=[[:space:]]*/, "", v)
        gsub(/[ \t"]/, "", v)
        if (v != "") dref[nd] = v
        next
      }
      if (line ~ /^[[:space:]]*select[[:space:]]*=/ || line ~ /^[[:space:]]*include[[:space:]]*=/) {
        sub(/select[[:space:]]*=/, "include =", line)
        if (line ~ /\]/) { dinc[nd] = line } else { cont = 1 }
        next
      }
      extra[nd] = extra[nd] line "\n"
      next
    }

    END {
      for (i = 1; i <= nr; i++) {
        if (root[i] ~ /^[[:space:]]*name[[:space:]]*=/) hasname = 1
        if (root[i] ~ /^[[:space:]]*type[[:space:]]*=/) hastype = 1
        if (root[i] ~ /[^ \t]/) last = i
      }
      for (i = 1; i <= last; i++) { print root[i]; wrote = 1 }
      if (!hasname && PKGNAME != "") { print "name = \"" PKGNAME "\""; wrote = 1 }
      if (!hastype && (gpkg || ISPKG == "1")) { print "type = \"package\""; wrote = 1 }
      for (i = 1; i <= nd; i++) {
        if (wrote) print ""
        wrote = 1
        print "[[dependency]]"
        s = dsrc[i]
        if (dref[i] != "") s = s "@" dref[i]
        print "source = \"" s "\""
        if (dinc[i] != "") print dinc[i]
        if (extra[i] != "") printf "%s", extra[i]
      }
      for (i = 1; i <= no; i++) print other[i]
    }
  ' .ai.toml > .ai.toml.kai-new
  mv .ai.toml.kai-new .ai.toml
  git add -- .ai.toml 2>/dev/null || true
  echo "  .ai.toml rewritten: dependency blocks, include lists, root-table identity"
  changed=1
elif [ ! -f .ai.toml ] && [ "$ispkg" = 1 ]; then
  { [ -n "$pkgname" ] && printf 'name = "%s"\n' "$pkgname"
    printf 'type = "package"\n'
  } > .ai.toml
  git add -- .ai.toml 2>/dev/null || true
  echo "  .ai.toml written with this package identity"
  changed=1
fi

if [ -f package.toml ]; then
  rm -f package.toml
  git add -A -- package.toml 2>/dev/null || true
  echo "  package.toml removed"
  changed=1
fi

[ "$changed" = 1 ] || echo "  already on one configuration file"
exit 0
```

## Verify

- Before: a `.ai.toml` holding `[sources."…"]` tables, possibly with `select`,
  `ref` or `origin` keys and a `[general]` table; possibly a `package.toml`;
  possibly a `.ai/lock.toml`.
- After one run: `.ai.toml` opens with the root table (`name` and
  `type = "package"` for a package, whatever the operator already wrote
  otherwise), followed by one `[[dependency]]` block per former source, each
  with `source = "…"` (carrying `@ref` if a `ref` key was there) and `include`
  where `select` was. Comments and unknown keys inside a source table are kept.
  Tables other than sources and `[general]` are kept as they were.
- `package.toml` is gone; `.ai/lock.toml` is now `.ai/migrations.toml` with the
  same content.
- A second run prints "already on one configuration file" and changes nothing.
- Nothing under `.ai/repositories/` is read or written, and nothing is committed.
