#!/usr/bin/env bash
# names.sh — the arithmetic of sources, identifiers and link targets.
#
# Everything here is a pure function of its arguments. Nothing reads a file,
# runs git, or looks at the filesystem, which is the point: every defect this
# library exists to prevent was a wrong answer about a NAME, and a wrong answer
# about a name needs no repository to demonstrate.
#
# Callers that must consult the filesystem — finding the declaration file above
# a link, discovering what a symlink points at — do that themselves and pass the
# answer in.

# --- sources -----------------------------------------------------------------

# ref_of <source> -> the @ref, or nothing.
# The @ is only a reference marker in the LAST path segment. A git address
# carries an @ in its user part (git@host:owner/repo) and cutting there leaves
# "git", which is how a perfectly ordinary source stopped being recognised.
ref_of() {
  local tail=${1##*/}
  case "$tail" in *@*) printf '%s\n' "${tail##*@}" ;; esac
}

# without_ref <source> -> the source with any @ref removed
without_ref() {
  local r; r=$(ref_of "$1")
  [ -z "$r" ] && { printf '%s\n' "$1"; return 0; }
  printf '%s\n' "${1%@"$r"}"
}

# repo_half <source> -> the repository name alone, from any shape of source.
# Used to answer "is this package already declared" without caring whether it
# was written as owner/repo, as a git address, or as a path to a checkout.
repo_half() {
  local s; s=$(without_ref "$1")
  s=${s%/}
  s=${s%.git}
  printf '%s\n' "${s##*/}"
}

# owner_repo <source> -> <owner>/<repo>, the identifier a package is stored under
owner_repo() {
  local s; s=$(without_ref "$1")
  s=${s%.git}; s=${s%/}
  local tail=${s##*:}                      # git@host:owner/repo -> owner/repo
  case "$tail" in
    */*) s=$tail ;;
  esac
  local repo=${s##*/} rest=${s%/*}
  printf '%s/%s\n' "${rest##*/}" "$repo"
}

# --- paths -------------------------------------------------------------------

# relative_to <from-dir> <to> -> <to> relative to <from-dir>, both absolute and
# collapsed, by text alone (see collapse for why never readlink -f)
relative_to() {
  awk -v a="$1" -v b="$2" 'BEGIN {
    na = split(a, x, "/"); nb = split(b, y, "/")
    i = 1; while (i <= na && i <= nb && x[i] == y[i]) i++
    s = ""
    for (j = i; j <= na; j++) if (x[j] != "") s = s "../"
    for (j = i; j <= nb; j++) if (y[j] != "") s = s y[j] "/"
    sub(/\/$/, "", s); print (s == "" ? "." : s)
  }'
}

# path_id <root> <path-as-written> -> the store slot of a local path source.
# A local repository has no owner, so it is named after its path relative to the
# repository that declares it, percent-encoded to keep it one folder: moving the
# package is a rename, like a renamed GitHub repository, and .ai.toml says so
# (operator, 2026-10-21).
# Both sides are compared physically when they exist: git answers the root
# physically (/private/var on macOS), and a path written through a symlink would
# otherwise climb to / and back down.
path_id() {
  local from to rel
  from=$(collapse "$1" .); to=$(collapse "$1" "$(without_ref "$2")")
  [ -d "$from" ] && from=$(cd "$from" && pwd -P)
  [ -d "$to" ] && to=$(cd "$to" && pwd -P)
  rel=$(relative_to "$from" "$to")
  rel=${rel%.git}
  # A name starting with a dot is hidden, and globs skip it: the dots of ".."
  # and a leading dot are written %2E too.
  rel=$(printf '%s\n' "$rel" | awk -F/ -v OFS=/ '{ for (i = 1; i <= NF; i++) if ($i == "..") $i = "%2E%2E"; sub(/^\./, "%2E"); print }')
  printf 'path/%s\n' "${rel//\//%2F}"
}


# absolute <base> <path> -> <path> made absolute against <base>, no resolution
absolute() {
  case "$2" in
    /*) printf '%s\n' "${2%/}" ;;
    *)  local p="${1%/}/${2#./}"; printf '%s\n' "${p%/}" ;;
  esac
}

# collapse <base> <path> -> absolute with "." and ".." resolved AS TEXT.
# Deliberately not readlink -f, for two reasons that both bit: it answers with
# nothing at all when a directory along the way does not exist, which is exactly
# the state of a link waiting to be repaired; and it follows symlinks, so a path
# reached through the package store answers with wherever the store really is
# rather than with the path being reasoned about.
collapse() {
  local p; p=$(absolute "$1" "$2")
  printf '%s\n' "$p" | awk -F/ '{
    n = 0
    for (i = 1; i <= NF; i++) {
      if ($i == "" || $i == ".") continue
      if ($i == "..") { if (n > 0) n--; continue }
      out[++n] = $i
    }
    s = ""
    for (i = 1; i <= n; i++) s = s "/" out[i]
    print (s == "" ? "/" : s)
  }'
}

# under <parent> <path> -> true when <path> is inside <parent>
under() {
  local parent=${1%/} path=$2
  [ "$path" = "$parent" ] && return 1
  case "$path" in "$parent"/*) return 0 ;; *) return 1 ;; esac
}

# depth_below <anchor> <dir> -> how many directories <dir> sits below <anchor>,
# or nothing when it does not sit below it at all.
depth_below() {
  local anchor=${1%/} dir=${2%/}
  [ "$dir" = "$anchor" ] && { printf '0\n'; return 0; }
  case "$dir" in
    "$anchor"/*) printf '%s' "${dir#"$anchor"/}" | awk -F/ '{print NF}' ;;
    *) return 1 ;;
  esac
}

# link_target <anchor> <target> <linkdir> -> what a link in <linkdir> should
# carry to reach <target>, counted from <anchor>.
#
# A laid link is COMMITTED, so its target has to be right in every checkout, not
# just the one that laid it. The count belongs to the link's own position below
# the anchor — never to a home directory, and never to wherever the command
# happened to be run, which is how links needing two steps up were written with
# five and broke the moment their branch landed.
#
# Answers with the target unchanged when it cannot be derived honestly: a
# working absolute link beats a relative one built on a guess.
link_target() {
  local anchor=${1%/} target=$2 linkdir=${3%/} rest depth prefix="" i=0
  under "$anchor" "$target" || { printf '%s\n' "$target"; return 0; }
  rest=${target#"$anchor"/}
  depth=$(depth_below "$anchor" "$linkdir") || { printf '%s\n' "$target"; return 0; }
  while [ "$i" -lt "$depth" ]; do prefix="../$prefix"; i=$((i + 1)); done
  printf '%s\n' "$prefix$rest"
}

# --- migration filenames -----------------------------------------------------

# mig_day <filename> -> the YYYY-MM-DD a migration is named for
mig_day() { local b=${1##*/}; b=${b%.md}; printf '%s\n' "${b:0:10}"; }

# mig_seq <filename> -> the NN within that day as an integer.
# The older <date>-<slug> form has no NN, so it answers 0 — which is why every
# migration of one such day shares a prefix and they must not be told apart by it.
mig_seq() {
  local b=${1##*/} rest nn
  b=${b%.md}; rest=${b:11}; nn=${rest%%-*}
  case "$nn" in ''|*[!0-9]*) nn=0 ;; esac
  printf '%d\n' "$((10#$nn))"
}
