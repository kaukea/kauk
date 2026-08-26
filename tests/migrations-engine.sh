#!/usr/bin/env bash
# Black-box suite for the reduced migration engine: one global watermark
# committed at .ai/migrations.toml, every dependency's migrations/ (plus this
# repository's own when the root table says type = "package") merged into a single
# stream ordered by the <YYYY-MM-DD>-<NN> filename prefix, an absent watermark
# meaning everything is pending, and errors reported rather than blocking. Builds
# throwaway git repositories under a temp dir and runs the real bin/kai
# against them, then diffs what actually happened on disk.
#
#   tests/migrations-engine.sh          run all cases
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

mig() { # mig <dir> <filename> <marker-line> — a migration whose scripted
        # step appends <marker-line> to order.log at the consumer root
  printf '# fixture migration\n\n```sh\necho %s >> order.log\n```\n' "$3" > "$1/migrations/$2"
}

failing_mig() { # failing_mig <dir> <filename> — a scripted step that fails
  printf '# fixture migration\n\n```sh\nexit 1\n```\n' > "$1/migrations/$2"
}

seed_watermark() { mkdir -p "$1/.ai"; printf '[migrations]\nwatermark = "%s"\n' "$2" > "$1/.ai/migrations.toml"; }

echo "== no watermark: every migration is pending, each detects for itself =="
PKG="$TMP/test/pkg"
git_init "$PKG"; mkdir -p "$PKG/skills/alpha" "$PKG/migrations"
printf -- '---\nname: alpha\n---\nbody\n' > "$PKG/skills/alpha/SKILL.md"
printf 'name = "pkg"\ntype = "package"\n' > "$PKG/.ai.toml"
mig "$PKG" "2026-01-01-01-old.md" old
commit_all "$PKG"

CON="$TMP/consumer"
git_init "$CON"; mkdir -p "$CON/.claude"
printf '[[dependency]]\nsource = "%s"\n' "$PKG" > "$CON/.ai.toml"
commit_all "$CON"
( cd "$CON" && "$KAUK" sync ) >"$TMP/out1" 2>&1 || true
sed 's/^/     /' "$TMP/out1" | head -10

check "absent watermark replays all"      '[ -f "$CON/order.log" ] && grep -qx "old" "$CON/order.log"'
check "the absence is announced"          'grep -q "no watermark here" "$TMP/out1"'
check "migrations.toml exists after fresh sync" '[ -f "$CON/.ai/migrations.toml" ]'
check "watermark advanced to what ran"    'grep -q "watermark = \"2026-01-01-1\"" "$CON/.ai/migrations.toml"'
check "package still laid"                '[ -L "$CON/.claude/skills/alpha" ]'
check "nothing written under .git"        '! find "$CON/.git" -iname "*migrat*" 2>/dev/null | grep -q .'
check "session reload announced"          'grep -q "^reload:" "$TMP/out1"'

echo "== the watermark lives at .ai/migrations.toml, not gitignored =="
# kai's own .gitignore management (ensure_gitignore) is exercised by
# tests/convention-reader.sh via install/init; here we assert the narrower,
# in-scope fact: kai's own .gitignore line never widens to swallow the file.
printf '.ai/repositories/\n' > "$CON/.gitignore"
check ".ai/migrations.toml is trackable"       '! git -C "$CON" check-ignore -q .ai/migrations.toml'
check ".ai/repositories/ still ignored"  'git -C "$CON" check-ignore -q .ai/repositories/x'

echo "== same-day migrations from two packages interleave by NN, not by source =="
PKG2="$TMP/test/pkg2"
git_init "$PKG2"; mkdir -p "$PKG2/skills/beta" "$PKG2/migrations"
printf -- '---\nname: beta\n---\nbody\n' > "$PKG2/skills/beta/SKILL.md"
printf 'name = "pkg2"\ntype = "package"\n' > "$PKG2/.ai.toml"
commit_all "$PKG2"
printf '\n[[dependency]]\nsource = "%s"\n' "$PKG2" >> "$CON/.ai.toml"
commit_all "$CON" "add pkg2"

# seed the watermark at what the first case already applied, so only the new
# same-day migrations below are pending
seed_watermark "$CON" "2026-01-01-1"
mig "$PKG"  "2026-08-19-01-a1.md" a1
mig "$PKG2" "2026-08-19-02-b1.md" b1
mig "$PKG"  "2026-08-19-03-a2.md" a2
commit_all "$PKG" "a1 and a2"; commit_all "$PKG2" "b1"

( cd "$CON" && "$KAUK" sync ) >"$TMP/out2" 2>&1 || true
sed 's/^/     /' "$TMP/out2" | grep -i migration

check "interleaved order is a1, b1, a2" '[ "$(tr "\n" , < "$CON/order.log")" = "old,a1,b1,a2," ]'
check "watermark advanced to highest"    'grep -q "watermark = \"2026-08-19-3\"" "$CON/.ai/migrations.toml"'

