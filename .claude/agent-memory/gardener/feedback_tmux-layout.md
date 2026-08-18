---
name: tmux-layout-contract
description: tmux layout — one new window per feature; auxiliary agent panes stack vertically in the right column
metadata:
  type: feedback
---

The fleet's tmux layout contract: every FEATURE gets its own new WINDOW (the
landscaper's); auxiliary/supervisory panes (bloomers, beekeepers, sidebar)
live in the RIGHT COLUMN of a window, vertically stacked — never full-width
splits below the main pane.

**Why:** Operator, 2026-08-18 — "I keep on explaining this... it is being
mis-rendered continuously." The dispatch default (`split-window` full-width
below) violates it every time.

**How to apply:** When dispatching panes into my own window, place them into
the right column stack (join under the sidebar pane). The durable fix lives
in the dispatch tooling — boarded as tmux-layout-contract on the kauk board.
