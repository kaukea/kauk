#!/usr/bin/env bash
# Black-box tests for the migrations-at-sync feature (Decision-055) and the
# stale-laid-links repoint/orphan scan it ships alongside. Same style as
# tests/convention-reader.sh: throwaway git repos, real bin/kai, check/ok/no.
#
#   tests/migrations-at-sync.sh          run all cases
set -uo pipefail

KAUK=$(cd "$(dirname "$0")/.." && pwd)/bin/kai
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
commit_all() { git -C "$1" add -A && git -C "$1" commit -qm "${2:-fixture}"; }
pkg_toml() { # pkg_toml <dir> <name>
  cat > "$1/package.toml" <<EOF
name = "$2"
title = "$2"
description = "fixture"
EOF
}

echo "== two sources, interleaved migration dates: both migrate, per-package order =="
PKGA="$TMP/test/pkga"; PKGB="$TMP/test/pkgb"
git_init "$PKGA"; mkdir -p "$PKGA/skills/a1" "$PKGA/migrations"
printf -- '---\nname: a1\n---\na\n' > "$PKGA/skills/a1/SKILL.md"
pkg_toml "$PKGA" pkga
printf '# a-early\n\n```sh\ntouch a-early\n```\n' > "$PKGA/migrations/2026-05-01-a1.md"
printf '# a-late\n\n```sh\ntouch a-late\n```\n'  > "$PKGA/migrations/2026-05-03-a3.md"
commit_all "$PKGA"
git_init "$PKGB"; mkdir -p "$PKGB/skills/b1" "$PKGB/migrations"
printf -- '---\nname: b1\n---\nb\n' > "$PKGB/skills/b1/SKILL.md"
pkg_toml "$PKGB" pkgb
printf '# b-mid\n\n```sh\ntouch b-mid\n```\n' > "$PKGB/migrations/2026-05-02-b1.md"
commit_all "$PKGB"
CON1="$TMP/consumer1"; git_init "$CON1"; mkdir -p "$CON1/.claude"; printf "placeholder\n" > "$CON1/.claude/.keep"; commit_all "$CON1"
( cd "$CON1" && "$KAUK" install "$PKGA" && "$KAUK" install "$PKGB" && "$KAUK" sync ) >"$TMP/out1" 2>&1 || true
check "pkga early migration ran"       '[ -f "$CON1/a-early" ]'
check "pkga late migration ran"        '[ -f "$CON1/a-late" ]'
check "pkgb migration ran"             '[ -f "$CON1/b-mid" ]'
check "pkga watermark at its latest"   'grep -q "2026-05-03-a3" "$CON1/.git/the-works/migrated/test/pkga"'
check "pkgb watermark at its own"      'grep -q "2026-05-02-b1" "$CON1/.git/the-works/migrated/test/pkgb"'

echo "== re-running kai sync is a no-op: no migration step re-executes =="
PKGC="$TMP/test/pkgc"; git_init "$PKGC"; mkdir -p "$PKGC/skills/c1"
printf -- '---\nname: c1\n---\nc\n' > "$PKGC/skills/c1/SKILL.md"
pkg_toml "$PKGC" pkgc
commit_all "$PKGC"
CON2="$TMP/consumer2"; git_init "$CON2"; mkdir -p "$CON2/.claude"; printf "placeholder\n" > "$CON2/.claude/.keep"; commit_all "$CON2"
( cd "$CON2" && "$KAUK" install "$PKGC" ) >/dev/null 2>&1 || true
mkdir -p "$PKGC/migrations"
printf '# append\n\n```sh\nprintf "ran\\n" >> append.log\n```\n' > "$PKGC/migrations/2026-06-01-append.md"
commit_all "$PKGC" "add append migration"
( cd "$CON2" && "$KAUK" sync ) >"$TMP/out2a" 2>&1 || true
( cd "$CON2" && "$KAUK" sync ) >"$TMP/out2b" 2>&1 || true
check "migration ran exactly once across two syncs" '[ "$(wc -l < "$CON2/append.log" 2>/dev/null | tr -d " ")" = "1" ]'
check "laid state unchanged"           '[ -L "$CON2/.claude/skills/c1" ]'

echo "== a scripted step applied twice by force is idempotent =="
PKGD="$TMP/test/pkgd"; git_init "$PKGD"; mkdir -p "$PKGD/skills/d1" "$PKGD/migrations"
printf -- '---\nname: d1\n---\nd\n' > "$PKGD/skills/d1/SKILL.md"
pkg_toml "$PKGD" pkgd
printf '# state-guarded flag\n\n```sh\ngrep -q "^flag=on$" guard.cfg 2>/dev/null || echo "flag=on" >> guard.cfg\n```\n' \
  > "$PKGD/migrations/2026-06-05-guard.md"