echo "== a second sync with nothing new re-runs nothing =="
BEFORE=$(cat "$CON/order.log")
( cd "$CON" && "$KAUK" sync ) >/dev/null 2>&1 || true
check "no re-application"                '[ "$(cat "$CON/order.log")" = "$BEFORE" ]'

echo "== a hotfix takes the next NN and reaches a consumer sitting at the earlier one =="
mig "$PKG" "2026-08-19-04-hotfix.md" hotfix
commit_all "$PKG" "hotfix"
( cd "$CON" && "$KAUK" sync ) >"$TMP/out3" 2>&1 || true
check "hotfix applied"                   'grep -q "^hotfix$" "$CON/order.log"'
check "hotfix applied exactly once"      '[ "$(grep -c "^hotfix$" "$CON/order.log")" = 1 ]'
check "watermark advanced past hotfix"   'grep -q "watermark = \"2026-08-19-4\"" "$CON/.ai/migrations.toml"'

echo "== a failing migration is reported, not blocking; kai moves on =="
mig "$PKG" "2026-08-19-05-ok-before.md" x
failing_mig "$PKG" "2026-08-19-06-broken.md"
mig "$PKG" "2026-08-19-07-ok-after.md" y
commit_all "$PKG" "one broken migration between two good ones"
( cd "$CON" && "$KAUK" sync ) >"$TMP/out4" 2>&1 || true
check "failure is reported"              'grep -q "FAILED" "$TMP/out4"'
check "migration before the failure ran" 'grep -q "^x$" "$CON/order.log"'
check "migration after the failure ran"  'grep -q "^y$" "$CON/order.log"'
check "watermark advances past the failure" 'grep -q "watermark = \"2026-08-19-7\"" "$CON/.ai/migrations.toml"'

echo "== root-table type = \"package\" applies this repository's own migrations =="
SELF="$TMP/test/selfpkg"
git_init "$SELF"; mkdir -p "$SELF/skills/own" "$SELF/migrations" "$SELF/.claude"
printf -- '---\nname: own\n---\nbody\n' > "$SELF/skills/own/SKILL.md"
printf 'name = "selfpkg"\ntype = "package"\n' > "$SELF/.ai.toml"
mig "$SELF" "2026-08-19-01-own.md" ownmig
commit_all "$SELF"
seed_watermark "$SELF" "2026-01-01-0"
( cd "$SELF" && "$KAUK" sync ) >"$TMP/out5" 2>&1 || true
sed 's/^/     /' "$TMP/out5" | head -10

check "own migration ran"                '[ -f "$SELF/order.log" ] && grep -q "^ownmig$" "$SELF/order.log"'
check "own skill laid by COPY, not link" '[ -f "$SELF/.claude/skills/own/SKILL.md" ] && [ ! -L "$SELF/.claude/skills/own" ]'
check "declares no sources yet syncs"    '! grep -qi "no sources in .ai.toml" "$TMP/out5"'

echo "== absent type = \"package\": a repository does not apply its own migrations =="
NOTSELF="$TMP/test/notpkg"
git_init "$NOTSELF"; mkdir -p "$NOTSELF/skills/own" "$NOTSELF/migrations" "$NOTSELF/.claude"
printf -- '---\nname: own\n---\nbody\n' > "$NOTSELF/skills/own/SKILL.md"
printf 'name = "notpkg"\n' > "$NOTSELF/.ai.toml"
mig "$NOTSELF" "2026-08-19-01-own.md" ownmig
# no type = "package" at all — an ordinary consumer with a dependency, so sync
# has something to do without dying for lack of dependencies
CONSUMER2="$TMP/test/notpkg-consumer"
git_init "$CONSUMER2"; mkdir -p "$CONSUMER2/.claude"
printf '[[dependency]]\nsource = "%s"\n' "$NOTSELF" > "$CONSUMER2/.ai.toml"
commit_all "$NOTSELF"; commit_all "$CONSUMER2"
( cd "$CONSUMER2" && "$KAUK" sync ) >"$TMP/out6" 2>&1 || true

check "no root-table type=package -> nothing self-applies" '[ ! -e "$NOTSELF/order.log" ]'
check "consumer still lays the source normally" '[ -L "$CONSUMER2/.claude/skills/own" ]'

echo "== install stamps the watermark with the install date =="
CONI="$TMP/consumer-install"
git_init "$CONI"; mkdir -p "$CONI/.claude"
commit_all "$CONI" "empty"
( cd "$CONI" && "$KAUK" install "$PKG" ) >"$TMP/out7" 2>&1 || true
check "install wrote a watermark"        '[ -f "$CONI/.ai/migrations.toml" ]'
check "it carries today's date"          'grep -q "watermark = \"$(date +%F)-0\"" "$CONI/.ai/migrations.toml"'
check "install is announced"             'grep -q "watermark set to the install date" "$TMP/out7"'
check "history was not replayed"         '[ ! -e "$CONI/order.log" ]'
check "the package was still laid"       '[ -L "$CONI/.claude/skills/alpha" ]'

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
