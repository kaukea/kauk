#!/usr/bin/env bash
# Fixture test for the convention reader: a package declares nothing, its tree is
# the contract. Builds throwaway git repositories under a temp dir, runs the real
# bin/kauk against them, and asserts on what landed.
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

git_init() { # git_init <dir>
  mkdir -p "$1"; git -C "$1" init -q
  git -C "$1" config user.email t@example.com
  git -C "$1" config user.name Test
}
commit_all() { git -C "$1" add -A && git -C "$1" commit -qm "${2:-fixture}"; }

# ---------------------------------------------------------------- the package
PKG="$TMP/pkg"
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
mkdir -p "$CON/.claude"                       # marks it a Claude repository
printf 'placeholder\n' > "$CON/.claude/.keep"
commit_all "$CON"

echo "== install a package that declares nothing =="
( cd "$CON" && "$KAUK" install test/pkg "$PKG" ) >"$TMP/out1" 2>&1 || true
sed 's/^/     /' "$TMP/out1"

check "skill laid from skills/"        '[ -L "$CON/.claude/skills/alpha" ]'
check "agent laid from agents/"        '[ -L "$CON/.claude/agents/beta.md" ]'
check "hook laid from hooks/"          '[ -L "$CON/.claude/hooks/on-start.sh" ]'
check "tool laid from tools/"          '[ -L "$CON/.claude/tools/helper.py" ]'
check "files/ mirrors to repo root"    '[ -L "$CON/AGENTS.shared.md" ]'
check "files/ keeps nested paths"      '[ -L "$CON/.github/workflows/ci.yml" ]'
check "skill content readable"         'grep -q body "$CON/.claude/skills/alpha/SKILL.md"'
check "docs/ ignored"                  '[ ! -e "$CON/docs/design.md" ]'
check "README.md ignored"              '[ ! -e "$CON/README.md" ]'
check "no manifest.conf anywhere"      '[ ! -e "$PKG/manifest.conf" ]'
check "install writes the lock"        'grep -q "test/pkg" "$CON/.ai.lock" && grep -Eq "sha = \"[0-9a-f]{40}\"" "$CON/.ai.lock"'

echo "== idempotence =="
( cd "$CON" && "$KAUK" sync ) >"$TMP/out2" 2>&1 || true
check "second run keeps the skill"     '[ -L "$CON/.claude/skills/alpha" ]'
check "second run reports no error"    '! grep -qi "error\|refusing" "$TMP/out2"'

echo "== an addition arrives on update, never on sync =="
mkdir -p "$PKG/skills/gamma"
printf -- '---\nname: gamma\n---\nnew\n' > "$PKG/skills/gamma/SKILL.md"
printf -- '---\nname: delta\n---\np\n' > "$PKG/agents/delta.md"
commit_all "$PKG" "add gamma and delta"
( cd "$CON" && "$KAUK" sync ) >"$TMP/out3a" 2>&1 || true
check "sync holds the pin"             '[ ! -e "$CON/.claude/skills/gamma" ]'
( cd "$CON" && "$KAUK" update ) >"$TMP/out3" 2>&1 || true
check "update distributes the skill"   '[ -L "$CON/.claude/skills/gamma" ]'
check "update distributes the agent"   '[ -L "$CON/.claude/agents/delta.md" ]'
check "update moves the lock"          'grep -q "$(git -C "$PKG" rev-parse HEAD)" "$CON/.ai.lock"'

echo "== removal prunes, and update warns about it =="
rm -rf "$PKG/skills/gamma"; commit_all "$PKG" "remove gamma"
( cd "$CON" && "$KAUK" update ) >"$TMP/out4" 2>&1 || true
check "removed skill pruned"           '[ ! -e "$CON/.claude/skills/gamma" ]'
check "removal warned for sessions"    'grep -q "s/gamma" "$TMP/out4"'

