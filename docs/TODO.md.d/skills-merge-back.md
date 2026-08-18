- created: 2026-08-17
- created_by: fable-5 (operator caveat, estate-sweep go)

## Blockers

None to start; BLOCKS the round-two migration (org move, orchids skill tour):
one codebase first.

## Questions

_None open — the sweep's BLOCKED reports supply the inventory._

## Findings

Operator caveat (2026-08-17): the skills have diverged across the estate —
repos carry local copies that drifted from orchids — and must be merged back
into orchids so there is ONE codebase before the solutions migrate. The
estate sweep's report-and-skip output enumerates every diverged file.

## Proposal

From the sweep's BLOCKED inventory: merge each diverged copy back into
orchids through its own workflow, then re-sync the repo so the link replaces
the copy. kai resolve lists pairs side by side per repo.

## Testing

After the pass, a sweep across the estate reports zero BLOCKED destinations
for orchids-owned artifacts.

## Inventory (machine-wide discovery, 2026-08-18)

No orchids-NAMED skill diverges anywhere — the divergence lives in skills that
left or never entered orchids. Scope extended by the operator: locally created
skills are investigated for adoption into orchids too.

1. **serialseb/orchids.forensics** — the LIVING forensic corpus, package-style
   `skills/` tree, newer than the forensics repo's stale mirror on every
   compared skill; `digital-signature` renamed `digsig`; NEW `read-keychain`,
   `read-ntfs` (head 2732e91, 2026-08-10). Proposal: this IS the one-codebase
   for forensics — the forensics repo installs kai with orchids.forensics as
   a source and drops the stale-mirror copies. (Execution in forensics is
   outside agent remit, Decision-145 — operator-run or sanctioned exception.)
2. **nanogenomic/ClaudeCodeBrowser `web-debug-browser` agent** — generic
   browser debug/automation agent. Proposal: adopt into orchids.
3. **SignMc `.claude/skills/core-stuff`** — unfinished stub (placeholder
   description). Proposal: judge content, likely delete or finish in place.
4. **judada `calibrate-camera`** — judada-camera-specific. Proposal: stays
   local (or a judada package later); not orchids material.
5. **serialseb.voice `skills/voice-setup`** — Jabra-hardware-specific,
   already package-style in its own repo. Proposal: stays as the voice
   package; consumers reach it as a cross-package source, not via orchids.
6. **judada** carries skills with NO kai at all — after rulings, kai install
   there and pull through kai instead of copies.
