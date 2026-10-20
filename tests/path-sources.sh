#!/usr/bin/env bash
# A local path source is a git repository, cloned like any other (operator,
# 2026-10-21). It has no owner, so its clone is named after its path relative to
# the repository that declares it. Found by house.sl.oracle: a path with no
# commit was cloned empty and called "not a kai package", and the next update
# called the empty clone a conflict when the source got its first commit.
#
#   tests/path-sources.sh
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
KAI="$ROOT/bin/kai"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

. "$(dirname "$0")/harness.sh"

gi() { mkdir -p "$1"; git -C "$1" init -q; git -C "$1" config user.email t@example.com; git -C "$1" config user.name Test; }
skill() { mkdir -p "$1/skills/$2"; printf -- '---\nname: %s\n---\nbody\n' "$2" > "$1/skills/$2/SKILL.md"; }
consumer() { gi "$1"; mkdir -p "$1/.claude"; touch "$1/CLAUDE.md"; git -C "$1" add -A; git -C "$1" commit -qm c; }

echo "== a path that is not a git repository is refused =="
mkdir -p "$TMP/plain"; skill "$TMP/plain" one
consumer "$TMP/c1"
( cd "$TMP/c1" && "$KAI" install ../plain ) >"$TMP/o1" 2>&1; rc=$?
check "install fails"                  '[ "$rc" -ne 0 ]'
check "it says it is not a git repository" 'grep -q "is not a git repository" "$TMP/o1"'
check "and declares nothing"           '! grep -q "plain" "$TMP/c1/.ai.toml"'

echo "== a git repository with no commit is refused =="
gi "$TMP/fresh"; skill "$TMP/fresh" one
( cd "$TMP/c1" && "$KAI" install ../fresh ) >"$TMP/o2" 2>&1; rc=$?
check "install fails"                  '[ "$rc" -ne 0 ]'
check "it says there are no commits"   'grep -q "has no commits yet" "$TMP/o2"'
check "and declares nothing"           '! grep -q "fresh" "$TMP/c1/.ai.toml"'

echo "== a committed path is cloned under its relative path =="
git -C "$TMP/fresh" add -A; git -C "$TMP/fresh" commit -qm v1
( cd "$TMP/c1" && "$KAI" install ../fresh ) >"$TMP/o3" 2>&1; rc=$?
check "install succeeds"               '[ "$rc" -eq 0 ]'
check "the clone is named after the path" '[ -d "$TMP/c1/.ai/repositories/path/%2E%2E%2Ffresh/.git" ]'
check "no owner is invented for it"    '[ ! -e "$TMP/c1/.ai/repositories/$(basename "$TMP")" ]'
check "the skill is laid"              '[ -e "$TMP/c1/.claude/skills/one/SKILL.md" ]'
skill "$TMP/fresh" uncommitted
( cd "$TMP/c1" && "$KAI" update ) >"$TMP/o4" 2>&1
check "what is not committed is not taken" '[ ! -e "$TMP/c1/.claude/skills/uncommitted" ]'

echo "== a source that was empty when installed is taken once it has a commit =="
git init -q --bare "$TMP/empty.git"
consumer "$TMP/c2"
( cd "$TMP/c2" && "$KAI" install "file://$TMP/empty.git" ) >"$TMP/o5" 2>&1; rc=$?
check "install fails"                  '[ "$rc" -ne 0 ]'
check "it says there are no commits"   'grep -q "no commits yet" "$TMP/o5"'
check "not that it is not a package"   '! grep -q "does not look like a kai package" "$TMP/o5"'
gi "$TMP/author"; skill "$TMP/author" two
git -C "$TMP/author" add -A; git -C "$TMP/author" commit -qm v1; git -C "$TMP/author" branch -M main
git -C "$TMP/author" push -q "$TMP/empty.git" main
( cd "$TMP/c2" && "$KAI" update ) >"$TMP/o6" 2>&1
check "no conflict is reported"        '! grep -q "both changed the same lines" "$TMP/o6"'
check "the first commit is laid"       '[ -e "$TMP/c2/.claude/skills/two/SKILL.md" ]'

summary "path-sources"
