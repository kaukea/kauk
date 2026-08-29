#!/usr/bin/env bash
# The assertion helpers every suite uses. Sourced, never copied.
#
# It is one file because it used to be ten, and the ten drifted: seventy-two
# assertions across nine suites piped a writer into a matcher that exits on its
# first match, so the writer took SIGPIPE and `pipefail` reported a failure that
# looked like the code under test. That was corrected three times in its
# instances and returned each time, because nothing stopped the next suite being
# written the same way.
#
# tests/suites-are-sound.sh fails if a suite defines these itself. That is the
# part that prevents it coming back — not this comment.

PASS=0; FAIL=0

ok() { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
no() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

# check <what it proves> <shell expression>
#
# The expression is evaluated with `pipefail` OFF. Every assertion of the form
# `producer | matcher` means "did the matcher find it", and that is what this
# restores: without it the producer's broken pipe fails the assertion at random.
check() { if ( set +o pipefail; eval "$2" ); then ok "$1"; else no "$1"; fi; }

# is <what it proves> <expected> <actual> — for a value rather than a condition
is() {
  if [ "$2" = "$3" ]; then ok "$1"
  else FAIL=$((FAIL+1)); printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"; fi
}

# summary <suite name> — prints the tally and sets the exit status
summary() {
  echo
  printf '%s: %s/%s passed\n' "$1" "$PASS" "$((PASS + FAIL))"
  [ "$FAIL" -eq 0 ]
}
