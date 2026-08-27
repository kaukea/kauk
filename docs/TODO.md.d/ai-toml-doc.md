- created: 2026-08-27
- created_by: opus-5
- created_during: f/ai-toml-doc
- completed: 2026-08-27
- completed_during: f/ai-toml-doc
- size: s

## Blockers

(none)

## Questions

_None._

## Findings

Result: merged to main on 2026-08-27, preserved under archive/ai-toml-doc.

- There was nowhere to send someone asking what goes in `.ai.toml`. The nearest
  thing, `docs/configuration-files.md`, is an operator-annotated correction
  scratchpad, not user documentation, and still describes the retired
  `[sources."owner/repo"]` syntax rather than `[[dependency]]`. Left alone: it is
  the operator's working file and says so at the top.
- Every claim in the new document was checked against the code rather than
  written from memory: `register_dependency` appends after the last dependency
  block and touches nothing else; `validate_config` refuses `include` on a local
  path; `dep_ref` parses a ref but only `@HEAD` is acted on, anything else is
  reported and nothing is moved; `lay_self` publishes a package into its own tree
  by copy; `pkg_namespace` uses the root table's `name`, falling back to the
  repository half of `<owner>/<repo>`.
- `description` is read by nothing. `root_field` is generic, but no caller asks
  for it. Documented as a sentence for whoever opens the file, explicitly not as
  something the tool acts on, at the operator's direction — it may be used later.
- Only `name` and `type` are read from the root table, one caller each.

## Proposal

Write the user-facing document for `.ai.toml`, keep `type = "package"` out of the
main flow and in its own section, and reach it from the README.

## Testing

Prose, so the check is that it does not lie: every behavioural claim traced to
the code that implements it (listed under Findings), and both relative links
resolve. The eight suites were run to confirm nothing was disturbed — 396
assertions, all green. No new test was written; there is no behaviour here to
assert.

## Changelog entry

#### 📝 `f/ai-toml-doc` → `archive/ai-toml-doc`

`.ai.toml` had no user-facing documentation — the only thing close was a
correction scratchpad describing a syntax the tool no longer uses. `docs/ai-toml.md`
now covers what the file is, that it belongs to whoever owns the repository and
that `kai install` only ever appends to it, how to name a project, the three
shapes a `source` takes, taking part of a package with `include`, why only `@HEAD`
is acted on today, and where the clones actually live. Turning a repository into
a package other repositories can install is kept in its own section, since most
readers never need it. Reached from the README.

_Board: `ai-toml-doc`._

## Readme delta

Applied on the branch: a "Configuring a repository" section near the top, saying
what the file does and that dependencies can be managed by hand, linking to
`docs/ai-toml.md`; the same link added to the `.ai.toml` and `docs/` bullets in
the layout list.
