#!/usr/bin/env bash
# Fixture test for the convention reader against the operator's configuration
# specification: one .ai.toml per repository, root-table identity,
# [[dependency]] blocks, per-dependency include, closure, lay-after-selection.
# Builds throwaway git repositories under a temp dir, runs the real bin/kauk
# against them, and asserts on what landed.
#
#   tests/convention-reader.sh          run all cases
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

# ---------------------------------------------------------------- the package
# Path $TMP/test/pkg so the derived identity is test/pkg.
PKG="$TMP/test/pkg"
git_init "$PKG"
mkdir -p "$PKG/skills/alpha" "$PKG/agents" "$PKG/hooks" "$PKG/tools" \
         "$PKG/files/.github/workflows" "$PKG/docs"
printf -- '---\nname: alpha\n---\nbody\n'  > "$PKG/skills/alpha/SKILL.md"
printf -- '---\nname: beta\n---\nprompt\n' > "$PKG/agents/beta.md"
printf '#!/bin/sh\necho hi\n'              > "$PKG/hooks/on-start.sh"
printf 'print("tool")\n'                   > "$PKG/tools/helper.py"
printf 'shared rules\n'                    > "$PKG/files/AGENTS.shared.md"
printf 'name: ci\n'                        > "$PKG/files/.github/workflows/ci.yml"
printf 'not shipped\n'                     > "$PKG/docs/design.md"
printf 'not shipped\n'                     > "$PKG/README.md"
printf 'name = "pkg"\ntype = "package"\n' > "$PKG/.ai.toml"
commit_all "$PKG"

# --------------------------------------------------------------- the consumer
CON="$TMP/consumer"
git_init "$CON"
mkdir -p "$CON/.claude"
printf 'placeholder\n' > "$CON/.claude/.keep"
commit_all "$CON"

echo "== install a path source; identity derives from the path =="
( cd "$CON" && "$KAUK" install "$PKG" ) >"$TMP/out1" 2>&1 || true
sed 's/^/     /' "$TMP/out1" | head -8

check "identity is test/pkg"           '[ -d "$CON/.ai/repositories/test/pkg/.git" ]'
check "skill laid from skills/"        '[ -L "$CON/.claude/skills/alpha" ]'
check "agent laid from agents/"        '[ -L "$CON/.claude/agents/beta.md" ]'
check "hook laid from hooks/"          '[ -L "$CON/.claude/hooks/on-start.sh" ]'
check "tool laid from tools/"          '[ -L "$CON/.claude/tools/helper.py" ]'
check "files/ mirrors to repo root"    '[ -L "$CON/AGENTS.shared.md" ]'
check "files/ keeps nested paths"      '[ -L "$CON/.github/workflows/ci.yml" ]'
check "docs/ ignored"                  '[ ! -e "$CON/docs/design.md" ]'
check "no include: tree offered"      'grep -qi "nothing is selected" "$TMP/out1"'

echo "== idempotence, and sync never pushes local clone edits =="
( cd "$CON" && "$KAUK" sync ) >"$TMP/out2" 2>&1 || true
check "second run keeps the skill"     '[ -L "$CON/.claude/skills/alpha" ]'
check "second run reports no error"    '! grep -qi "error\|refusing" "$TMP/out2"'
BEFORE=$(git -C "$PKG" rev-parse HEAD)
printf 'edited by consumer\n' >> "$CON/.ai/repositories/test/pkg/skills/alpha/SKILL.md"
( cd "$CON" && "$KAUK" sync ) >"$TMP/out3" 2>&1 || true
check "local edit stays local on sync"  '[ "$(git -C "$PKG" rev-parse HEAD)" = "$BEFORE" ]'
( cd "$CON/.ai/repositories/test/pkg" && git checkout -q -- . )