commit_all "$PKGD"
CON3="$TMP/consumer3"; git_init "$CON3"; mkdir -p "$CON3/.claude"; printf "placeholder\n" > "$CON3/.claude/.keep"; commit_all "$CON3"
( cd "$CON3" && "$KAUK" install "$PKGD" && "$KAUK" sync ) >"$TMP/out3a" 2>&1 || true
FIRST=$(cat "$CON3/guard.cfg" 2>/dev/null || echo MISSING)
rm -f "$CON3/.git/the-works/migrated/test/pkgd"
( cd "$CON3" && "$KAUK" sync ) >"$TMP/out3b" 2>&1 || true
SECOND=$(cat "$CON3/guard.cfg" 2>/dev/null || echo MISSING)
check "first application set the flag" '[ "$FIRST" = "flag=on" ]'
check "forced second application is idempotent (same observable state)" \
  '[ "$SECOND" = "flag=on" ] && [ "$(grep -c "^flag=on$" "$CON3/guard.cfg" 2>/dev/null)" = "1" ]'

echo "== order around the rebase: pending-before-rebase, arriving-after-rebase =="
PKGE="$TMP/test/pkge"; git_init "$PKGE"; mkdir -p "$PKGE/skills/e1" "$PKGE/migrations"
printf -- '---\nname: e1\n---\ne\n' > "$PKGE/skills/e1/SKILL.md"
pkg_toml "$PKGE" pkge
printf 'orig\n' > "$PKGE/marker.txt"
cat > "$PKGE/migrations/2026-04-01-early.md" <<'EOF'
# early — already pending in the clone before this sync

```sh
root=$(git rev-parse --show-toplevel); cd "$root"
f=".ai/repositories/test/pkge/marker.txt"
if [ -f "$f" ] && grep -q LOCAL-EDIT "$f"; then
  echo "M1-after-edit" >> order.log
else
  echo "M1-before-edit" >> order.log
fi
```
EOF
commit_all "$PKGE"
CONE="$TMP/consumer-order"; git_init "$CONE"; mkdir -p "$CONE/.claude"; printf "placeholder\n" > "$CONE/.claude/.keep"; commit_all "$CONE"
( cd "$CONE" && "$KAUK" install "$PKGE" ) >/dev/null 2>&1 || true
printf 'LOCAL-EDIT\n' >> "$CONE/.ai/repositories/test/pkge/marker.txt"
cat > "$PKGE/migrations/2026-04-02-late.md" <<'EOF'
# late — arrives with this pull

```sh
root=$(git rev-parse --show-toplevel); cd "$root"
f=".ai/repositories/test/pkge/marker.txt"
if [ -f "$f" ] && grep -q LOCAL-EDIT "$f"; then
  echo "M2-after-edit" >> order.log
else
  echo "M2-before-edit" >> order.log
fi
```
EOF
commit_all "$PKGE" "late migration arrives"
( cd "$CONE" && "$KAUK" sync ) >"$TMP/out4" 2>&1 || true
check "pre-existing migration ran BEFORE the local edit replayed" \
  'head -1 "$CONE/order.log" 2>/dev/null | grep -q "M1-before-edit"'
check "newly-arrived migration ran AFTER the rebase"              \
  'tail -1 "$CONE/order.log" 2>/dev/null | grep -q "M2-after-edit"'
check "the local edit itself survived the rebase"                 \
  'grep -q LOCAL-EDIT "$CONE/.ai/repositories/test/pkge/marker.txt"'

echo "== self-source: a repo's own pending migration applies via plain kai sync =="
SELF="$TMP/test/selfpkg2"; git_init "$SELF"
mkdir -p "$SELF/skills/own2" "$SELF/.claude" "$SELF/migrations"
printf -- '---\nname: own2\n---\nself\n' > "$SELF/skills/own2/SKILL.md"
pkg_toml "$SELF" selfpkg2
printf '# self migration\n\n```sh\ntouch self-mig-ran\n```\n' > "$SELF/migrations/2026-07-01-selfmig.md"
cat > "$SELF/.ai.toml" <<EOF
[sources."$SELF"]
EOF
commit_all "$SELF"
( cd "$SELF" && "$KAUK" sync ) >"$TMP/out5" 2>&1 || true
check "self-source's own migration ran, no agent, no manual step" '[ -f "$SELF/self-mig-ran" ]'
check "self-source has its own per-repo watermark"                \
  'grep -q "2026-07-01-selfmig" "$SELF/.git/the-works/migrated/test/selfpkg2"'

echo "== an applied-by: agent step is not executed and is recorded as an ask =="
PKGF="$TMP/test/pkgagent"; git_init "$PKGF"; mkdir -p "$PKGF/skills/f1" "$PKGF/migrations"
printf -- '---\nname: f1\n---\nf\n' > "$PKGF/skills/f1/SKILL.md"
pkg_toml "$PKGF" pkgagent
cat > "$PKGF/migrations/2026-07-10-agentstep.md" <<'EOF'
# mixed step: one scripted, one agent-only

```sh
touch shell-step-ran
```

```applied-by:agent
touch agent-step-ran
```

