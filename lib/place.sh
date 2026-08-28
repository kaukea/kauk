#!/usr/bin/env bash
# place.sh — what to do about a destination, decided from facts alone.
#
# Every function here is a pure function of its arguments. The facts come from
# lib/fs.sh; the decisions are here so they can be asked every awkward question
# without building a repository to ask it in. See spec/place.cases.

# place_action <kind> <current-target> <wanted-target> -> create|correct|rewrite|replace
#
#   absent                       -> create   nothing is there
#   link, already correct        -> correct  leave it alone
#   link or dead-link, otherwise -> rewrite  point it where it belongs
#   file or dir                  -> replace  something real stands there
#
# A dead link is rewritten rather than replaced: it is still a link, and pointing
# it somewhere is not the same act as removing a file somebody wrote.
place_action() {
  local kind=$1 current=$2 wanted=$3
  case "$kind" in
    absent)              printf 'create\n' ;;
    link|dead-link)      if [ "$current" = "$wanted" ]; then printf 'correct\n'; else printf 'rewrite\n'; fi ;;
    file|dir)            printf 'replace\n' ;;
    *)                   printf 'replace\n' ;;
  esac
}

# name_choice <local-taken> <kind> <existing-resolved> <source-resolved>
#             -> plain | namespace
#
# Whether two things sharing a name are the same thing depends on WHOSE name it
# collides with.
#
#   Your own file, where a package you have declared has one of its own, is
#   almost certainly the same file: you consume that package and can publish back
#   to it. It takes the plain name and becomes your edit of it.
#
#   Two DIFFERENT packages shipping one name say nothing about meaning the same
#   thing, and both are kept under the name of the package that brought them.
#
#   A DEAD link is neither. It ships nothing, so it is no evidence of a second
#   package; it is usually a source that moved, and renaming it aside stops the
#   dead-link repair from healing it.
#
# The comparison is between two RESOLVED PATHS, never between a package's name
# and a path: the store is keyed by owner and repository while a package's
# namespace is whatever it calls itself, and the two are routinely different, so
# comparing them means no package ever matches itself.
name_choice() {
  local local_taken=$1 kind=$2 existing=$3 source=$4
  [ "$local_taken" = yes ] && { printf 'namespace\n'; return 0; }
  [ "$kind" = link ] || { printf 'plain\n'; return 0; }
  [ -n "$source" ] || { printf 'plain\n'; return 0; }
  case "$existing" in
    "${source%/}"/*) printf 'plain\n' ;;
    *)               printf 'namespace\n' ;;
  esac
}
