#!/usr/bin/env bash
# Black-box tests for estate link/clone hygiene: the two hand-repair
# migrations (2026-08-19-01-estate-link-repoint, 2026-08-19-02-relative-
# symlinks and their own fenced sh blocks run verbatim, the deployed
# arrangement), the shipped 2026-08-18-kaukea-move-links migration, and the
# live `prune_links`/`sweep_orphan_clones` behaviour kai runs at every
# `kai sync` (the link-healing/orphan-sweep coverage ported from the retired
# tests/migrations-at-sync.sh, whose per-source-watermark and
# applied-by:agent ask-file assertions no longer apply — that mechanism was
# replaced by the single global watermark). Throwaway git repos, real
# bin/kai, check/ok/no.
#
#   tests/migrations-estate-links.sh          run all cases
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
KAUK="$ROOT/bin/kai"
MIG01="$ROOT/migrations/2026-08-19-01-estate-link-repoint.md"
MIG02="$ROOT/migrations/2026-08-19-02-relative-symlinks.md"
MIG_MOVE="$ROOT/migrations/2026-08-18-kaukea-move-links.md"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

. "$(dirname "$0")/harness.sh"

git_init() {
  mkdir -p "$1"; git -C "$1" init -q
  git -C "$1" config user.email t@example.com
  git -C "$1" config user.name Test
}
commit_all() { git -C "$1" add -A && git -C "$1" commit -qm "${2:-fixture}"; }
pkg_toml() { # pkg_toml <dir> <name> — the package's own identity, root table
  printf 'name = "%s"\ntype = "package"\n' "$2" > "$1/.ai.toml"
}

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

echo "== live prune_links: a renamed source repoints, a true orphan is removed =="
PKGG="$TMP/test/pkgg"; git_init "$PKGG"; mkdir -p "$PKGG/skills/gfoo"
printf -- '---\nname: gfoo\n---\ng\n' > "$PKGG/skills/gfoo/SKILL.md"
pkg_toml "$PKGG" pkgg
commit_all "$PKGG"
PKGH="$TMP/test/pkgh"; git_init "$PKGH"; mkdir -p "$PKGH/skills/horph"
printf -- '---\nname: horph\n---\nh\n' > "$PKGH/skills/horph/SKILL.md"
pkg_toml "$PKGH" pkgh
commit_all "$PKGH"
CON_STALE="$TMP/consumer-stale"; git_init "$CON_STALE"; mkdir -p "$CON_STALE/.claude"; printf "placeholder\n" > "$CON_STALE/.claude/.keep"; commit_all "$CON_STALE"
( cd "$CON_STALE" && "$KAUK" install "$PKGG" && "$KAUK" install "$PKGH" ) >/dev/null 2>&1 || true
check "setup: gfoo laid before the rename"     '[ -L "$CON_STALE/.claude/skills/gfoo" ]'
check "setup: horph laid before removal"       '[ -L "$CON_STALE/.claude/skills/horph" ]'
# Rename pkgg's identity: move the source, repoint .ai.toml, drop the old clone.
# pkgh drops out of .ai.toml entirely at the same time, and its clone goes with
# it — no source anywhere still carries a skills/horph tail, so its laid link is
# a true orphan.
mv "$PKGG" "$TMP/test/pkgg-ren"
printf '[[dependency]]\nsource = "%s"\n' "$TMP/test/pkgg-ren" > "$CON_STALE/.ai.toml"
rm -rf "$CON_STALE/.ai/repositories/test/pkgg"
rm -rf "$CON_STALE/.ai/repositories/test/pkgh"
( cd "$CON_STALE" && "$KAUK" sync ) >"$TMP/out-stale" 2>&1 || true
check "renamed source's link resolves into the new store path" \
  '[ -e "$CON_STALE/.claude/skills/gfoo" ] && readlink "$CON_STALE/.claude/skills/gfoo" | grep -q "test/pkgg-ren"'
check "no dangling link into .ai/repositories/ remains" \
  '[ -z "$(find "$CON_STALE/.claude" -type l ! -exec test -e {} \; -print 2>/dev/null)" ]'
check "a link whose tail exists in no source is removed as an orphan" \
  '[ ! -e "$CON_STALE/.claude/skills/horph" ] && [ ! -L "$CON_STALE/.claude/skills/horph" ]'

PKGJ="$TMP/test/pkgj"; git_init "$PKGJ"; mkdir -p "$PKGJ/skills/j1"
printf -- '---\nname: j1\n---\nj\n' > "$PKGJ/skills/j1/SKILL.md"
pkg_toml "$PKGJ" pkgj
commit_all "$PKGJ"

