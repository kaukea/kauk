- created: 2026-09-06
- created_by: opus-5
- created_during: adapter-and-identity

## Blockers

_None._

## Questions

- A `kai list` command of its own, or the name and description folded into the
  two places that already list? Recommendation: fold them in first — the two
  existing reports are where a user already looks.

## Findings

- Identity is the source in whatever shape it arrived: `<owner>/<repo>`, a full
  git address, or a local path. Nothing in the configuration file changes it,
  and nothing on disk moves — the store stays keyed on where a package was
  fetched from (Operator, 2026-09-06).
- `name` is free text, defaults to the repository name when absent, and is for
  display. `description` is display only as well, ruled free text in the root
  table on 2026-08-27. There is no `title` key and none was agreed.
- Both are readable from a clone today: `root_field` takes a clone, which is how
  `pkg_namespace` already reads `name`. No new machinery is needed.
- `name` currently has exactly one use — `pkg_namespace` feeds it to
  `namespace_for`, which uses it only when two packages ship an artifact of the
  same name. With no collision the value is computed and discarded, so a package
  that declares a name produces byte-identical output to one that does not, and
  nothing ever shows it.
- Two places list today, and both print the bare identity: `status_source` and
  `offer_tree`. There is no `kai list`.
- Agreed display shape (Operator, 2026-09-06):

  ```
  Orchard Workflow / kaukea/orchard
    Who touched the evidence store, in plain sentences.
    0 incoming · 0 outgoing · no local edits
  ```

  Full identity on the first line after the name; the description under it.
- `docs/package-format.md` is stale on this: it states that identity is `name`
  and `type` and that this is the whole of it, which predates the 2026-08-27
  ruling on `description`. `docs/ai-toml.md` is correct.

## Proposal

Surface a package's `name` and `description` where packages are reported, in
the shape above, so that a repository can say what it is and a user can see it.
Read properly when either is absent. Correct the stale sentence in
`docs/package-format.md`.

## Testing

A package declaring a name and a description shows both. One declaring neither
shows its identity alone, with no empty line and no placeholder. One declaring
only a name shows the name.
