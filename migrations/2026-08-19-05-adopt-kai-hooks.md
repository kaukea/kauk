# The adoption path onto kai-hooks.sh

kai now ships its own static settings pair beside its executable — `bin/kai.settings.json`
and `bin/kai-hooks.sh` — and every fleet dispatch (`tools/dispatch-agent.sh`) passes
`--settings <kai.settings.json>` to every agent it spawns. That wires hooks for spawned
agents automatically, resolved fresh at every launch from wherever `kai` sits on `PATH`.
It does nothing for a plain, non-spawned session started directly in a consumer
repository — the operator's own top-level `claude` — because `--settings` is a
per-invocation flag nothing adds there. Before this change that gap was invisible: the
package-laid `.claude/settings.json` symlink (retired by the previous migration in this
same run) carried the wiring for exactly that case. Nothing in `kai init` or `kai sync`
moves an existing consumer onto the new path, so without this migration a consumer that
had the old symlink loses hook wiring for its own interactive sessions the moment that
link is retired, and a consumer that never had it stays without it forever.

The fix adopted here is narrow, on purpose: lay a **real, consumer-owned**
`.claude/settings.json`, copied verbatim from kai's own `kai.settings.json` — found the
same way `tools/dispatch-agent.sh` finds it, by resolving the `kai` binary off `PATH`
and looking beside it — but only into a repository that has no `.claude/settings.json`
at all. A symlink still sitting there is left to the settings-symlink migration to
retire first; a real file already there — user content or a previous run of this same
migration — is left untouched and reported, matching `docs/package-format.md`'s
universal delivery rule: conflicts report and skip, nothing is overwritten. Composing
kai's wiring into a settings file the operator already customised is the deferred
`settings-lay-clobbers` problem, not this one; this migration only ever fills an empty
slot.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
cd "$root"
target=".claude/settings.json"

if [ -L "$target" ]; then
  echo "$target is still a package-laid symlink — resolved by the settings-symlink migration first, nothing to do here yet"
  exit 0
fi

if [ -e "$target" ]; then
  echo "$target already exists as a real file — left untouched, adopt kai-hooks.sh by hand if wanted"
  exit 0
fi

kai_bin=$(command -v kai 2>/dev/null || true)
if [ -z "$kai_bin" ]; then
  echo "kai not found on PATH — nothing to adopt yet; re-run after installing kai"
  exit 0
fi
kai_bin=$(readlink -f "$kai_bin" 2>/dev/null || printf '%s' "$kai_bin")
source_settings="$(dirname "$kai_bin")/kai.settings.json"
source_hooks="$(dirname "$kai_bin")/kai-hooks.sh"

if [ ! -f "$source_settings" ] || [ ! -x "$source_hooks" ]; then
  echo "kai on PATH has no kai.settings.json/kai-hooks.sh beside it — nothing to adopt yet"
  exit 0
fi

mkdir -p .claude
cp "$source_settings" "$target"
git add -- "$target" 2>/dev/null || true
echo "laid $target from kai's own settings file — this repository's own sessions now dispatch through kai-hooks.sh too"
exit 0
```

## Verify

- Before: a consumer with no `.claude/settings.json` at all (never had one, or had the
  package-laid symlink already retired by the previous migration), `kai` resolvable on
  `PATH`, and `kai.settings.json` / `kai-hooks.sh` present beside the resolved binary —
  the exact same resolution `tools/dispatch-agent.sh` performs (`command -v kai`,
  `readlink -f` with a raw-path fallback, `dirname`).
- After one run: `.claude/settings.json` exists as a real file, byte-identical to kai's
  own `kai.settings.json` at the time of the run, and is staged with `git add`.
- A consumer with a real, pre-existing `.claude/settings.json` — hand-written or from a
  previous run of this migration — is reported and left untouched; running again after
  a first successful adoption reports the file already exists and changes nothing.
- A consumer whose `.claude/settings.json` is still the package-laid symlink is left for
  the prior migration; this one performs no action on a symlink, ever.
- Without `kai` on `PATH`, or without a `kai.settings.json`/`kai-hooks.sh` pair beside
  it, nothing is written and the reason is printed — safe to re-run once kai is
  actually installed.
- Nothing is written under `.git/` or `.ai/repositories/`; only the consumer's own
  `.claude/settings.json` is ever touched, and only when that slot was empty.