echo "== live prune_links: a RELATIVE dangling link into the store is normalized and repointed =="
CON_REL="$TMP/consumer-rel"; git_init "$CON_REL"; mkdir -p "$CON_REL/.claude"; printf "placeholder\n" > "$CON_REL/.claude/.keep"; commit_all "$CON_REL"
( cd "$CON_REL" && "$KAUK" install "$PKGJ" ) >/dev/null 2>&1 || true
ln -s ".ai/repositories/test/gone/skills/j1/SKILL.md" "$CON_REL/rel-toplevel.md"
mkdir -p "$CON_REL/sub/dir"
ln -s "../../.ai/repositories/test/gone/skills/j1/SKILL.md" "$CON_REL/sub/dir/rel-nested.md"
( cd "$CON_REL" && "$KAUK" sync ) >"$TMP/out-rel" 2>&1 || true
check "relative dead link repointed to the one source carrying its tail" \
  '[ -e "$CON_REL/rel-toplevel.md" ] && readlink "$CON_REL/rel-toplevel.md" | grep -q "repositories/test/pkgj/skills/j1/SKILL.md"'
check "nested ../.. relative dead link normalized and repointed too" \
  '[ -e "$CON_REL/sub/dir/rel-nested.md" ] && readlink "$CON_REL/sub/dir/rel-nested.md" | grep -q "repositories/test/pkgj/skills/j1/SKILL.md"'

echo "== live prune_links: a TRACKED dangling link with no candidate is reported, never removed =="
CON_DEBRIS="$TMP/consumer-debris"; git_init "$CON_DEBRIS"; mkdir -p "$CON_DEBRIS/.claude"; printf "placeholder\n" > "$CON_DEBRIS/.claude/.keep"; commit_all "$CON_DEBRIS"
( cd "$CON_DEBRIS" && "$KAUK" install "$PKGJ" ) >/dev/null 2>&1 || true
ln -s "$CON_DEBRIS/.ai/repositories/test/gone/nowhere/at-all.md" "$CON_DEBRIS/tracked-debris.md"
git -C "$CON_DEBRIS" add tracked-debris.md && git -C "$CON_DEBRIS" commit -qm "tracked debris fixture"
ln -s "$CON_DEBRIS/.ai/repositories/test/gone/nowhere/at-all.md" "$CON_DEBRIS/untracked-orphan.md"
( cd "$CON_DEBRIS" && "$KAUK" sync ) >"$TMP/out-debris" 2>&1 || true
check "tracked dangling link still present"   '[ -L "$CON_DEBRIS/tracked-debris.md" ]'
check "tracked dangling link reported as DEBRIS" 'grep -q "DEBRIS tracked-debris.md" "$TMP/out-debris"'
check "untracked orphan with no candidate pruned as before" '[ ! -L "$CON_DEBRIS/untracked-orphan.md" ]'

echo "== sweep_orphan_clones: undeclared clean clones removed, diverged or dirty kept =="
CON_SWEEP="$TMP/consumer-sweep"; git_init "$CON_SWEEP"; mkdir -p "$CON_SWEEP/.claude"; printf "placeholder\n" > "$CON_SWEEP/.claude/.keep"; commit_all "$CON_SWEEP"
( cd "$CON_SWEEP" && "$KAUK" install "$PKGJ" ) >/dev/null 2>&1 || true
git clone --quiet "$PKGJ" "$CON_SWEEP/.ai/repositories/orichea/orchids" 2>/dev/null
git clone --quiet "$PKGJ" "$CON_SWEEP/.ai/repositories/orchea/diverged" 2>/dev/null
( cd "$CON_SWEEP/.ai/repositories/orchea/diverged" && printf 'drift\n' > drift.md && git add -A && git -c user.email=t@example.com -c user.name=Test commit -qm "local drift" )
git clone --quiet "$PKGJ" "$CON_SWEEP/.ai/repositories/orchea/dirty" 2>/dev/null
printf 'uncommitted\n' > "$CON_SWEEP/.ai/repositories/orchea/dirty/mess.md"
( cd "$CON_SWEEP" && "$KAUK" sync ) >"$TMP/out-sweep" 2>&1 || true
check "undeclared clean clone swept"          '[ ! -d "$CON_SWEEP/.ai/repositories/orichea" ]'
check "sweep reported"                        'grep -q "SWEEP orichea/orchids" "$TMP/out-sweep"'
check "undeclared clone with unpushed commit kept" '[ -d "$CON_SWEEP/.ai/repositories/orchea/diverged/.git" ]'
check "diverged clone reported as ORPHAN"     'grep -q "ORPHAN orchea/diverged" "$TMP/out-sweep"'
check "undeclared dirty clone kept"           '[ -d "$CON_SWEEP/.ai/repositories/orchea/dirty/.git" ]'
check "declared source clone untouched"       '[ -d "$CON_SWEEP/.ai/repositories/test/pkgj/.git" ]'

