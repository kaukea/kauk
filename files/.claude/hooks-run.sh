#!/usr/bin/env bash
set -uo pipefail

event="${1:-}"
repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
hooks_dir="$repo_root/.claude/hooks"

run_script() {
  local script="$1" stdin_data="$2"
  [ -x "$script" ] || return 0
  printf '%s' "$stdin_data" | "$script"
}

fallback_scripts_for() {
  case "$1" in
    session.start)      echo courier-init.sh ;;
    session.end)        echo courier-end.sh ;;
    tool.shell.before)  echo courier-only-transport.sh ;;
    prompt.submit)       echo migrations-pending.sh question-input-activity.sh ;;
    notification)        echo question-notification-backstop.sh ;;
  esac
}

stdin_data="$(cat)"
event_dir="$hooks_dir/$event"

if [ -d "$event_dir" ]; then
  for script in "$event_dir"/*; do
    run_script "$script" "$stdin_data"
  done
else
  for name in $(fallback_scripts_for "$event"); do
    run_script "$hooks_dir/$name" "$stdin_data"
  done
fi

exit 0
