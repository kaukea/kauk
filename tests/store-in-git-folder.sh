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
KAI="$ROOT/bin/kai"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

. "$(dirname "$0")/harness.sh"

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

# same fence extraction the migration engine itself uses
run_migration() { awk '/^```sh$/{b=1;next} /^```/{b=0} b' "$1" | (cd "$2" && bash); }

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
check "the checkout links to that clone"              '[ -L "$CON/.ai/repositories/kaukea/orchard" ] && [ "$CON/.ai/repositories/kaukea/orchard" -ef "$CON/.git/kai/repositories/kaukea/orchard" ]'
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
check "it reuses the one clone in the git folder"     '[ -L "$WT/.ai/repositories/kaukea/orchard" ] && [ "$WT/.ai/repositories/kaukea/orchard" -ef "$CON/.git/kai/repositories/kaukea/orchard" ]'
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

echo "== a laid link is counted from the repository it sits in, not from anywhere else =="
# The defect this guards against: laying, or repairing, while standing in a
# worktree used to count the link's depth from the outer checkout, so a link
# that needed two steps was written with five. It resolved where it was written
# and was wrong the moment its branch landed on the main branch.
CON5="$TMP/con5"; make_consumer "$CON5" "$ORIGIN"
run_hook "$CON5"
( cd "$CON5" && "$KAI" sync ) >"$TMP/sync1" 2>&1 || true
check "laid target is relative"                       '[ "$(readlink "$CON5/.claude/skills/enforcing-rules")" = "../../.ai/repositories/kaukea/orchard/skills/enforcing-rules" ]'
check "no laid target is absolute"                    '! find "$CON5/.claude" -type l -exec readlink {} \; | grep -q "^/"'
check "no laid target names a home directory"         '! find "$CON5/.claude" -type l -exec readlink {} \; | grep -q "$HOME"'
check "the skill still resolves"                      'grep -q "SKILL BODY" "$CON5/.claude/skills/enforcing-rules/SKILL.md"'

git -C "$CON5" worktree add -q "$CON5/.claude/worktrees/w2" -b f/w2 HEAD
WT2="$CON5/.claude/worktrees/w2"
run_hook "$WT2"
( cd "$WT2" && "$KAI" sync ) >"$TMP/sync2" 2>&1 || true
check "laying inside a worktree counts two, not five"  '[ "$(readlink "$WT2/.claude/skills/enforcing-rules")" = "../../.ai/repositories/kaukea/orchard/skills/enforcing-rules" ]'
check "no worktree target is absolute"                 '! find "$WT2/.claude" -type l -exec readlink {} \; | grep -q "^/"'
check "the skill resolves in the worktree"             'grep -q "SKILL BODY" "$WT2/.claude/skills/enforcing-rules/SKILL.md"'
check "the worktree records nothing to commit"         '[ -z "$(git -C "$WT2" status --porcelain)" ]'
check "and the outer checkout was left alone"          '[ "$(readlink "$CON5/.claude/skills/enforcing-rules")" = "../../.ai/repositories/kaukea/orchard/skills/enforcing-rules" ]'

echo "== a dead store link is repaired relative, never back to an absolute path =="
CON6="$TMP/con6"; make_consumer "$CON6" "$ORIGIN"
run_hook "$CON6"
# a link left over from an older layout, dead, with the tail still carried by the source
ln -sfn "../../.ai/repositories/kaukea/orchard/skills/moved-away/enforcing-rules" "$CON6/.claude/skills/enforcing-rules"
check "it really is dead"                              '[ ! -e "$CON6/.claude/skills/enforcing-rules" ]'
( cd "$CON6" && "$KAI" sync ) >"$TMP/sync3" 2>&1 || true
check "it was repaired"                                '[ -e "$CON6/.claude/skills/enforcing-rules/SKILL.md" ]'
check "and the repair is relative"                     '[ "$(readlink "$CON6/.claude/skills/enforcing-rules")" = "../../.ai/repositories/kaukea/orchard/skills/enforcing-rules" ]'
check "the repair names no home directory"             '! readlink "$CON6/.claude/skills/enforcing-rules" | grep -q "$HOME"'

