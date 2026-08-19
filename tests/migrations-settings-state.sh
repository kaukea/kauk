#!/usr/bin/env bash
# Black-box tests for the three settings/state migrations
# (2026-08-19-03-retire-dangling-settings-symlink,
#  2026-08-19-04-migration-state-into-ai-lock, 2026-08-19-05-adopt-kai-hooks).
# Same style as tests/migrations-estate-links.sh: throwaway git repos, the
# shipped migration files' own fenced sh blocks extracted and run verbatim
# (the deployed arrangement), check/ok/no. Migrations ship no tests of their
# own to consumers — this file never leaves the kauk repository.
#
#   tests/migrations-settings-state.sh          run all cases
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
MIG03="$ROOT/migrations/2026-08-19-03-retire-dangling-settings-symlink.md"
MIG04="$ROOT/migrations/2026-08-19-04-migration-state-into-ai-lock.md"
MIG05="$ROOT/migrations/2026-08-19-05-adopt-kai-hooks.md"
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
commit_all() { git -C "$1" add -A && git -C "$1" commit -qm "${2:-fixture}" --allow-empty >/dev/null; }

run_migration() { # run_migration <migration-file> <repo-dir> [PATH override] -> stdout
  local mig=$1 dir=$2 pathenv=${3:-$PATH}
  awk '/^```sh$/{f=1;next} /^```$/{f=0} f' "$mig" | (cd "$dir" && PATH="$pathenv" bash)
}

for f in "$MIG03" "$MIG04" "$MIG05"; do
  [ -f "$f" ] || { echo "FATAL: missing migration file $f" >&2; exit 2; }
done

# ============================================================ migration 03
echo "== migration 03: a dangling package-laid settings.json symlink is removed =="
CON1="$TMP/con1"; git_init "$CON1"
mkdir -p "$CON1/.claude" "$CON1/.ai/repositories/kaukea/orchard/files/.claude"
# upstream deleted files/.claude/settings.json (d8f21f1) — the clone carries no file
ln -s "$CON1/.ai/repositories/kaukea/orchard/files/.claude/settings.json" "$CON1/.claude/settings.json"
commit_all "$CON1" "fixture: dangling package settings symlink"
OUT1=$(run_migration "$MIG03" "$CON1" 2>&1) || true
check "dangling symlink is gone"        '[ ! -e "$CON1/.claude/settings.json" ] && [ ! -L "$CON1/.claude/settings.json" ]'
check "removal was reported"            'printf "%s" "$OUT1" | grep -q "removed dangling package-laid symlink"'

echo "== migration 03: a still-resolving stale-clone symlink is removed too (is-or-WAS the package file) =="
CON2="$TMP/con2"; git_init "$CON2"
mkdir -p "$CON2/.claude" "$CON2/.ai/repositories/kaukea/orchard/files/.claude"
printf '{"stale":true}\n' > "$CON2/.ai/repositories/kaukea/orchard/files/.claude/settings.json"
ln -s "$CON2/.ai/repositories/kaukea/orchard/files/.claude/settings.json" "$CON2/.claude/settings.json"
commit_all "$CON2" "fixture: symlink still resolving (stale pinned clone)"
OUT2=$(run_migration "$MIG03" "$CON2" 2>&1) || true
check "still-resolving package symlink is removed anyway" '[ ! -e "$CON2/.claude/settings.json" ] && [ ! -L "$CON2/.claude/settings.json" ]'

echo "== migration 03: a real, user-owned settings.json is never touched =="
CON3="$TMP/con3"; git_init "$CON3"
mkdir -p "$CON3/.claude"
printf '{"mine":true}\n' > "$CON3/.claude/settings.json"
commit_all "$CON3" "fixture: real user settings.json"
OUT3=$(run_migration "$MIG03" "$CON3" 2>&1) || true
check "real file is untouched"           '[ "$(cat "$CON3/.claude/settings.json")" = "{\"mine\":true}" ]'
check "not-a-symlink was reported"       'printf "%s" "$OUT3" | grep -q "not a symlink"'

echo "== migration 03: a symlink to something else entirely is left alone and reported =="
CON4="$TMP/con4"; git_init "$CON4"
mkdir -p "$CON4/.claude" "$CON4/elsewhere"
printf '{"other":true}\n' > "$CON4/elsewhere/real.json"
ln -s "$CON4/elsewhere/real.json" "$CON4/.claude/settings.json"
commit_all "$CON4" "fixture: symlink to an unrelated file"
OUT4=$(run_migration "$MIG03" "$CON4" 2>&1) || true
check "unrelated symlink is left in place" '[ "$(readlink "$CON4/.claude/settings.json")" = "$CON4/elsewhere/real.json" ]'
check "unrelated symlink was reported"     'printf "%s" "$OUT4" | grep -q "not the package settings file"'