echo "== sync pulls with rebase; migrations run; removals warn =="
# Seed the consumer's watermark BEFORE the new migration is introduced, so it
# lands as a genuinely pending migration rather than a fresh install: under
# the ratified design (absent watermark = fresh install: run nothing, stamp
# to now) a consumer with no watermark yet treats any already-visible
# migration as caught-up, not pending — see apply_pending_migrations in
# bin/kaukea.
mkdir -p "$CON/.ai"
printf '[migrations]\nwatermark = "2020-01-01-0"\n' > "$CON/.ai/migrations.toml"
mkdir -p "$PKG/skills/gamma" "$PKG/migrations"
printf -- '---\nname: gamma\n---\nnew\n' > "$PKG/skills/gamma/SKILL.md"
printf '# fixture migration\n\n```sh\ntouch mig-ran\n```\n' > "$PKG/migrations/2026-01-01-touch.md"
commit_all "$PKG" "gamma and a migration"
( cd "$CON" && "$KAUK" sync ) >"$TMP/outP1" 2>&1 || true
check "sync pulled the new skill"      '[ -L "$CON/.claude/skills/gamma" ]'
check "migration scripted step ran"    '[ -f "$CON/mig-ran" ]'
WM_LINE='watermark = "2026-01-01-0"'
check "watermark advanced in .ai/migrations.toml" 'grep -qF "$WM_LINE" "$CON/.ai/migrations.toml"'
rm -rf "$PKG/skills/gamma"; commit_all "$PKG" "remove gamma"
( cd "$CON" && "$KAUK" sync ) >"$TMP/outP2" 2>&1 || true
check "removal warned"                 'grep -q "s/gamma" "$TMP/outP2"'
check "removed skill pruned"           '[ ! -e "$CON/.claude/skills/gamma" ]'

echo "== local edits stay local on sync; --push publishes =="
printf 'consumer note\n' >> "$CON/.ai/repositories/test/pkg/skills/alpha/SKILL.md"
UP=$(git -C "$PKG" rev-parse HEAD)
( cd "$CON" && "$KAUK" sync ) >"$TMP/outP3" 2>&1 || true
check "sync kept the edit local"       '[ "$(git -C "$PKG" rev-parse HEAD)" = "$UP" ] && grep -q "consumer note" "$CON/.ai/repositories/test/pkg/skills/alpha/SKILL.md"'
mkdir -p "$PKG/skills/zeta"
printf -- '---\nname: zeta\n---\nz\n' > "$PKG/skills/zeta/SKILL.md"
commit_all "$PKG" "zeta upstream"
( cd "$CON" && "$KAUK" sync --push ) >"$TMP/outP4" 2>&1 || true
check "edit published to the source"   'grep -q "consumer note" "$PKG/skills/alpha/SKILL.md"'
check "history stayed linear"          'git -C "$PKG" log --format=%p -1 | grep -qv " "'
check "zeta arrived via the rebase"    '[ -L "$CON/.claude/skills/zeta" ]'

echo "== a conflicting rebase stops and reports =="
printf 'upstream line\n' >> "$PKG/skills/alpha/SKILL.md"
commit_all "$PKG" "upstream touches alpha"
printf 'conflicting local line\n' >> "$CON/.ai/repositories/test/pkg/skills/alpha/SKILL.md"
UP=$(git -C "$PKG" rev-parse HEAD)
( cd "$CON" && "$KAUK" sync --push ) >"$TMP/outP5" 2>&1 || true
check "the update says it is waiting"  'grep -q "waiting on you" "$TMP/outP5"'
check "source repository untouched"    '[ "$(git -C "$PKG" rev-parse HEAD)" = "$UP" ]'
check "the rebase is left open to act on" '[ -d "$CON/.ai/repositories/test/pkg/.git/rebase-merge" ] || [ -d "$CON/.ai/repositories/test/pkg/.git/rebase-apply" ]'
( cd "$CON" && "$KAUK" update ) >"$TMP/outP5b" 2>&1 || true
check "and says so again until it is settled" 'grep -q "already waiting on you" "$TMP/outP5b"'
check "it offers the three ways out"   'grep -q -- "--abort" "$TMP/outP5b" && grep -q -- "--automerge" "$TMP/outP5b" && grep -q -- "--resolve" "$TMP/outP5b"'
( cd "$CON" && "$KAUK" update --abort ) >"$TMP/outP5c" 2>&1 || true
check "abort puts it back"             '[ ! -d "$CON/.ai/repositories/test/pkg/.git/rebase-merge" ] && [ ! -d "$CON/.ai/repositories/test/pkg/.git/rebase-apply" ]'
check "abort says what it did"         'grep -q "put back as it was" "$TMP/outP5c"'
( cd "$CON/.ai/repositories/test/pkg" && git reset -q --hard origin/main 2>/dev/null && git pull -q --rebase origin main 2>/dev/null || true )