echo "== migration move-links: heals RELATIVE serialseb targets =="
CON_MOVE="$TMP/consumer-mig-rel"; git_init "$CON_MOVE"
mkdir -p "$CON_MOVE/.ai/repositories/kaukea/kauk/skills" "$CON_MOVE/files"
printf 'the moved file\n' > "$CON_MOVE/.ai/repositories/kaukea/kauk/skills/thing.md"
ln -s ".ai/repositories/serialseb/kauk/skills/thing.md" "$CON_MOVE/files/rel-stale.md"
commit_all "$CON_MOVE"
run_migration "$MIG_MOVE" "$CON_MOVE" >"$TMP/out-move" 2>&1 || true
check "relative serialseb link repointed by the migration" \
  '[ -e "$CON_MOVE/files/rel-stale.md" ] && readlink "$CON_MOVE/files/rel-stale.md" | grep -q "repositories/kaukea/kauk/skills/thing.md"'

echo "== nothing readable in .ai.toml means nothing can be swept =="
CON_UNREAD="$TMP/consumer-unreadable"; git_init "$CON_UNREAD"; mkdir -p "$CON_UNREAD/.claude"
printf "placeholder\n" > "$CON_UNREAD/.claude/.keep"; commit_all "$CON_UNREAD"
( cd "$CON_UNREAD" && "$KAUK" install "$PKGJ" ) >/dev/null 2>&1 || true
check "setup: the clone is there"      '[ -d "$CON_UNREAD/.ai/repositories/test/pkgj/.git" ]'
printf '[sources."test/pkgj"]\n' > "$CON_UNREAD/.ai.toml"
( cd "$CON_UNREAD" && "$KAUK" sync ) >"$TMP/out-unread" 2>&1 || true
check "the store survives an unreadable file" '[ -d "$CON_UNREAD/.ai/repositories/test/pkgj/.git" ]'
check "the skipped sweep is announced"        'grep -q "sweep skipped" "$TMP/out-unread"'

echo "== a retired source is renamed in a dependency block, not only in the old table syntax =="
# The earlier rename matches [sources."owner/repo"] headers. A repository that
# reached the [[dependency]] form before it ran can never be matched by it, so
# its sources keep naming repositories that moved. Three in the estate were in
# exactly that state, one of them naming an identifier that never existed.
MIGDEP="$ROOT/migrations/2026-08-29-01-retired-sources-in-dependency-blocks.md"

DEPC="$TMP/dep-consumer"; git_init "$DEPC"
printf '# mine, hands off\nname = "thing"\n\n[[dependency]]\nsource = "serialseb/kauk"\n\n[[dependency]]\nsource = "kaukea/orchids"\n\n[[dependency]]\nsource = "/home/someone/src/serialseb/orchids"\n\n[[dependency]]\nsource = "kaukea/other@HEAD"\n' > "$DEPC/.ai.toml"
commit_all "$DEPC"
mkdir -p "$DEPC/.ai/repositories/serialseb/kauk" "$DEPC/.ai/repositories/kaukea/orchids"
run_migration "$MIGDEP" "$DEPC" >"$TMP/out-dep" 2>&1
check "the retired owner is renamed"        'grep -q "^source = \"kaukea/kauk\"$" "$DEPC/.ai.toml"'
check "an identifier that never existed too" '! grep -q "kaukea/orchids" "$DEPC/.ai.toml"'
check "a path is matched by its tail"       '[ "$(grep -c "^source = \"kaukea/orchard\"$" "$DEPC/.ai.toml")" -eq 2 ]'
check "an unrelated source is untouched"    'grep -q "^source = \"kaukea/other@HEAD\"$" "$DEPC/.ai.toml"'
check "the operator comment survives"       'grep -q "^# mine, hands off$" "$DEPC/.ai.toml"'
check "the root table survives"             'grep -q "^name = \"thing\"$" "$DEPC/.ai.toml"'
check "clones under retired names are gone" '[ ! -d "$DEPC/.ai/repositories/serialseb/kauk" ] && [ ! -d "$DEPC/.ai/repositories/kaukea/orchids" ]'
check "it says what it renamed"             'grep -q "renamed retired sources" "$TMP/out-dep"'
BEFORE_DEP=$(cat "$DEPC/.ai.toml")
run_migration "$MIGDEP" "$DEPC" >"$TMP/out-dep2" 2>&1
check "a second run changes nothing"        '[ "$(cat "$DEPC/.ai.toml")" = "$BEFORE_DEP" ]'
check "and says so"                         'grep -q "nothing to do" "$TMP/out-dep2"'

CLEANC="$TMP/dep-clean"; git_init "$CLEANC"
printf 'name = "x"\n\n[[dependency]]\nsource = "kaukea/orchard"\n' > "$CLEANC/.ai.toml"; commit_all "$CLEANC"
run_migration "$MIGDEP" "$CLEANC" >"$TMP/out-clean" 2>&1
check "a repository naming none is left alone" 'grep -q "nothing to do" "$TMP/out-clean"'


printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
