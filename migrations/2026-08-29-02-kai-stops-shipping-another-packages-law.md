# The skill about launching agents through a particular script is withdrawn

kai shipped a skill stating that every agent must be launched through
`.claude/tools/dispatch-agent.sh`, and that work launched any other way is invalid. That
script belongs to another package. A repository that installs kai without it receives
the instruction and not the file.

Any agent can be launched in the kai environment by calling the CLI with the right
parameters, which is what the `agent` skill does. There is no privileged launcher.

The laid link is removed here rather than left to the dead-link report, which only names
a tracked dangling link and leaves removing it to the operator — so without this it
would sit in every consumer, resolving to nothing, saying something untrue.

## Detect → convert

```sh
set -eu
root=$(git rev-parse --show-toplevel)
cd "$root"

removed=0
for l in .claude/skills/orchard .claude/skills/kauk:orchard .claude/skills/local:orchard; do
  [ -L "$l" ] || continue
  case "$(readlink "$l")" in
    *".ai/repositories/"*"/kauk/skills/orchard"|*"/skills/orchard") ;;
    *) continue ;;
  esac
  git rm -q --ignore-unmatch -- "$l" 2>/dev/null || rm -f "$l"
  echo "withdrew $l"
  removed=$((removed + 1))
done

[ "$removed" = 0 ] && echo "the withdrawn skill was never laid here — nothing to do"
exit 0
```

## Verify

- Before: `.claude/skills/orchard` is a link into the kai package's `skills/orchard`,
  which no longer exists there, so it resolves to nothing.
- After one run: it is gone, and gone from the index if it was tracked.
- A repository that never had it is reported and left alone.
- A skill named `orchard` that came from somewhere else — laid from a different package,
  or written by hand — is not touched: only a link whose target is that package's
  `skills/orchard` is withdrawn.
- A second run finds nothing.