echo "== migration 03: no .claude at all is a clean no-op =="
CON5="$TMP/con5"; git_init "$CON5"; commit_all "$CON5" "fixture: nothing"
OUT5=$(run_migration "$MIG03" "$CON5" 2>&1) || true
check "absent settings.json reports nothing to do" 'printf "%s" "$OUT5" | grep -q "nothing to do"'

echo "== migration 03: re-run after removal is idempotent =="
OUT1b=$(run_migration "$MIG03" "$CON1" 2>&1) || true
check "second run on the converted repo reports nothing to do" 'printf "%s" "$OUT1b" | grep -q "nothing to do"'

# ============================================================ migration 04
echo "== migration 04: single highest recorded watermark, no clones present =="
CON6="$TMP/con6"; git_init "$CON6"
mkdir -p "$CON6/.git/the-works/migrated/acme" "$CON6/.git/the-works/migrated/other"
printf '2026-08-10-01-first\n'  > "$CON6/.git/the-works/migrated/acme/pkgone"
printf '2026-08-15-02-second\n' > "$CON6/.git/the-works/migrated/other/pkgtwo"
commit_all "$CON6" "fixture: two per-source watermarks, no clones"
OUT6=$(run_migration "$MIG04" "$CON6" 2>&1) || true
check "lock.toml carries [migrations]"        'grep -q "^\[migrations\]" "$CON6/.ai/lock.toml"'
check "watermark is the highest recorded"     'grep -q '"'"'watermark = "2026-08-15-02-second"'"'"' "$CON6/.ai/lock.toml"'
check "old watermark dir is gone"             '[ ! -d "$CON6/.git/the-works/migrated" ]'
check "removal was reported"                  'printf "%s" "$OUT6" | grep -q "removed old per-source watermarks"'

echo "== migration 04: re-run is idempotent =="
OUT6b=$(run_migration "$MIG04" "$CON6" 2>&1) || true
check "second run reports nothing to do"      'printf "%s" "$OUT6b" | grep -q "nothing to do"'
check "watermark unchanged after re-run"      'grep -q '"'"'watermark = "2026-08-15-02-second"'"'"' "$CON6/.ai/lock.toml"'

echo "== migration 04: the lying-watermark case — recorded is stale, the clone's own migrations/ overrides it =="
CON7="$TMP/con7"; git_init "$CON7"
mkdir -p "$CON7/.git/the-works/migrated/kaukea"
printf '2026-08-10-arborist-to-beekeeper\n' > "$CON7/.git/the-works/migrated/kaukea/orchard"
mkdir -p "$CON7/.ai/repositories/kaukea/orchard/migrations"
for m in 2026-08-10-arborist-to-beekeeper 2026-08-11-per-package-watermark \
         2026-08-18-four-names 2026-08-18-skill-tour; do
  printf '# %s\n' "$m" > "$CON7/.ai/repositories/kaukea/orchard/migrations/$m.md"
done
commit_all "$CON7" "fixture: orchard's watermark lies low; all its migrations are physically present"
OUT7=$(run_migration "$MIG04" "$CON7" 2>&1) || true
check "watermark takes the clone's newest migration, not the stale record" \
  'grep -q '"'"'watermark = "2026-08-18-skill-tour"'"'"' "$CON7/.ai/lock.toml"'
check "the override was printed as evidence, not silently taken" \
  'printf "%s" "$OUT7" | grep -q "evidence: kaukea/orchard.*ahead of recorded 2026-08-10-arborist-to-beekeeper"'
OUT7b=$(run_migration "$MIG04" "$CON7" 2>&1) || true
check "re-run reports nothing to do"          'printf "%s" "$OUT7b" | grep -q "nothing to do"'
check "re-running does not regress the reconciled watermark" \
  'grep -q '"'"'watermark = "2026-08-18-skill-tour"'"'"' "$CON7/.ai/lock.toml"'

echo "== migration 04: no watermark files at all leaves no [migrations] table (fresh-install rule stays with the engine) =="
CON8="$TMP/con8"; git_init "$CON8"; commit_all "$CON8" "fixture: nothing to reconcile"
OUT8=$(run_migration "$MIG04" "$CON8" 2>&1) || true
check "nothing found was reported"            'printf "%s" "$OUT8" | grep -q "no per-source watermarks found"'
check "no lock.toml was fabricated"           '[ ! -f "$CON8/.ai/lock.toml" ]'

