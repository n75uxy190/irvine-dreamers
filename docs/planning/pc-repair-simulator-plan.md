# PC Repair Simulator — plan

`irvine-dreamers` (converted from the "Steal a Base" place — see [rojo-conversion.md](rojo-conversion.md)) is being reskinned into a **PC Repair Simulator**, reusing the existing steal-a-base codebase and systems rather than starting fresh. Will be published under the existing "Bouncing Obbies" Roblox group.

> This plan came from an ongoing Discord conversation and is a snapshot, not a final spec. Update it as decisions change.

## Core loop (planned)
- Characters (e.g. "Tung Sahur" — a brainrot-meme-style character, analogous to the existing "Things" being stolen in steal-a-base) sit on a conveyor holding PCs.
- Player steals a PC off the conveyor and brings it back to their base.
- At the base, the player repairs the PC through a minigame sequence.

## Scope
1. **The PC repair event/minigame system itself** (the bulk of new work)
2. **PC model overhaul** (new/reworked PC models)
3. **Map overhaul** — lower priority, "just a bit different," unique theme TBD

## Repair minigame design
- Each stolen PC gets RNG-rolled **issues/problems** scaled by rarity — common PCs have fewer issues than rarer ones.
- Issues are drawn from a finite pool of high-level repair tasks (replace motherboard, fix heat sink, replace thermal paste, etc.) — the team wants to fully enumerate this pool.
- A player rolls ~3-4 issues from that pool per PC; each issue maps to its own minigame step.
- Issues are framed as **"mix-ins"** — transient attributes/components inherited/de-inherited per PC instance (maps naturally onto Roblox `Attribute`s or a component pattern).
- Sabotage mechanic (proposed): another player can RNG-select from the same issue pool to add problems to someone else's PC.

### Minigame feel
- **Leading direction: ASMR-max / satisfying input feedback** — each step has its own sound and simple mechanic, e.g. for "replace motherboard": unscrew (sound), pop panel open (sound), swap part (simple mechanic + sound).
- Alternative floated but not chosen: Surgeon Simulator-style silly physics.
- Explicit goal: "nothing crazy complicated but nothing boring."

## PC modeling approach
- **Not** modeling real PC parts 1:1. Generic outer case ("box") containing modular **sections**, illustrated by a reference image with colour-coded regions (e.g. red = cooling system). Each section rolls independently from its own pool of parts.
- A "PC" = a composition of independent rolls, one per section.
- **Multiple distinct case shapes** planned for visual variety, each needing its own schema/mapping of where each modular section attaches.
- Next step: define the standardized schema (how many section categories, what each represents), then curate reference parts via PCPartPicker per category.

### Part-pool architecture
- A single generic **"pool of parts + RNG + rarity"** template, with each section type inheriting/extending it: e.g. `CoolingSystem extends genericPool`, `CPUSystem extends genericPool`, `OuterBox extends genericPool`.

### Part rarity — resolved
- Parts are RNG'd per-PC too, weighted by the PC's own overall rarity (common PC → parts skew common, scaling up for rarer PCs).
- **Weighting formula: a hand-authored lookup table per PC rarity tier**, listing the % distribution over part tiers (e.g. `Common PC: { Common: 70%, Uncommon: 25%, Rare: 5% }`) — chosen over a computed/geometric-decay formula for designer control.
- **One shared table reused across all sections** — not a separate table per section.
- Still needs: rarity tier names/count finalized before the table can actually be authored.

### PC rarity — resolved
- Reuses the existing steal-a-base rarity mechanism as-is (see [rarity-system.md](rarity-system.md)) rather than being redesigned — same `Rarities` table, same weighted roll, same "reroll N times via luck, keep the rarest" model, fed by the existing `ServerLuck` purchase path. This is a "for now" decision — revisit if the team wants to change the roll mechanism later.

## Open items
- The section schema itself: how many categories, what each one represents.
- The actual weighting numbers in the pcTier → partTier table.
- Part sourcing via PCPartPicker once the schema exists.
- Whether the game repo/monetization setup is actually ready to publish under "Bouncing Obbies" — see [monetization-ownership-check.md](monetization-ownership-check.md), this is currently unresolved and blocks anything money-related.
