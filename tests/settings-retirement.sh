#!/usr/bin/env bash
# Suite for Decision-061 on the consumer side: kai refuses to lay a settings
# JSON whatever a package ships, and the shipped migration takes back the ones
# already placed — without ever touching a file the operator wrote.
#
#   tests/settings-retirement.sh          run all cases
set -uo pipefail

HERE=$(cd "$(dirname "$0")/.." && pwd)
KAUK="$HERE/bin/kai"
MIG="$HERE/migrations/2026-08-26-04-settings-json-returns-to-the-project.md"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

. "$(dirname "$0")/harness.sh"

git_init() {
  mkdir -p "$1"; git -C "$1" init -q
  git -C "$1" config user.email t@example.com
  git -C "$1" config user.name Test
}
commit_all() { git -C "$1" add -A && git -C "$1" commit -qm "${2:-fixture}"; }
run_migration() { awk '/^```sh$/{f=1;next} /^```$/{f=0} f' "$MIG" | (cd "$1" && bash); }

# A package that still ships a settings JSON, exactly as the old one did.
PKG="$TMP/test/pkg"
git_init "$PKG"
mkdir -p "$PKG/skills/alpha" "$PKG/files/.claude"
printf -- '---\nname: alpha\n---\nb\n' > "$PKG/skills/alpha/SKILL.md"
printf 'name = "pkg"\ntype = "package"\n' > "$PKG/.ai.toml"
printf '{"permissions":{"defaultMode":"auto"}}\n' > "$PKG/files/.claude/settings.json"
printf '{"local":true}\n' > "$PKG/files/.claude/settings.local.json"
printf 'shared rules\n' > "$PKG/files/AGENTS.shared.md"
commit_all "$PKG"

echo "== kai refuses to lay a settings JSON, whatever the package ships =="
CON="$TMP/consumer"
git_init "$CON"; mkdir -p "$CON/.claude"
printf 'placeholder\n' > "$CON/.claude/.keep"
commit_all "$CON"
( cd "$CON" && "$KAUK" install "$PKG" ) >"$TMP/out1" 2>&1 || true
check "settings.json not laid"         '[ ! -e "$CON/.claude/settings.json" ]'
check "settings.local.json not laid"   '[ ! -e "$CON/.claude/settings.local.json" ]'
check "the refusal is announced"       'grep -q "REFUSED .claude/settings.json" "$TMP/out1"'
check "the reason is given"            'grep -q "passed at spawn, never laid" "$TMP/out1"'
check "everything else still lays"     '[ -L "$CON/AGENTS.shared.md" ] && [ -L "$CON/.claude/skills/alpha" ]'
( cd "$CON" && "$KAUK" sync ) >"$TMP/out2" 2>&1 || true
check "a later sync does not lay it"   '[ ! -e "$CON/.claude/settings.json" ]'

echo "== a project's own settings file is never disturbed =="
CONO="$TMP/consumer-owner"
git_init "$CONO"; mkdir -p "$CONO/.claude"
printf '{"mine":"do not touch"}\n' > "$CONO/.claude/settings.json"
commit_all "$CONO"
( cd "$CONO" && "$KAUK" install "$PKG" ) >"$TMP/out3" 2>&1 || true
check "the project file survives sync" 'grep -q "do not touch" "$CONO/.claude/settings.json"'
OUT4=$(run_migration "$CONO" 2>&1)
check "the migration leaves it alone"  'grep -q "do not touch" "$CONO/.claude/settings.json"'
check "and says whose it is"           'printf "%s" "$OUT4" | grep -q "is yours"'

echo "== a package-laid symlink is taken back =="
CONL="$TMP/consumer-link"
git_init "$CONL"; mkdir -p "$CONL/.claude" "$CONL/.ai/repositories/test/pkg/files/.claude"
printf '{"fleet":true}\n' > "$CONL/.ai/repositories/test/pkg/files/.claude/settings.json"
ln -s "$CONL/.ai/repositories/test/pkg/files/.claude/settings.json" "$CONL/.claude/settings.json"
commit_all "$CONL"
OUT5=$(run_migration "$CONL" 2>&1)
check "the laid link is gone"          '[ ! -e "$CONL/.claude/settings.json" ] && [ ! -L "$CONL/.claude/settings.json" ]'
check "the removal is announced"       'printf "%s" "$OUT5" | grep -q "removed the package-laid"'
check "the removal is staged"          'git -C "$CONL" diff --cached --name-only --diff-filter=D | grep -q "settings.json"'
check "a second run has nothing to do" 'run_migration "$CONL" 2>&1 | grep -q "nothing to take back"'

echo "== a symlink kai did not place is left alone =="
CONX="$TMP/consumer-otherlink"
git_init "$CONX"; mkdir -p "$CONX/.claude"
printf '{"elsewhere":true}\n' > "$CONX/elsewhere.json"
ln -s "$CONX/elsewhere.json" "$CONX/.claude/settings.json"
commit_all "$CONX"
OUT6=$(run_migration "$CONX" 2>&1)
check "the foreign link survives"      '[ -L "$CONX/.claude/settings.json" ]'
check "and is reported as not kai's"   'printf "%s" "$OUT6" | grep -q "kai did not place"'

echo "== the file the adoption migration wrote is taken back, an edited one is not =="
FAKEBIN="$TMP/fakebin"
mkdir -p "$FAKEBIN"
cp "$HERE/bin/kai" "$FAKEBIN/kai" 2>/dev/null || printf '#!/bin/sh\n' > "$FAKEBIN/kai"
chmod +x "$FAKEBIN/kai"
cp "$HERE/bin/kai.settings.json" "$FAKEBIN/kai.settings.json"
CONA="$TMP/consumer-adopted"
git_init "$CONA"; mkdir -p "$CONA/.claude"
cp "$HERE/bin/kai.settings.json" "$CONA/.claude/settings.json"
commit_all "$CONA"
OUT7=$(cd "$CONA" && PATH="$FAKEBIN:$PATH" bash -c "$(awk '/^```sh$/{f=1;next} /^```$/{f=0} f' "$MIG")" 2>&1)
check "kai's own unedited file goes"   '[ ! -e "$CONA/.claude/settings.json" ]'
check "and the reason is given"        'printf "%s" "$OUT7" | grep -q "it was kai.s own file, unedited"'

CONE="$TMP/consumer-edited"
git_init "$CONE"; mkdir -p "$CONE/.claude"
cp "$HERE/bin/kai.settings.json" "$CONE/.claude/settings.json"
printf '\n' >> "$CONE/.claude/settings.json"
commit_all "$CONE"
OUT8=$(cd "$CONE" && PATH="$FAKEBIN:$PATH" bash -c "$(awk '/^```sh$/{f=1;next} /^```$/{f=0} f' "$MIG")" 2>&1)
check "one edited byte makes it his"   '[ -f "$CONE/.claude/settings.json" ]'
check "and it is reported as his"      'printf "%s" "$OUT8" | grep -q "is yours"'

echo "== a repository with no settings file at all =="
CONN="$TMP/consumer-none"
git_init "$CONN"; mkdir -p "$CONN/.claude"
commit_all "$CONN" "empty" >/dev/null 2>&1 || true
OUT9=$(run_migration "$CONN" 2>&1)
check "nothing to take back"           'printf "%s" "$OUT9" | grep -q "nothing to take back"'

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