echo "== migration 04: existing .ai/lock.toml content is preserved, not clobbered =="
CON9="$TMP/con9"; git_init "$CON9"
mkdir -p "$CON9/.ai" "$CON9/.git/the-works/migrated/acme"
printf '[some]\nfoo = "bar"\n' > "$CON9/.ai/lock.toml"
printf '2026-08-12-01-x\n' > "$CON9/.git/the-works/migrated/acme/pkg"
commit_all "$CON9" "fixture: pre-existing lock.toml content"
OUT9=$(run_migration "$MIG04" "$CON9" 2>&1) || true
check "prior [some] table survives"           'grep -q "^\[some\]" "$CON9/.ai/lock.toml"'
check "prior foo value survives"              'grep -q '"'"'foo = "bar"'"'"' "$CON9/.ai/lock.toml"'
check "[migrations] table was appended"       'grep -q '"'"'watermark = "2026-08-12-01-x"'"'"' "$CON9/.ai/lock.toml"'

echo "== migration 04 never writes under .git or .ai/repositories =="
check ".git of con6 is still a valid repo"    'git -C "$CON6" log -1 --format=%s >/dev/null 2>&1'
check "con7's clone tree is untouched"        '[ -f "$CON7/.ai/repositories/kaukea/orchard/migrations/2026-08-18-skill-tour.md" ]'

# ============================================================ migration 05
echo "== migration 05: real kai on PATH, resolved through a symlink exactly as dispatch-agent.sh does =="
# Mirrors orchard's tools/dispatch-agent.sh resolution verbatim as an
# independent oracle: command -v, readlink -f with a raw-path fallback,
# dirname — so this test diffs the migration's own resolution against the
# other end of the same contract instead of only checking its own output.
resolve_like_dispatch_agent() { # resolve_like_dispatch_agent <PATH> -> settings path or empty
  local p=$1 kb
  kb=$(PATH="$p" command -v kai 2>/dev/null) || { echo ""; return; }
  kb=$(readlink -f "$kb" 2>/dev/null || printf '%s' "$kb")
  local cand; cand="$(dirname "$kb")/kai.settings.json"
  [ -f "$cand" ] && echo "$cand" || echo ""
}

KAIREAL="$TMP/kai-real"; KAIONPATH="$TMP/kai-onpath"
mkdir -p "$KAIREAL" "$KAIONPATH"
printf '#!/bin/sh\necho fake-kai\n' > "$KAIREAL/kaukea"; chmod +x "$KAIREAL/kaukea"
printf '{"adopted":"from-kai"}\n' > "$KAIREAL/kai.settings.json"
printf '#!/bin/sh\nexit 0\n' > "$KAIREAL/kai-hooks.sh"; chmod +x "$KAIREAL/kai-hooks.sh"
ln -s "$KAIREAL/kaukea" "$KAIONPATH/kai"   # "kai" on PATH is a symlink, like a real static install
FAKEPATH="$KAIONPATH:$PATH"

ORACLE=$(resolve_like_dispatch_agent "$FAKEPATH")
check "oracle resolves through the symlink to the real kai.settings.json" \
  '[ "$ORACLE" = "$KAIREAL/kai.settings.json" ]'

CON10="$TMP/con10"; git_init "$CON10"; commit_all "$CON10" "fixture: no settings.json yet"
OUT10=$(run_migration "$MIG05" "$CON10" "$FAKEPATH" 2>&1) || true
check "settings.json was laid as a real file"     '[ -f "$CON10/.claude/settings.json" ] && [ ! -L "$CON10/.claude/settings.json" ]'
check "laid content matches kai's own settings file (the oracle's target)" \
  '[ "$(cat "$CON10/.claude/settings.json")" = "$(cat "$ORACLE")" ]'
check "adoption was reported"                     'printf "%s" "$OUT10" | grep -q "laid .claude/settings.json"'
check "it was staged with git add"                'git -C "$CON10" diff --cached --name-only | grep -q "^\.claude/settings\.json$"'

echo "== migration 05: re-run after adoption is idempotent (real file now present) =="
OUT10b=$(run_migration "$MIG05" "$CON10" "$FAKEPATH" 2>&1) || true
check "second run reports the file already exists" 'printf "%s" "$OUT10b" | grep -q "already exists as a real file"'
check "content is unchanged"                        '[ "$(cat "$CON10/.claude/settings.json")" = "$(cat "$ORACLE")" ]'

echo "== migration 05: a package-laid symlink still in place is left to the prior migration =="
CON11="$TMP/con11"; git_init "$CON11"
mkdir -p "$CON11/.claude" "$CON11/.ai/repositories/kaukea/orchard/files/.claude"
ln -s "$CON11/.ai/repositories/kaukea/orchard/files/.claude/settings.json" "$CON11/.claude/settings.json"
commit_all "$CON11" "fixture: symlink still present"
OUT11=$(run_migration "$MIG05" "$CON11" "$FAKEPATH" 2>&1) || true
check "the symlink is untouched"     '[ -L "$CON11/.claude/settings.json" ]'
check "deferral was reported"        'printf "%s" "$OUT11" | grep -q "settings-symlink migration first"'

