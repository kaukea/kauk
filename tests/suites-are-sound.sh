#!/usr/bin/env bash
# A test over the tests.
#
# Seventy-two assertions across nine suites once piped a writer into a matcher
# that exits on its first match. The writer took SIGPIPE, `pipefail` called that
# a failure, and it looked exactly like the code under test was broken. It was
# corrected three times in its instances and came back each time, because every
# suite carried its own copy of the assertion helper and nothing stopped the next
# one being written the same way.
#
# There is now one helper, in tests/harness.sh, and this suite fails if a suite
# defines its own. That is what stops it recurring — not a rule, and not a note.
#
#   tests/suites-are-sound.sh
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/harness.sh"

for f in "$HERE"/*.sh; do
  n=$(basename "$f")
  case "$n" in harness.sh|suites-are-sound.sh) continue ;; esac

  check "$n sources the harness" \
    "grep -q 'harness\.sh' '$f'"

  for helper in check ok no is; do
    check "$n does not define its own $helper" \
      "! grep -qE '^[[:space:]]*${helper}\(\)' '$f'"
  done

  check "$n does not re-initialise the counters" \
    "! grep -qE '^[[:space:]]*(PASS|FAIL)=0' '$f'"
done

check "the harness evaluates with pipefail off" \
  "grep -q 'set +o pipefail; eval' '$HERE/harness.sh'"
check "and says why, so it is not removed as noise" \
  "grep -qi 'SIGPIPE' '$HERE/harness.sh'"

summary suites-are-sound
