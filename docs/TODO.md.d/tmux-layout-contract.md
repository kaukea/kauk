- created: 2026-08-18
- created_by: fable-5 (operator recurring correction)

## Blockers

(none)

## Questions

_None — the contract is the operator's, repeated: one new WINDOW per feature;
auxiliary agent panes (bloomer, beekeeper, sidebar) in the RIGHT COLUMN,
vertically stacked._

## Findings

- Same defect class in `.claude/tools/pane-promote.sh` (recorded at the
  migrations-at-sync close): it resolves the CLIENT's active pane instead of
  the caller's — $TMUX_PANE ignored — so self-promotion can grab the wrong
  pane. Fix alongside the dispatcher (which got the $TMUX_PANE anchoring
  2026-08-18, orchard 09c76cf).
- Live mis-render evidence (2026-08-18): `dispatch-agent.sh` uses plain
  `tmux split-window -d` — a full-width split below the current pane — so every
  dispatched pane lands bottom-full-width instead of the right-column stack.
  The operator has corrected this repeatedly.

## Proposal

The dispatch tooling honours the layout contract itself: dispatched auxiliary
panes join the current window's right column, stacked vertically (creating the
column if absent); feature windows are unaffected (landscaper self-promotion
already gives the window). Scripted placement — no per-dispatch hand-moving.

## Testing

To be agreed at bloom: dispatch two panes into a window with a sidebar; both
land stacked in the right column; a feature spawn still gets its own window.
