---
name: orchard
description: "Run when the operator says start the gardener, open the board, or /orchard. A running session cannot re-apply --settings to itself, so this is the only way to get the fleet's hook wiring (.claude/kauk.settings.json, dispatched through .claude/hooks-run.sh) into a real gardener session: launches a fresh `claude --agent gardener --settings .claude/kauk.settings.json` process in its own tmux window and hands over."
metadata:
  tags: [orchard, gardener, launch, settings, hooks, tmux, entry-point]
visibility:
  user-invocable: true
---

# orchard (start the gardener)

`--settings` only takes effect at process start, so a session already running cannot
wire itself up. `/orchard` starts a NEW `claude` process — `--agent gardener` with
`--settings .claude/kauk.settings.json` — in its own tmux window, then hands over.

## When

- The operator says start the gardener, open the board, or runs `/orchard`.

## What it does

Requires tmux (`$TMUX` set); refuse with a clear message if not.

```bash
root="$(git rev-parse --show-toplevel)"
settings="$root/.claude/kauk.settings.json"
[ -f "$settings" ] || { echo "orchard: $settings missing, cannot launch gardener" >&2; exit 1; }

cmd=$(printf 'env ORCHID_PARENT_SESSION=%q claude --agent %q --settings %q' \
  "${CLAUDE_CODE_SESSION_ID:-}" "gardener" "$settings")
win=$(tmux new-window -P -F '#{window_id}' -n Gardener -c "$root" "$cmd")
tmux select-window -t "$win"
```

Tell the operator the gardener is starting in its own window, then step aside — this
session does not become the gardener, it only starts one.

## Rules

- Copies `.claude/tools/dispatch-agent.sh`'s conventions — the `%q`-quoted command
  string, `ORCHID_PARENT_SESSION` set to the launching session's id — but uses
  `tmux new-window` in place of `split-window -d`: the gardener gets its own window
  directly, never a hidden pane to promote out of later.
- `--settings` must point at `.claude/kauk.settings.json` itself, never a copy or an
  inline reconstruction — that file is the one place the fleet's hook wiring is named.
- No prompt argument: `claude --agent gardener` uses the agent's own `initialPrompt`.
