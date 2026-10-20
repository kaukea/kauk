#!/usr/bin/env bash
# Where no agent is set up, init asks which one will be used
# (docs/package-format.md, Runtime detection). Run without a terminal — by an
# agent — it cannot ask, so it stops and names the flag (operator, 2026-10-21).
# Found by house.sl.oracle: init said done, and sync then laid nothing.
#
# The prompt itself needs a terminal and is not exercised here.
#
#   tests/init-runtime.sh
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
KAI="$ROOT/bin/kai"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

. "$(dirname "$0")/harness.sh"

gi() { mkdir -p "$1"; git -C "$1" init -q; git -C "$1" config user.email t@example.com; git -C "$1" config user.name Test; }

# kai's own package comes from a local copy, never the network
export GIT_CONFIG_GLOBAL="$TMP/gitconfig"
mkdir -p "$TMP/mirror/kaukea"; git clone -q --no-local "$ROOT" "$TMP/mirror/kaukea/kauk"
git config --file "$GIT_CONFIG_GLOBAL" url."$TMP/mirror/".insteadOf https://github.com/

echo "== no agent set up, no terminal: init stops and names the flag =="
gi "$TMP/a"
( cd "$TMP/a" && "$KAI" init --package ) </dev/null >"$TMP/a.out" 2>&1; rc=$?
check "init fails"                    '[ "$rc" -ne 0 ]'
check "it names the flag"             'grep -q -- "--runtime claude" "$TMP/a.out"'
check "it does not say done"          '! grep -q "init: done" "$TMP/a.out"'
check "it writes nothing"             '[ ! -e "$TMP/a/.ai.toml" ] && [ ! -e "$TMP/a/.claude" ]'

echo "== --runtime claude sets the agent up =="
( cd "$TMP/a" && "$KAI" init --package --runtime claude ) </dev/null >"$TMP/b.out" 2>&1; rc=$?
check "init succeeds"                 '[ "$rc" -eq 0 ]'
check ".claude/ is created"           '[ -d "$TMP/a/.claude" ]'
check "and the kai skill is laid"     '[ -e "$TMP/a/.claude/skills/kai/SKILL.md" ]'

echo "== an agent kai does not lay for is refused =="
gi "$TMP/c"
( cd "$TMP/c" && "$KAI" init --runtime=nonesuch ) </dev/null >"$TMP/c.out" 2>&1; rc=$?
check "init fails"                    '[ "$rc" -ne 0 ]'
check "it says claude is the only one" 'grep -q "claude only" "$TMP/c.out"'

echo "== an agent already set up needs no flag =="
gi "$TMP/d"; touch "$TMP/d/CLAUDE.md"
( cd "$TMP/d" && "$KAI" init ) </dev/null >"$TMP/d.out" 2>&1; rc=$?
check "init succeeds"                 '[ "$rc" -eq 0 ]'

summary "init-runtime"
