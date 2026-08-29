---
name: agent
description: "Run when the operator wants to (re)start any named agent's root session with kai's fleet settings applied. A session cannot re-apply its own --settings, so this launches a fresh `claude --agent <name> --settings <kai.settings.json>` process in its own tmux window and hands the operator to it. Takes the agent name as an argument to the skill invocation. Any agent can be launched this way — there is no privileged launcher and nothing else to know."
metadata:
  tags: [kai, launch, settings, tmux, session, bootstrap]
user-invocable: true
---

# agent (launch a settings-carrying agent session)

## Intent

A running Claude session cannot re-apply its own `--settings` — the fleet's hooks,
permission mode, and courier wiring (`bin/kai.settings.json`) only take effect on a
process started with them. This skill is the operator's entry point out of a plain
session for ANY named agent: it resolves the settings file the way every fleet
dispatch resolves it, then launches a real session for the named agent carrying it,
and hands the operator over.

## Checklist

- [ ] An agent name given as the skill's argument
- [ ] `kai` resolved from PATH — never assumed to sit beside this repository
- [ ] `kai.settings.json` resolved beside the RESOLVED kai binary (`readlink -f`,
      never a bare `dirname` of the PATH entry alone)
- [ ] A new session launched as `claude --agent <name> --settings <file>` in its own
      tmux window
- [ ] The operator handed over to the new window

## What it does

Run `launch-agent.sh <agent-name>` from this skill's own base directory (the path
Claude Code shows when this skill loads). It:

1. Resolves `kai` via `command -v kai`, then `readlink -f` the result — falling back to
   the unresolved path if that fails — and what
   `bin/kai.settings.json`'s own hooks do before calling `kai-hooks.sh`.
2. Takes `dirname` of the resolved binary and looks for `kai.settings.json` beside it.
3. Opens a new tmux window named after the agent, running
   `claude --agent <agent-name> --settings <resolved kai.settings.json>`, then switches
   the operator's client to it.

## Rules

- **Never resolve the settings file relative to the repository being worked in.** It
  lives beside the installed `kai` binary — a static install already on PATH — not in
  whatever checkout happens to be open.
- **Both ends of the resolution must agree, exactly.** The settings file finds the hook
  script beside the binary, and anything launching a session finds the settings file the
  same way. They have disagreed before — one resolving with `dirname` alone while the
  other used `readlink -f` — and a green test suite missed it, because each end was
  correct on its own. A change to one is a change to both.
- **Fail loudly, not silently.** No agent name given, no `kai` on PATH, or no
  `kai.settings.json` beside it, is reported and the launch aborts — it never falls
  back to an unsettinged or unnamed session without saying so.
