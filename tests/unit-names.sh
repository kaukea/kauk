#!/usr/bin/env bash
# Unit tests for lib/names.sh — the arithmetic of sources, identifiers and link
# targets. No repository, no package, no network: every case here is a question
# about a name, answered by a function of its arguments.
#
# Every defect shipped on 2026-08-28 was of exactly this kind and none of them
# was reachable by the scenario suites, which stayed green throughout. The cases
# marked REGRESSION are those defects, written as the question that would have
# been asked before the code was.
#
#   tests/unit-names.sh
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT/lib/names.sh"

PASS=0; FAIL=0
is() { # is <what> <expected> <actual>
  if [ "$2" = "$3" ]; then PASS=$((PASS+1)); printf '  ok   %s\n' "$1"
  else FAIL=$((FAIL+1)); printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"; fi
}
yes_() { if eval "$2"; then PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; else FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; fi; }
no_()  { if eval "$2"; then FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; else PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; fi; }

echo "== a reference is only a reference in the last segment =="
is "plain source has none"            ""       "$(ref_of kaukea/kauk)"
is "a named ref is found"             "HEAD"   "$(ref_of kaukea/kauk@HEAD)"
is "a branch is found"                "topic"  "$(ref_of kaukea/kauk@topic)"
is "REGRESSION: a git address has none" ""     "$(ref_of git@github.com:kaukea/kauk.git)"
is "a git address WITH a ref"         "HEAD"   "$(ref_of git@github.com:kaukea/kauk.git@HEAD)"
is "a path with an @ in a parent"     ""       "$(ref_of /home/me@work/src/kauk)"

echo "== removing a reference leaves the source whole =="
is "nothing to remove"                "kaukea/kauk"                    "$(without_ref kaukea/kauk)"
is "a ref is removed"                 "kaukea/kauk"                    "$(without_ref kaukea/kauk@HEAD)"
is "REGRESSION: a git address survives" "git@github.com:kaukea/kauk.git" "$(without_ref git@github.com:kaukea/kauk.git)"
is "an @ in a parent survives"        "/home/me@work/src/kauk"         "$(without_ref /home/me@work/src/kauk)"

echo "== the repository half, whatever shape the source takes =="
is "owner/repo"                       "kauk" "$(repo_half kaukea/kauk)"
is "with a ref"                       "kauk" "$(repo_half kaukea/kauk@HEAD)"
is "REGRESSION: a git address"        "kauk" "$(repo_half git@github.com:kaukea/kauk.git)"
is "an https address"                 "kauk" "$(repo_half https://github.com/kaukea/kauk.git)"
is "a path to a checkout"             "kauk" "$(repo_half /home/me/src/kaukea/kauk)"
is "a path with a trailing slash"     "kauk" "$(repo_half /home/me/src/kaukea/kauk/)"
is "something else entirely"          "orchard" "$(repo_half kaukea/orchard)"

echo "== the identifier a package is stored under =="
is "owner/repo passes through"        "kaukea/kauk" "$(owner_repo kaukea/kauk)"
is "an https address"                 "kaukea/kauk" "$(owner_repo https://github.com/kaukea/kauk.git)"
is "a git address"                    "kaukea/kauk" "$(owner_repo git@github.com:kaukea/kauk.git)"
is "a file address"                   "kaukea/kauk" "$(owner_repo file:///home/me/kaukea/kauk)"
is "a path to a checkout"             "kaukea/kauk" "$(owner_repo /home/me/src/kaukea/kauk)"
is "a ref does not disturb it"        "kaukea/kauk" "$(owner_repo kaukea/kauk@HEAD)"
is "REGRESSION: the name is not the id" "kaukea/kauk" "$(owner_repo /home/me/src/kaukea/kauk)"

echo "== making a path absolute, without resolving anything =="
is "already absolute"                 "/a/b"      "$(absolute /root /a/b)"
is "relative to the base"             "/root/a/b" "$(absolute /root a/b)"
is "a leading dot-slash"              "/root/a"   "$(absolute /root ./a)"
is "a trailing slash is dropped"      "/root/a"   "$(absolute /root a/)"

