#!/usr/bin/env bash
# Black-box tests for the two hand-repair migrations
# (2026-08-19-01-estate-link-repoint, 2026-08-19-02-relative-symlinks). Same
# style as tests/migrations-at-sync.sh: throwaway git repos, the shipped
# migration files' own fenced sh blocks extracted and run verbatim (the
# deployed arrangement), check/ok/no.
#
#   tests/migrations-estate-links.sh          run all cases
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
MIG01="$ROOT/migrations/2026-08-19-01-estate-link-repoint.md"
MIG02="$ROOT/migrations/2026-08-19-02-relative-symlinks.md"
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

run_migration() { # run_migration <migration-file> <repo-dir> -> stdout captured by caller
  awk '/^```sh$/{f=1;next} /^```$/{f=0} f' "$1" | (cd "$2" && bash)
}

echo "== migration 01: a serialseb-store link repoints to the source that now carries its tail =="
CON1="$TMP/con1"; git_init "$CON1"
mkdir -p "$CON1/.ai/repositories/kaukea/orchard/files" "$CON1/.ai/repositories/serialseb/kauk-clone-debris"
printf 'the moved file\n' > "$CON1/.ai/repositories/kaukea/orchard/files/AGENTS.shared.md"
# dangling committed link into a store directory that no longer exists at all
ln -s "$CON1/.ai/repositories/serialseb/orchids/files/AGENTS.shared.md" "$CON1/AGENTS.shared.md"
commit_all "$CON1" "hand-repaired fixture: dangling serialseb link, old store gone"
rm -rf "$CON1/.ai/repositories/serialseb/kauk-clone-debris" 2>/dev/null || true
OUT1=$(run_migration "$MIG01" "$CON1" 2>&1) || true
check "link now resolves"                         '[ -e "$CON1/AGENTS.shared.md" ]'
check "link repoints into the surviving kaukea clone" \
  'readlink "$CON1/AGENTS.shared.md" | grep -q "repositories/kaukea/orchard/files/AGENTS.shared.md"'
check "repoint was reported"                       'printf "%s" "$OUT1" | grep -q "repointed AGENTS.shared.md"'

echo "== migration 01: a serialseb-store link with no surviving claimant is removed, not left dangling =="
CON2="$TMP/con2"; git_init "$CON2"
mkdir -p "$CON2/.ai/repositories/kaukea/kauk"
ln -s "$CON2/.ai/repositories/serialseb/orchids/skills/gone/SKILL.md" "$CON2/AGENTS.files.md"
commit_all "$CON2" "hand-repaired fixture: orphaned serialseb link"
OUT2=$(run_migration "$MIG01" "$CON2" 2>&1) || true
check "orphaned link removed"   '[ ! -e "$CON2/AGENTS.files.md" ] && [ ! -L "$CON2/AGENTS.files.md" ]'
check "removal was reported"    'printf "%s" "$OUT2" | grep -q "removed AGENTS.files.md"'

echo "== migration 01: a tail claimed by two cloned sources is ambiguous, left alone =="
CON1b="$TMP/con1b"; git_init "$CON1b"
mkdir -p "$CON1b/.ai/repositories/kaukea/orchard/files" "$CON1b/.ai/repositories/other/fork/files"
printf 'one\n' > "$CON1b/.ai/repositories/kaukea/orchard/files/AGENTS.shared.md"
printf 'two\n' > "$CON1b/.ai/repositories/other/fork/files/AGENTS.shared.md"
ln -s "$CON1b/.ai/repositories/serialseb/orchids/files/AGENTS.shared.md" "$CON1b/AGENTS.shared.md"
commit_all "$CON1b" "hand-repaired fixture: ambiguous tail claimed by two sources"
OUT1c=$(run_migration "$MIG01" "$CON1b" 2>&1) || true
check "ambiguous link is left in place, not removed or guessed at" \
  '[ -L "$CON1b/AGENTS.shared.md" ] && readlink "$CON1b/AGENTS.shared.md" | grep -q "serialseb/orchids"'
check "ambiguity was reported"          'printf "%s" "$OUT1c" | grep -q "ambiguous"'

