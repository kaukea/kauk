#!/usr/bin/env bash
# agent — launch a named agent session carrying kai's fleet settings.
#
# A running Claude session cannot re-apply its own --settings, so the only way
# to pick up bin/kai.settings.json is a fresh `claude` process started with it.
# This script resolves that file EXACTLY the way every fleet dispatch resolves
# it (.claude/tools/dispatch-agent.sh, and bin/kai.settings.json's own
# SessionStart/SessionEnd/PreToolUse/UserPromptSubmit/Notification hooks that
# call bin/kai-hooks.sh): command -v kai on PATH, then readlink -f the result
# with a graceful fallback to the unresolved path, then dirname.
#
# Matching that resolution is not optional — the two ends of this exact
# contract have disagreed before (kai.settings.json resolved kai-hooks.sh with
# a bare `dirname` while dispatch-agent.sh resolved kai.settings.json with
# `readlink -f`) and a green 13/13 suite missed it
# (docs/TODO.md.d/fleet-settings-wiring.md, Decision — 2026-08-19
# #verification #close).
set -euo pipefail

# resolve_settings — print the absolute path to kai.settings.json beside the
# RESOLVED kai binary on PATH, or fail. Never guesses relative to the
# repository being worked in; kai is a static install, found only via PATH.
resolve_settings() {
  local kai_bin settings
  kai_bin=$(command -v kai 2>/dev/null) || return 1
  kai_bin=$(readlink -f "$kai_bin" 2>/dev/null || printf '%s' "$kai_bin")
  settings="$(dirname "$kai_bin")/kai.settings.json"
  [ -f "$settings" ] || return 1
  printf '%s\n' "$settings"
}

settings=$(resolve_settings) || {
  echo "agent: could not resolve kai.settings.json — is kai installed and on PATH?" >&2
  exit 1
}

# --print-settings: resolution only, no tmux side effect. What the self-check
# and the deployed-arrangement test below exercise. No agent name needed.
if [ "${1:-}" = "--print-settings" ]; then
  printf '%s\n' "$settings"
  exit 0
fi

agent_name="${1:-}"
if [ -z "$agent_name" ]; then
  echo "agent: usage: launch-agent.sh <agent-name> | --print-settings" >&2
  exit 1
fi

command -v tmux >/dev/null 2>&1 || {
  echo "agent: tmux not found — cannot open the agent's own window" >&2
  exit 1
}

cmd=$(printf 'claude --agent %q --settings %q' "$agent_name" "$settings")
win=$(tmux new-window -d -P -F '#{window_id}' -n "$agent_name" "$cmd")
tmux select-window -t "$win"
echo "$win"