echo "== collapsing, as text, never by following links =="
is "nothing to collapse"              "/a/b/c"  "$(collapse / /a/b/c)"
is "one step up"                      "/a/b"    "$(collapse / /a/b/c/..)"
is "several steps up"                 "/a"      "$(collapse / /a/b/c/../..)"
is "a relative target from a base"    "/a/x"    "$(collapse /a/b ../x)"
is "REGRESSION: a path that does not exist" "/nowhere/at/all" "$(collapse / /nowhere/at/all)"
is "REGRESSION: through a missing directory" "/a/x" "$(collapse /a/b/missing ../../x)"
is "past the root"                    "/"       "$(collapse / /../..)"
is "dots are ignored"                 "/a/b"    "$(collapse / /a/./b)"

echo "== is one path inside another =="
yes_ "a child is inside"              'under /a/b /a/b/c'
no_  "the same path is not inside itself" 'under /a/b /a/b'
no_  "a sibling is not inside"        'under /a/b /a/bb/c'
no_  "a parent is not inside"         'under /a/b/c /a/b'
yes_ "a trailing slash on the parent" 'under /a/b/ /a/b/c'

echo "== how far below the anchor =="
is "at the anchor"                    "0" "$(depth_below /r /r)"
is "one down"                         "1" "$(depth_below /r /r/a)"
is "two down"                         "2" "$(depth_below /r /r/a/b)"
is "REGRESSION: five down is five"    "5" "$(depth_below /r /r/a/b/c/d/e)"
no_  "outside the anchor has no depth" 'depth_below /r /elsewhere/a'

echo "== what a laid link should carry =="
is "at the root"                      ".ai/repositories/p/skills/x" \
   "$(link_target /r /r/.ai/repositories/p/skills/x /r)"
is "REGRESSION: two down carries two"  "../../.ai/repositories/p/skills/x" \
   "$(link_target /r /r/.ai/repositories/p/skills/x /r/.claude/skills)"
is "three down carries three"          "../../../.ai/repositories/p/skills/x" \
   "$(link_target /r /r/.ai/repositories/p/skills/x /r/.claude/a/b)"
is "REGRESSION: counted from the checkout it sits in, not the one above" \
   "../../.ai/repositories/p/skills/x" \
   "$(link_target /r/.claude/worktrees/w /r/.claude/worktrees/w/.ai/repositories/p/skills/x /r/.claude/worktrees/w/.claude/skills)"
is "a target outside the anchor is left alone" "/elsewhere/thing" \
   "$(link_target /r /elsewhere/thing /r/.claude/skills)"
is "a link outside the anchor is left alone" "/r/thing" \
   "$(link_target /r /r/thing /elsewhere/skills)"
is "REGRESSION: no home directory can appear" "../../.ai/repositories/p/x" \
   "$(link_target /home/someone/src/repo /home/someone/src/repo/.ai/repositories/p/x /home/someone/src/repo/.claude/skills)"

echo "== migration filenames =="
is "the day"                          "2026-08-28" "$(mig_day migrations/2026-08-28-01-a-thing.md)"
is "the day of an old-form name"      "2026-08-19" "$(mig_day migrations/2026-08-19-relative-symlinks.md)"
is "the sequence"                     "1"  "$(mig_seq migrations/2026-08-28-01-a-thing.md)"
is "a two-digit sequence"             "12" "$(mig_seq migrations/2026-08-28-12-a-thing.md)"
is "REGRESSION: a leading zero is not octal" "8" "$(mig_seq migrations/2026-08-28-08-a-thing.md)"
is "REGRESSION: the old form has no sequence" "0" "$(mig_seq migrations/2026-08-19-relative-symlinks.md)"
is "a bare path works too"            "2"  "$(mig_seq 2026-08-28-02-x.md)"

echo
printf 'unit-names: %s/%s passed\n' "$PASS" "$((PASS + FAIL))"
[ "$FAIL" -eq 0 ]
