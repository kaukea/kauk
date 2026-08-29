#!/usr/bin/env bash
# The two commands you would want to trust while nobody is watching.
#
# `--status` promises to report and write nothing. It is what somebody reaches
# for before deciding whether to act, so writing while claiming not to is worse
# than not existing. It laid every artifact until 2026-08-29; nothing checked.
#
# `--push` is the only command that writes into a repository other than the one
# it is run in. It had no assertion of any kind against it.
#
#   tests/status-and-push.sh
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
KAI="$ROOT/bin/kai"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

. "$(dirname "$0")/harness.sh"

gi() { mkdir -p "$1"; git -C "$1" init -q; git -C "$1" config user.email t@example.com; git -C "$1" config user.name Test; }

# a package with somewhere to push back to: a bare origin the clone can publish into
scenario() {
  local n=$1
  ORIGIN="$TMP/$n/origin.git"; P="$TMP/$n/pkg"; C="$TMP/$n/con"
  gi "$P"; mkdir -p "$P/skills/one"
  printf -- '---\nname: one\n---\nORIGINAL\n' > "$P/skills/one/SKILL.md"
  printf 'name = "p"\ntype = "package"\n' > "$P/.ai.toml"
  git -C "$P" add -A; git -C "$P" commit -qm v1
  git -C "$P" branch -M main
  git init -q --bare "$ORIGIN"
  git -C "$P" remote add origin "$ORIGIN"; git -C "$P" push -q origin main
  gi "$C"; mkdir -p "$C/.claude"
  printf '.ai/repositories/\n' > "$C/.gitignore"
  printf '[[dependency]]\nsource = "%s"\n' "$ORIGIN" > "$C/.ai.toml"
  git -C "$C" add -A; git -C "$C" commit -qm c
  ( cd "$C" && "$KAI" update ) >/dev/null 2>&1
  CLONE=$(cd "$C" && readlink -f .claude/skills/one | sed 's|/skills/one$||')
}
published() { git --git-dir="$ORIGIN" show main:skills/one/SKILL.md 2>/dev/null; }

echo "== --status reports and writes nothing =="
scenario a
BEFORE_LAID=$(ls "$C/.claude/skills" 2>/dev/null)
rm -rf "$C/.claude/skills"
( cd "$C" && "$KAI" update --status ) >"$TMP/a.out" 2>&1
check "it says what it found"                'grep -q "incoming" "$TMP/a.out"'
check "REGRESSION: it lays nothing"          '[ ! -d "$C/.claude/skills" ]'
check "and a real update still does"         '( cd "$C" && "$KAI" update ) >/dev/null 2>&1; [ "$(ls "$C/.claude/skills")" = "$BEFORE_LAID" ]'

scenario b
printf 'AN EDIT\n' > "$C/.claude/skills/one/SKILL.md"
BEFORE_HEAD=$(git -C "$CLONE" rev-parse HEAD)
( cd "$C" && "$KAI" update --status ) >"$TMP/b.out" 2>&1
check "it does not commit a local edit"      '[ "$(git -C "$CLONE" rev-parse HEAD)" = "$BEFORE_HEAD" ]'
check "the edit is still uncommitted"        '[ -n "$(git -C "$CLONE" status --porcelain)" ]'
check "and it reports the edit"              'grep -q "1 uncommitted" "$TMP/b.out"'
check "it publishes nothing"                 '[ "$(published)" = "$(printf -- "---\nname: one\n---\nORIGINAL")" ]'

echo "== an update never publishes, however much has changed locally =="
scenario c
printf 'MINE\n' > "$C/.claude/skills/one/SKILL.md"
( cd "$C" && "$KAI" update ) >/dev/null 2>&1
check "the edit is committed in the clone"   '[ -n "$(git -C "$CLONE" log --oneline --grep="local edits, preserved")" ]'
check "but nothing reached the source"       '[ "$(published)" = "$(printf -- "---\nname: one\n---\nORIGINAL")" ]'

echo "== --push publishes exactly what was edited, and nothing else =="
scenario d
printf 'PUBLISHED BY PUSH\n' > "$C/.claude/skills/one/SKILL.md"
( cd "$C" && "$KAI" update --push ) >"$TMP/d.out" 2>&1
check "the source now carries the edit"      '[ "$(published)" = "PUBLISHED BY PUSH" ]'
check "it says what it published"            'grep -q "published" "$TMP/d.out"'
check "the consumer still resolves it"       'grep -q "PUBLISHED BY PUSH" "$C/.claude/skills/one/SKILL.md"'

echo "== --push sends nothing when there is nothing to send =="
scenario e
BEFORE_E=$(git --git-dir="$ORIGIN" rev-parse main)
( cd "$C" && "$KAI" update --push ) >"$TMP/e.out" 2>&1
check "the source is untouched"              '[ "$(git --git-dir="$ORIGIN" rev-parse main)" = "$BEFORE_E" ]'

echo "== --push and --pull cannot be asked for together =="
scenario f
BEFORE_F=$(git --git-dir="$ORIGIN" rev-parse main)
printf 'SHOULD NOT SHIP\n' > "$C/.claude/skills/one/SKILL.md"
( cd "$C" && "$KAI" update --pull --push ) >"$TMP/f.out" 2>&1
check "it is refused"                        'grep -q "taking and giving are separate acts" "$TMP/f.out"'
check "and nothing was published"            '[ "$(git --git-dir="$ORIGIN" rev-parse main)" = "$BEFORE_F" ]'

echo
printf 'status-and-push: %s/%s passed\n' "$PASS" "$((PASS + FAIL))"
[ "$FAIL" -eq 0 ]