echo "== migration 01 repairs a depth counted from the wrong repository =="
CON7="$TMP/con7"; make_consumer "$CON7" "$ORIGIN"
run_hook "$CON7"
# exactly the damage seen in the field: five steps where two are correct, which
# resolved inside the worktree it was written in and nowhere after the squash
ln -sfn "../../../../../.ai/repositories/kaukea/orchard/agents/gardener.md" "$CON7/.claude/agents/gardener.md"
# and the older shape the same pass has to heal: an absolute path naming this machine
ln -sfn "$CON7/.ai/repositories/kaukea/orchard/skills/enforcing-rules" "$CON7/.claude/skills/enforcing-rules"
mkdir -p "$CON7/.claude/tools"
ln -s ../../.ai/repositories/kaukea/orchard/agents/gardener.md "$CON7/.claude/tools/already-right.md"
# a worktree whose links belong to it, not to the checkout running the migration
git -C "$CON7" worktree add -q "$CON7/.claude/worktrees/w3" -b f/w3 HEAD
ln -sfn "../../../../../.ai/repositories/kaukea/orchard/agents/gardener.md" "$CON7/.claude/worktrees/w3/.claude/agents/gardener.md"

check "the damaged link really is dead"               '[ ! -e "$CON7/.claude/agents/gardener.md" ]'
run_migration "$ROOT/migrations/2026-08-27-01-links-counted-from-their-own-repository.md" "$CON7" >"$TMP/mig1" 2>&1
check "five steps became two"                         '[ "$(readlink "$CON7/.claude/agents/gardener.md")" = "../../.ai/repositories/kaukea/orchard/agents/gardener.md" ]'
check "the repaired link resolves"                    'grep -q "AGENT BODY" "$CON7/.claude/agents/gardener.md"'
check "the absolute one was relativized"              '[ "$(readlink "$CON7/.claude/skills/enforcing-rules")" = "../../.ai/repositories/kaukea/orchard/skills/enforcing-rules" ]'
check "no target names a home directory any more"     '! find "$CON7/.claude" -maxdepth 2 -type l -exec readlink {} \; | grep -q "^/"'
check "a correct link was left alone"                 '[ "$(readlink "$CON7/.claude/tools/already-right.md")" = "../../.ai/repositories/kaukea/orchard/agents/gardener.md" ]'
check "the worktree was not touched"                  '[ "$(readlink "$CON7/.claude/worktrees/w3/.claude/agents/gardener.md")" = "../../../../../.ai/repositories/kaukea/orchard/agents/gardener.md" ]'
check "the store itself was not descended into"       '! grep -q "^repointed \.ai/" "$TMP/mig1"'
check "what it did is reported"                       'grep -q "repointed" "$TMP/mig1"'
run_migration "$ROOT/migrations/2026-08-27-01-links-counted-from-their-own-repository.md" "$CON7" >"$TMP/mig1b" 2>&1
check "a second run repoints nothing"                 'grep -q "0 repointed" "$TMP/mig1b"'

# The case that matters in the field: a clone made somewhere else. Its committed
# links carry an absolute path naming the checkout they were written in, which is
# never this repository's root — so the claimed base cannot be matched against it
# and the tail has to be taken from the store marker instead.
CON9="$TMP/con9"; make_consumer "$CON9" "$ORIGIN"
ln -sfn "/somewhere/else/entirely/.ai/repositories/kaukea/orchard/agents/gardener.md" "$CON9/.claude/agents/gardener.md"
ln -sfn "/somewhere/else/entirely/.ai/repositories/kaukea/orchard/skills/enforcing-rules" "$CON9/.claude/skills/enforcing-rules"
run_migration "$ROOT/migrations/2026-08-27-01-links-counted-from-their-own-repository.md" "$CON9" >"$TMP/mig1c" 2>&1
check "a foreign absolute path is still repaired"     '[ "$(readlink "$CON9/.claude/agents/gardener.md")" = "../../.ai/repositories/kaukea/orchard/agents/gardener.md" ]'
check "both of them were"                             '[ "$(readlink "$CON9/.claude/skills/enforcing-rules")" = "../../.ai/repositories/kaukea/orchard/skills/enforcing-rules" ]'
check "and it reports having seen them"               'grep -q "2 store link(s) examined, 2 repointed" "$TMP/mig1c"'
run_hook "$CON9"
check "they resolve once the store arrives"           'grep -q "AGENT BODY" "$CON9/.claude/agents/gardener.md"'

# a link that is absolute but has nothing to do with the store is not ours
ln -sfn "/etc/hostname" "$CON9/.claude/agents/unrelated.md"
run_migration "$ROOT/migrations/2026-08-27-01-links-counted-from-their-own-repository.md" "$CON9" >"$TMP/mig1d" 2>&1
check "an unrelated absolute link is left alone"      '[ "$(readlink "$CON9/.claude/agents/unrelated.md")" = "/etc/hostname" ]'

