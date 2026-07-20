- created: 2026-07-19
- created_by: fable-5
- created_during: f/status-channel

## Blockers

_None._

## Questions

- Where does the non-derivable residue live once the file is gone? Three candidates
  to place: the kauk package's `pull-only` nature (Decision-008), the
  template-vs-prefix semantics of the two `templates/` files, and the root-file
  placements (`settings.json` → `.claude/`, `AGENTS.shared.md`/`AGENTS.files.md` →
  repo root). Constraint from Decision-011: wherever they go must NOT be a parallel
  copy of the directory listing.
- Does the derivation land in the stopgap `bin/kauk` now, or wait for the 0.1.0 CLI
  (~cli-mvp)? Files are being added to packages weekly, so the silent-drift cost is
  paid continuously until one of them ships it.

### Superseded questions (Decision-011 made them moot)

- ~~Derive before or after the real CLI, keeping the manifest meanwhile?~~ The
  manifest is removed, not kept.
- ~~Interim tree-vs-manifest lint?~~ Nothing left to lint against.

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

RESCOPED by Decision-011 (2026-07-21, operator ruling): **remove `manifest.conf`
entirely** — do not derive-and-keep, do not lint it. A package's payload IS its
tree: `skills/<name>/`, `agents/*.md`, `hooks/*.sh`, `tools/*`, `templates/`;
roles come from skill frontmatter. `bin/kauk` walks the tree instead of reading
the file; the non-derivable residue (see Questions) gets a home that is not a
file index. The orchids repo deletes its `manifest.conf` through its own
workflow once the reader no longer needs it — ship the reader change first so
no consumer breaks mid-transition, and a dated migration rides the change per
§Migrations.

## Testing

A file added to a payload directory is distributed on the next `kauk sync` with no
index edited by anyone — the 2026-07-19 bus-files failure mode becomes impossible.
Both packages lay correctly with their `manifest.conf` deleted; a repo still
carrying one syncs identically (the file is simply ignored).