echo "== a real file the user owns is reported and skipped =="
CON2="$TMP/consumer2"
git_init "$CON2"; mkdir -p "$CON2/.claude"
printf 'MINE — not kauk\n' > "$CON2/AGENTS.shared.md"
commit_all "$CON2"
( cd "$CON2" && "$KAUK" install test/pkg "$PKG" ) >"$TMP/out5" 2>&1 || true
check "user file not replaced"         'grep -q "MINE" "$CON2/AGENTS.shared.md"'
check "conflict reported"              'grep -qi "blocked" "$TMP/out5"'
check "user invited to decide"         'grep -q "kauk resolve" "$TMP/out5"'
# NEVER auto-dispatch an agent: an install must not start a Claude session.
check "no agent dispatched on install" '! grep -qi "dispatching\|claude -p" "$TMP/out5"'

echo "== resolve lists conflicts and decides nothing =="
( cd "$CON2" && "$KAUK" resolve ) >"$TMP/out8" 2>&1 || true
check "resolve lists the conflict"     'grep -q "AGENTS.shared.md" "$TMP/out8"'
check "resolve shows both versions"    'grep -q "yours:" "$TMP/out8" && grep -q "package:" "$TMP/out8"'
check "resolve changes nothing"        'grep -q "MINE" "$CON2/AGENTS.shared.md"'
check "resolve offers assist, no run"  'grep -q -- "--assist" "$TMP/out8" && ! grep -qi "attempting an assisted" "$TMP/out8"'
( cd "$CON" && "$KAUK" resolve ) >"$TMP/out9" 2>&1 || true
check "resolve is quiet when clean"    'grep -qi "nothing to resolve" "$TMP/out9"'

echo "== a name collision is namespaced, not merged =="
CON4="$TMP/consumer4"
git_init "$CON4"; mkdir -p "$CON4/.claude/skills/alpha"
printf -- '---\nname: alpha\n---\nMY OWN alpha\n' > "$CON4/.claude/skills/alpha/SKILL.md"
commit_all "$CON4"
( cd "$CON4" && "$KAUK" install test/pkg "$PKG" ) >"$TMP/outA" 2>&1 || true
check "user's version kept as local:"  'grep -q "MY OWN" "$CON4/.claude/skills/local:alpha/SKILL.md"'
check "package version namespaced"     '[ -L "$CON4/.claude/skills/pkg:alpha" ]'
check "package content is the package" 'grep -q "^body" "$CON4/.claude/skills/pkg:alpha/SKILL.md"'
check "bare name no longer occupied"   '[ ! -e "$CON4/.claude/skills/alpha" ]'
check "namespacing is announced"       'grep -qi "namespaced" "$TMP/outA"'
check "non-colliding skill unchanged"  '[ -L "$CON4/.claude/agents/beta.md" ]'
( cd "$CON4" && "$KAUK" sync ) >"$TMP/outB" 2>&1 || true
check "namespacing is idempotent"      '[ ! -e "$CON4/.claude/skills/alpha" ] && [ -L "$CON4/.claude/skills/pkg:alpha" ]'
check "local version survives sync"    'grep -q "MY OWN" "$CON4/.claude/skills/local:alpha/SKILL.md"'

echo "== no runtime detected: nothing is laid =="
CON3="$TMP/consumer3"
git_init "$CON3"
printf 'placeholder\n' > "$CON3/.keep"; commit_all "$CON3" "empty" >/dev/null
( cd "$CON3" && "$KAUK" install test/pkg "$PKG" ) >"$TMP/out6" 2>&1 || true
check "nothing laid without a runtime" '[ ! -e "$CON3/.claude/skills/alpha" ]'
check "detection explained"            'grep -qi "no agent runtime detected" "$TMP/out6"'