echo "== a source naming anything but @HEAD is left untouched =="
git -C "$PKG" tag vREF
BEFORE_REF=$(git -C "$CON/.ai/repositories/test/pkg" rev-parse HEAD)
mkdir -p "$PKG/skills/afterref"
printf -- '---\nname: afterref\n---\nlate\n' > "$PKG/skills/afterref/SKILL.md"
commit_all "$PKG" "after the ref"
sed -i "s|^source = \"$PKG\"$|source = \"$PKG@vREF\"|" "$CON/.ai.toml"
( cd "$CON" && "$KAUK" sync ) >"$TMP/outP6" 2>&1 || true
check "clone not moved"                '[ "$(git -C "$CON/.ai/repositories/test/pkg" rev-parse HEAD)" = "$BEFORE_REF" ]'
check "untouched is announced"         'grep -q "waits for the versioning work" "$TMP/outP6"'
check "still lays what is there"       '[ -L "$CON/.claude/skills/alpha" ]'
sed -i "s|^source = \"$PKG@vREF\"$|source = \"$PKG\"|" "$CON/.ai.toml"
( cd "$CON" && "$KAUK" sync ) >/dev/null 2>&1 || true

echo "== a source that is no known form is reported and ignored =="
CONE="$TMP/consumer-err"
git_init "$CONE"; mkdir -p "$CONE/.claude"
cat > "$CONE/.ai.toml" <<'EOF'
[[dependency]]
source = "nonsense"
EOF
commit_all "$CONE"
( cd "$CONE" && "$KAUK" sync ) >"$TMP/out4" 2>&1 || true
check "unknown source form warned"     'grep -q "is not <owner>/<repo>, a git URI, or a path" "$TMP/out4"'
check "nothing was laid"               '[ ! -e "$CONE/.claude/skills/alpha" ]'

echo "== an owner/repo source resolves to github by default =="
CONG="$TMP/consumer-gh"
git_init "$CONG"; mkdir -p "$CONG/.claude"
cat > "$CONG/.ai.toml" <<'EOF'
[[dependency]]
source = "test/nonexist"
EOF
commit_all "$CONG"
( cd "$CONG" && GIT_TERMINAL_PROMPT=0 "$KAUK" install test/nonexist ) >"$TMP/out5" 2>&1 || true
check "github URL attempted"           'grep -q "github.com/test/nonexist" "$TMP/out5"'

echo "== selection by category trims what lays =="
CATPKG="$TMP/test/catpkg"
git_init "$CATPKG"
mkdir -p "$CATPKG/skills/devx" "$CATPKG/skills/devroot" "$CATPKG/skills/opsy" \
         "$CATPKG/skills/helper" "$CATPKG/skills/plain" "$CATPKG/agents" "$CATPKG/tools"
