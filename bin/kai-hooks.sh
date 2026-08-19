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
OUT_DIR=""
CAPTURE_FILE=""
cleanup() {
  [ -n "$STDIN_FILE" ] && rm -f "$STDIN_FILE"
  [ -n "$OUT_DIR" ] && rm -rf "$OUT_DIR"
}
trap cleanup EXIT

# The hook's stdin (Claude's event JSON) is read at most once and replayed to
# every script an action runs. Sets $STDIN_FILE — called as a plain
# statement, never via `$(stdin_file)`: a command substitution runs in a
# subshell, so an assignment to a global made inside one is invisible to the
# caller once it returns, and the SECOND script to run would see STDIN_FILE
# still empty, re-`cat` an already-drained real stdin, and get nothing.
stdin_file() {
  if [ -z "$STDIN_FILE" ]; then
    STDIN_FILE=$(mktemp)
    cat > "$STDIN_FILE"
  fi
}

# capture_file -> sets $CAPTURE_FILE to a fresh path to hold one producer's
# stdout. Every path handed out is recorded in $OUT_DIR/.manifest so
# emit_output can compose them once, after every source/hookdir/action/script
# for this event has run — a script's stdout must never go straight to our
# own stdout, or two producers racing onto the single stream the harness
# reads concatenate into invalid JSON. Same subshell hazard as stdin_file:
# called as a plain statement, never via `$(capture_file)`, or every call
# would see OUT_DIR as still-unset and hand out a fresh, disconnected
# directory instead of accumulating into the one manifest.
capture_file() {
  [ -n "$OUT_DIR" ] || OUT_DIR=$(mktemp -d)
  CAPTURE_FILE=$(mktemp "$OUT_DIR/out.XXXXXX")
  printf '%s\n' "$CAPTURE_FILE" >> "$OUT_DIR/.manifest"
}

# source_dirs -> one source directory per line, from .ai.toml's [sources."…"]
# table headers (bin/kaukea's src_tables convention). A key that is neither
# an absolute path nor <owner>/<repo> is invalid — bin/kaukea's sources_list
# warns and ignores it; mirrored here. On stderr, not stdout: unlike kaukea,
# this process's stdout IS the hook-output channel the harness parses, never
# a place for free text.
source_dirs() {
  awk '/^\[sources\."/ { s=$0; sub(/^\[sources\."/,"",s); sub(/"\].*$/,"",s); print s }' "$AITOML" |
  while IFS= read -r key; do
    [ -n "$key" ] || continue
    case "$key" in
      /*)   printf '%s\n' "$key" ;;
      */*)  printf '%s\n' "$ROOT/.ai/repositories/$key" ;;
      *)    printf 'kai-hooks: .ai.toml: source "%s" is neither <owner>/<repo> nor a full path — ignored\n' "$key" >&2 ;;
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
# matching executable, replaying the hook's stdin into it and capturing its
# stdout for emit_output to compose (see capture_file).
run_scripts_action() {
  local dir=$1; shift
  local pattern script sfile ofile
  for pattern in "$@"; do
    for script in "$dir"/$pattern; do
      [ -e "$script" ] && [ -x "$script" ] || continue
      stdin_file;   sfile=$STDIN_FILE
      capture_file; ofile=$CAPTURE_FILE
      "$script" < "$sfile" > "$ofile"
    done
  done
}

# unimplemented_action <name> — inject-context and notify are real, documented
# hooks/ vocabulary (docs/package-format.md ## hooks/) that this dispatcher
# does not yet run. Flagged distinctly from invalid_action so an operator can
# tell "not built here yet" apart from "typo in your index.toml".
unimplemented_action() {
  printf 'kai-hooks: %s: action "%s" is documented but not yet implemented in kai-hooks.sh — ignored\n' "$EVENT" "$1" >&2
}

# invalid_action <name> <toml-path> — docs/package-format.md ## hooks/: the
# action vocabulary is closed, so a key outside it is an error, not an
# extension point. Still never aborts the hook (see header).
invalid_action() {
  printf 'kai-hooks: %s: ERROR: "%s" in %s is not a recognised hooks/ action — ignored\n' "$EVENT" "$1" "$2" >&2
}

# bracket_depth <text> -> count of unmatched '[' in text, so a TOML array
# value that spans multiple physical lines can be recognised as still open.
bracket_depth() {
  local s=$1 opens closes
  opens=$(printf '%s' "$s" | tr -cd '[' | wc -c)
  closes=$(printf '%s' "$s" | tr -cd ']' | wc -c)
  printf '%s' $((opens - closes))
}

