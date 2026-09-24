# 005 — PC container build

**Date:** 2026-09-22
**Status:** built and Lune-tested (config, `PCUnit`, `PCFactory`,
`TransitionTable`, `WeightedPick`, `GenerateId`). `PCUnitDebugView` built but
**not yet verified in Studio** — see open items below.

## What got built

See the class diagram from this session (not reproduced here — ask for it
again if needed) for the shape. Files:

- `src/ReplicatedStorage/Configuration/Modules/PCRepair/{PartDefs,ZoneDefs,FaultDefs,IncomeMultipliers}.luau`
- `src/ServerStorage/Modules/PCRepair/{PCUnit,PCFactory,TransitionTable,WeightedPick,GenerateId,PCUnitDebugView}.luau`
- `tests/PCRepair/{PCUnit,PCFactory,TransitionTable,WeightedPick}.spec.luau` — 30 tests total, all passing under `lune run`.

## Decisions made this pass (not spelled out in the handoff)

- **`IncomeMultipliers.luau`** is new. `Rarities.luau` (the tier names we're
  reusing) has no income concept at all — just `Chance`/`Colour`/etc. — so
  income-per-tier needed exactly one new table. This is the single number
  the handoff's `TierDefs.incomeMult` concept was pointing at; it's not a
  parallel tier scale, since the keys are the same tier names.
- **`completeRepair`** (on `PCUnit`) atomically validates all issues fixed,
  transitions `InRepair → Repaired`, and freezes `incomeRate` in one call —
  encodes "computed once, ever" as something the API refuses to violate,
  rather than caller discipline.
- **Issues never stack on the same part.** `PCFactory` picks distinct
  `(zoneId, slotIdx)` targets for its 3-4 issues (Fisher-Yates shuffle over
  filled slots, take N). Not specified either way in the handoff; this was
  the simpler, cleaner reading of "3-4 randomly rolled issues."
- **Cross-tree requires use relative paths** (`../../../ReplicatedStorage/...`),
  matching `src/`'s real folder nesting, so the exact same files run under
  both Lune and (assuming the item below holds) live Roblox without
  rewriting. This is why `tests/PCRepair/*.spec.luau` require the real
  `src/` files directly rather than duplicating logic.

## Open items — do not assume these are resolved

1. **Roblox require-by-string is unverified.** Every new module uses
   `require("./Sibling")` / relative-path requires (Lune convention) instead
   of `require(script.Parent.Sibling)` (this codebase's existing Instance-
   based convention everywhere else). This is *assumed* to also resolve
   correctly in live Roblox because Rojo mirrors the filesystem 1:1 onto the
   DataModel — but that assumption has only been checked under Lune, never
   in actual Studio. **First thing to check when this gets opened in
   Studio:** sync via Rojo, check Output for require errors on any
   `PCRepair` module. If it doesn't resolve, every `require("./...")` /
   `require("../../../...")` in the new files needs converting to
   `require(script.Parent.Sibling)` style instead.
2. **`TransitionTable` has no `Claimed → OnConveyor` edge.** If a player
   claims a PC off the conveyor but disconnects (or otherwise never enters
   the repair viewport), there's currently no legal transition back to
   `OnConveyor` for that unit — it's stuck `Claimed` forever. The handoff's
   state diagram doesn't show this edge, so it wasn't added, but this is a
   real gap once `ConveyorService`/`RepairService` get built. Needs a
   decision, not a silent fix.
3. **`PCUnitDebugView` is not wired to anything.** No chat command, no
   automatic trigger — deliberately not integrated into the existing
   whitelisted admin-command system (`Commands.server.luau`) without being
   asked to touch it. Usable right now only via the Studio command bar (see
   the comment at the top of the file for the exact one-liner). Needs an
   actual playtest to confirm the boxes/colors look right — nothing about
   this file could be verified by Lune.