echo "== a package that is its own source is not vendored =="
SELF="$TMP/selfpkg"
git_init "$SELF"
mkdir -p "$SELF/skills/own" "$SELF/.claude"
printf -- '---\nname: own\n---\nself\n' > "$SELF/skills/own/SKILL.md"
cat > "$SELF/package.toml" <<'EOF'
name = "selfpkg"
title = "Self"
description = "Publishes into itself."
EOF
cat > "$SELF/.ai.toml" <<EOF
[sources."test/selfpkg"]
origin = "$SELF"
EOF
commit_all "$SELF"
( cd "$SELF" && "$KAUK" sync ) >"$TMP/out7" 2>&1 || true
sed 's/^/     /' "$TMP/out7"
check "self-source not cloned"         '[ ! -d "$SELF/.ai/repositories/test/selfpkg" ]'
check "self-source published by copy"  '[ -f "$SELF/.claude/skills/own/SKILL.md" ] && [ ! -L "$SELF/.claude/skills/own" ]'
check "self-publish is idempotent"     '( cd "$SELF" && "$KAUK" sync >/dev/null 2>&1 ); [ -f "$SELF/.claude/skills/own/SKILL.md" ]'
check "self-source records no head"    '[ ! -f "$SELF/.ai.lock" ] || ! grep -q selfpkg "$SELF/.ai.lock"'

echo "== a fresh clone plus the lock reproduces the pinned head =="
LOCKED=$(git -C "$CON/.ai/repositories/test/pkg" rev-parse HEAD)
mkdir -p "$PKG/skills/zeta"
printf -- '---\nname: zeta\n---\nz\n' > "$PKG/skills/zeta/SKILL.md"
commit_all "$PKG" "zeta, beyond the pin"
rm -rf "$CON/.ai/repositories"
( cd "$CON" && "$KAUK" sync ) >"$TMP/outC" 2>&1 || true
check "clone recreated"                '[ -d "$CON/.ai/repositories/test/pkg/.git" ]'
check "checked out at the locked sha"  '[ "$(git -C "$CON/.ai/repositories/test/pkg" rev-parse HEAD)" = "$LOCKED" ]'
check "content beyond the pin absent"  '[ ! -e "$CON/.claude/skills/zeta" ]'

echo "== a tag is a valid pin =="
git -C "$PKG" tag v1
mkdir -p "$PKG/skills/afterv1"
printf -- '---\nname: afterv1\n---\nlate\n' > "$PKG/skills/afterv1/SKILL.md"
commit_all "$PKG" "after the tag"
CON6="$TMP/consumer6"
git_init "$CON6"; mkdir -p "$CON6/.claude"
cat > "$CON6/.ai.toml" <<EOF
[sources."test/pkg"]
origin = "$PKG"
ref = "v1"
EOF
commit_all "$CON6"
( cd "$CON6" && "$KAUK" install test/pkg ) >"$TMP/outD" 2>&1 || true
check "tag pin honoured"               '[ "$(git -C "$CON6/.ai/repositories/test/pkg" rev-parse HEAD)" = "$(git -C "$PKG" rev-parse "v1^{commit}")" ]'
check "content after the tag absent"   '[ ! -e "$CON6/.claude/skills/afterv1" ]'
check "lock records the ref"           'grep -q "ref = \"v1\"" "$CON6/.ai.lock"'
( cd "$CON6" && "$KAUK" update ) >"$TMP/outD2" 2>&1 || true
check "update keeps a tag pin"         'grep -q "already at" "$TMP/outD2" && [ ! -e "$CON6/.claude/skills/afterv1" ]'

echo "== selection by category trims what lays =="
CATPKG="$TMP/catpkg"
git_init "$CATPKG"
mkdir -p "$CATPKG/skills/devx" "$CATPKG/skills/devroot" "$CATPKG/skills/opsy" \
         "$CATPKG/skills/helper" "$CATPKG/skills/plain" "$CATPKG/agents" "$CATPKG/tools"
