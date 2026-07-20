- created: 2026-07-19
- created_by: fable-5
- created_during: f/status-channel

## Blockers

_None._

## Questions

- Does the DERIVATION land before or after the real kauk CLI? `manifest.conf` is parsed by
  the `kauk-sync` stopgap, documented as dying when the real CLI ships, so the redesign may
  belong in that CLI instead.
- The LINT is not subject to that question. Drift accrues per file added, so waiting for the
  CLI does not hold the problem still — it compounds it. Split the task: lint now, derivation
  whenever the CLI question resolves.

## Findings

- **Moved from serialseb/orchids (2026-07-20, operator ruling).** This is a kauk problem,
  not an orchids one: the manifest concept was a model invention — inferred from other
  parts of the code, never an operator design — so the hand-typed index is not a contract
  anyone chose. The fix (derive from the tree, fail loudly meanwhile) belongs in the reader.
- **The manifest is a hand-typed index of files the package already contains.** kauk reads it
  with `grep -Ev '^[[:space:]]*(#|$)' manifest.conf` — no derivation, no validation, nothing
  reconciling it against the tree.
- **Nothing catches a missing entry, and the failure is silent.** On 2026-07-19 four files
  (`agents/bus.md`, `hooks/bus-init.sh`, `hooks/bus-end.sh`, `tools/bus.py`) were committed,
  reviewed and tested in orchids, and distributed to nobody — because four lines were missing
  from that file. The mechanism was reported as working while it had never run in any session.
- **It is not an allowlist for shipping.** The consumer gets the WHOLE repo: the clone at
  `.ai/repositories/<owner>/<repo>/` contains `docs/`, `migrations/`, the board and
  `ARCHITECTURE.md` regardless. The manifest only picks which files are symlinked into
  `.claude/` — so nothing is being withheld from anyone and the "we must declare what ships"
  justification does not hold.
- **Most entries restate their own path.** `link agents/x.md .claude/agents/x.md` is the
  source path with a prefix swapped. Four directory conventions cover every one of them:
  `agents/*.md`, `hooks/*.sh`, `tools/*`, `skills/<name>/`.
- **What is genuinely not derivable is small:** the `link` vs `template` distinction (one
  tracks upstream, the other is copied once at install and thereafter owned by the project) —
  which a `templates/` directory would express — and `option` lines, which describe the
  package rather than any file. Per-skill roles now live in frontmatter (orchids
  role-dag-frontmatter, closed 2026-07-20).

## Proposal

Derive distribution from the tree instead of authoring it. Directory conventions replace the
per-file `link` and `skill` lines; whatever cannot be derived (delivery semantics, package
options) moves somewhere that is not a parallel copy of the directory listing.

**Do the lint NOW, not as a first half of a later project.** A check comparing the payload
directories against the manifest, failing on anything present in the tree but undeclared. It
converts a silent failure into a loud one, would have caught the 19 July bug at commit time,
and is worth doing even if every other line of this task is thrown away — because the cost of
not having it is paid per file added, and files are being added now.

## Testing

A file added to a payload directory and not declared must cause a visible failure — and once
derivation lands, must be distributed without anyone editing an index.
