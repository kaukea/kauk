- created: 2026-08-29
- created_by: opus-5
- created_during: f/type-is-a-dependency
- completed: 2026-08-29
- completed_during: f/type-is-a-dependency
- size: s

## Blockers

(none)

## Questions

_None._

## Findings

Result: merged to main on 2026-08-29, preserved under archive/type-is-a-dependency.

- The operator's objection, and it is right: a key of its own reads as a second
  way of saying what artifacts already say. They declare what they depend on, and
  needing the repository to be a package is one of those.
- The nested `dependencies:` map is the form that was designed. The flat
  `dependencies-<kind>` spelling beside it was never vetted. Nothing in the
  estate had ever used the nested form, so it is now used for the thing it fits.
- Reading a plain value from that block is new — the reader handled inline lists
  and dash blocks only.
- Nothing breaks, and the operator said why before I checked it: the only two
  files carrying the old key are this repository and the symlink to it, and no
  consumer has ever synced it. A repository that already refers to the package
  still does not receive the skill, because `type` defaults to `project`.
  Verified across all three states — no root table, `type = "project"` written
  out, and `type = "package"`.
- The flat spelling is deliberately left alone: 28 artifacts across the estate
  use it, and never having been vetted is not on its own a reason to disturb
  them.

## Proposal

Express "this artifact needs the repository to be a package" as a dependency in
the nested map, and drop the key invented for it.

## Testing

`tests/convention-reader.sh` keeps the twelve behavioural cases and swaps the
three about the frontmatter to assert the dependency form — under `dependencies:`,
a plain value, and no key of its own. Three further states checked by hand: a
consumer with no root table, one declaring `type = "project"`, and one declaring
`type = "package"`; only the last receives the skill. 611 assertions across
twelve suites, all green.

## Changelog entry

#### ♻️ `f/type-is-a-dependency` → `archive/type-is-a-dependency`

An artifact that is only usable in a repository which is itself a package now
says so as a dependency, in the nested map that was designed for it and that
nothing had used, rather than through a key invented beside it:

```yaml
dependencies:
  type: package
```

Reading a plain value from that block is new; the reader understood lists only.
The flat `dependencies-<kind>` spelling is untouched. Nothing breaks: no consumer
had synced the old key, and a repository that already refers to the package still
does not receive the skill, because `type` defaults to `project`.

_Board: `type-is-a-dependency` · corrects `authoring-skill`._

## Readme delta

None.
