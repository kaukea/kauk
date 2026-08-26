#!/usr/bin/env bash
# Fixture suite for migrations/2026-08-26-01-one-configuration-file.md: a
# repository configured the old way — [sources."…"] tables, select, ref, a
# package.toml, a .ai/lock.toml — is carried onto the operator's specification
# in one run, and a second run changes nothing.
#
#   tests/config-migration.sh          run all cases
set -uo pipefail

HERE=$(cd "$(dirname "$0")/.." && pwd)
MIG="$HERE/migrations/2026-08-26-01-one-configuration-file.md"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
no()   { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else no "$1"; fi; }

git_init() {
  mkdir -p "$1"; git -C "$1" init -q
  git -C "$1" config user.email t@example.com
  git -C "$1" config user.name Test
}
run_migration() { awk '/^```sh$/{f=1;next} /^```$/{f=0} f' "$MIG" | (cd "$1" && bash); }

echo "== a package configured the old way lands on one file =="
R="$TMP/pkg"
git_init "$R"
cat > "$R/.ai.toml" <<'EOF'
# Yours to edit — this file says what this repository consumes.
# [sources."<owner>/<repo>"] resolves to github.com; [sources."/full/path"] is
# local. Each table may carry select = ["<category-path>", ...]; no select
# means everything. Clones sit at .ai/repositories/<owner>/<repo>/ (gitignored).

[sources."kaukea/orchard"]
select = ["process/orchard", "development"]

[sources."/home/someone/src/thing"]
# a comment the operator wrote inside the table
ref = "v2"

[general]
type = "package"
EOF
cat > "$R/package.toml" <<'EOF'
name = "mypkg"
title = "My Package"
description = "A fixture."
pull-only = true
EOF
mkdir -p "$R/.ai"
printf '# kai own state\n[migrations]\nwatermark = "2026-08-19-04"\n' > "$R/.ai/lock.toml"
git -C "$R" add -A >/dev/null 2>&1; git -C "$R" commit -qm fixture

OUT1=$(run_migration "$R" 2>&1)
printf '%s\n' "$OUT1" | sed 's/^/     /'

check "package.toml is gone"           '[ ! -e "$R/package.toml" ]'
check "its name is the root name"      'grep -qx "name = \"mypkg\"" "$R/.ai.toml"'
check "the package declares its type"  'grep -qx "type = \"package\"" "$R/.ai.toml"'
check "title and description dropped"  '! grep -q "title\|description" "$R/.ai.toml"'
check "pull-only dropped"              '! grep -q "pull-only" "$R/.ai.toml"'
check "no source tables remain"        '! grep -q "\[sources\." "$R/.ai.toml"'
check "no general table remains"       '! grep -q "\[general\]" "$R/.ai.toml"'
check "two dependency blocks"          '[ "$(grep -c "^\[\[dependency\]\]$" "$R/.ai.toml")" = 2 ]'
check "the git source carried over"    'grep -qx "source = \"kaukea/orchard\"" "$R/.ai.toml"'
check "select became include"          'grep -qxF "include = [\"process/orchard\", \"development\"]" "$R/.ai.toml"'
check "the ref joined its source"      'grep -qx "source = \"/home/someone/src/thing@v2\"" "$R/.ai.toml"'
check "no ref key survives"            '! grep -q "^ref = " "$R/.ai.toml"'
check "the operator's comment stayed"  'grep -q "a comment the operator wrote" "$R/.ai.toml"'
check "kai's own header is gone"       '! grep -q "Yours to edit" "$R/.ai.toml"'
check "identity precedes every table"  '[ "$(grep -n "^\[" "$R/.ai.toml" | head -1 | cut -d: -f1)" -gt "$(grep -n "^type = " "$R/.ai.toml" | head -1 | cut -d: -f1)" ]'
check "the date file changed name"     '[ -f "$R/.ai/migrations.toml" ] && [ ! -e "$R/.ai/lock.toml" ]'
check "the date itself is untouched"   'grep -qx "watermark = \"2026-08-19-04\"" "$R/.ai/migrations.toml"'
check "the rewrite is staged"          'git -C "$R" diff --cached --name-only | grep -q "^.ai.toml$"'
check "the removal is staged"          'git -C "$R" diff --cached --name-only --diff-filter=D | grep -q "^package.toml$"'
check "nothing was committed"          '[ "$(git -C "$R" log --oneline | wc -l)" = 1 ]'

echo "== the new reader agrees with what the migration wrote =="
check "kai reads both dependencies"    '[ "$(cd "$R" && "$HERE/bin/kai" sync --status 2>&1 | grep -c "no clone")" = 2 ]'

echo "== a second run changes nothing =="
BEFORE=$(cat "$R/.ai.toml")
OUT2=$(run_migration "$R" 2>&1)
check "second run reports it is done"  'printf "%s" "$OUT2" | grep -q "already on one configuration file"'
check "second run rewrote nothing"     '[ "$(cat "$R/.ai.toml")" = "$BEFORE" ]'

echo "== a plain consumer keeps its shape, and gains no identity it never had =="
C="$TMP/consumer"
git_init "$C"
printf '[sources."kaukea/orchard"]\n' > "$C/.ai.toml"
git -C "$C" add -A >/dev/null 2>&1; git -C "$C" commit -qm fixture
run_migration "$C" >/dev/null 2>&1
check "converted to a dependency"      'grep -qx "source = \"kaukea/orchard\"" "$C/.ai.toml"'
check "no name invented"               '! grep -q "^name = " "$C/.ai.toml"'
check "not declared a package"         '! grep -q "^type = " "$C/.ai.toml"'

echo "== a repository already on the specification is left alone =="
N="$TMP/already"
git_init "$N"
printf 'name = "new"\ntype = "package"\n\n[[dependency]]\nsource = "kaukea/orchard"\ninclude = ["dev"]\n' > "$N/.ai.toml"
git -C "$N" add -A >/dev/null 2>&1; git -C "$N" commit -qm fixture
BEFORE_N=$(cat "$N/.ai.toml")
OUT3=$(run_migration "$N" 2>&1)
check "nothing to do is reported"      'printf "%s" "$OUT3" | grep -q "already on one configuration file"'
check "the file is byte-identical"     '[ "$(cat "$N/.ai.toml")" = "$BEFORE_N" ]'

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
