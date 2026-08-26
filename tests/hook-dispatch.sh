#!/usr/bin/env bash
# Fixture test for bin/kai-hooks.sh — the static hook dispatcher installed
# beside the kai executable — and for bin/kai.settings.json, the settings
# file whose five hook commands resolve kai-hooks.sh next to kai itself.
# Builds a throwaway source + consumer repo pair under a temp dir, points
# the consumer's .ai.toml at the source, and asserts on what the dispatcher
# does for each event/action case. No case here is allowed to SKIP: every
# check either runs for real or fails — a check that quietly does nothing
# on some machine and leaves the suite green is exactly the defect this
# file exists to catch.
#
#   tests/hook-dispatch.sh          run all cases
set -uo pipefail

HOOKS=$(cd "$(dirname "$0")/.." && pwd)/bin/kai-hooks.sh
SETTINGS=$(cd "$(dirname "$0")/.." && pwd)/bin/kai.settings.json
KAUKEA=$(cd "$(dirname "$0")/.." && pwd)/bin/kaukea
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
no()   { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else no "$1"; fi; }

git_init() { mkdir -p "$1"; git -C "$1" init -q; }

# settings_field <event> <command|timeout> -> that field's raw JSON text
# (still quoted/escaped for "command"). Pure awk/sed, no jq: the whole point
# of this suite is that it never silently skips a case for want of a tool.
settings_field() {
  awk -v evt="\"$1\":" -v field="\"$2\":" '
    index($0, evt) { on=1 }
    on && index($0, field) {
      line=$0
      sub(/^[^:]*:[[:space:]]*/, "", line)
      sub(/,[[:space:]]*$/, "", line)
      print line
      exit
    }
  ' "$SETTINGS"
}

# settings_command <event> -> that event's shell command, unescaped and
# unquoted, ready for `sh -c`.
settings_command() {
  settings_field "$1" command | sed -e 's/^"//' -e 's/"$//' -e 's/\\"/"/g'
}

# ---------------------------------------------------------------- the source
SRC="$TMP/src/pkg"
mkdir -p "$SRC/hooks/session.start" "$SRC/hooks/session.end" \
         "$SRC/hooks/compose.check" "$SRC/hooks/multiline.check" \
         "$SRC/hooks/vocab.check"

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

# defect 2: two scripts matched by one glob, both emitting hookSpecificOutput.
cat > "$SRC/hooks/compose.check/index.toml" <<'EOF'
description = "fixture: two scripts that both emit hookSpecificOutput"

[[actions]]
scripts = ["*.sh"]
EOF
cat > "$SRC/hooks/compose.check/a.sh" <<'EOF'
#!/bin/sh
printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"MARKER_ALPHA"}}\n'
EOF
cat > "$SRC/hooks/compose.check/b.sh" <<'EOF'
#!/bin/sh
printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"MARKER_BETA"}}\n'
EOF
chmod +x "$SRC/hooks/compose.check/a.sh" "$SRC/hooks/compose.check/b.sh"

# defect 4: a scripts array split across multiple physical lines.
cat > "$SRC/hooks/multiline.check/index.toml" <<'EOF'
description = "fixture: a multi-line TOML array"

[[actions]]
scripts = [
  "*.sh",
]
EOF
cat > "$SRC/hooks/multiline.check/stub.sh" <<'EOF'
#!/bin/sh
: > "$MULTILINE_OUT"
EOF
chmod +x "$SRC/hooks/multiline.check/stub.sh"

# defect 6: the two documented-but-unimplemented actions, distinct from a typo.
cat > "$SRC/hooks/vocab.check/index.toml" <<'EOF'
description = "fixture: documented vocabulary this dispatcher does not run yet"

[[actions]]
inject-context = "some context"

[[actions]]
notify = { text = "hi", level = "warn" }
EOF

# --------------------------------------------------------------- the consumer
CON="$TMP/consumer"
git_init "$CON"
cat > "$CON/.ai.toml" <<EOF
[[dependency]]
source = "$SRC"
EOF

echo "== a scripts action runs the matching script, stdin passed through =="
STUB_OUT="$TMP/stub.out"
echo '{"hook":"data"}' | ( cd "$CON" && STUB_OUT="$STUB_OUT" "$HOOKS" session.start ) >"$TMP/out1" 2>&1
RC1=$?
check "exits 0"                        '[ "$RC1" -eq 0 ]'
check "script ran"                     '[ -f "$STUB_OUT" ]'
check "hook stdin reached the script"  'grep -q '"'"'{"hook":"data"}'"'"' "$STUB_OUT"'

