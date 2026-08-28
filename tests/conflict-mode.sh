#!/usr/bin/env bash
# Black-box tests for what happens when an update cannot finish on its own.
#
# A file of yours where a package has one of its own is not a standoff: the link
# reaches the package's repository, so an edit through it IS an edit of that
# repository, committed there and rebased onto the package's changes like any
# other. Only when both sides moved the same lines does the update stop, and it
# stops by leaving the rebase open — being unfinished is the mode, and git holds
# the state rather than kai keeping a record of its own.
#
# Nothing here is lossy: every version is in a commit, which is what lets --abort
# put things back and lets a side be chosen after the fact.
#
#   tests/conflict-mode.sh
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
KAI="$ROOT/bin/kai"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
no()   { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else no "$1"; fi; }

gi() { mkdir -p "$1"; git -C "$1" init -q; git -C "$1" config user.email t@example.com; git -C "$1" config user.name Test; }

# A consumer already laid against a package, with both sides about to move the
# same line. Returns with $C, $P and $CLONE set.
scenario() {
  local n=$1
  P="$TMP/$n/pkg"; C="$TMP/$n/con"
  gi "$P"; mkdir -p "$P/skills/rules"
  printf 'one\ntwo\nthree\n' > "$P/skills/rules/SKILL.md"
  printf 'name = "p"\ntype = "package"\n' > "$P/.ai.toml"
  git -C "$P" add -A; git -C "$P" commit -qm v1
  gi "$C"; mkdir -p "$C/.claude/skills"
  printf '.ai/repositories/\n' > "$C/.gitignore"
  printf '[[dependency]]\nsource = "file://%s"\n' "$P" > "$C/.ai.toml"
  git -C "$C" add -A; git -C "$C" commit -qm c
  ( cd "$C" && "$KAI" update ) >/dev/null 2>&1
  CLONE=$(cd "$C" && readlink -f .claude/skills/rules | sed 's|/skills/rules$||')
  printf 'one\nMINE\nthree\n' > "$C/.claude/skills/rules/SKILL.md"
  printf 'one\nTHEIRS\nthree\n' > "$P/skills/rules/SKILL.md"
  git -C "$P" add -A; git -C "$P" commit -qm v2
  ( cd "$C" && "$KAI" update ) >"$TMP/$n.out" 2>&1
}
mid_rebase() { [ -d "$1/.git/rebase-merge" ] || [ -d "$1/.git/rebase-apply" ]; }
laid() { cat "$1/.claude/skills/rules/SKILL.md"; }

echo "== an edit through the link reaches the package, and only stops when both moved =="
scenario a
check "the update says it is waiting"       'grep -q "waiting on you" "$TMP/a.out"'
check "the rebase is left open"             'mid_rebase "$CLONE"'
check "both sides are in the file"          'grep -q MINE "$CLONE/skills/rules/SKILL.md" && grep -q THEIRS "$CLONE/skills/rules/SKILL.md"'
check "the package repository is untouched" '[ -z "$(git -C "$P" status --porcelain)" ]'

echo "== asking again says the same thing, and offers the ways out =="
( cd "$C" && "$KAI" update ) >"$TMP/again" 2>&1
check "it does not start another update"    'grep -q "already waiting on you" "$TMP/again"'
check "it names the file"                   'grep -q "skills/rules/SKILL.md" "$TMP/again"'
check "--abort is offered"                  'grep -q -- "--abort" "$TMP/again"'
check "--automerge is offered"              'grep -q -- "--automerge" "$TMP/again"'
check "--resolve is offered"                'grep -q -- "--resolve" "$TMP/again"'
check "it says nothing is lost"             'grep -qi "nothing is lost" "$TMP/again"'

echo "== abort puts it back exactly as it was =="
scenario b
BEFORE_B=$(git -C "$CLONE" rev-parse HEAD)
( cd "$C" && "$KAI" update --abort ) >"$TMP/b.abort" 2>&1
check "the rebase is closed"                '! mid_rebase "$CLONE"'
check "it says what it did"                 'grep -q "put back as it was" "$TMP/b.abort"'
check "your edit is what you see"           '[ "$(laid "$C")" = "$(printf "one\nMINE\nthree")" ]'
( cd "$C" && "$KAI" update --abort ) >"$TMP/b.abort2" 2>&1
check "aborting twice is harmless"          'grep -q "nothing to abort" "$TMP/b.abort2"'

echo "== resolve refuses while markers are still in the files =="
scenario c
( cd "$C" && "$KAI" update --resolve ) >"$TMP/c.res" 2>&1
check "it refuses"                          'grep -q "still carry conflict markers" "$TMP/c.res"'
check "it names the file"                   'grep -q "skills/rules/SKILL.md" "$TMP/c.res"'
check "and the rebase is still open"        'mid_rebase "$CLONE"'

echo "== resolve carries on once you have fixed them =="
printf 'one\nRECONCILED\nthree\n' > "$CLONE/skills/rules/SKILL.md"
( cd "$C" && "$KAI" update --resolve ) >"$TMP/c.res2" 2>&1
check "it resolves"                         'grep -q "resolved at" "$TMP/c.res2"'
check "the rebase is closed"                '! mid_rebase "$CLONE"'
check "your reconciliation is what is laid" '[ "$(laid "$C")" = "$(printf "one\nRECONCILED\nthree")" ]'
check "it sits on top of the package"       'git -C "$CLONE" log --oneline | sed -n 2p | grep -q v2'
( cd "$C" && "$KAI" update --resolve ) >"$TMP/c.res3" 2>&1
check "resolving with nothing open is quiet" 'grep -q "nothing to resolve" "$TMP/c.res3"'

echo "== naming a side settles it without editing anything =="
scenario d
( cd "$C" && "$KAI" update --resolve mine ) >"$TMP/d.mine" 2>&1
check "mine keeps your line"                '[ "$(laid "$C")" = "$(printf "one\nMINE\nthree")" ]'
check "it says which side it took"          'grep -q "took mine" "$TMP/d.mine"'
check "the rebase is closed"                '! mid_rebase "$CLONE"'

scenario e
( cd "$C" && "$KAI" update --resolve theirs ) >"$TMP/e.theirs" 2>&1
check "theirs keeps the package's line"     '[ "$(laid "$C")" = "$(printf "one\nTHEIRS\nthree")" ]'
check "it says which side it took"          'grep -q "took theirs" "$TMP/e.theirs"'
check "the rebase is closed"                '! mid_rebase "$CLONE"'

echo "== a side that is not a side is refused =="
scenario f
( cd "$C" && "$KAI" update --resolve sideways ) >"$TMP/f.bad" 2>&1
check "it is refused"                       'grep -q "takes mine or theirs" "$TMP/f.bad"'
check "and nothing was decided"             'mid_rebase "$CLONE"'

echo "== an update that does not collide never enters the mode =="
scenario g
( cd "$C" && "$KAI" update --resolve theirs ) >/dev/null 2>&1
printf 'one\nTHEIRS\nfour\n' > "$P/skills/rules/SKILL.md"
git -C "$P" add -A; git -C "$P" commit -qm v3
( cd "$C" && "$KAI" update ) >"$TMP/g.out" 2>&1
check "it just updates"                     '! grep -q "waiting on you" "$TMP/g.out"'
check "the rebase never opened"             '! mid_rebase "$CLONE"'
check "the new version is laid"             'grep -q four "$C/.claude/skills/rules/SKILL.md"'

echo
printf 'conflict-mode: %s/%s passed\n' "$PASS" "$((PASS + FAIL))"
[ "$FAIL" -eq 0 ]
