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

# The ONE reader of .ai.toml, beside this script. This file used to carry its own
# simplified copy, and the two had already diverged about what counts as a
# dependency — see lib/aitoml.sh.
# Resolved the way everything in this fleet resolves a path beside the binary:
# readlink -f, with a graceful fallback to the unresolved path. A readlink
# without -f is not a failure to exit on — it is the BSD one, and this script
# has to keep dispatching under it.
KAI_SELF=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || printf '%s' "${BASH_SOURCE[0]}")
KAI_LIB=$(cd "$(dirname "$KAI_SELF")/../lib" 2>/dev/null && pwd) || KAI_LIB=""
if [ -n "$KAI_LIB" ] && [ -f "$KAI_LIB/aitoml.sh" ]; then
  . "$KAI_LIB/names.sh"
  . "$KAI_LIB/aitoml.sh"
else
  # A hook must never break a session, so this exits 0 — but silence here means
  # nothing is bootstrapped and nobody knows why, so it says so first.
  printf 'kai-hooks: cannot find its library beside the executable — the bin and lib directories travel together. Nothing was set up for this session.\n' >&2
  exit 0
fi

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

# source_dirs -> one package directory per line, from .ai.toml's [[dependency]]
# blocks. A source that is neither a path, a git URI, nor <owner>/<repo> is
# invalid — bin/kaukea's deps_list warns and ignores it; mirrored here. On
# stderr, not stdout: unlike kaukea, this process's stdout IS the hook-output
# channel the harness parses, never a place for free text.
source_dirs() {
  # A self-published package is a package (docs/package-format.md): its own
  # hooks/ run here like any dependency's.
  [ "$(root_field "$ROOT" type)" = package ] && printf '%s\n' "$ROOT"
  ai_package_sources "$ROOT" |
  while IFS= read -r src; do
    [ -n "$src" ] || continue
    tail=${src##*/}
    case "$tail" in *@*) src=${src%@*} ;; esac
    case "$src" in
      *://*|git@*)
        bare=${src%.git}; bare=${bare%/}; tail=${bare##*:}
        case "$tail" in */*) ;; *) tail=$bare ;; esac
        printf '%s\n' "$ROOT/.ai/repositories/$(basename "$(dirname "$tail")")/$(basename "$tail")" ;;
      /*|./*|../*) printf '%s\n' "$ROOT/.ai/repositories/$(path_id "$ROOT" "$src")" ;;  # cloned by kai install
      */*)  printf '%s\n' "$ROOT/.ai/repositories/$src" ;;
      *)    printf 'kai-hooks: .ai.toml: source "%s" is not <owner>/<repo>, a git URI, or a path — ignored\n' "$src" >&2 ;;
    esac
  done
}

# ---------- the package store ----------
# The store lives in the git folder rather than in the working tree, because
# every worktree of a repository shares that folder: one clone then serves all
# of them, and no worktree ends up carrying a version of its own. Each checkout
# reaches it through .ai/repositories/<owner>/<repo>, which is inside the
# already-ignored directory and so is never committed — which is exactly what
# lets the committed links keep one short relative form that is correct in
# every checkout, measured from the checkout it sits in.

store_dir() { # -> the shared store, absolute
  local common
  common=$(git rev-parse --git-common-dir 2>/dev/null) || return 1
  case "$common" in /*) ;; *) common="$ROOT/${common#./}" ;; esac
  printf '%s\n' "$common/kai/repositories"
}

uri_id_of() { # a git URI -> <owner>/<repo>, mirroring bin/kaukea's uri_id
  local bare=$1 tail
  bare=${bare%.git}; bare=${bare%/}; tail=${bare##*:}
  case "$tail" in
    */*) printf '%s/%s\n' "$(basename "$(dirname "$tail")")" "$(basename "$tail")" ;;
    *)   printf '%s/%s\n' "$(basename "$(dirname "$bare")")" "$(basename "$bare")" ;;
  esac
}

write_store_readme() { # explain the directory to whoever opens it, never committed
  local f="$1/README.md"
  [ -f "$f" ] && return 0
  cat > "$f" 2>/dev/null <<'MD'
# Package store

This directory holds the packages this repository depends on, as declared in
`.ai.toml`. It is ignored by git, so nothing here is part of the repository's
history and nothing here needs to be committed.

Each entry is a link into a single clone kept in this repository's git folder.
Every worktree shares that folder, so all of them read the same clone and none
of them can drift onto a version of its own.

You do not need to create or restore any of this by hand. It is rebuilt at the
start of every session: whatever `.ai.toml` declares and is not present yet is
cloned then. Deleting this directory is safe — the next session puts it back.
MD
}

# ensure_sources — make every declared source present before anything looks for
# what it carries. This runs at session start because the sources may not exist
# in this checkout at all: a fresh clone has never had them, and a fresh worktree
# gets nothing, since the directory holding them is ignored and git therefore
# never checks it out. Clone-if-absent only; it never fetches, pulls, or lays.
#
# A clone lands on a temporary name and is moved into place once it has finished,
# so a session-start timeout that kills this mid-clone leaves no half-written
# package behind — the next session simply tries again.
ensure_sources() {
  local store slot origin id link tmp src tail
  store=$(store_dir) || return 0
  mkdir -p "$ROOT/.ai/repositories" 2>/dev/null || return 0
  write_store_readme "$ROOT/.ai/repositories"
  while IFS= read -r src; do
    [ -n "$src" ] || continue
    tail=${src##*/}
    case "$tail" in *@*) src=${src%@*} ;; esac
    case "$src" in
      /*|./*|../*) continue ;;                                  # cloned by kai install
      *://*|git@*) id=$(uri_id_of "$src"); origin=$src ;;
      */*)         id=$src; origin="https://github.com/$src" ;;
      *)           continue ;;                                  # source_dirs reports it
    esac
    slot="$store/$id"
    if [ ! -d "$slot/.git" ]; then
      mkdir -p "$(dirname "$slot")" 2>/dev/null || continue
      tmp="$slot.incoming.$$"
      rm -rf "$tmp" 2>/dev/null
      if git clone --quiet "$origin" "$tmp" 2>/dev/null; then
        rm -rf "$slot" 2>/dev/null
        mv "$tmp" "$slot" 2>/dev/null || { rm -rf "$tmp" 2>/dev/null; continue; }
      else
        rm -rf "$tmp" 2>/dev/null
        printf 'kai-hooks: %s: could not be cloned from %s — what it provides is unavailable this session\n' "$id" "$origin" >&2
        continue
      fi
    fi
    link="$ROOT/.ai/repositories/$id"
    [ -L "$link" ] && [ "$(readlink "$link")" = "$slot" ] && continue
    [ -e "$link" ] && [ ! -L "$link" ] && continue               # a real clone is already there
    mkdir -p "$(dirname "$link")" 2>/dev/null || continue
    ln -sfn "$slot" "$link" 2>/dev/null || true
  done < <(ai_package_sources "$ROOT")
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

# Before anything is looked for in a source, make the sources exist. Only at
# session start: it is the one event that precedes all work, and the only one
# where paying for a clone is right.
[ "$EVENT" = "session.start" ] && ensure_sources

# Same reasoning as run_hook_dir: read off fd 9, not fd 0, and no mapfile.
while IFS= read -r src <&9 || [ -n "$src" ]; do
  [ -n "$src" ] || continue
  event_dir="$src/hooks/$EVENT"
  [ -d "$event_dir" ] || continue
  run_hook_dir "$event_dir"
done 9< <(source_dirs)

emit_output
exit 0
