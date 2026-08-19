---
name: garden
description: "Run when the operator wants to (re)start the fleet's root session with kai's fleet settings applied. A session cannot re-apply its own --settings, so this launches a fresh `claude --agent gardener --settings <kai.settings.json>` process in its own tmux window and hands the operator to it. This is the one skill kai ships (Decision — kai package, 2026-08-19): everything else the package needs is already in the bin, present from the static install."
metadata:
  tags: [kai, gardener, launch, settings, tmux, session, bootstrap, dispatch]
visibility:
  user-invocable: true
---

# garden (launch the settings-carrying gardener session)

## Intent

A running Claude session cannot re-apply its own `--settings` — the fleet's hooks,
permission mode, and courier wiring (`bin/kai.settings.json`) only take effect on a
process started with them. This skill is the operator's entry point out of a plain
session: it resolves the settings file the way every fleet dispatch resolves it, then
launches a real `gardener` session carrying it and hands the operator over.

## Checklist

- [ ] `kai` resolved from PATH — never assumed to sit beside this repository
- [ ] `kai.settings.json` resolved beside the RESOLVED kai binary (`readlink -f`,
      never a bare `dirname` of the PATH entry alone)
- [ ] A new session launched as `claude --agent gardener --settings <file>` in its own
      tmux window
- [ ] The operator handed over to the new window

## What it does

Run `launch-gardener.sh` from this skill's own base directory (the path Claude Code
shows when this skill loads). It:

1. Resolves `kai` via `command -v kai`, then `readlink -f` the result — falling back to
   the unresolved path if that fails — exactly what `.claude/tools/dispatch-agent.sh`
   does before appending `--settings` to any fleet dispatch, and what
   `bin/kai.settings.json`'s own hooks do before calling `kai-hooks.sh`.
2. Takes `dirname` of the resolved binary and looks for `kai.settings.json` beside it.
3. Opens a new tmux window running
   `claude --agent gardener --settings <resolved kai.settings.json>`, then switches the
   operator's client to it.

## Rules

- **Never resolve the settings file relative to the repository being worked in.** It
  lives beside the installed `kai` binary — a static install already on PATH — not in
  whatever checkout happens to be open.
- **Match the resolution the dispatcher uses, exactly.** The two ends of this contract
  have disagreed before — `kai.settings.json` resolving `kai-hooks.sh` with `dirname`
  alone while `dispatch-agent.sh` resolved `kai.settings.json` with `readlink -f` — and a
  green test suite missed it. A change to one end is a change to both.
- **Fail loudly, not silently.** No `kai` on PATH, or no `kai.settings.json` beside it,
  is reported and the launch aborts — it never falls back to an unsettinged session
  without saying so.
