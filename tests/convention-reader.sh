#!/usr/bin/env bash
# Fixture test for the convention reader under the ratified selection model:
# defaults-only .ai.toml, per-source select, closure, lay-after-selection.
# Builds throwaway git repositories under a temp dir, runs the real bin/kauk
# against them, and asserts on what landed.
#
#   tests/convention-reader.sh          run all cases
set -uo pipefail

KAUK=$(cd "$(dirname "$0")/.." && pwd)/bin/kauk
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
cat > "$PKG/package.toml" <<'EOF'
name = "pkg"
title = "Test Package"
description = "A fixture."
EOF
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
check "no select: tree offered"       'grep -qi "nothing is selected" "$TMP/out1"'

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
mkdir -p "$PKG/skills/gamma" "$PKG/migrations"
printf -- '---\nname: gamma\n---\nnew\n' > "$PKG/skills/gamma/SKILL.md"
printf '# fixture migration\n\n```sh\ntouch mig-ran\n```\n' > "$PKG/migrations/2026-01-01-touch.md"
commit_all "$PKG" "gamma and a migration"
( cd "$CON" && "$KAUK" sync ) >"$TMP/outP1" 2>&1 || true
check "sync pulled the new skill"      '[ -L "$CON/.claude/skills/gamma" ]'
check "migration scripted step ran"    '[ -f "$CON/mig-ran" ]'
check "watermark advanced per package" 'grep -q "2026-01-01-touch" "$CON/.git/the-works/migrated/test/pkg"'
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
check "conflict reported, not degraded" 'grep -q "CONFLICTS" "$TMP/outP5"'
check "source repository untouched"    '[ "$(git -C "$PKG" rev-parse HEAD)" = "$UP" ]'
( cd "$CON/.ai/repositories/test/pkg" && git reset -q --hard origin/main 2>/dev/null && git pull -q --rebase origin main 2>/dev/null || true )

echo "== a pull-only package refuses --push =="
PO="$TMP/test/pullonly"
git_init "$PO"; mkdir -p "$PO/skills/ro"
printf -- '---\nname: ro\n---\nro\n' > "$PO/skills/ro/SKILL.md"
printf 'name = "pullonly"\ntitle = "RO"\ndescription = "x"\npull-only = true\n' > "$PO/package.toml"
commit_all "$PO"
CONR="$TMP/consumer-ro"
git_init "$CONR"; mkdir -p "$CONR/.claude"
commit_all "$CONR"
( cd "$CONR" && "$KAUK" install "$PO" ) >/dev/null 2>&1 || true
printf 'edit\n' >> "$CONR/.ai/repositories/test/pullonly/skills/ro/SKILL.md"
ROUP=$(git -C "$PO" rev-parse HEAD)
( cd "$CONR" && "$KAUK" sync --push ) >"$TMP/outRO" 2>&1 || true
check "pull-only refuses --push"       'grep -q "pull-only" "$TMP/outRO" && [ "$(git -C "$PO" rev-parse HEAD)" = "$ROUP" ]'

echo "== a ref'd source is left untouched =="
git -C "$PKG" tag vREF
BEFORE_REF=$(git -C "$CON/.ai/repositories/test/pkg" rev-parse HEAD)
mkdir -p "$PKG/skills/afterref"
printf -- '---\nname: afterref\n---\nlate\n' > "$PKG/skills/afterref/SKILL.md"
commit_all "$PKG" "after the ref"
printf 'ref = "vREF"\n' >> "$CON/.ai.toml"
( cd "$CON" && "$KAUK" sync ) >"$TMP/outP6" 2>&1 || true
check "clone not moved"                '[ "$(git -C "$CON/.ai/repositories/test/pkg" rev-parse HEAD)" = "$BEFORE_REF" ]'
check "untouched is announced"         'grep -q "left untouched" "$TMP/outP6"'
check "still lays what is there"       '[ -L "$CON/.claude/skills/alpha" ]'
sed -i '/ref = "vREF"/d' "$CON/.ai.toml"
( cd "$CON" && "$KAUK" sync ) >/dev/null 2>&1 || true

echo "== origin on an owner/repo source is an error =="
CONE="$TMP/consumer-err"
git_init "$CONE"; mkdir -p "$CONE/.claude"
cat > "$CONE/.ai.toml" <<EOF
[sources."test/pkg"]
origin = "$PKG"
EOF
commit_all "$CONE"
( cd "$CONE" && "$KAUK" sync ) >"$TMP/out4" 2>&1 || true
check "origin refused with guidance"   'grep -q "origin is retired" "$TMP/out4"'
check "nothing was laid"               '[ ! -e "$CONE/.claude/skills/alpha" ]'

