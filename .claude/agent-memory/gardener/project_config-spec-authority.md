---
name: config-spec-authority
description: docs/configuration-files.md is the operator's hand-written config spec — it outranks contradicting decisions and docs
metadata:
  type: project
---

On 2026-08-21 the operator hand-wrote the configuration spec into
`docs/configuration-files.md` (it took him a long time; treat it as
load-bearing). It OUTRANKS any decision entry, package-format doc, or
implementation that contradicts it: one `.ai.toml` (root-table identity,
`[[dependency]]` tables, `@ref` on git sources, kai-append on install),
package.toml deleted, one package per repository, the-works reduced to
agent-only data (single committed migration date, asks killed, MOOD out),
laid files user-editable with push-or-stay semantics.

**Why:** two days of agents mis-recording his design; he wrote it himself to
end the drift.

**How to apply:** before touching any config-file behaviour, re-read that
file. Never re-derive from decisions.md where they conflict — flag the
conflict instead. Four clarifications were pending at write time (.ai/ vendor
dir approval, watermark location, name/type-only confirmation, select's
fate) — check the file or ask before assuming them settled.
