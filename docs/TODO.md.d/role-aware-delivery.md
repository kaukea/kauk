- created: 2026-07-17
- created_by: opus-4.8
- created_during: orchids board work (cross-repo spec handoff)

## Blockers
- None. orchids can land its declarations before this exists — kauk has no YAML reader,
  so unknown frontmatter keys are inert and nothing regresses while this is unbuilt.
- Conversely orchids CANNOT test its own work until this ships. Their four role tasks
  all park at "declaration lint only". This is the gate on the other side.

## Questions
- **Stopgap or 0.1.0?** This is real engine work in `bin/kauk` (bash), which
  `cli-mvp` supersedes. Building it twice is waste; waiting blocks orchids indefinitely,
  since 0.1.0 has no language chosen yet (`cli-mvp` Questions). Operator's call.
- **Frontmatter syntax** — orchids owns this and has not settled it (their
  `role-dag-frontmatter` task). Candidates: `roles: [security/forensics]` (slash paths
  as strings) vs nested YAML vs flat `role:` + `parent:`. Agree it across both boards
  before either side builds; kauk has to parse whatever wins, and bash+awk parsing
  argues hard for the flat string-path form.
- **Required-skill conflict** — a selected role pulls in an agent whose required skill
  the user excluded. Install the skill anyway, warn, or refuse the selection?
- **Where does the selection persist?** `.ai.toml` is the natural home (it already
  holds per-repo delivery), but it is per-repo while roles may want to be per-source.

## Findings
Facts verified in `bin/kauk` on 2026-07-17 — trust these rather than re-deriving:

- **The role field is already there and does nothing.** `resolve_mode`
  (`bin/kauk:41-56`) takes the manifest's `<role>` only as an `.ai.toml` *section name*
  to look up. It is never compared against a list, never validated, never a filter.
  No `.ai.toml` in the fleet defines a role section, so every skill falls through the
  4-level precedence ladder to the hardcoded `link` default.
- **Consequence:** all 26 orchids skills link into every consuming repo today.
  Confirmed against `.claude/skills/`. The context cost is 10,190 bytes of `description`
  frontmatter per session, per repo, regardless of the work.
- **`all` is not special-cased.** It resolves by looking for a literal `[all]` section
  that no one has. It behaves identically to any unconfigured role — i.e. inertly.
- **The one hardcoded role literal** is `cmd_install:272`:
  `printf 'skill %s dev\n' "$skill"` — every auto-adopted skill is stamped `dev`
  regardless of what it is. orchids' current buckets are partly just this artifact.
- **The parser is positional and lax**, which is good news: `lay_source`
  (`bin/kauk:114-140`) dispatches on `read -r t a b _rest` and warns-and-skips unknown
  types. A new `agent` line type, or extra fields on `skill`, are additive and
  backward-compatible at the parse layer.
- **There is no YAML/frontmatter reader at all.** kauk touches `SKILL.md` at 5 places
  (`:158`, `:269-271`, `:279-280`), all byte-level (`cmp -s`, `-e`, `cp`). Reading
  `roles:` out of frontmatter is genuinely new capability, not an extension.
- **Agents are `link` lines** with no role and no identity — installed unconditionally
  into every repo. They need a real line type before they can be filtered or carry deps.
- **`prune_links` (`bin/kauk:183-191`) already garbage-collects** dangling symlinks into
  `.ai/repositories/`. Deselecting a role should therefore clean up on next `sync` for
  free — worth verifying rather than re-implementing.

## Proposal
orchids ships the data (vocabulary, per-definition role declarations, agent→skill
dependency edges) per their Decision-002/003. kauk owns everything below:

1. **Read** `roles:` from `SKILL.md` / agent frontmatter. Minimal reader — the agreed
   syntax should be chosen so awk can do it.
2. **Ask** at `kauk install`: which roles apply to this repo. Static list, multi-select.
3. **Persist** the selection (`.ai.toml`).
4. **Filter** in `lay_source`: lay a definition only if its declared roles intersect the
   selection. Semantics (orchids Decision-002): selecting node N installs N, N's whole
   subtree, and N's ancestors' own non-child skills. A definition may declare several
   paths (`coding-tofu` is both `development/tofu` and `infrastructure/tofu`) — match is
   "any path intersects".
5. **`agent` line type** + resolution of each agent's required skills.
6. **Retire** the manifest `role` field and the `cmd_install:272` `dev` stamp once
   frontmatter is authoritative.

`.ai.toml`'s existing `exclude|copy|link|local` per-skill override stays — it is a
different axis (HOW to deliver), not this one (WHETHER to).

## Testing
Scratch repo, per role node: install it and assert the delivered `.claude/skills/` set
is exactly the declared subtree — no more, no less. Deselect a role, `kauk sync`, assert
the links are pruned and nothing dangles. An agent with a `requires:` edge installs its
required skills. Regression: a package with no `roles:` anywhere still installs exactly
as today (orchids will be in that state until their side lands).

Report the real before/after description-byte count for a repo selecting one role —
10,190 b is the baseline to beat, and the number is the point of the feature.