echo "== an unrecognised action key is a loud error and does not abort =="
OUT2=$( cd "$CON" && "$HOOKS" session.end 2>&1 ); RC2=$?
check "exits 0"                        '[ "$RC2" -eq 0 ]'
check "unknown key named as an error on stderr" \
  'printf "%s" "$OUT2" | grep -q '"'"'ERROR: "frobnicate".*not a recognised hooks/ action'"'"''

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

echo "== defect 2: two scripts under one event compose into ONE valid JSON object =="
OUT7=$( cd "$CON" && "$HOOKS" compose.check 2>/dev/null ); RC7=$?
check "exits 0"                            '[ "$RC7" -eq 0 ]'
check "both scripts contributed"           'printf "%s" "$OUT7" | grep -q MARKER_ALPHA && printf "%s" "$OUT7" | grep -q MARKER_BETA'
check "not naive concatenation (no }{ )"   '! printf "%s" "$OUT7" | grep -q "}{"'
check "exactly one top-level object"       '[ "$(printf "%s" "$OUT7" | grep -o hookSpecificOutput | wc -l)" -eq 1 ]'
check "parses as valid JSON" \
  'printf "%s" "$OUT7" | python3 -c "import json,sys; json.loads(sys.stdin.read())"'

echo "== defect 4: a multi-line TOML array still runs its scripts =="
MULTILINE_OUT="$TMP/multiline.out"
OUT8=$( cd "$CON" && MULTILINE_OUT="$MULTILINE_OUT" "$HOOKS" multiline.check 2>&1 ); RC8=$?
check "exits 0"                        '[ "$RC8" -eq 0 ]'
check "script from the multi-line array ran" '[ -f "$MULTILINE_OUT" ]'

echo "== defect 6: documented-but-unimplemented actions are distinguished from a typo =="
OUT9=$( cd "$CON" && "$HOOKS" vocab.check 2>&1 ); RC9=$?
check "exits 0"                        '[ "$RC9" -eq 0 ]'
check "inject-context named as documented, not an error" \
  'printf "%s" "$OUT9" | grep -q '"'"'action "inject-context" is documented but not yet implemented'"'"''
check "notify named as documented, not an error" \
  'printf "%s" "$OUT9" | grep -q '"'"'action "notify" is documented but not yet implemented'"'"''
check "neither is reported via the invalid-action (ERROR) wording" \
  '! printf "%s" "$OUT9" | grep -q "ERROR:"'

echo "== defect 5: a malformed .ai.toml source is named and ignored, not silently dropped =="
CON3="$TMP/consumer-badsrc"; git_init "$CON3"
cat > "$CON3/.ai.toml" <<EOF
[[dependency]]
source = "$SRC"

[[dependency]]
source = "bogus"
EOF
STUB_OUT10="$TMP/stub10.out"
OUT10=$( cd "$CON3" && STUB_OUT="$STUB_OUT10" "$HOOKS" session.start 2>&1 >/dev/null ); RC10=$?
check "exits 0"                            '[ "$RC10" -eq 0 ]'
check "bad source named on stderr"         'printf "%s" "$OUT10" | grep -q '"'"'source "bogus"'"'"''
check "bad source flagged as no form"      'printf "%s" "$OUT10" | grep -q "is not <owner>/<repo>, a git URI, or a path"'
check "the valid sibling source still ran" '[ -f "$STUB_OUT10" ]'
# bin/kaukea's own deps_list (the other end of this contract) must trigger
# on exactly the same shapes it accepts — read-only comparison, this
# suite does not invoke bin/kaukea's CLI (it may be mid-edit by a sibling
# task and is out of this file's ownership).
KSRC_FN=$(sed -n '/^deps_list() {/,/^}/p' "$KAUKEA")
check "bin/kaukea accepts an absolute path the same way"   'printf "%s" "$KSRC_FN" | grep -q '"'"'/\*)'"'"''
check "bin/kaukea accepts owner/repo the same way"         'printf "%s" "$KSRC_FN" | grep -q '"'"'\*/\*)'"'"''
check "bin/kaukea warns on anything else, same as kai-hooks.sh" \
  'printf "%s" "$KSRC_FN" | grep -q "is not <owner>/<repo>, a git URI, or a path"'

