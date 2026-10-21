#!/usr/bin/env bash
# Tests for lib/fs.sh — the port that asks the filesystem what is there.
#
# This one DOES need a filesystem, because that is what it is for. It stays
# small and builds a handful of files in a temporary directory: the port's whole
# job is to turn what is on disk into facts, and the facts are what everything
# else reasons about without touching disk at all.
#
# The case that earns this file is the dead link whose path is missing a
# directory in the middle. `readlink -f` answers nothing at all for it, which is
# how a package's own link came to look like a stranger's and was renamed out of
# the dead-link repair's reach. Asking the port instead gives it a name.
#
#   tests/unit-fs.sh
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT/lib/fs.sh"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

. "$(dirname "$0")/harness.sh"

mkdir -p "$TMP/adir" "$TMP/target-dir"
printf 'x\n' > "$TMP/afile"
printf 'y\n' > "$TMP/target-file"
ln -s target-file       "$TMP/live-file-link"
ln -s target-dir        "$TMP/live-dir-link"
ln -s nowhere           "$TMP/dead-simple"
ln -s missing/deeper/x  "$TMP/dead-through-missing-dir"
ln -s ../outside/thing  "$TMP/dead-relative-upward"

echo "== what kind of thing is there =="
is "nothing at all"                  "absent"    "$(fs_kind "$TMP/not-here")"
is "a file"                          "file"      "$(fs_kind "$TMP/afile")"
is "a directory"                     "dir"       "$(fs_kind "$TMP/adir")"
is "a link to a file"                "link"      "$(fs_kind "$TMP/live-file-link")"
is "a link to a directory"           "link"      "$(fs_kind "$TMP/live-dir-link")"
is "a link to nothing"               "dead-link" "$(fs_kind "$TMP/dead-simple")"
is "REGRESSION: dead through a missing directory" "dead-link" "$(fs_kind "$TMP/dead-through-missing-dir")"
is "dead pointing outside"           "dead-link" "$(fs_kind "$TMP/dead-relative-upward")"

echo "== what a link literally carries =="
is "a live link's target"            "target-file"      "$(fs_target "$TMP/live-file-link")"
is "REGRESSION: a dead link still has one" "missing/deeper/x" "$(fs_target "$TMP/dead-through-missing-dir")"
is "REGRESSION: unresolved, never followed" "target-dir"  "$(fs_target "$TMP/live-dir-link")"
is "a file carries nothing"          ""                 "$(fs_target "$TMP/afile")"
is "nothing carries nothing"         ""                 "$(fs_target "$TMP/not-here")"

echo "== the difference the port exists to preserve =="
# This is the defect, demonstrated: the resolver that was used cannot tell a
# dead link from a live one. GNU answers with silence, macOS with a path that
# does not exist; either way a caller comparing paths concluded the link
# belonged elsewhere.
check "the old way cannot tell it is dead" '[ ! -e "$(readlink -f "$TMP/dead-through-missing-dir" 2>/dev/null)" ]'

is "the port answers with a kind"    "dead-link" "$(fs_kind "$TMP/dead-through-missing-dir")"
is "and with what it carries"        "missing/deeper/x" "$(fs_target "$TMP/dead-through-missing-dir")"

echo "== walking up for a marker =="
mkdir -p "$TMP/r/a/b/c"; printf '\n' > "$TMP/r/.ai.toml"
is "found from far below"            "$TMP/r"   "$(fs_find_up "$TMP/r/a/b/c" .ai.toml)"
is "found at the marker itself"      "$TMP/r"   "$(fs_find_up "$TMP/r" .ai.toml)"
printf '\n' > "$TMP/r/a/.ai.toml"
is "the nearest one wins"            "$TMP/r/a" "$(fs_find_up "$TMP/r/a/b/c" .ai.toml)"
is "absent when there is none"       ""         "$(fs_find_up "$TMP/adir" no-such-marker.toml)"

echo "== actions =="
fs_link "target-file" "$TMP/made"
is "a link is made"                  "target-file" "$(fs_target "$TMP/made")"
fs_link "target-dir" "$TMP/made"
is "and repointed in place"          "target-dir"  "$(fs_target "$TMP/made")"
mkdir -p "$TMP/standing/inside"
fs_replace_with_link "target-file" "$TMP/standing"
is "REGRESSION: a directory is replaced, not landed inside" "link" "$(fs_kind "$TMP/standing")"
is "and carries the right target"    "target-file" "$(fs_target "$TMP/standing")"

summary unit-fs
