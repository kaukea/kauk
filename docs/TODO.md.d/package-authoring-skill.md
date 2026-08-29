- created: 2026-08-29
- created_by: opus-5
- created_during: f/none (intake during a session on orchard's layout)
- size: m

## Blockers

Depends on how a self-publishing package lays its own artifacts being settled —
see `self-publish-layout`.

## Questions

- What does an agent do when the artifact it is editing is the one it is
  currently running? Editing a skill mid-session changes what the next session
  loads, not this one.
- How does an author test a package artifact against a runtime that is not the
  one they are running in?

## Findings

- The problem, in the operator's words: an agent editing a skill is editing the
  one in that agent's own directory, and that copy is specific to that agent. The
  skill has to teach an agent how to write a package that works for ALL agents
  while being written by one of them. The operator's own assessment: difficult.
- This is not the same as the mechanical question of where artifacts are laid.
  That is a tooling matter. This is about what an author must know and check.

## Proposal

A skill that carries what an agent needs in order to author a kai package: what
the convention directories mean, what belongs in an agent file versus a skill
folder versus a tool, how to write something that is not shaped around the
runtime the author happens to be running in, and how to check it before shipping.

## Testing

_Not started._
