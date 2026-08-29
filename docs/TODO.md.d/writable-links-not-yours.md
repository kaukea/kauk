- created: 2026-08-29
- created_by: opus-5
- created_during: f/kai-is-self-contained
- size: m

## Blockers

No approach chosen. The operator's words: "I'm not sure how we solve this one, so
I put it in the backlog."

## Questions

- Should a laid artifact be writable at all by default, or should writing to one
  be an explicit act?
- If it stays writable, what tells an agent whose file it is at the moment it
  writes — not in a document it may not have read?
- Does the answer differ for a package you can publish back to and one you
  cannot?

## Findings

- A laid artifact is a link into the package it came from, so anything with write
  access to the working tree can edit that package's repository through it. That
  is deliberate and useful: a user's own change to a skill reaches its source and
  rebases onto the package's changes.
- It is also indistinguishable, at the moment of writing, from editing something
  you own. Nothing at the point of the edit says whose file it is.
- Live case, 2026-08-29: kai's own rule about migrations was written into
  `AGENTS.files.md` at kauk's root, which is a link into orchard. It landed in
  orchard's clone. It was reverted, and the rule went into kai's own documents
  instead — but only because the operator noticed and asked who owned the file.
- The rule now in `AGENTS.md` — check whether it is a link before writing, and
  write access through a link is not ownership — is a rule, not a mechanism. It
  works only for an agent that has read it and remembers to check.
- The problem is sharpest for a repository you have write access to but is not
  yours in any other sense: same machine, same operator, different subject and
  different workflow.

## Proposal

_None yet._ Possibilities, none chosen: make laid artifacts read-only and require
an explicit act to edit one; have the tool notice a write through a link and say
whose it is; distinguish packages you may publish back to from those you may not;
or leave it as a rule and accept that it depends on the agent having read it.

## Testing

_Not started._
