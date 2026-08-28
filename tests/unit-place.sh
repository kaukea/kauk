#!/usr/bin/env bash
# Runs spec/place.cases against the shell implementation. The cases are the
# contract; this runner knows nothing about what it is asking.
#
#   tests/unit-place.sh
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CASES="$ROOT/spec/place.cases"
. "$ROOT/lib/place.sh"

[ -f "$CASES" ] || { printf 'unit-place: no cases at %s\n' "$CASES" >&2; exit 1; }

PASS=0; FAIL=0
while IFS=$'\t' read -r fn args expected note; do
  case "$fn" in ''|'#'*) continue ;; esac
  IFS='|' read -r -a argv <<< "$args"
  local_i=0
  for local_i in "${!argv[@]}"; do
    [ "${argv[$local_i]}" = '<empty>' ] && argv[$local_i]=''
  done
  case "$expected" in
    '<true>'|'<false>')
      if "$fn" "${argv[@]}" >/dev/null 2>&1; then actual='<true>'; else actual='<false>'; fi ;;
    *)
      actual=$("$fn" "${argv[@]}" 2>/dev/null) || actual='<false>'
      [ -z "$actual" ] && actual='<empty>' ;;
  esac
  if [ "$actual" = "$expected" ]; then
    PASS=$((PASS+1)); printf '  ok   %s(%s) — %s\n' "$fn" "$args" "$note"
  else
    FAIL=$((FAIL+1)); printf '  FAIL %s(%s) — %s\n       expected: %s\n       actual:   %s\n' \
      "$fn" "$args" "$note" "$expected" "$actual"
  fi
done < "$CASES"

echo
R=$(grep -c 'REGRESSION' "$CASES" || true)
printf 'unit-place: %s/%s passed (%s of them defects that once shipped)\n' "$PASS" "$((PASS + FAIL))" "$R"
[ "$FAIL" -eq 0 ]
