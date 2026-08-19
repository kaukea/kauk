#!/usr/bin/env bash
# Fixture test for bin/kai-hooks.sh — the static hook dispatcher installed
# beside the kai executable. Builds a throwaway source + consumer repo pair
# under a temp dir, points the consumer's .ai.toml at the source, and asserts
# on what the dispatcher does for each event/action case.
#
#   tests/hook-dispatch.sh          run all cases
set -uo pipefail

HOOKS=$(cd "$(dirname "$0")/.." && pwd)/bin/kai-hooks.sh
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
no()   { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else no "$1"; fi; }

git_init() { mkdir -p "$1"; git -C "$1" init -q; }

# ---------------------------------------------------------------- the source
SRC="$TMP/src/pkg"
mkdir -p "$SRC/hooks/session.start" "$SRC/hooks/session.end"
cat > "$SRC/hooks/session.start/index.toml" <<'EOF'
description = "fixture: a scripts action, and a not-yet-implemented action"

[[actions]]
scripts = ["*.sh"]

[[actions]]
notify = { text = "hi", level = "warn" }
compatibility = ["claude"]
EOF
cat > "$SRC/hooks/session.start/stub.sh" <<'EOF'
#!/bin/sh
printf 'STUB RAN: %s\n' "$(cat -)" > "$STUB_OUT"
EOF
chmod +x "$SRC/hooks/session.start/stub.sh"
cat > "$SRC/hooks/session.end/index.toml" <<'EOF'
description = "fixture: an unrecognised action key"

[[actions]]
frobnicate = "nope"
EOF

# --------------------------------------------------------------- the consumer
CON="$TMP/consumer"
git_init "$CON"
cat > "$CON/.ai.toml" <<EOF
[sources."$SRC"]
EOF

echo "== a scripts action runs the matching script, stdin passed through =="
STUB_OUT="$TMP/stub.out"
echo '{"hook":"data"}' | ( cd "$CON" && STUB_OUT="$STUB_OUT" "$HOOKS" session.start ) >"$TMP/out1" 2>&1
RC1=$?
check "exits 0"                        '[ "$RC1" -eq 0 ]'
check "script ran"                     '[ -f "$STUB_OUT" ]'
check "hook stdin reached the script"  'grep -q '"'"'{"hook":"data"}'"'"' "$STUB_OUT"'

echo "== an unrecognised action key is reported and does not abort =="
OUT2=$( cd "$CON" && "$HOOKS" session.end 2>&1 ); RC2=$?
check "exits 0"                        '[ "$RC2" -eq 0 ]'
check "unknown key named on stderr"    'printf "%s" "$OUT2" | grep -q "unrecognised action \"frobnicate\""'

echo "== an unknown event produces nothing and exits 0 =="
OUT3=$( cd "$CON" && "$HOOKS" bogus.event 2>&1 ); RC3=$?
check "no output"                      '[ -z "$OUT3" ]'
check "exits 0"                        '[ "$RC3" -eq 0 ]'

echo "== no event argument produces nothing and exits 0 =="
OUT4=$( cd "$CON" && "$HOOKS" 2>&1 ); RC4=$?
check "no output"                      '[ -z "$OUT4" ]'
check "exits 0"                        '[ "$RC4" -eq 0 ]'

echo "== no sources in .ai.toml produces nothing and exits 0 =="
CON2="$TMP/consumer-nosrc"; git_init "$CON2"; : > "$CON2/.ai.toml"
OUT5=$( cd "$CON2" && "$HOOKS" session.start 2>&1 ); RC5=$?
check "no output"                      '[ -z "$OUT5" ]'
check "exits 0"                        '[ "$RC5" -eq 0 ]'

echo "== no matching hook directory produces nothing and exits 0 =="
OUT6=$( cd "$CON" && "$HOOKS" prompt.submit 2>&1 ); RC6=$?
check "no output"                      '[ -z "$OUT6" ]'
check "exits 0"                        '[ "$RC6" -eq 0 ]'

echo "== settings.json hook command resolves kai-hooks.sh through a symlinked kai =="
# Regression for the resolution defect fixed alongside this test: a real
# install has kai on PATH as a SYMLINK (e.g. ~/.local/bin/kai) pointing at
# the repo where kai-hooks.sh actually lives. dirname on the unresolved
# symlink path lands in the symlink's own directory, not the repo's -- the
# hook command must readlink -f the symlink before taking dirname, exactly
# as tools/dispatch-agent.sh already does for kai.settings.json.
SETTINGS="$(cd "$(dirname "$0")/.." && pwd)/bin/kai.settings.json"
command -v jq >/dev/null 2>&1 || { echo "  SKIP settings.json symlink case (jq not installed)"; }
if command -v jq >/dev/null 2>&1; then
  HOOK_CMD=$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$SETTINGS")

  REAL="$TMP/install"                       # where kai-hooks.sh actually lives
  mkdir -p "$REAL"
  cp "$HOOKS" "$REAL/kai-hooks.sh"
  chmod +x "$REAL/kai-hooks.sh"
  : > "$REAL/kaukea"; chmod +x "$REAL/kaukea" # stand-in for the real kai binary

  LINKDIR="$TMP/path-bin"                   # a DIFFERENT dir, on PATH
  mkdir -p "$LINKDIR"
  ln -s "$REAL/kaukea" "$LINKDIR/kai"       # kai is a symlink here, not the real file

  STUB_OUT7="$TMP/stub7.out"
  OUT7=$(cd "$CON" && PATH="$LINKDIR:$PATH" STUB_OUT="$STUB_OUT7" sh -c "$HOOK_CMD" 2>&1)
  RC7=$?
  check "exits 0"                        '[ "$RC7" -eq 0 ]'
  check "hooks.sh ran via resolved symlink" '[ -f "$STUB_OUT7" ]'
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