echo "== an owner/repo source resolves to github by default =="
CONG="$TMP/consumer-gh"
git_init "$CONG"; mkdir -p "$CONG/.claude"
cat > "$CONG/.ai.toml" <<'EOF'
[sources."test/nonexist"]
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
cat > "$CATPKG/package.toml" <<'EOF'
name = "catpkg"
title = "Categorised"
description = "A fixture with placements."
EOF
commit_all "$CATPKG"
CON5="$TMP/consumer5"
git_init "$CON5"; mkdir -p "$CON5/.claude"
cat > "$CON5/.ai.toml" <<EOF
[sources."$CATPKG"]
select = ["dev/x"]
EOF
commit_all "$CON5"
( cd "$CON5" && "$KAUK" install "$CATPKG" ) >"$TMP/out6" 2>&1 || true
check "selected subtree laid"          '[ -L "$CON5/.claude/skills/devx" ]'
check "ancestor'\''s own skill laid"   '[ -L "$CON5/.claude/skills/devroot" ]'
check "unplaced artifact always lays"  '[ -L "$CON5/.claude/skills/plain" ]'
check "other category not laid"        '[ ! -e "$CON5/.claude/skills/opsy" ]'
check "its dependency not laid either" '[ ! -e "$CON5/.claude/skills/helper" ]'
check "agent in selection laid"        '[ -L "$CON5/.claude/agents/aget.md" ]'
check "agent outside not laid"         '[ ! -e "$CON5/.claude/agents/aux.md" ]'
check "tools lay unfiltered"           '[ -L "$CON5/.claude/tools/t.py" ]'

echo "== reselection: flat-key closure pulls, deselection prunes =="
sed -i 's|select = \["dev/x"\]|select = ["ops/y"]|' "$CON5/.ai.toml"
( cd "$CON5" && "$KAUK" sync ) >"$TMP/out7" 2>&1 || true
check "roles: fallback selects"        '[ -L "$CON5/.claude/skills/opsy" ]'
check "dependencies-skills: pulled"    '[ -L "$CON5/.claude/skills/helper" ]'
check "agent'\''s skills: pulled"      '[ -L "$CON5/.claude/skills/devx" ]'
check "closure additions reported"     'grep -q "closure: +s/helper" "$TMP/out7"'
check "deselected skill pruned"        '[ ! -e "$CON5/.claude/skills/devroot" ]'
check "deselected agent pruned"        '[ ! -e "$CON5/.claude/agents/aget.md" ]'
check "unplaced artifact survives"     '[ -L "$CON5/.claude/skills/plain" ]'

echo "== a leaf entry picks one artifact =="
sed -i 's|select = \["ops/y"\]|select = ["misc/h/helper"]|' "$CON5/.ai.toml"
( cd "$CON5" && "$KAUK" sync ) >"$TMP/out8" 2>&1 || true
check "leaf-picked artifact laid"      '[ -L "$CON5/.claude/skills/helper" ]'
check "everything else pruned"         '[ ! -e "$CON5/.claude/skills/opsy" ] && [ ! -e "$CON5/.claude/skills/devx" ]'
check "unplaced still survives"        '[ -L "$CON5/.claude/skills/plain" ]'

echo "== cross-package closure by the name-rooted grammar =="
DEP="$TMP/test/dep"
git_init "$DEP"; mkdir -p "$DEP/skills/dep1"
printf -- '---\nname: dep1\ncategories: [util]\n---\nd\n' > "$DEP/skills/dep1/SKILL.md"
cat > "$DEP/package.toml" <<'EOF'
name = "dep"
title = "Dependency"
description = "Pulled in."
EOF
commit_all "$DEP"
PKG2="$TMP/test/pkg2"
git_init "$PKG2"; mkdir -p "$PKG2/skills/needy"
printf -- '---\nname: needy\ncategories: [main]\ndependencies-skills: [dep/util/dep1]\n---\nm\n' > "$PKG2/skills/needy/SKILL.md"
cat > "$PKG2/package.toml" <<'EOF'
name = "pkg2"
title = "Depends"
description = "Needs the dep package."
dependencies = ["test/dep"]
EOF
commit_all "$PKG2"
CON7="$TMP/consumer7"
git_init "$CON7"; mkdir -p "$CON7/.claude"
cat > "$CON7/.ai.toml" <<EOF
[sources."$DEP"]
select = ["nothing-here"]

[sources."$PKG2"]
select = ["main"]
EOF
commit_all "$CON7"
( cd "$CON7" && "$KAUK" install "$DEP" && "$KAUK" install "$PKG2" ) >"$TMP/out9" 2>&1 || true
check "selected artifact laid"         '[ -L "$CON7/.claude/skills/needy" ]'
check "cross-package dep laid"         '[ -L "$CON7/.claude/skills/dep1" ]'
check "cross-package closure reported" 'grep -q "closure: +dep" "$TMP/out9"'