echo "== migration 02 moves an existing store into the git folder =="
CON8="$TMP/con8"; make_consumer "$CON8" "$ORIGIN"
mkdir -p "$CON8/.ai/repositories/kaukea"
git clone --quiet "$ORIGIN" "$CON8/.ai/repositories/kaukea/orchard"
check "the clone starts in the working tree"          '[ -d "$CON8/.ai/repositories/kaukea/orchard/.git" ] && [ ! -L "$CON8/.ai/repositories/kaukea/orchard" ]'
check "the git folder holds nothing yet"              '[ ! -d "$CON8/.git/kai/repositories" ]'
check "the committed link resolves before"            'grep -q "SKILL BODY" "$CON8/.claude/skills/enforcing-rules/SKILL.md"'
run_migration "$ROOT/migrations/2026-08-27-02-store-moves-into-the-git-folder.md" "$CON8" >"$TMP/mig2" 2>&1
check "the clone now lives in the git folder"         '[ -d "$CON8/.git/kai/repositories/kaukea/orchard/.git" ]'
check "a link was left in its place"                  '[ -L "$CON8/.ai/repositories/kaukea/orchard" ]'
check "the link points at the moved clone"            '[ -L "$CON8/.ai/repositories/kaukea/orchard" ] && [ "$CON8/.ai/repositories/kaukea/orchard" -ef "$CON8/.git/kai/repositories/kaukea/orchard" ]'
check "the committed link still resolves"             'grep -q "SKILL BODY" "$CON8/.claude/skills/enforcing-rules/SKILL.md"'
check "the committed link was not rewritten"          '[ "$(readlink "$CON8/.claude/skills/enforcing-rules")" = "../../.ai/repositories/kaukea/orchard/skills/enforcing-rules" ]'
check "nothing new appears to commit"                 '[ -z "$(git -C "$CON8" status --porcelain)" ]'
check "the move is reported"                          'grep -q "moved kaukea/orchard" "$TMP/mig2"'
run_migration "$ROOT/migrations/2026-08-27-02-store-moves-into-the-git-folder.md" "$CON8" >"$TMP/mig2b" 2>&1
check "a second run moves nothing"                    'grep -q "0 clone(s) moved" "$TMP/mig2b"'
check "and a worktree then shares that one clone"     'git -C "$CON8" worktree add -q "$CON8/.claude/worktrees/w4" -b f/w4 HEAD && run_hook "$CON8/.claude/worktrees/w4" && grep -q "SKILL BODY" "$CON8/.claude/worktrees/w4/.claude/skills/enforcing-rules/SKILL.md"'
check "still exactly one clone on disk"               '[ "$(find "$CON8/.git/kai/repositories" -maxdepth 3 -name .git | wc -l)" -eq 1 ]'

echo "== a sync stays inside the checkout that started it =="
# Live incident: a sync run in the main checkout rewrote seventy-four links
# belonging to another session's worktree and deleted six of its files, because
# the dead-link repair walks the whole tree and stopped only at .git and .ai.
CON10="$TMP/con10"; make_consumer "$CON10" "$ORIGIN"
run_hook "$CON10"
git -C "$CON10" worktree add -q "$CON10/.claude/worktrees/theirs" -b f/theirs HEAD
THEIRS="$CON10/.claude/worktrees/theirs"
# their links: one dead with a tail the source still carries (repair bait), one
# dead with a tail nothing carries (prune bait)
ln -sfn "../../.ai/repositories/kaukea/orchard/skills/moved/enforcing-rules" "$THEIRS/.claude/skills/enforcing-rules"
ln -sfn "../../.ai/repositories/kaukea/orchard/agents/vanished.md" "$THEIRS/.claude/agents/gardener.md"
THEIR_SKILL=$(readlink "$THEIRS/.claude/skills/enforcing-rules")
THEIR_AGENT=$(readlink "$THEIRS/.claude/agents/gardener.md")
THEIR_STATUS=$(git -C "$THEIRS" status --porcelain)
( cd "$CON10" && "$KAI" sync ) >"$TMP/sync10" 2>&1 || true
check "their repair-bait link is untouched"           '[ "$(readlink "$THEIRS/.claude/skills/enforcing-rules")" = "$THEIR_SKILL" ]'
check "their prune-bait link still exists"            '[ -L "$THEIRS/.claude/agents/gardener.md" ]'
check "and was not repointed either"                  '[ "$(readlink "$THEIRS/.claude/agents/gardener.md")" = "$THEIR_AGENT" ]'
check "nothing in their worktree is reported at all"  '! grep -q "worktrees/theirs" "$TMP/sync10"'
check "sync changed nothing in their tree"            '[ "$(git -C "$THEIRS" status --porcelain)" = "$THEIR_STATUS" ]'
check "ours was still laid"                           'grep -q "SKILL BODY" "$CON10/.claude/skills/enforcing-rules/SKILL.md"'

