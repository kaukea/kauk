#!/usr/bin/env bash
# Black-box tests for the session-start store bootstrap in bin/kai-hooks.sh.
#
# The store lives in the git folder, which every worktree of a repository
# shares, and each checkout reaches it through a link inside the ignored
# .ai/repositories/ directory. What these cases have to prove is that the
# arrangement holds in the two places it has always broken: a checkout that
# has never had the store, and a worktree, which git gives nothing because
# the directory holding it is ignored and so never checked out.
#
# Throwaway git repos, file:// origins so nothing touches the network, real
# bin/kai-hooks.sh, check/ok/no.
#
#   tests/store-in-git-folder.sh              run all cases
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
HOOKS="$ROOT/bin/kai-hooks.sh"
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

# A package to depend on: one skill, one agent, so both a directory artifact
# and a file artifact are exercised through the link chain.
make_package() {
  local p=$1
  git_init "$p"
  mkdir -p "$p/skills/enforcing-rules" "$p/agents"
  printf -- '---\nname: enforcing-rules\n---\nSKILL BODY\n' > "$p/skills/enforcing-rules/SKILL.md"
  printf 'AGENT BODY\n' > "$p/agents/gardener.md"
  printf 'name = "orchard"\ntype = "package"\n' > "$p/.ai.toml"
  git -C "$p" add -A && git -C "$p" commit -qm package
}

# A consumer holding exactly what a real one commits: the ignore line, the
# .ai.toml declaration, and the laid links in their short relative form.
make_consumer() {
  local c=$1 origin=$2
  git_init "$c"
  mkdir -p "$c/.claude/skills" "$c/.claude/agents"
  printf '.ai/repositories/\n/.claude/worktrees/\n' > "$c/.gitignore"
  printf '[[dependency]]\nsource = "%s"\n' "$origin" > "$c/.ai.toml"
  ln -s ../../.ai/repositories/kaukea/orchard/skills/enforcing-rules "$c/.claude/skills/enforcing-rules"
  ln -s ../../.ai/repositories/kaukea/orchard/agents/gardener.md "$c/.claude/agents/gardener.md"
  git -C "$c" add -A && git -C "$c" commit -qm consumer
}

run_hook() { (cd "$1" && "$HOOKS" session.start </dev/null 2>"$TMP/err"); }

PKG="$TMP/origins/kaukea/orchard"
make_package "$PKG"
ORIGIN="file://$PKG"

echo "== a checkout that has never had the store bootstraps itself =="
CON="$TMP/con"; make_consumer "$CON" "$ORIGIN"
check "committed link is dead before the hook runs"  '[ ! -e "$CON/.claude/skills/enforcing-rules/SKILL.md" ]'
check "no store directory exists yet"                '[ ! -d "$CON/.git/kai/repositories" ]'
run_hook "$CON"
check "hook exits 0"                                  '[ $? -eq 0 ]'
check "the ignored directory now exists"              '[ -d "$CON/.ai/repositories" ]'
check "it explains itself with a README"              '[ -f "$CON/.ai/repositories/README.md" ]'
check "the README is not committed"                   '[ -z "$(git -C "$CON" ls-files .ai/)" ]'
check "the clone landed in the git folder"            '[ -d "$CON/.git/kai/repositories/kaukea/orchard/.git" ]'
check "the checkout links to that clone"              '[ "$(readlink "$CON/.ai/repositories/kaukea/orchard")" = "$CON/.git/kai/repositories/kaukea/orchard" ]'
check "a skill resolves through the chain"            'grep -q "SKILL BODY" "$CON/.claude/skills/enforcing-rules/SKILL.md"'
check "an agent resolves through the chain"           'grep -q "AGENT BODY" "$CON/.claude/agents/gardener.md"'
check "the tree is clean"                             '[ -z "$(git -C "$CON" status --porcelain)" ]'
check "no incoming clone was left behind"             '[ -z "$(find "$CON/.git/kai" -name "*.incoming.*" 2>/dev/null)" ]'

echo "== a second run changes nothing and does not clone again =="
BEFORE=$(git -C "$CON/.git/kai/repositories/kaukea/orchard" rev-parse HEAD)
STAMP=$(stat -c %Y "$CON/.git/kai/repositories/kaukea/orchard/.git" 2>/dev/null)
run_hook "$CON"
check "the same clone is still in place"              '[ "$(git -C "$CON/.git/kai/repositories/kaukea/orchard" rev-parse HEAD)" = "$BEFORE" ]'
check "it was not re-cloned"                          '[ "$(stat -c %Y "$CON/.git/kai/repositories/kaukea/orchard/.git" 2>/dev/null)" = "$STAMP" ]'
check "the tree is still clean"                       '[ -z "$(git -C "$CON" status --porcelain)" ]'

