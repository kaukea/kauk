#!/usr/bin/env bash
# aitoml.sh — the ONE reader of .ai.toml.
#
# It was two. `bin/kaukea` had this, and `bin/kai-hooks.sh` had a simplified copy
# written beside the code that needed it. They had already diverged: a dependency
# whose `type` is not `package` is ignored by the tool, with a warning, and was
# cloned by the session-start hook regardless.
#
# tests/one-reader.sh fails if either executable grows its own parser again.

ai_file() { echo "$1/.ai.toml"; }

AWK_UNQ='
  function unq(s,   q) {
    sub(/^[ \t]*[A-Za-z_][A-Za-z_0-9-]*[ \t]*=[ \t]*/, "", s)
    if (substr(s, 1, 1) == "\"") { q = substr(s, 2); sub(/".*$/, "", q); return q }
    sub(/[ \t]*#.*$/, "", s); sub(/[ \t]+$/, "", s); sub(/^[ \t]+/, "", s)
    return s
  }
  function arr(s,   n, a, i, out) {
    sub(/^[^[]*\[/, "", s); sub(/\].*$/, "", s)
    n = split(s, a, ",")
    for (i = 1; i <= n; i++) {
      gsub(/^[ \t"'"'"']+|[ \t"'"'"']+$/, "", a[i])
      if (a[i] != "") out = out (out ? "," : "") a[i]
    }
    return out
  }
'

root_field() { # root_field <repo-or-clone> <field> -> value from the root table
  local f; f=$(ai_file "$1")
  [ -f "$f" ] || return 0
  awk -v key="$2" "$AWK_UNQ"'
    /^[ \t]*\[/ { exit }
    $0 ~ "^[ \t]*" key "[ \t]*=" { print unq($0); exit }
  ' "$f"
}

dep_rows() { # dep_rows <root> -> "<source>\t<type>\t<include-csv>" per dependency
  local f; f=$(ai_file "$1")
  [ -f "$f" ] || return 0
  awk "$AWK_UNQ"'
    function flush() {
      if (indep && src != "") printf "%s|%s|%s\n", src, typ, inc
      src = ""; typ = ""; inc = ""
    }
    /^[ \t]*\[\[dependency\]\][ \t]*$/ { flush(); indep = 1; next }
    /^[ \t]*\[/                        { flush(); indep = 0; next }
    inarr {
      buf = buf " " $0
      if ($0 ~ /\]/) { inc = arr(buf); inarr = 0; buf = "" }
      next
    }
    indep && /^[ \t]*source[ \t]*=/  { src = unq($0); next }
    indep && /^[ \t]*type[ \t]*=/    { typ = unq($0); next }
    indep && /^[ \t]*include[ \t]*=/ {
      buf = $0
      if (buf ~ /\]/) { inc = arr(buf) } else { inarr = 1 }
      next
    }
    END { flush() }
  ' "$f"
}

# ai_package_sources <root> -> one source per line, ONLY those the tool acts on.
# A dependency declaring a type other than `package` is not one of them; that is
# the distinction the two readers disagreed about.
ai_package_sources() {
  local raw typ inc
  while IFS='|' read -r raw typ inc; do
    [ -n "$raw" ] || continue
    case "$typ" in ''|package) printf '%s\n' "$raw" ;; esac
  done < <(dep_rows "$1")
}