printf -- '---\nname: devx\ncategories: [dev/x]\n---\nx\n'      > "$CATPKG/skills/devx/SKILL.md"
printf -- '---\nname: devroot\ncategories: [dev]\n---\nr\n'     > "$CATPKG/skills/devroot/SKILL.md"
printf -- '---\nname: opsy\nroles: [ops/y]\ndependencies-skills: [helper]\n---\ny\n' > "$CATPKG/skills/opsy/SKILL.md"
printf -- '---\nname: helper\ncategories: [misc/h]\n---\nh\n'   > "$CATPKG/skills/helper/SKILL.md"
printf -- '---\nname: plain\n---\nno placement\n'               > "$CATPKG/skills/plain/SKILL.md"
printf -- '---\nname: aget\ncategories: [dev/x]\n---\np\n'      > "$CATPKG/agents/aget.md"
printf -- '---\nname: aux\ncategories: [ops/y]\nskills: [devx]\n---\np\n' > "$CATPKG/agents/aux.md"
printf 'print("t")\n'                                           > "$CATPKG/tools/t.py"
printf 'name = "catpkg"\ntype = "package"\n' > "$CATPKG/.ai.toml"
commit_all "$CATPKG"
CON5="$TMP/consumer5"
git_init "$CON5"; mkdir -p "$CON5/.claude"
cat > "$CON5/.ai.toml" <<EOF
[[dependency]]
source = "file://$CATPKG"
include = ["dev/x"]
EOF
commit_all "$CON5"
( cd "$CON5" && "$KAUK" install "file://$CATPKG" ) >"$TMP/out6" 2>&1 || true
check "selected subtree laid"          '[ -L "$CON5/.claude/skills/devx" ]'
check "ancestor'\''s own skill laid"   '[ -L "$CON5/.claude/skills/devroot" ]'
check "unplaced artifact always lays"  '[ -L "$CON5/.claude/skills/plain" ]'
check "other category not laid"        '[ ! -e "$CON5/.claude/skills/opsy" ]'
check "its dependency not laid either" '[ ! -e "$CON5/.claude/skills/helper" ]'
check "agent in selection laid"        '[ -L "$CON5/.claude/agents/aget.md" ]'
check "agent outside not laid"         '[ ! -e "$CON5/.claude/agents/aux.md" ]'
check "tools lay unfiltered"           '[ -L "$CON5/.claude/tools/t.py" ]'

echo "== reselection: flat-key closure pulls, deselection prunes =="
sed -i 's|include = \["dev/x"\]|include = ["ops/y"]|' "$CON5/.ai.toml"
( cd "$CON5" && "$KAUK" sync ) >"$TMP/out7" 2>&1 || true
check "roles: fallback selects"        '[ -L "$CON5/.claude/skills/opsy" ]'
check "dependencies-skills: pulled"    '[ -L "$CON5/.claude/skills/helper" ]'
check "agent'\''s skills: pulled"      '[ -L "$CON5/.claude/skills/devx" ]'
check "closure additions reported"     'grep -q "closure: +s/helper" "$TMP/out7"'
check "deselected skill pruned"        '[ ! -e "$CON5/.claude/skills/devroot" ]'
check "deselected agent pruned"        '[ ! -e "$CON5/.claude/agents/aget.md" ]'
check "unplaced artifact survives"     '[ -L "$CON5/.claude/skills/plain" ]'

echo "== a leaf entry picks one artifact =="
sed -i 's|include = \["ops/y"\]|include = ["misc/h/helper"]|' "$CON5/.ai.toml"
( cd "$CON5" && "$KAUK" sync ) >"$TMP/out8" 2>&1 || true
check "leaf-picked artifact laid"      '[ -L "$CON5/.claude/skills/helper" ]'
check "everything else pruned"         '[ ! -e "$CON5/.claude/skills/opsy" ] && [ ! -e "$CON5/.claude/skills/devx" ]'
check "unplaced still survives"        '[ -L "$CON5/.claude/skills/plain" ]'

echo "== cross-package closure by the name-rooted grammar =="
DEP="$TMP/test/dep"
git_init "$DEP"; mkdir -p "$DEP/skills/dep1"
printf -- '---\nname: dep1\ncategories: [util]\n---\nd\n' > "$DEP/skills/dep1/SKILL.md"
printf 'name = "dep"\ntype = "package"\n' > "$DEP/.ai.toml"
commit_all "$DEP"
PKG2="$TMP/test/pkg2"
git_init "$PKG2"; mkdir -p "$PKG2/skills/needy"
printf -- '---\nname: needy\ncategories: [main]\ndependencies-skills: [dep/util/dep1]\n---\nm\n' > "$PKG2/skills/needy/SKILL.md"
printf 'name = "pkg2"\ntype = "package"\n' > "$PKG2/.ai.toml"
commit_all "$PKG2"
CON7="$TMP/consumer7"
git_init "$CON7"; mkdir -p "$CON7/.claude"
cat > "$CON7/.ai.toml" <<EOF
[[dependency]]
source = "file://$DEP"
include = ["nothing-here"]

