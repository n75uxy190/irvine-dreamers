# 002 — PC Repair handoff verification

**Date:** 2026-09-22

## Context

Two handoff docs were dropped in `Downloads/` (outside this repo, not
committed): `PC_REPAIR_HANDOFF.md` (the feature design — a repair minigame
sitting between "acquire a PC" and "place it on your plot," with a sabotage
mechanic) and `CLAUDE.md` for a *different, unrelated* project
(`character-creator`) that happened to be in the same folder — not relevant
to this repo, noted here only so a future reader isn't confused by it
showing up alongside.

The handoff doc explicitly warns: read the template before writing new
modules, reuse what exists, don't stand up parallel systems. It also
provides a reuse table of assumed existing systems. Rather than trust that
table, each claim was checked against the actual code before treating it as
true.

## Verified findings

| Handoff assumption | Verified? | Actual location / name |
|---|---|---|
| Rarity/tier table for parts | ✅ matches | [`src/ReplicatedStorage/Configuration/Modules/Things.luau`](../src/ReplicatedStorage/Configuration/Modules/Things.luau) — `Rarity` field per item (`Common`/`Rare`/`Epic`/...). Reuse directly for part tiers, no new tier scale. |
| Plot ownership + bounds check | ✅ matches, different name | Called **`Base`**, not `Plot`. `Player.Configuration.Base.Value` points at a base instance with `Slots`, `Floors`, `Doors`, `AllowedFriends` — see [`src/ServerScriptService/Things.server.luau`](../src/ServerScriptService/Things.server.luau) (line ~111 onward). This is what "enter the victim's plot" should check against. |
| Passive income per placed item | ✅ matches | [`src/ReplicatedStorage/Modules/UpdateMoneyPerSecond.luau`](../src/ReplicatedStorage/Modules/UpdateMoneyPerSecond.luau) |
| Exactly one `ProcessReceipt`, dispatch-table shaped | ✅ matches | [`src/ServerScriptService/ProcessReceipt.server.luau`](../src/ServerScriptService/ProcessReceipt.server.luau) — flat numbered (`1️⃣2️⃣3️⃣`) dispatch keyed by `ReceiptInfo.ProductId`. Adding sabotage is a clean new section. **Caveat:** confirmed it does **not** write consumed `receiptId`s anywhere — no idempotency guard exists today (see [KNOWN_ISSUES.md](KNOWN_ISSUES.md)). |
| Conveyor / spawn queue | ⚠️ real, but not under that name — initial grep for "Conveyor"/"Spawn"/"Belt" as standalone systems found nothing and was reported (incorrectly) as absent | It's `workspace.Waypoints` (an ordered list of points — the yellow path players see) plus a `TweenService`-driven walk loop in `Module.Spawn`, inside [`src/ServerStorage/Modules/Things.luau`](../src/ServerStorage/Modules/Things.luau) (roughly lines 1083–1330). Each spawned "Thing" tweens waypoint-to-waypoint while carrying a live `ProximityPrompt`; `ProximityPrompt.Triggered` is the "claim" step, calling `Module.Add(Player, Base, UnoccupiedSlot, ...)` to place it into the player's `Base` `Slots`. `SpawnedThings[Thing]` tracks claim state to stop the walk once claimed. Confirmed only after the user pointed at a screenshot of the actual belt in-game — the lesson here is that a grep for the *expected* name isn't sufficient evidence of absence in this codebase; corroborate with the user/screenshots when a "doesn't exist" finding seems surprising. |

## Implication for the feature build

The reuse table in the handoff is trustworthy in spirit but not in exact
naming — map concepts, don't grep for the handoff's own vocabulary. See
[003](003-pc-repair-module-layout-plan.md) for how each of these maps onto
new modules.