echo "== a package dependency installs its source =="
CON8="$TMP/consumer8"
git_init "$CON8"; mkdir -p "$CON8/.claude"
cat > "$CON8/.ai.toml" <<EOF
[sources."$DEP"]
EOF
commit_all "$CON8"
( cd "$CON8" && "$KAUK" install "$PKG2" ) >"$TMP/outA" 2>&1 || true
check "package itself laid"            '[ -L "$CON8/.claude/skills/needy" ]'
check "dependency announced"           'grep -q "dependency: test/dep" "$TMP/outA"'
check "dependency contents laid"       '[ -L "$CON8/.claude/skills/dep1" ]'

echo "== a real file the user owns is reported and skipped =="
CON2="$TMP/consumer2"
git_init "$CON2"; mkdir -p "$CON2/.claude"
printf 'MINE — not kauk\n' > "$CON2/AGENTS.shared.md"
commit_all "$CON2"
( cd "$CON2" && "$KAUK" install "$PKG" ) >"$TMP/outB" 2>&1 || true
check "user file not replaced"         'grep -q "MINE" "$CON2/AGENTS.shared.md"'
check "conflict reported"              'grep -qi "blocked" "$TMP/outB"'
check "user invited to decide"         'grep -q "kauk resolve" "$TMP/outB"'
check "no agent dispatched on install" '! grep -qi "dispatching\|claude -p" "$TMP/outB"'

echo "== resolve lists conflicts and decides nothing =="
( cd "$CON2" && "$KAUK" resolve ) >"$TMP/outC" 2>&1 || true
check "resolve lists the conflict"     'grep -q "AGENTS.shared.md" "$TMP/outC"'
check "resolve shows both versions"    'grep -q "yours:" "$TMP/outC" && grep -q "package:" "$TMP/outC"'
check "resolve changes nothing"        'grep -q "MINE" "$CON2/AGENTS.shared.md"'
( cd "$CON" && "$KAUK" resolve ) >"$TMP/outD" 2>&1 || true
check "resolve is quiet when clean"    'grep -qi "nothing to resolve" "$TMP/outD"'

echo "== a name collision is namespaced, not merged =="
CON4="$TMP/consumer4"
git_init "$CON4"; mkdir -p "$CON4/.claude/skills/alpha"
printf -- '---\nname: alpha\n---\nMY OWN alpha\n' > "$CON4/.claude/skills/alpha/SKILL.md"
commit_all "$CON4"
( cd "$CON4" && "$KAUK" install "$PKG" ) >"$TMP/outE" 2>&1 || true
check "user's version kept as local:"  'grep -q "MY OWN" "$CON4/.claude/skills/local:alpha/SKILL.md"'
check "package version namespaced"     '[ -L "$CON4/.claude/skills/pkg:alpha" ]'
check "bare name no longer occupied"   '[ ! -e "$CON4/.claude/skills/alpha" ]'
check "namespacing is announced"       'grep -qi "namespaced" "$TMP/outE"'

echo "== no runtime detected: nothing is laid =="
CON3="$TMP/consumer3"
git_init "$CON3"
printf 'placeholder\n' > "$CON3/.keep"; commit_all "$CON3" "empty" >/dev/null
( cd "$CON3" && "$KAUK" install "$PKG" ) >"$TMP/outF" 2>&1 || true
check "nothing laid without a runtime" '[ ! -e "$CON3/.claude/skills/alpha" ]'
check "detection explained"            'grep -qi "no agent runtime detected" "$TMP/outF"'

echo "== a package that is its own source is not vendored =="
SELF="$TMP/test/selfpkg"
git_init "$SELF"
mkdir -p "$SELF/skills/own" "$SELF/.claude"
printf -- '---\nname: own\n---\nself\n' > "$SELF/skills/own/SKILL.md"
cat > "$SELF/package.toml" <<'EOF'
name = "selfpkg"
title = "Self"
description = "Publishes into itself."
EOF
cat > "$SELF/.ai.toml" <<EOF
[sources."$SELF"]
EOF
commit_all "$SELF"
( cd "$SELF" && "$KAUK" sync ) >"$TMP/outG" 2>&1 || true
check "self-source not cloned"         '[ ! -d "$SELF/.ai/repositories/test/selfpkg" ]'
check "self-source published by copy"  '[ -f "$SELF/.claude/skills/own/SKILL.md" ] && [ ! -L "$SELF/.claude/skills/own" ]'
check "self-publish is idempotent"     '( cd "$SELF" && "$KAUK" sync >/dev/null 2>&1 ); [ -f "$SELF/.claude/skills/own/SKILL.md" ]'

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
