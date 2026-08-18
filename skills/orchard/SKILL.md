---
name: orchard
description: "Read before launching any agent in this fleet, and before treating any agent's finished work as valid. States the hard rule: every agent is launched through .claude/tools/dispatch-agent.sh, the dispatcher that supplies the fleet's permission mode and its hook wiring — courier, session lifecycle hooks, and the question broker. Work from an agent launched any other way is unsuccessful and must be redone through the dispatcher."
metadata:
  tags: [orchard, dispatch-agent, launch, hooks, courier, question-broker, enforcement, permission-mode]
visibility:
  user-invocable: true
---

# orchard (how agents must be launched)

## Intent

An agent only becomes part of this fleet if it is wired into it at the moment
it starts. That wiring cannot be added after the fact — an agent that is
already running cannot retroactively gain a courier, its session lifecycle
hooks, or a way to ask a question through the question broker. So there is
exactly one supported way to start an agent, and this skill states the rule
that keeps it that way.

## Checklist

- [ ] The agent was started through `.claude/tools/dispatch-agent.sh` — never
      a bare `claude` invocation, and never any other launcher
- [ ] If it was not, its work is treated as not done, and is redone by an
      agent launched through the dispatcher

## Rules

- **Every agent MUST be launched through `.claude/tools/dispatch-agent.sh`.**
  That script is the only supported way to start an agent in this fleet. No
  other invocation — a hand-typed `claude` command, a copy of the dispatcher's
  command line, any shortcut that skips the script itself — is a substitute
  for it.
- **The dispatcher is what supplies the fleet's settings.** It sets the
  agent's permission mode and wires in the hooks that give the agent its
  courier (how it sends and receives messages), its session lifecycle hooks
  (how its start and end are tracked), and the question broker (how it asks
  for a decision it cannot make on its own). None of that exists for an agent
  unless the dispatcher put it there.
- **An agent started any other way silently runs without any of it.** It will
  not announce itself, cannot be reached by the agents that need to reach it,
  and cannot ask a question through the broker — and nothing will report the
  gap, because there is no error for it.
- **Work performed by an agent that was NOT launched through the dispatcher
  is UNSUCCESSFUL and does not count**, even if the agent finished its task
  and the result looks correct. It must be redone by an agent launched
  through `.claude/tools/dispatch-agent.sh`. This is a hard rule, not advice:
  do not accept, merge, or build on work produced outside it.

## Temporary shape

This rule exists because starting an agent and wiring it into the fleet are,
today, two separate steps held together only by using the dispatcher every
time. Once agent launching becomes pluggable and these settings are injected
natively at launch, this instruction will no longer be needed.
