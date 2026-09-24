# 003 — PC Repair module layout plan

**Date:** 2026-09-22
**Status:** proposed, not yet built. Two decisions below are open.

## Context

Given the verified mappings in [002](002-pc-repair-handoff-verification.md),
this is the proposed Rojo file/folder layout for the feature — chosen to
match conventions already present in the repo rather than introducing new
ones.

## Proposed layout

**Config** — `ReplicatedStorage.Configuration.Modules.PCRepair/` (new
subfolder, sibling to the existing flat `Rarities.luau`, `Mutations.luau`,
etc.)
- `PartDefs.luau`, `ZoneDefs.luau`, `FaultDefs.luau`, `AssetMap.luau`
- No new `TierDefs` — reuse `Rarities.luau` directly.

**Runtime model** — `ServerStorage.Modules.PCRepair/` (sibling to the
existing `Things.luau`, which already owns the waypoint-walk state)
- `PCUnit.luau`, `RepairSession.luau`, `PCFactory.luau`

**Services** — `ServerScriptService.Services/` (existing
`ServicesManager.server.luau` + `LikeService.luau` pattern: plain table
module, a `:Start()` method, registered in the manager)
- `ConveyorService.luau` — thin wrapper: reuses `Things.luau`'s
  `Module.Spawn`/`Waypoints` walk for a PC-type "Thing," branches the
  existing `ProximityPrompt.Triggered` claim into starting a repair session
  instead of an immediate `Module.Add` into a `Base` slot.
- `RepairService.luau`, `SabotageService.luau`
- `PlotService.luau` — wraps `Player.Configuration.Base` lookups (real name
  is `Base`, see 002)
- **No separate `ReceiptService`** — `ProcessReceipt.server.luau` is a flat
  numbered dispatch already; sabotage becomes a new numbered section there,
  matching its existing style instead of adding an abstraction for one
  dispatch entry. Must include its own consumed-`receiptId` store (see
  KNOWN_ISSUES.md — the template doesn't provide one).

**Remotes** — new entries under existing `ReplicatedStorage.Remotes.Events`:
`ClaimPC`, `RepairProgress`, `SabotageAlert`.

**Client** — new loose folder
`src/StarterPlayer/StarterPlayerScripts/PCRepairClient/` (see open decision
#1 below):
- `init.client.luau`, `RepairViewport.luau`,
  `Minigames/{PinStraighten,PasteApply,...}.luau`,
  `Primitives/{Click,Drag,HoldDuration,DragPath}.luau`, `RepairAudio.luau`

## Open decisions (not yet answered by the user)

1. **Convert only the new `PCRepairClient` slice from binary `.rbxm` to
   loose Rojo-synced files, leaving the rest of `StarterPlayerScripts`
   untouched?** (Recommended — see KNOWN_ISSUES.md for why the binary-blob
   status of `StarterPlayer`/`StarterGui` matters here.)
2. **Repair HUD / proximity-alert GUI: loose `StarterGui` files for just
   this feature, or built in Studio and exported as another `.rbxm` like
   the existing GUIs?**

Do not start scaffolding Layer 4 (viewport/minigames/GUI) until these are
answered — Layers 1–3 and the services layer don't depend on the answer and
can proceed either way.
