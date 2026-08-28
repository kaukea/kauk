#!/usr/bin/env bash
# fs.sh — the only place that asks the filesystem what is there.
#
# This is a port, not logic. It answers questions and performs actions; it
# decides nothing. Everything that decides takes the answers as arguments and
# lives in lib/place.sh, where it can be asked without a filesystem at all.
#
# The single most important thing here is that a DEAD LINK is a kind of its own.
# It was not, and the cost was a defect: `readlink -f` answers with nothing when
# a directory along the path is missing, which is the ordinary state of a link
# waiting to be repaired, so a package's own link looked like a stranger's and
# was renamed out of the repair's reach. A caller that must distinguish those
# cases can now do so by name instead of by inference.

# fs_kind <path> -> absent | file | dir | link | dead-link
# A link is reported as a link whether or not it resolves, because both are
# facts about the same thing and conflating them is how the above happened.
fs_kind() {
  local p=$1
  if [ -L "$p" ]; then
    if [ -e "$p" ]; then printf 'link\n'; else printf 'dead-link\n'; fi
  elif [ -d "$p" ]; then printf 'dir\n'
  elif [ -e "$p" ]; then printf 'file\n'
  else printf 'absent\n'
  fi
}

# fs_target <path> -> what a link literally carries, unresolved.
# Never `readlink -f`: the raw string is what was written, what is committed, and
# what a caller must reason about. Resolving it follows the store's own link and
# answers with somewhere else entirely.
fs_target() { readlink "$1" 2>/dev/null; }

# fs_find_up <dir> <filename> -> the nearest directory at or above <dir> holding
# <filename>, or nothing. The one filesystem walk the placing logic needs.
fs_find_up() {
  local d=$1 name=$2
  while [ -n "$d" ] && [ "$d" != / ] && [ "$d" != . ]; do
    [ -f "$d/$name" ] && { printf '%s\n' "$d"; return 0; }
    d=${d%/*}
    [ -z "$d" ] && break
  done
  return 1
}

# --- actions -----------------------------------------------------------------

fs_link()   { ln -sfn "$1" "$2"; }            # fs_link <target> <at>
fs_rename() { mv "$1" "$2"; }                 # fs_rename <from> <to>

# fs_replace_with_link <target> <at> — put a link where something else stands.
# The removal is separate on purpose: `ln` into an existing directory lands
# INSIDE it rather than replacing it, which is a silent wrong answer.
fs_replace_with_link() { rm -rf "$2"; ln -sfn "$1" "$2"; }
