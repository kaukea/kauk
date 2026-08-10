- created: 2026-08-11
- created_by: opus-5
- created_during: f/convention-reader

## Blockers

Operator is still thinking it through — deliberately parked at the back of the
implementation order to bake longer. Nothing depends on it.

## Questions

- How does it interact with a LOCAL plugin? A locally-built plugin has no
  marketplace to arrive from, so the bootstrap path and the local path may not be
  the same act.
- Does kauk arrive as a plugin from a marketplace, or as the thing that creates
  the marketplace in the first place?

## Findings

- The idea: kauk installs itself at the same time as the first package, rather
  than being a separate prerequisite the user has to arrange first.
- It is what makes the natural-language install path complete end to end
  (Decision-039): asking for a package cannot require already having the tool
  that installs packages.

## Proposal

Park. Revisit once the marketplace publishing path (claude-marketplace) exists,
since that is what determines whether kauk can arrive by the same mechanism as
everything else.

## Testing

To agree when it is taken off the shelf.