echo "== migration 05: a real, pre-existing settings.json is never overwritten =="
CON12="$TMP/con12"; git_init "$CON12"
mkdir -p "$CON12/.claude"
printf '{"mine":true}\n' > "$CON12/.claude/settings.json"
commit_all "$CON12" "fixture: operator's own settings.json"
OUT12=$(run_migration "$MIG05" "$CON12" "$FAKEPATH" 2>&1) || true
check "the real file's content is unchanged"  '[ "$(cat "$CON12/.claude/settings.json")" = "{\"mine\":true}" ]'
check "it was reported, not silently kept"    'printf "%s" "$OUT12" | grep -q "left untouched"'

echo "== migration 05: kai not on PATH at all — nothing is written =="
CON13="$TMP/con13"; git_init "$CON13"; commit_all "$CON13" "fixture: no kai installed"
BAREPATH="/usr/bin:/bin"
OUT13=$(run_migration "$MIG05" "$CON13" "$BAREPATH" 2>&1) || true
check "no settings.json was created"          '[ ! -e "$CON13/.claude/settings.json" ]'
check "the reason was reported"               'printf "%s" "$OUT13" | grep -q "kai not found on PATH"'

echo "== migration 05: kai on PATH but no settings pair beside it — nothing is written =="
KAIBARE="$TMP/kai-bare"; mkdir -p "$KAIBARE"
printf '#!/bin/sh\necho bare-kai\n' > "$KAIBARE/kai"; chmod +x "$KAIBARE/kai"
BAREKAIPATH="$KAIBARE:$PATH"
CON14="$TMP/con14"; git_init "$CON14"; commit_all "$CON14" "fixture: kai present, no settings pair"
OUT14=$(run_migration "$MIG05" "$CON14" "$BAREKAIPATH" 2>&1) || true
check "no settings.json was created"          '[ ! -e "$CON14/.claude/settings.json" ]'
check "the reason was reported"               'printf "%s" "$OUT14" | grep -q "no kai.settings.json/kai-hooks.sh beside it"'

echo "== migration 05 never writes under .git or .ai/repositories =="
check ".git of con10 is still a valid repo"   'git -C "$CON10" log -1 --format=%s >/dev/null 2>&1'
check "con11's clone tree is untouched"       '[ -d "$CON11/.ai/repositories/kaukea/orchard/files/.claude" ]'

# ==================================================================== combined
echo "== all three compose in ASCII order over one realistic consumer =="
CON15="$TMP/con15"; git_init "$CON15"
mkdir -p "$CON15/.claude" "$CON15/.ai/repositories/kaukea/orchard/files/.claude" \
         "$CON15/.git/the-works/migrated/kaukea"
ln -s "$CON15/.ai/repositories/kaukea/orchard/files/.claude/settings.json" "$CON15/.claude/settings.json"
printf '2026-08-10-arborist-to-beekeeper\n' > "$CON15/.git/the-works/migrated/kaukea/orchard"
commit_all "$CON15" "fixture: a real pre-redesign consumer"
for m in "$MIG03" "$MIG04" "$MIG05"; do run_migration "$m" "$CON15" "$FAKEPATH" >/dev/null 2>&1 || true; done
check "the dangling package symlink is gone"      '[ ! -L "$CON15/.claude/settings.json" ]'
check "kai-hooks.sh adoption filled the empty slot" '[ -f "$CON15/.claude/settings.json" ]'
check "adopted content is kai's own settings file"  '[ "$(cat "$CON15/.claude/settings.json")" = "$(cat "$ORACLE")" ]'
check "the watermark moved into .ai/lock.toml"      'grep -q '"'"'watermark = "2026-08-10-arborist-to-beekeeper"'"'"' "$CON15/.ai/lock.toml"'
check "the old watermark dir is gone"               '[ ! -d "$CON15/.git/the-works/migrated" ]'
check "a second full pass changes nothing further" \
  'a=$(md5sum "$CON15/.claude/settings.json" "$CON15/.ai/lock.toml" | md5sum);
   for m in "$MIG03" "$MIG04" "$MIG05"; do run_migration "$m" "$CON15" "$FAKEPATH" >/dev/null 2>&1 || true; done;
   b=$(md5sum "$CON15/.claude/settings.json" "$CON15/.ai/lock.toml" | md5sum);
   [ "$a" = "$b" ]'

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
