- created: 2026-08-18
- created_by: fable-5
- created_during: (gardener boot triage — fallout of stale-laid-links)
- completed: 2026-08-18

### Why cancelled

Decision-055 supersedes the agent-duty reading the same day it was recorded:
migration application belongs to a kai SCRIPT — ordered, watermarked by the tool,
agent-independent. Encoding an agent duty in the workflow rules is the opposite of
that. The delivery-reach problem this task carried folds into migrations-at-sync
(gh#23), now urgent.

## Blockers

(none)

## Questions

- ~~How do package-targeted migrations reach a package repository that consumes
  nothing?~~ Operator ruling (2026-08-18): applying migrations is the AGENT's
  job, like laying and links — no new tool channel. The session working in a
  repository applies the migrations that target it; the gardener discharged the
  backlog (convention-packages in orchard, per-package-watermark in orchard).

## Findings

- The watermark mechanism itself works: per-package date watermarks under
  `.git/the-works/migrated/<owner>/<repo>`, hook-reported, applied in order on
  update. Verified current in the kauk checkout (→ 2026-08-18-kaukea-move).
- Orchard has NO `.ai.toml` (unvendored itself, orchard migration
  2026-07-27-unvendor-self) — so kauk's `2026-08-12-convention-packages.md`,
  aimed at "repositories that ARE packages", never had a carrier into orchard.
  It no-opped through every consumer and never ran where it mattered. This is
  how stale-laid-links happened; the class of failure outlives that fix.

## Proposal

Encode the ruled duty in the workflow component so it survives sessions: an agent
booting in a repository checks for and applies pending migrations that target it —
package-clause migrations in package repositories included, not only
consumer-side hook reports. A rule/skill edit in orchard (gardener's own domain,
Decision-065), no product code. Out of scope: the concrete stale-links heal (that
is stale-laid-links) and migrations-at-sync's tool-side automation.

## Testing

To be agreed at bloom. Candidate: a fixture package repo with a pending
package-clause migration; assert the chosen channel applies it and the
watermark only advances after execution.