echo "== a worktree gets the same store without a second clone =="
git -C "$CON" worktree add -q "$CON/.claude/worktrees/feat" -b f/feat HEAD
WT="$CON/.claude/worktrees/feat"
check "git checked out the committed links"           '[ -L "$WT/.claude/skills/enforcing-rules" ]'
check "committed target is identical to the parent's" '[ "$(readlink "$WT/.claude/skills/enforcing-rules")" = "$(readlink "$CON/.claude/skills/enforcing-rules")" ]'
check "and it is dead until the hook runs"            '[ ! -e "$WT/.claude/skills/enforcing-rules/SKILL.md" ]'
run_hook "$WT"
check "a skill resolves in the worktree"              'grep -q "SKILL BODY" "$WT/.claude/skills/enforcing-rules/SKILL.md"'
check "an agent resolves in the worktree"             'grep -q "AGENT BODY" "$WT/.claude/agents/gardener.md"'
check "it reuses the one clone in the git folder"     '[ "$(readlink "$WT/.ai/repositories/kaukea/orchard")" = "$CON/.git/kai/repositories/kaukea/orchard" ]'
check "there is still exactly one clone"              '[ "$(find "$CON/.git/kai/repositories" -maxdepth 3 -name .git | wc -l)" -eq 1 ]'
check "the worktree tree is clean"                    '[ -z "$(git -C "$WT" status --porcelain)" ]'
check "the worktree kept its own branch"              '[ "$(git -C "$WT" rev-parse --abbrev-ref HEAD)" = "f/feat" ]'
check "the parent tree is still clean"                '[ -z "$(git -C "$CON" status --porcelain)" ]'

echo "== the committed link is never rewritten by any of this =="
check "parent link unchanged"                         '[ "$(readlink "$CON/.claude/skills/enforcing-rules")" = "../../.ai/repositories/kaukea/orchard/skills/enforcing-rules" ]'
check "worktree link unchanged"                       '[ "$(readlink "$WT/.claude/skills/enforcing-rules")" = "../../.ai/repositories/kaukea/orchard/skills/enforcing-rules" ]'
check "no committed target names a home directory"    '! git -C "$CON" ls-tree -r HEAD | awk "\$1==\"120000\"{print \$4}" | while read -r f; do git -C "$CON" cat-file -p "HEAD:$f"; echo; done | grep -q "^/"'

echo "== deleting the directory is safe: the next session restores it =="
rm -rf "$CON/.ai"
check "it is gone"                                    '[ ! -d "$CON/.ai/repositories" ]'
run_hook "$CON"
check "restored"                                      '[ -d "$CON/.ai/repositories" ]'
check "the skill resolves again"                      'grep -q "SKILL BODY" "$CON/.claude/skills/enforcing-rules/SKILL.md"'
check "without cloning a second time"                 '[ "$(find "$CON/.git/kai/repositories" -maxdepth 3 -name .git | wc -l)" -eq 1 ]'

echo "== a local-path source is used where it lies, never cloned =="
LOCAL="$TMP/local-pkg"; make_package "$LOCAL"
CON2="$TMP/con2"; git_init "$CON2"
printf '.ai/repositories/\n' > "$CON2/.gitignore"
printf '[[dependency]]\nsource = "%s"\n' "$LOCAL" > "$CON2/.ai.toml"
git -C "$CON2" add -A && git -C "$CON2" commit -qm consumer
run_hook "$CON2"
check "nothing was cloned for it"                     '[ ! -d "$CON2/.git/kai/repositories" ] || [ -z "$(find "$CON2/.git/kai/repositories" -maxdepth 3 -name .git 2>/dev/null)" ]'
check "the directory was still prepared"              '[ -f "$CON2/.ai/repositories/README.md" ]'
check "the tree is clean"                             '[ -z "$(git -C "$CON2" status --porcelain)" ]'

echo "== a real clone already in place is left alone =="
CON3="$TMP/con3"; make_consumer "$CON3" "$ORIGIN"
mkdir -p "$CON3/.ai/repositories/kaukea"
cp -r "$PKG" "$CON3/.ai/repositories/kaukea/orchard"
printf 'HAND PLACED\n' > "$CON3/.ai/repositories/kaukea/orchard/skills/enforcing-rules/SKILL.md"
run_hook "$CON3"
check "it was not replaced by a link"                 '[ ! -L "$CON3/.ai/repositories/kaukea/orchard" ]'
check "its contents were not touched"                 'grep -q "HAND PLACED" "$CON3/.ai/repositories/kaukea/orchard/skills/enforcing-rules/SKILL.md"'

echo "== an unreachable source is reported, and never breaks the session =="
CON4="$TMP/con4"; make_consumer "$CON4" "file://$TMP/does-not-exist"
run_hook "$CON4"; rc=$?
check "the hook still exits 0"                        '[ $rc -eq 0 ]'
check "the failure is named on stderr"                'grep -q "could not be cloned" "$TMP/err"'
check "stderr names the source"                       'grep -q "does-not-exist" "$TMP/err"'
check "no half-written clone was left"                '[ -z "$(find "$CON4/.git/kai" -name "*.incoming.*" 2>/dev/null)" ]'
check "the tree is clean"                             '[ -z "$(git -C "$CON4" status --porcelain)" ]'

echo
printf 'store-in-git-folder: %s/%s passed\n' "$PASS" "$((PASS + FAIL))"
[ "$FAIL" -eq 0 ]