[[dependency]]
source = "file://$PKG2"
include = ["main"]
EOF
commit_all "$CON7"
( cd "$CON7" && "$KAUK" install "file://$DEP" && "$KAUK" install "file://$PKG2" ) >"$TMP/out9" 2>&1 || true
check "selected artifact laid"         '[ -L "$CON7/.claude/skills/needy" ]'
check "cross-package dep laid"         '[ -L "$CON7/.claude/skills/dep1" ]'
check "cross-package closure reported" 'grep -q "closure: +dep" "$TMP/out9"'

echo "== a file of yours becomes your edit of the package's file =="
CON2="$TMP/consumer2"
git_init "$CON2"; mkdir -p "$CON2/.claude"
printf 'MINE — not kauk\n' > "$CON2/AGENTS.shared.md"
commit_all "$CON2"
( cd "$CON2" && "$KAUK" install "$PKG" ) >"$TMP/outB" 2>&1 || true
check "it is laid at the plain name"   '[ -L "$CON2/AGENTS.shared.md" ]'
check "it reaches the package"         'readlink "$CON2/AGENTS.shared.md" | grep -q ".ai/repositories/"'
check "and says where edits now go"    'grep -q "edits through it now go to the package" "$TMP/outB"'
check "your version is still in history" 'git -C "$CON2" show HEAD:AGENTS.shared.md | grep -q "MINE"'
check "nothing is namespaced"          '[ ! -e "$CON2/local:AGENTS.shared.md" ]'
check "no agent dispatched on install" '! grep -qi "dispatching\|claude -p" "$TMP/outB"'

echo "== an edit through the link is an edit of the package =="
printf 'MY EDIT\n' > "$CON2/AGENTS.shared.md"
CLONE2=$(cd "$CON2" && readlink -f "$(readlink AGENTS.shared.md)" | sed 's|/files/.*||')
check "the package repository sees it" '[ -n "$(git -C "$CLONE2" status --porcelain)" ]'
check "the edit is not in this repository" '! git -C "$CON2" diff -- AGENTS.shared.md | grep -q "MY EDIT"'
check "what changed here is the link"      'git -C "$CON2" status --porcelain -- AGENTS.shared.md | grep -qE "^ (T|M)" && [ -L "$CON2/AGENTS.shared.md" ]'

echo "== resolve is no longer a command of its own =="
( cd "$CON2" && "$KAUK" resolve ) >"$TMP/outC" 2>&1 || true
check "it is refused"                  'grep -q "resolve is not a kai command" "$TMP/outC"'
check "and the help is offered"        'grep -q -- "--resolve" "$TMP/outC"'

echo "== two DIFFERENT packages sharing a name keep both =="
CON4="$TMP/consumer4"
git_init "$CON4"; mkdir -p "$CON4/.claude"
commit_all "$CON4"
PKGX="$TMP/test/pkgx"; git_init "$PKGX"; mkdir -p "$PKGX/skills/alpha"
printf -- '---\nname: alpha\n---\nX ALPHA\n' > "$PKGX/skills/alpha/SKILL.md"
pkg_toml "$PKGX" pkgx; commit_all "$PKGX"
( cd "$CON4" && "$KAUK" install "$PKG" && "$KAUK" install "$PKGX" ) >"$TMP/outE" 2>&1 || true
check "the first keeps a namespaced copy" '[ -e "$CON4/.claude/skills/local:alpha" ]'
check "the second is namespaced too"      '[ -L "$CON4/.claude/skills/pkgx:alpha" ]'
check "the bare name is given up"         '[ ! -e "$CON4/.claude/skills/alpha" ]'
check "and it says why"                   'grep -qi "two packages ship this name" "$TMP/outE"'

echo "== no runtime detected: nothing is laid =="
CON3="$TMP/consumer3"
git_init "$CON3"
printf 'placeholder\n' > "$CON3/.keep"; commit_all "$CON3" "empty" >/dev/null
( cd "$CON3" && "$KAUK" install "$PKG" ) >"$TMP/outF" 2>&1 || true
check "nothing laid without a runtime" '[ ! -e "$CON3/.claude/skills/alpha" ]'
check "detection explained"            'grep -qi "no agent runtime detected" "$TMP/outF"'

