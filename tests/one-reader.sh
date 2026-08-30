#!/usr/bin/env bash
# One reader of .ai.toml, and nothing may grow its own.
#
# There were two: bin/kaukea had the real parser, and bin/kai-hooks.sh had a
# simplified copy written beside the code that needed it rather than sourced from
# the one that existed. They had already diverged — a dependency declaring a type
# other than `package` is ignored by the tool, with a warning, and was cloned by
# the session-start hook regardless.
#
# The habit that produced it is reproducing whatever is closest to where you are
# editing. This suite is what stops the next copy, and it also pins the agreement
# itself: both ends are asked the same awkward file and must answer alike.
#
#   tests/one-reader.sh
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
. "$HERE/harness.sh"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

echo "== the reader lives in one place =="
check "the library has it"                'grep -q "^dep_rows()" "$ROOT/lib/aitoml.sh"'
check "the executable does not"           '! grep -qE "^(dep_rows|root_field|ai_file)\(\)" "$ROOT/bin/kaukea"'
check "nor does the hook dispatcher"      '! grep -qE "^(dep_rows|raw_sources|root_field|ai_file)\(\)" "$ROOT/bin/kai-hooks.sh"'
# writing a block and mentioning one in a comment are fine; matching on it
# inside an awk program is a second parser
check "neither matches it inside awk"     '! grep -nE "^[[:space:]]*/.*dependency.*/[[:space:]]*\{" "$ROOT/bin/kaukea" "$ROOT/bin/kai-hooks.sh"'
check "both source the library"           'grep -q "aitoml.sh" "$ROOT/bin/kaukea" && grep -q "aitoml.sh" "$ROOT/bin/kai-hooks.sh"'

echo "== and both ends answer the same awkward file alike =="
cat > "$TMP/.ai.toml" <<'EOF'
name = "thing"
type = "package"

[[dependency]]
source = "kaukea/orchard"

[[dependency]]
type = "package"
source = "kaukea/kauk@HEAD"

[[dependency]]
type = "something-else"
source = "kaukea/not-a-package"

[[dependency]]
source = "/home/me/src/o/p"

[other]
source = "outside/any/dependency/block"
EOF

. "$ROOT/lib/aitoml.sh"
GOT=$(ai_package_sources "$TMP")
check "the retired type is left out"      '! printf "%s" "$GOT" | grep -q "not-a-package"'
check "a source outside a block is too"   '! printf "%s" "$GOT" | grep -q "outside/any"'
check "the plain one is in"               'printf "%s" "$GOT" | grep -q "kaukea/orchard"'
check "so is one carrying a reference"    'printf "%s" "$GOT" | grep -q "kaukea/kauk@HEAD"'
check "so is a path"                      'printf "%s" "$GOT" | grep -q "/home/me/src/o/p"'
check "and that is all of them"           '[ "$(printf "%s\n" "$GOT" | grep -c .)" -eq 3 ]'
check "the root table is still readable"  '[ "$(root_field "$TMP" type)" = "package" ]'

echo "== and one resolution of where the tool lives =="
# It was written three times in bin/kaukea, in three forms, two without a
# fallback. Where `readlink -f` is unsupported those print nothing, `dirname ""`
# is `.`, and the path becomes `./../lib` — relative to wherever the command was
# run. That does not fail; it finds a stranger's library and sources it.
check "resolved once in the executable"   '[ "$(grep -c "^[^#]*readlink -f" "$ROOT/bin/kaukea")" -eq 1 ]'
check "and reused, not recomputed"        'grep -q "script_repo=\$KAI_HOME" "$ROOT/bin/kaukea"'
check "with a fallback when -f is absent" 'grep -q "readlink -f .* 2>/dev/null || printf" "$ROOT/bin/kaukea"'
check "the hook resolves the same way"    'grep -q "readlink -f .* 2>/dev/null || printf" "$ROOT/bin/kai-hooks.sh"'

BSD="$TMP/bsd-bin"; mkdir -p "$BSD" "$TMP/decoy/lib" "$TMP/decoy/sub"
printf '#!/bin/sh\nfor a in "$@"; do case "$a" in -f) exit 1 ;; esac; done\nexec /bin/readlink "$@"\n' > "$BSD/readlink"
chmod +x "$BSD/readlink"
printf 'echo DECOY >&2\n' > "$TMP/decoy/lib/names.sh"
( cd "$TMP/decoy/sub" && PATH="$BSD:$PATH" "$ROOT/bin/kai" --help ) >/dev/null 2>"$TMP/decoy.err"
check "a stranger library is never sourced" '! grep -q DECOY "$TMP/decoy.err"'

summary one-reader