printf -- '---\nname: devx\ncategories: [dev/x]\n---\nx\n'      > "$CATPKG/skills/devx/SKILL.md"
printf -- '---\nname: devroot\ncategories: [dev]\n---\nr\n'     > "$CATPKG/skills/devroot/SKILL.md"
printf -- '---\nname: opsy\ncategories: [ops/y]\ndependencies:\n  skills: [helper]\n---\ny\n' > "$CATPKG/skills/opsy/SKILL.md"
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
[sources."test/catpkg"]
origin = "$CATPKG"
categories = ["dev/x"]
EOF
commit_all "$CON5"
( cd "$CON5" && "$KAUK" install test/catpkg ) >"$TMP/outE" 2>&1 || true
check "selected subtree laid"          '[ -L "$CON5/.claude/skills/devx" ]'
check "ancestor'\''s own skill laid"   '[ -L "$CON5/.claude/skills/devroot" ]'
check "unplaced artifact always lays"  '[ -L "$CON5/.claude/skills/plain" ]'
check "other category not laid"        '[ ! -e "$CON5/.claude/skills/opsy" ]'
check "its dependency not laid either" '[ ! -e "$CON5/.claude/skills/helper" ]'
check "agent in selection laid"        '[ -L "$CON5/.claude/agents/aget.md" ]'
check "agent outside not laid"         '[ ! -e "$CON5/.claude/agents/aux.md" ]'
check "tools lay unfiltered"           '[ -L "$CON5/.claude/tools/t.py" ]'

echo "== reselection converges: closure pulls, deselection prunes =="
sed -i 's|categories = \["dev/x"\]|categories = ["ops/y"]|' "$CON5/.ai.toml"
( cd "$CON5" && "$KAUK" sync ) >"$TMP/outF" 2>&1 || true
check "new selection laid"             '[ -L "$CON5/.claude/skills/opsy" ]'
check "skill dependency pulled"        '[ -L "$CON5/.claude/skills/helper" ]'
check "agent'\''s skills: pulled"      '[ -L "$CON5/.claude/skills/devx" ]'
check "closure additions reported"     'grep -q "closure: +s/helper" "$TMP/outF"'
check "deselected skill pruned"        '[ ! -e "$CON5/.claude/skills/devroot" ]'
check "deselected agent pruned"        '[ ! -e "$CON5/.claude/agents/aget.md" ]'
check "unplaced artifact survives"     '[ -L "$CON5/.claude/skills/plain" ]'

echo "== a package pulls the packages it depends on =="
DEP="$TMP/dep"
git_init "$DEP"; mkdir -p "$DEP/skills/dep1"
printf -- '---\nname: dep1\n---\nd\n' > "$DEP/skills/dep1/SKILL.md"
cat > "$DEP/package.toml" <<'EOF'
name = "dep"
title = "Dependency"
description = "Pulled in."
EOF
commit_all "$DEP"
PKG2="$TMP/pkg2"
git_init "$PKG2"; mkdir -p "$PKG2/skills/main1"
printf -- '---\nname: main1\n---\nm\n' > "$PKG2/skills/main1/SKILL.md"
cat > "$PKG2/package.toml" <<'EOF'
name = "pkg2"
title = "Depends"
description = "Needs test/dep."
dependencies = ["test/dep"]
EOF
commit_all "$PKG2"
CON7="$TMP/consumer7"
git_init "$CON7"; mkdir -p "$CON7/.claude"
cat > "$CON7/.ai.toml" <<EOF
[sources."test/dep"]
origin = "$DEP"
EOF
commit_all "$CON7"
( cd "$CON7" && "$KAUK" install test/pkg2 "$PKG2" ) >"$TMP/outG" 2>&1 || true
check "package itself laid"            '[ -L "$CON7/.claude/skills/main1" ]'
check "dependency package laid"        '[ -L "$CON7/.claude/skills/dep1" ]'
check "dependency announced"           'grep -q "dependency: test/dep" "$TMP/outG"'
check "both pinned in the lock"        'grep -q "test/pkg2" "$CON7/.ai.lock" && grep -q "test/dep" "$CON7/.ai.lock"'

echo "== update runs pending migrations =="
mkdir -p "$PKG/migrations"
cat > "$PKG/migrations/2026-01-01-touch.md" <<'EOF'
# fixture migration

```sh
touch mig-ran
```
EOF
commit_all "$PKG" "ship a migration"
( cd "$CON" && "$KAUK" update ) >"$TMP/outH" 2>&1 || true
check "scripted step ran in consumer"  '[ -f "$CON/mig-ran" ]'
check "watermark advanced per package" 'grep -q "2026-01-01-touch" "$CON/.git/the-works/migrated/test/pkg"'

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