Rename the legacy widget id by hand — kai cannot infer the mapping safely.
EOF
commit_all "$PKGF"
CON6="$TMP/consumer-agent"; git_init "$CON6"; mkdir -p "$CON6/.claude"; printf "placeholder\n" > "$CON6/.claude/.keep"; commit_all "$CON6"
( cd "$CON6" && "$KAUK" install "$PKGF" && "$KAUK" sync ) >"$TMP/out6" 2>&1 || true
check "the scripted fence ran"                 '[ -f "$CON6/shell-step-ran" ]'
check "the applied-by:agent fence did NOT run" '[ ! -f "$CON6/agent-step-ran" ]'
check "TODO outstanding ask recorded under .git/the-works/ (path not yet ratified)" \
  '[ -d "$CON6/.git/the-works" ] && find "$CON6/.git/the-works" -type f -not -path "*/the-works/migrated/*" 2>/dev/null | xargs -I{} grep -l "2026-07-10-agentstep\|agent-step-ran\|applied-by" {} 2>/dev/null | grep -q .'

echo "== stale links: a renamed source repoints, a true orphan is removed =="
PKGG="$TMP/test/pkgg"; git_init "$PKGG"; mkdir -p "$PKGG/skills/gfoo"
printf -- '---\nname: gfoo\n---\ng\n' > "$PKGG/skills/gfoo/SKILL.md"
pkg_toml "$PKGG" pkgg
commit_all "$PKGG"
PKGH="$TMP/test/pkgh"; git_init "$PKGH"; mkdir -p "$PKGH/skills/horph"
printf -- '---\nname: horph\n---\nh\n' > "$PKGH/skills/horph/SKILL.md"
pkg_toml "$PKGH" pkgh
commit_all "$PKGH"
CON7="$TMP/consumer-stale"; git_init "$CON7"; mkdir -p "$CON7/.claude"; printf "placeholder\n" > "$CON7/.claude/.keep"; commit_all "$CON7"
( cd "$CON7" && "$KAUK" install "$PKGG" && "$KAUK" install "$PKGH" ) >/dev/null 2>&1 || true
check "setup: gfoo laid before the rename"     '[ -L "$CON7/.claude/skills/gfoo" ]'
check "setup: horph laid before removal"       '[ -L "$CON7/.claude/skills/horph" ]'
# Rename pkgg's identity: move the source, repoint .ai.toml, drop the old clone.
mv "$PKGG" "$TMP/test/pkgg-ren"
sed -i "s|$PKGG|$TMP/test/pkgg-ren|" "$CON7/.ai.toml"
rm -rf "$CON7/.ai/repositories/test/pkgg"
# True orphan: pkgh drops out of .ai.toml entirely, and its clone is gone too —
# no source anywhere still carries a skills/horph tail.
sed -i '\|\[sources\."'"$PKGH"'"\]|d' "$CON7/.ai.toml"
rm -rf "$CON7/.ai/repositories/test/pkgh"
( cd "$CON7" && "$KAUK" sync ) >"$TMP/out7" 2>&1 || true
check "renamed source's link resolves into the new store path" \
  '[ -e "$CON7/.claude/skills/gfoo" ] && readlink "$CON7/.claude/skills/gfoo" | grep -q "test/pkgg-ren"'
check "no dangling link into .ai/repositories/ remains" \
  '[ -z "$(find "$CON7/.claude" -type l ! -exec test -e {} \; -print 2>/dev/null)" ]'
check "a link whose tail exists in no source is removed as an orphan" \
  '[ ! -e "$CON7/.claude/skills/horph" ] && [ ! -L "$CON7/.claude/skills/horph" ]'

echo "== regression: a normal install from a local path still lays every skill =="
PKGI="$TMP/test/pkgi"; git_init "$PKGI"
mkdir -p "$PKGI/skills/i1" "$PKGI/agents" "$PKGI/hooks" "$PKGI/tools" "$PKGI/files"
printf -- '---\nname: i1\n---\ni\n'  > "$PKGI/skills/i1/SKILL.md"
printf -- '---\nname: ia\n---\np\n'  > "$PKGI/agents/ia.md"
printf '#!/bin/sh\necho hi\n'        > "$PKGI/hooks/ih.sh"
printf 'print(1)\n'                  > "$PKGI/tools/it.py"
printf 'shared\n'                    > "$PKGI/files/AGENTS.shared.md"
pkg_toml "$PKGI" pkgi
commit_all "$PKGI"
CON8="$TMP/consumer-regress"; git_init "$CON8"; mkdir -p "$CON8/.claude"; printf "placeholder\n" > "$CON8/.claude/.keep"; commit_all "$CON8"
( cd "$CON8" && "$KAUK" install "$PKGI" ) >"$TMP/out8" 2>&1 || true
check "skill laid"  '[ -L "$CON8/.claude/skills/i1" ]'
check "agent laid"  '[ -L "$CON8/.claude/agents/ia.md" ]'
check "hook laid"   '[ -L "$CON8/.claude/hooks/ih.sh" ]'
check "tool laid"   '[ -L "$CON8/.claude/tools/it.py" ]'
check "files/ mirrored to repo root" '[ -L "$CON8/AGENTS.shared.md" ]'

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
