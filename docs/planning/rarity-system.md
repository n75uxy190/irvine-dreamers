# Existing rarity system

How the current steal-a-base rarity/luck roll works — this mechanism is being reused as-is for PC rarity in the PC Repair Simulator overhaul (see [pc-repair-simulator-plan.md](pc-repair-simulator-plan.md)).

- **Tiers** — [`src/ReplicatedStorage/Configuration/Modules/Rarities.luau`](../../src/ReplicatedStorage/Configuration/Modules/Rarities.luau): Common 40.75%, Rare 30%, Epic 15%, Legendary 9%, Mythic 5%, Developer God 0.2%, Secret 0.05%. Each entry has `Chance`, `Colour`, `ChatAnnouncement`, `VisualsPreset`.
- **Roll algorithm** — `Module.Random` in [`src/ServerStorage/Modules/Things.luau`](../../src/ServerStorage/Modules/Things.luau) (~line 61): weighted cumulative-sum roll over whichever rarities currently have at least one item defined.
  - **Luck works by rerolling, not reweighting** — it rolls the full weighted pick `Module.Luck` times and keeps whichever result landed the rarest (lowest `Chance`).
  - `Module.Luck` is temporarily boosted by dev-product purchases defined in [`src/ReplicatedStorage/Configuration/Modules/ServerLuck.luau`](../../src/ReplicatedStorage/Configuration/Modules/ServerLuck.luau) (2x/4x/6x/8x/10x luck for 900s/15min, scaling price).
- Once a tier is chosen, the specific item within it is picked **uniformly at random** — items don't have individual weights within their tier.
- **Pity timer** — [`src/ServerStorage/Configuration/Modules/GuaranteedRarities.luau`](../../src/ServerStorage/Configuration/Modules/GuaranteedRarities.luau) guarantees a spawn of a given tier within a max wait for some tiers only: Common every 10s, Legendary every 300s, Mythic every 900s, Developer God every 3600s. Rare/Epic/Secret have no guarantee.

**Decision:** keep this mechanism as-is for determining a stolen PC's rarity, rather than building something new — same `Rarities` table/roll function, same luck-via-reroll model, same `ServerLuck` purchase path. This is a "for now" call, not necessarily final.