echo "== sync finishes cleanly once migrations have run =="
# The cleanup a function installs for its own return stayed installed in its
# caller and fired again with its variable out of scope, so `set -u` ended every
# migration-applying sync with "done_file: unbound variable".
CON11="$TMP/con11"; make_consumer "$CON11" "$ORIGIN"
run_hook "$CON11"
( cd "$CON11" && "$KAI" sync ) >"$TMP/sync11" 2>&1; rc=$?
check "sync exits 0"                                  '[ $rc -eq 0 ]'
check "no unbound variable is reported"               '! grep -q "unbound variable" "$TMP/sync11"'
check "and nothing else went to stderr as an error"   '! grep -qi "line [0-9]*:" "$TMP/sync11"'

echo "== a managed repository ends up declaring the package that manages it =="
MIG_KAI="$ROOT/migrations/2026-08-28-01-kai-package-is-always-declared.md"

# a consumer that lost the declaration, with a root table and a comment to preserve
CON12="$TMP/con12"; git_init "$CON12"
printf '# my own note, hands off\nname = "thing"\ntype = "project"\n\n[[dependency]]\nsource = "kaukea/orchard"\n' > "$CON12/.ai.toml"
git -C "$CON12" add -A && git -C "$CON12" commit -qm consumer
run_migration "$MIG_KAI" "$CON12" >"$TMP/migkai" 2>&1
check "the declaration was added"                     'grep -q "^source = \"kaukea/kauk\"$" "$CON12/.ai.toml"'
check "exactly one of them"                           '[ "$(grep -c "kaukea/kauk" "$CON12/.ai.toml")" -eq 1 ]'
check "the operator comment survived"                 'grep -q "^# my own note, hands off$" "$CON12/.ai.toml"'
check "the root table survived"                       'grep -q "^name = \"thing\"$" "$CON12/.ai.toml"'
check "the existing dependency survived"              'grep -q "kaukea/orchard" "$CON12/.ai.toml"'
check "it is placed after the last dependency"        '[ "$(grep -n "kaukea/kauk" "$CON12/.ai.toml" | cut -d: -f1)" -gt "$(grep -n "kaukea/orchard" "$CON12/.ai.toml" | cut -d: -f1)" ]'
check "and it says what it did"                       'grep -q "declared the kai package" "$TMP/migkai"'
BEFORE12=$(cat "$CON12/.ai.toml")
run_migration "$MIG_KAI" "$CON12" >"$TMP/migkai2" 2>&1
check "a second run changes nothing"                  '[ "$(cat "$CON12/.ai.toml")" = "$BEFORE12" ]'
check "and says it was already there"                 'grep -q "already declared" "$TMP/migkai2"'

echo "== every shape of an existing declaration is recognised =="
for shape in 'kaukea/kauk' 'kaukea/kauk@HEAD' 'git@github.com:kaukea/kauk.git' '/home/someone/src/kaukea/kauk'; do
  C="$TMP/shape-$(echo "$shape" | tr -c 'a-zA-Z0-9' '-')"; git_init "$C"
  printf '[[dependency]]\nsource = "%s"\n' "$shape" > "$C/.ai.toml"
  git -C "$C" add -A && git -C "$C" commit -qm c
  run_migration "$MIG_KAI" "$C" >"$TMP/s.out" 2>&1
  check "left alone: $shape"                          '[ "$(grep -c "^source" "$C/.ai.toml")" -eq 1 ]'
done

echo "== the tool's own repository, and repositories kai does not manage =="
SELF="$TMP/self"; git_init "$SELF"
mkdir -p "$SELF/bin"; printf '#!/bin/sh\n' > "$SELF/bin/kaukea"
printf 'name = "kauk"\ntype = "package"\n' > "$SELF/.ai.toml"
git -C "$SELF" add -A && git -C "$SELF" commit -qm self
run_migration "$MIG_KAI" "$SELF" >"$TMP/self.out" 2>&1
check "the kai package declares nothing"              '! grep -q "kaukea/kauk" "$SELF/.ai.toml"'
check "and says why"                                  'grep -q "IS the kai package" "$TMP/self.out"'

