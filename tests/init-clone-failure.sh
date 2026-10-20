#!/usr/bin/env bash
# `kai init` installs kai's own package, kaukea/kauk, into the repository. When
# that clone failed it printed a warning, then "init: done" and exited 0, so a
# repository was left without the kai skill and nothing said it was broken
# (found by house.sl.oracle on 2026-10-21, against an unreadable GitHub).
#
# GitHub is redirected with a throwaway git config, so nothing leaves the machine.
#
#   tests/init-clone-failure.sh
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
KAI="$ROOT/bin/kai"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

. "$(dirname "$0")/harness.sh"

gi() { mkdir -p "$1"; git -C "$1" init -q; git -C "$1" config user.email t@example.com; git -C "$1" config user.name Test; }

export GIT_CONFIG_GLOBAL="$TMP/gitconfig"

echo "== the kai package cannot be cloned =="
git config --file "$GIT_CONFIG_GLOBAL" url."$TMP/nowhere/".insteadOf https://github.com/
gi "$TMP/a"; mkdir -p "$TMP/a/.claude"
( cd "$TMP/a" && "$KAI" init --package ) >"$TMP/a.out" 2>&1; rc=$?
check "init fails"                          '[ "$rc" -ne 0 ]'
check "it does not say done"                '! grep -q "init: done" "$TMP/a.out"'
check "it says init is not done, and why"   'grep -q "init: not done" "$TMP/a.out"'
check "git's own reason is shown"           'grep -q "git: " "$TMP/a.out"'

echo "== the kai package can be cloned =="
git config --file "$GIT_CONFIG_GLOBAL" --unset-all url."$TMP/nowhere/".insteadOf
mkdir -p "$TMP/mirror/kaukea"
git clone -q --no-local "$ROOT" "$TMP/mirror/kaukea/kauk"
git config --file "$GIT_CONFIG_GLOBAL" url."$TMP/mirror/".insteadOf https://github.com/
gi "$TMP/b"; mkdir -p "$TMP/b/.claude"
( cd "$TMP/b" && "$KAI" init ) >"$TMP/b.out" 2>&1; rc=$?
check "init succeeds"                       '[ "$rc" -eq 0 ]'
check "and says done"                       'grep -q "init: done" "$TMP/b.out"'

summary "init-clone-failure"