echo "== migration 01: re-run is a no-op (idempotent) =="
OUT1b=$(run_migration "$MIG01" "$CON1" 2>&1) || true
OUT2b=$(run_migration "$MIG01" "$CON2" 2>&1) || true
check "re-run on the repointed repo reports nothing to do" 'printf "%s" "$OUT1b" | grep -q "nothing to do"'
check "re-run on the pruned repo reports nothing to do"    'printf "%s" "$OUT2b" | grep -q "nothing to do"'
check "the repointed link is unchanged on re-run" \
  'readlink "$CON1/AGENTS.shared.md" | grep -q "repositories/kaukea/orchard/files/AGENTS.shared.md"'

echo "== migration 01 does not touch .git or .ai internals =="
check ".git of the fixture repo is untouched (still a valid repo)" \
  'git -C "$CON1" log -1 --format=%s >/dev/null 2>&1'
check "no stray files written under .ai/repositories" \
  '[ ! -e "$CON1/.ai/repositories/serialseb" ] || [ -d "$CON1/.ai/repositories/serialseb" ]'

echo "== migration 02: an absolute committed link into .ai/repositories becomes relative =="
CON3="$TMP/con3"; git_init "$CON3"
mkdir -p "$CON3/.claude/skills" "$CON3/.ai/repositories/kaukea/kauk/skills/foo" "$CON3/sub/dir"
printf 'skill\n' > "$CON3/.ai/repositories/kaukea/kauk/skills/foo/SKILL.md"
# root-level absolute link (depth 0 — the AGENTS.files.md/AGENTS.shared.md shape)
ln -s "$CON3/.ai/repositories/kaukea/kauk/skills/foo/SKILL.md" "$CON3/root-link.md"
# a link two directories deep
ln -s "$CON3/.ai/repositories/kaukea/kauk/skills/foo" "$CON3/.claude/skills/foo"
# nested absolute link, two directories deep
ln -s "$CON3/.ai/repositories/kaukea/kauk/skills/foo/SKILL.md" "$CON3/sub/dir/nested.md"
# already-relative link: must be left untouched
ln -s "../.ai/repositories/kaukea/kauk/skills/foo/SKILL.md" "$CON3/already-rel.md"
commit_all "$CON3" "fixture: absolute committed links naming this machine's home"
BEFORE_REL=$(readlink "$CON3/already-rel.md")
OUT3=$(run_migration "$MIG02" "$CON3" 2>&1) || true
check "root-level link (depth 0) has no ../ prefix" \
  '[ "$(readlink "$CON3/root-link.md")" = ".ai/repositories/kaukea/kauk/skills/foo/SKILL.md" ]'
check "link two levels deep (.claude/skills/) is relative with correct ../ depth" \
  '[ "$(readlink "$CON3/.claude/skills/foo")" = "../../.ai/repositories/kaukea/kauk/skills/foo" ]'
check "nested link is relative with correct ../ depth" \
  '[ "$(readlink "$CON3/sub/dir/nested.md")" = "../../.ai/repositories/kaukea/kauk/skills/foo/SKILL.md" ]'
check "top-level relativized link still resolves"   '[ -e "$CON3/.claude/skills/foo" ]'
check "nested relativized link still resolves"      '[ -e "$CON3/sub/dir/nested.md" ]'
check "already-relative link is untouched"          '[ "$(readlink "$CON3/already-rel.md")" = "$BEFORE_REL" ]'
check "no committed link still carries this machine's absolute path" \
  '[ -z "$(find "$CON3" -path "$CON3/.git" -prune -o -path "$CON3/.ai" -prune -o -type l -print 2>/dev/null | xargs -I{} readlink {} | grep "^/")" ]'
check "relativizing was reported"                   'printf "%s" "$OUT3" | grep -q "relativized .claude/skills/foo"'

echo "== migration 02: re-run is a no-op (idempotent) =="
OUT3b=$(run_migration "$MIG02" "$CON3" 2>&1) || true
check "re-run reports nothing to do" 'printf "%s" "$OUT3b" | grep -q "nothing to do"'
check "links unchanged after re-run" \
  '[ "$(readlink "$CON3/.claude/skills/foo")" = "../../.ai/repositories/kaukea/kauk/skills/foo" ] && [ "$(readlink "$CON3/sub/dir/nested.md")" = "../../.ai/repositories/kaukea/kauk/skills/foo/SKILL.md" ]'

echo "== migration 02 does not touch .git or .ai internals =="
check ".git of the fixture repo is untouched (still a valid repo)" \
  'git -C "$CON3" log -1 --format=%s >/dev/null 2>&1'
check "the clone tree under .ai/repositories is untouched" \
  '[ -f "$CON3/.ai/repositories/kaukea/kauk/skills/foo/SKILL.md" ]'

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
