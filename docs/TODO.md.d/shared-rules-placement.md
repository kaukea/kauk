- created: 2026-08-18
- created_by: fable-5

## Blockers

(none)

## Questions

_None open — placement ruled by the operator, 2026-08-18._

## Findings

- Verified (harness docs, memory.md): every markdown file under `.claude/rules/`
  auto-loads (recursive, symlinks supported, optional `paths:` frontmatter
  scoping) — no CLAUDE.md edit needed.
- Operator placement ruling: AGENTS.md — the project-owned rules the user edits —
  stays VISIBLE at repo root, never hidden. The package-shipped
  AGENTS.shared.md / AGENTS.files.md move to `.claude/rules/`.

## Proposal

The reader lays the package-shipped rule markdown (AGENTS.shared.md,
AGENTS.files.md) into `.claude/rules/` instead of repo root + CLAUDE.md imports;
CLAUDE.md's import stub for them retires. AGENTS.md placement is untouched. A
shipped migration moves existing consumers (old root links removed, rules laid) —
all steps scripted (Decision-055).

## Testing

To be agreed at bloom. Candidate: consumer fixture syncs; rule files resolve
under `.claude/rules/`, a session loads them with no CLAUDE.md reference, no
root link remains.