echo "== settings.json: all five hook entries carry a timeout (courier-init.sh was unbounded) =="
expect_timeout() {  # expect_timeout <event> -> the timeout it must carry (matches the
                     # settings file kai.settings.json replaced: 10s for session
                     # start/end, 5s for the rest). No bash arrays, kept 3.2-safe.
  case "$1" in
    SessionStart|SessionEnd) printf '10' ;;
    *)                       printf '5' ;;
  esac
}
for evt in SessionStart SessionEnd PreToolUse UserPromptSubmit Notification; do
  to=$(settings_field "$evt" timeout)
  want=$(expect_timeout "$evt")
  check "$evt timeout is ${want}s"  '[ "$to" = "$want" ]'
done

echo "== defect 1: kai symlink resolution survives a BSD readlink with no -f support =="
# Reproduction rig: a fake 'kai' that is a SYMLINK on PATH (as a real install
# has it, e.g. ~/.local/bin/kai -> the repo where kai-hooks.sh lives), and a
# fake 'readlink' shadowing PATH ahead of it that rejects -f exactly like
# BSD/macOS readlink does. Every one of the five settings.json commands must
# still find and run kai-hooks.sh under this rig.
REAL="$TMP/install"
mkdir -p "$REAL"
cp "$HOOKS" "$REAL/kai-hooks.sh"; chmod +x "$REAL/kai-hooks.sh"
: > "$REAL/kaukea"; chmod +x "$REAL/kaukea"

LINKDIR="$TMP/path-bin"
mkdir -p "$LINKDIR"
ln -s "$REAL/kaukea" "$LINKDIR/kai"

BSDBIN="$TMP/bsd-bin"
mkdir -p "$BSDBIN"
cat > "$BSDBIN/readlink" <<'EOF'
#!/bin/sh
# Stands in for BSD/macOS readlink: no -f extension at all.
for a in "$@"; do
  case "$a" in
    -f) echo "readlink: illegal option -- f" >&2; exit 1 ;;
  esac
done
exec /bin/readlink "$@"
EOF
chmod +x "$BSDBIN/readlink"

# Prove the rig actually reproduces the original bug before trusting it to
# clear the fix: the pre-fix resolution (readlink -f, falling back to the
# unresolved path on failure) must fail to find kai-hooks.sh under it.
OLD_CMD='k=$(command -v kai 2>/dev/null); [ -n "$k" ] || exit 0; k=$(readlink -f "$k" 2>/dev/null || printf "%s" "$k"); h="$(dirname "$k")/kai-hooks.sh"; [ -x "$h" ] && "$h" session.start; exit 0'
OLD_MARK="$TMP/old-stub.out"
( cd "$CON" && PATH="$BSDBIN:$LINKDIR:$PATH" STUB_OUT="$OLD_MARK" sh -c "$OLD_CMD" ) >/dev/null 2>&1
check "rig reproduces the pre-fix bug (old resolution finds nothing under it)" '[ ! -f "$OLD_MARK" ]'

for evt in SessionStart SessionEnd PreToolUse UserPromptSubmit Notification; do
  CMD=$(settings_command "$evt")
  OUT=$( cd "$CON" && PATH="$BSDBIN:$LINKDIR:$PATH" sh -c "$CMD" 2>&1 ); RC=$?
  check "$evt: exits 0 under a BSD readlink"          '[ "$RC" -eq 0 ]'
done

# The above loop proves exit-0 survival; confirm actual resolution reached
# kai-hooks.sh (not just a no-op early exit) via the one event with a real
# script attached in the fixture: session.start.
SS_CMD=$(settings_command SessionStart)
SS_MARK="$TMP/bsd-session.start.out"
( cd "$CON" && PATH="$BSDBIN:$LINKDIR:$PATH" STUB_OUT="$SS_MARK" sh -c "$SS_CMD" ) >/dev/null 2>&1
check "SessionStart under a BSD readlink actually ran kai-hooks.sh's dispatch" '[ -f "$SS_MARK" ]'

echo "== all five settings.json commands use the identical resolution logic =="
FIRST_RESOLUTION=""
DIVERGED=0
for evt in SessionStart SessionEnd PreToolUse UserPromptSubmit Notification; do
  CMD=$(settings_command "$evt")
  RES=${CMD%%h=*}   # everything up to the "h=" that builds the kai-hooks.sh path
  if [ -z "$FIRST_RESOLUTION" ]; then
    FIRST_RESOLUTION=$RES
  elif [ "$RES" != "$FIRST_RESOLUTION" ]; then
    DIVERGED=1
  fi
done
check "resolution prefix is identical across all five hook commands" '[ "$DIVERGED" -eq 0 ]'

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
