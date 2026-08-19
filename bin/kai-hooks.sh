#!/usr/bin/env bash
# kai-hooks.sh — the static hook dispatcher. Installed once beside the kai
# executable (bin/kai.settings.json points every Claude event at this file,
# resolved next to kai itself — never via the repository being worked in).
#
# Given a runtime-neutral event name, runs what the CURRENT repository's
# installed package sources expose for it: hooks/<event>/index.toml, per the
# closed action vocabulary in docs/package-format.md (## hooks/). Source
# resolution mirrors bin/kaukea's own convention (src_tables / clone_of):
# an "<owner>/<repo>" source lives under .ai/repositories/<owner>/<repo>,
# a "/absolute/path" source is used directly.
#
# No event, an unknown event, no sources, or no matching hook directory:
# no output, exit 0. Always exits 0 — a hook must never break a session.
set -uo pipefail

EVENT=${1:-}
[ -n "$EVENT" ] || exit 0

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
AITOML="$ROOT/.ai.toml"
[ -f "$AITOML" ] || exit 0

STDIN_FILE=""
cleanup() { [ -n "$STDIN_FILE" ] && rm -f "$STDIN_FILE"; }
trap cleanup EXIT

# The hook's stdin (Claude's event JSON) is read at most once and replayed to
# every script an action runs.
stdin_file() {
  if [ -z "$STDIN_FILE" ]; then
    STDIN_FILE=$(mktemp)
    cat > "$STDIN_FILE"
  fi
  printf '%s\n' "$STDIN_FILE"
}

# source_dirs -> one source directory per line, from .ai.toml's [sources."…"]
# table headers (bin/kaukea's src_tables convention).
source_dirs() {
  awk '/^\[sources\."/ { s=$0; sub(/^\[sources\."/,"",s); sub(/"\].*$/,"",s); print s }' "$AITOML" |
  while IFS= read -r key; do
    case "$key" in
      /*)   printf '%s\n' "$key" ;;
      */*)  printf '%s\n' "$ROOT/.ai/repositories/$key" ;;
    esac
  done
}

# array_values <toml-array-literal> -> one bare item per line, e.g.
# '["*.sh", "*.py"]' -> "*.sh" then "*.py"
array_values() {
  local v=$1 part
  v=${v#*[}; v=${v%]*}
  local IFS=','
  for part in $v; do
    part=${part#"${part%%[![:space:]]*}"}
    part=${part%"${part##*[![:space:]]}"}
    part=${part#\"}; part=${part%\"}
    part=${part#\'}; part=${part%\'}
    [ -n "$part" ] && printf '%s\n' "$part"
  done
}

# scripts = [...] — glob patterns relative to the event directory; run each
# matching executable, replaying the hook's stdin into it.
run_scripts_action() {
  local dir=$1; shift
  local pattern script sfile
  for pattern in "$@"; do
    for script in "$dir"/$pattern; do
      [ -e "$script" ] && [ -x "$script" ] || continue
      sfile=$(stdin_file)
      "$script" < "$sfile"
    done
  done
}

# run_hook_dir <event-dir> — parse index.toml and execute each [[actions]]
# entry. The action's key is its first `key = value` line; any further line
# before the next [[actions]] is that action's own parameter, not a new key.
# Reads the file off fd 9 (not a plain `while read < file`, which would
# rebind fd 0) so the hook's real stdin stays intact for stdin_file(). No
# `mapfile`/`readarray` — those are bash 4+ only and this runs under stock
# bash 3.2 on BSD/macOS too.
run_hook_dir() {
  local dir=$1 toml="$1/index.toml"
  [ -f "$toml" ] || return 0
  local line in_action=0 key val
  while IFS= read -r line <&9 || [ -n "$line" ]; do
    case "$line" in
      '[[actions]]') in_action=1; key=""; continue ;;
      '['*)          in_action=0; continue ;;
    esac
    [ "$in_action" = 1 ] || continue
    [ -n "$key" ] && continue
    case "$line" in ''|'#'*) continue ;; esac
    key=${line%%=*}; key=$(printf '%s' "$key" | xargs)
    val=${line#*=}; val=$(printf '%s' "$val" | xargs)
    case "$key" in
      scripts)
        run_scripts_action "$dir" $(array_values "$val")
        ;;
      *)
        printf 'kai-hooks: %s: unrecognised action "%s" in %s — ignored\n' "$EVENT" "$key" "$toml" >&2
        ;;
    esac
  done 9< "$toml"
}

# Same reasoning as run_hook_dir: read off fd 9, not fd 0, and no mapfile.
while IFS= read -r src <&9 || [ -n "$src" ]; do
  [ -n "$src" ] || continue
  event_dir="$src/hooks/$EVENT"
  [ -d "$event_dir" ] || continue
  run_hook_dir "$event_dir"
done 9< <(source_dirs)

exit 0