echo "== root-table type = \"package\" lays the repo into itself, by copy =="
# is_self_source is retired: self-application is never inferred from a source
# declaration pointing at the repo's own path. It is declared exclusively via
# type = "package" in the ROOT TABLE of the repo's own .ai.toml (see
# is_package_repo / lay_self in bin/kaukea). This fixture carries NO dependency
# entry for itself, to also prove a self-referencing source is no longer
# special-cased — it simply isn't present here at all.
SELF="$TMP/test/selfpkg"
git_init "$SELF"
mkdir -p "$SELF/skills/own" "$SELF/.claude"
printf -- '---\nname: own\n---\nself\n' > "$SELF/skills/own/SKILL.md"
printf 'name = "selfpkg"\ntype = "package"\n' > "$SELF/.ai.toml"
commit_all "$SELF"
( cd "$SELF" && "$KAUK" sync ) >"$TMP/outG" 2>&1 || true
check "package repo is not cloned into itself" '[ ! -d "$SELF/.ai/repositories/test/selfpkg" ]'
check "package repo lays its own skill by copy, not symlink" '[ -f "$SELF/.claude/skills/own/SKILL.md" ] && [ ! -L "$SELF/.claude/skills/own" ]'
check "package repo self-sync is idempotent" '( cd "$SELF" && "$KAUK" sync >/dev/null 2>&1 ); [ -f "$SELF/.claude/skills/own/SKILL.md" ]'

echo "== include on a local path is refused, with the reason =="
CONI="$TMP/consumer-inc"
git_init "$CONI"; mkdir -p "$CONI/.claude"
cat > "$CONI/.ai.toml" <<EOF
[[dependency]]
source = "$CATPKG"
include = ["dev/x"]
EOF
commit_all "$CONI"
( cd "$CONI" && "$KAUK" sync ) >"$TMP/outH" 2>&1 || true
check "local path + include refused"   'grep -q "include is accepted on git sources only" "$TMP/outH"'
check "the swap is explained"          'grep -q "replaced by its git source before publishing" "$TMP/outH"'
check "nothing laid while refused"     '[ ! -e "$CONI/.claude/skills/devx" ]'

echo "== @HEAD is the one ref that syncs like any other source =="
CONHD="$TMP/consumer-head"
git_init "$CONHD"; mkdir -p "$CONHD/.claude"
commit_all "$CONHD"
( cd "$CONHD" && "$KAUK" install "$PKG@HEAD" ) >"$TMP/outI" 2>&1 || true
check "@HEAD source cloned"            '[ -d "$CONHD/.ai/repositories/test/pkg/.git" ]'
check "@HEAD source laid"              '[ -L "$CONHD/.claude/skills/alpha" ]'
check "@HEAD is not parked"            '! grep -q "waits for the versioning work" "$TMP/outI"'
check "@HEAD kept as written"          'grep -qF "source = \"$PKG@HEAD\"" "$CONHD/.ai.toml"'

echo "== install appends after the last dependency, not at the end of the file =="
CONAP="$TMP/consumer-append"
git_init "$CONAP"; mkdir -p "$CONAP/.claude"
cat > "$CONAP/.ai.toml" <<EOF
name = "appender"

[[dependency]]
source = "test/first"

[somethingelse]
key = "value"
EOF
commit_all "$CONAP"
( cd "$CONAP" && GIT_TERMINAL_PROMPT=0 "$KAUK" install "$PKG" ) >"$TMP/outJ" 2>&1 || true
check "the new dependency is there"    'grep -qF "source = \"$PKG\"" "$CONAP/.ai.toml"'
check "it lands before the next table" 'awk "/^\\[somethingelse\\]/{exit} /source = /{n++} END{exit !(n==2)}" "$CONAP/.ai.toml"'
check "the operator's own table stays" 'grep -q "^key = \"value\"" "$CONAP/.ai.toml"'
check "the root table is untouched"    '[ "$(head -1 "$CONAP/.ai.toml")" = "name = \"appender\"" ]'
check "a second install adds nothing"  '( cd "$CONAP" && "$KAUK" install "$PKG" >/dev/null 2>&1 ); [ "$(grep -cF "source = \"$PKG\"" "$CONAP/.ai.toml")" = 1 ]'

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