# run_hook_dir <event-dir> — parse index.toml and execute each [[actions]]
# entry. The action's key is its first `key = value` line. A value that
# opens an array ('[') without closing it on that line is a multi-line TOML
# array, continued from the following lines until the brackets balance (see
# bracket_depth) — array_values sees the whole assembled value, not just its
# first line. Any further `key = value` line before the next [[actions]]
# belongs to the same action and is not itself dispatched as a new one.
# Reads the file off fd 9 (not a plain `while read < file`, which would
# rebind fd 0) so the hook's real stdin stays intact for stdin_file(). No
# `mapfile`/`readarray` — those are bash 4+ only and this runs under stock
# bash 3.2 on BSD/macOS too.
run_hook_dir() {
  local dir=$1 toml="$1/index.toml"
  [ -f "$toml" ] || return 0
  local line in_action=0 key val depth
  while IFS= read -r line <&9 || [ -n "$line" ]; do
    case "$line" in
      '[[actions]]') in_action=1; key=""; continue ;;
      '['*)          in_action=0; continue ;;
    esac
    [ "$in_action" = 1 ] || continue
    [ -n "$key" ] && continue
    case "$line" in ''|'#'*) continue ;; esac
    key=${line%%=*}; key=$(printf '%s' "$key" | xargs)
    val=${line#*=}
    depth=$(bracket_depth "$val")
    while [ "$depth" -gt 0 ]; do
      IFS= read -r line <&9 || break
      val="$val
$line"
      depth=$(bracket_depth "$val")
    done
    val=$(printf '%s' "$val" | xargs)
    case "$key" in
      scripts)
        run_scripts_action "$dir" $(array_values "$val")
        ;;
      inject-context|notify)
        unimplemented_action "$key"
        ;;
      *)
        invalid_action "$key" "$toml"
        ;;
    esac
  done 9< "$toml"
}

# emit_output — after every source/hookdir/action/script for this event has
# run, compose every producer's captured stdout (see capture_file) into the
# single JSON document the harness reads for this one hook invocation. Zero
# producers: nothing. Exactly one: passed through untouched. More than one:
# merged (see compose_json) — writing them one after another would put two
# adjacent top-level JSON values on the same stream, which is not valid JSON.
emit_output() {
  [ -n "$OUT_DIR" ] && [ -f "$OUT_DIR/.manifest" ] || return 0
  local f nonempty="" count=0
  while IFS= read -r f; do
    [ -s "$f" ] || continue
    nonempty="$nonempty $f"
    count=$((count + 1))
  done < "$OUT_DIR/.manifest"
  [ "$count" -gt 0 ] || return 0
  if [ "$count" -eq 1 ]; then
    cat $nonempty
    return 0
  fi
  compose_json $nonempty
}

# compose_json <file>... — merge N JSON-object files, each shaped like this
# dispatcher's own producers (`{"hookSpecificOutput":{"hookEventName":…,
# "additionalContext":…}}`), into one valid object: additionalContext is
# concatenated in order, every other field is a shallow last-write-wins
# merge. Prefers jq, falls back to python3 — both already assumed elsewhere
# in this ecosystem (courier-only-transport.sh uses jq; courier-init.sh
# shells out to python3), neither is GNU/Linux-only. With neither available,
# valid JSON still wins over a full merge: only the first producer's output
# is kept, and how many were dropped is named on stderr so the gap is
# diagnosable rather than silent.
compose_json() {
  if command -v jq >/dev/null 2>&1; then
    jq -sc '
      [.[] | .hookSpecificOutput? | select(type=="object")] as $items
      | if ($items | length) == 0 then empty else
          ($items | map(.additionalContext? | select(type=="string" and length>0))) as $ctxs
          | (reduce $items[] as $it ({}; . * $it) | del(.additionalContext)) as $base
          | {hookSpecificOutput: (if ($ctxs|length) > 0 then $base + {additionalContext: ($ctxs | join("\n\n"))} else $base end)}
        end
    ' "$@" 2>/dev/null && return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$@" <<'PY' && return 0
import json, sys

items, ctxs, base = [], [], {}
for path in sys.argv[1:]:
    try:
        obj = json.load(open(path))
    except ValueError:
        continue
    hso = obj.get("hookSpecificOutput") if isinstance(obj, dict) else None
    if isinstance(hso, dict):
        items.append(hso)

if items:
    for hso in items:
        base.update(hso)
        ctx = hso.get("additionalContext")
        if isinstance(ctx, str) and ctx:
            ctxs.append(ctx)
    if ctxs:
        base["additionalContext"] = "\n\n".join(ctxs)
    else:
        base.pop("additionalContext", None)
    print(json.dumps({"hookSpecificOutput": base}))
PY
    return 0
  fi
  local first=$1 total=$#
  printf 'kai-hooks: %s: %s scripts produced output but neither jq nor python3 is available to merge them — emitting only the first, dropping %s other(s)\n' \
    "$EVENT" "$total" "$((total - 1))" >&2
  cat "$first"
}

# Same reasoning as run_hook_dir: read off fd 9, not fd 0, and no mapfile.
while IFS= read -r src <&9 || [ -n "$src" ]; do
  [ -n "$src" ] || continue
  event_dir="$src/hooks/$EVENT"
  [ -d "$event_dir" ] || continue
  run_hook_dir "$event_dir"
done 9< <(source_dirs)

emit_output
exit 0
