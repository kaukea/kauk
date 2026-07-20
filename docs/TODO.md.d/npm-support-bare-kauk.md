- created: 2026-07-17
- created_by: opus-4.8
- created_during: f/reserve-namespaces

## Blockers

Needs the operator — only the npm account holder can file a support request. Agent cannot.

## Questions

- Is the bare npm `kauk` worth pursuing at all, given `@kauk.ai/kauk@0.0.0` already reserves
  the identity and works? *Recommendation:* file it once, cheaply, and drop it if refused —
  the scoped name is not blocking anything, so this is upside-only and should stay `low`.

## Findings

Decision-010 records that npm rejects the unscoped `kauk` on its typosquat similarity
heuristic, naming `ka23,caduk,vaul,walk` as the collisions and suggesting `@kauk.ai/kauk`
itself. That block is a **false positive**: `kauk` is a real project (domain `kauk.ai`, gh org
`kaukai`, PyPI's bare `kauk` already published at 0.0.0), not a typosquat of any of those four.

Nobody owns the name — `npm view kauk` → E404. The dormant `kauk` npm *username* (0 packages)
is not the cause. The heuristic is the only thing standing in the way, and no flag, retry, or
version change gets past it; a human at npm support is the only route.

Decision-010 flagged this follow-up but no task carried it — this is that task.

## Proposal

File one support request with npm (<https://www.npmjs.com/support>) asking for the unscoped
`kauk` to be granted past the similarity filter. Make the legitimacy case: the `kauk.ai`
domain, the `kaukai` GitHub org, the already-published bare `kauk` on PyPI, and the scoped
`@kauk.ai/kauk@0.0.0` placeholder as evidence of genuine intent. Quote the E403 verbatim.

If granted, publish the bare `kauk@0.0.0` as an **alias alongside** the scoped package — per
Decision-010 this is explicitly not a reason to unpick the scoped identity, which stays the
canonical npm name unless the operator decides otherwise.

If refused, close this `cancelled` and record the refusal in the sidecar so no future session
re-opens it.

## Testing

If granted: `npm view kauk version` → `0.0.0` (exit 0). If refused: the support response
recorded here, task closed `cancelled` — no code change to test.