UNMANAGED="$TMP/unmanaged"; git_init "$UNMANAGED"
printf 'hello\n' > "$UNMANAGED/README.md"
git -C "$UNMANAGED" add -A && git -C "$UNMANAGED" commit -qm c
run_migration "$MIG_KAI" "$UNMANAGED" >"$TMP/un.out" 2>&1
check "an unmanaged repository is untouched"          '[ ! -f "$UNMANAGED/.ai.toml" ]'
check "and says so"                                   'grep -q "not managed by kai" "$TMP/un.out"'

echo "== a repository with no dependencies at all gets one =="
EMPTY="$TMP/empty"; git_init "$EMPTY"
printf 'name = "solo"\n' > "$EMPTY/.ai.toml"
git -C "$EMPTY" add -A && git -C "$EMPTY" commit -qm c
run_migration "$MIG_KAI" "$EMPTY" >"$TMP/e.out" 2>&1
check "the declaration was added"                     'grep -q "^source = \"kaukea/kauk\"$" "$EMPTY/.ai.toml"'
check "the root table survived"                       'grep -q "^name = \"solo\"$" "$EMPTY/.ai.toml"'
check "and the file is still valid to kai's reader"   '[ "$(grep -c "^\[\[dependency\]\]$" "$EMPTY/.ai.toml")" -eq 1 ]'

echo "== the help says what each command does =="
"$KAI" --help >"$TMP/help" 2>&1; HELP_RC=$?
check "--help exits 0"                                '[ $HELP_RC -eq 0 ]'
check "it goes to stdout, not stderr"                 '[ -s "$TMP/help" ] && [ -z "$("$KAI" --help 2>&1 >/dev/null)" ]'
for verb in init install update; do
  check "$verb is listed"                             'grep -q "^  '"$verb"'" "$TMP/help"'
done
check "sync is named as the other spelling"           'grep -q "Also spelled .sync" "$TMP/help"'
check "resolve is no longer a command of its own"     '! grep -q "^  resolve " "$TMP/help"'
for flag in --status --pull --push --abort --automerge --resolve; do
  check "$flag is explained"                          'grep -q -- "'"$flag"'" "$TMP/help"'
done
check "it says what a source can be"                  'grep -q "owner/repo" "$TMP/help" && grep -q "git address" "$TMP/help"'
check "it says push is deliberate"                    'grep -qi "a plain update never sends" "$TMP/help"'
check "it says your file becomes your edit"           'grep -qi "taken as your local edit" "$TMP/help"'
check "it says nothing is ever lost"                  'grep -qi "every version is in a commit" "$TMP/help"'
check "it says the config file is yours"              'grep -q "yours to edit" "$TMP/help"'
check "it points at the written-up docs"              'grep -q "docs/ai-toml.md" "$TMP/help"'
check "-h prints the same thing"                      '[ "$("$KAI" -h 2>&1)" = "$(cat "$TMP/help")" ]'
check "help prints the same thing"                    '[ "$("$KAI" help 2>&1)" = "$(cat "$TMP/help")" ]'

echo "== getting it wrong is told, not just refused =="
"$KAI" frobnicate >"$TMP/bad" 2>&1; BAD_RC=$?
check "an unknown command exits non-zero"             '[ $BAD_RC -ne 0 ]'
check "it names what was not understood"              'grep -q "frobnicate is not a kai command" "$TMP/bad"'
check "and prints the help after it"                  'grep -q "^  install <source>" "$TMP/bad"'
"$KAI" >"$TMP/bare" 2>&1; BARE_RC=$?
check "no command at all exits non-zero"              '[ $BARE_RC -ne 0 ]'
check "and prints the help"                           'grep -q "^usage: kai <command>" "$TMP/bare"'
CON13="$TMP/con13"; make_consumer "$CON13" "$ORIGIN"
( cd "$CON13" && "$KAI" install ) >"$TMP/badinstall" 2>&1 || true
check "install with nothing says what it needs"       'grep -q "install needs a package to add" "$TMP/badinstall"'
( cd "$CON13" && "$KAI" update --wat ) >"$TMP/badsync" 2>&1 || true
check "an unknown flag names the flag"                'grep -q -- "update does not take \"--wat\"" "$TMP/badsync"'
check "and lists the ones it does take"               'grep -q -- "--status" "$TMP/badsync"'
check "sync is accepted as the same command"          '( cd "$CON13" && "$KAI" sync --status ) >/dev/null 2>&1'

echo
printf 'store-in-git-folder: %s/%s passed\n' "$PASS" "$((PASS + FAIL))"
[ "$FAIL" -eq 0 ]
