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

echo "== idempotence =="
( cd "$CON" && "$KAUK" sync ) >"$TMP/out2" 2>&1 || true
check "second run keeps the skill"     '[ -L "$CON/.claude/skills/alpha" ]'
check "second run reports no error"    '! grep -qi "error\|refusing" "$TMP/out2"'

echo "== a file added to the package needs no index edit =="
mkdir -p "$PKG/skills/gamma"
printf -- '---\nname: gamma\n---\nnew\n' > "$PKG/skills/gamma/SKILL.md"
printf -- '---\nname: delta\n---\np\n' > "$PKG/agents/delta.md"
commit_all "$PKG" "add gamma and delta"
( cd "$CON" && "$KAUK" sync ) >"$TMP/out3" 2>&1 || true
check "new skill distributed"          '[ -L "$CON/.claude/skills/gamma" ]'
check "new agent distributed"          '[ -L "$CON/.claude/agents/delta.md" ]'

echo "== removal prunes =="
rm -rf "$PKG/skills/gamma"; commit_all "$PKG" "remove gamma"
( cd "$CON" && "$KAUK" sync ) >"$TMP/out4" 2>&1 || true
check "removed skill pruned"           '[ ! -e "$CON/.claude/skills/gamma" ]'

echo "== a real file the user owns is reported and skipped =="
CON2="$TMP/consumer2"
git_init "$CON2"; mkdir -p "$CON2/.claude"
printf 'MINE — not kauk\n' > "$CON2/AGENTS.shared.md"
commit_all "$CON2"
( cd "$CON2" && "$KAUK" install test/pkg "$PKG" ) >"$TMP/out5" 2>&1 || true
check "user file not replaced"         'grep -q "MINE" "$CON2/AGENTS.shared.md"'
check "conflict reported"              'grep -qi "blocked\|uncommitted" "$TMP/out5"'

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

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
