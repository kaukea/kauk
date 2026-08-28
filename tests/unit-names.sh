#!/usr/bin/env bash
# Runs spec/names.cases against the shell implementation.
#
# The cases are NOT in this file. They are the contract every implementation of
# kai answers to, and a runner in any language reads the same file — see
# spec/names.cases for the format and for why the regressions in it are never
# removed. This runner's only job is to call the shell library and compare.
#
#   tests/unit-names.sh
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CASES="$ROOT/spec/names.cases"
. "$ROOT/lib/names.sh"

[ -f "$CASES" ] || { printf 'unit-names: no cases at %s\n' "$CASES" >&2; exit 1; }

PASS=0; FAIL=0
while IFS=$'\t' read -r fn args expected note; do
  case "$fn" in ''|'#'*) continue ;; esac

  IFS='|' read -r -a argv <<< "$args"

  case "$expected" in
    '<true>'|'<false>')
      if "$fn" "${argv[@]}" >/dev/null 2>&1; then actual='<true>'; else actual='<false>'; fi ;;
    *)
      actual=$("$fn" "${argv[@]}" 2>/dev/null) || actual='<false>'
      [ -z "$actual" ] && actual='<empty>' ;;
  esac

  if [ "$actual" = "$expected" ]; then
    PASS=$((PASS+1))
    printf '  ok   %s(%s) — %s\n' "$fn" "$args" "$note"
  else
    FAIL=$((FAIL+1))
    printf '  FAIL %s(%s) — %s\n       expected: %s\n       actual:   %s\n' \
           "$fn" "$args" "$note" "$expected" "$actual"
  fi
done < "$CASES"

echo
REGRESSIONS=$(grep -c 'REGRESSION' "$CASES" || true)
printf 'unit-names: %s/%s passed (%s of them defects that once shipped)\n' \
       "$PASS" "$((PASS + FAIL))" "$REGRESSIONS"
[ "$FAIL" -eq 0 ]
