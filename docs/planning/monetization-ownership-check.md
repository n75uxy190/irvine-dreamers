# Monetization ownership check

**Status: unresolved. Do not touch `AssetIds.luau`, `Commands.luau`, or `ServerLuck.luau` until this is settled.**

A code review (2026-09-21) for malicious code found nothing — no webhooks, `loadstring`, `getfenv`/`setfenv`, external HTTP exfiltration, or hidden remote-code-execution vectors anywhere in `src`. The only outbound HTTP call in the whole codebase is `LikeService.luau` reading a public vote-count API (`games.roproxy.com`), which is a normal community proxy and doesn't send anything out.

The real risk isn't injected code — it's where the money goes.

## The finding

Every GamePass ID in [`src/ReplicatedStorage/Configuration/Modules/AssetIds.luau`](../../src/ReplicatedStorage/Configuration/Modules/AssetIds.luau) (HD Admin, 2x Money, VIP, Astral Slap, Ban Hammer, Flying Carpet) is a separate Roblox object whose Robux payout target is fixed by whoever created it — not by anything in this code. Checked via Roblox's public API:

```
HD Admin, 2x Money, VIP, Astral Slap, Ban Hammer, Flying Carpet
→ ALL owned by group "FireFlare Creations" (group id 16290076)
→ group owner: Roblox user "Borniqo" (userId 2752190121)
```

That same UserId, `2752190121`, is the **sole entry** in [`src/ServerStorage/Configuration/Modules/Commands.luau`](../../src/ServerStorage/Configuration/Modules/Commands.luau)'s `Whitelist` — the one person with full admin-panel and chat-command power in this game (ban/kick, edit any player's Money/leaderstats, spawn items, server luck, everything) is also the one whose group collects every GamePass purchase.

The ~20 Developer Product IDs (currency packs, donations, luck boosts) couldn't be verified the same way — they're not public catalog items — but there's no reason to think they're routed differently.

## Why it matters

The plan is to publish under the existing "Bouncing Obbies" group. **Publishing the place under a different group does not change where GamePass/Developer Product money goes** — those are independent Roblox objects with fixed payout targets baked into the hardcoded IDs. If "Borniqo"/FireFlare Creations isn't part of this team, every Robux spent on VIP/2x Money/the admin pass/combat tools goes to that outside account, not to Bouncing Obbies.

## What needs to happen

1. **Confirm identity first:** is "Borniqo" (FireFlare Creations, group 16290076) one of the people working on this project, or someone outside it? Doesn't obviously match either Discord handle seen in planning so far ("C++の苦悩する弟子" or "zhuieen [FF]"), though "FF" could plausibly stand for FireFlare — unconfirmed.
2. **If it's not the team:** create new GamePasses/Developer Products under whichever group should actually get paid, and swap every ID in `AssetIds.luau` and `ServerLuck.luau`.
3. **If it is the team:** this is all fine as-is, no action needed beyond noting it here.

## Also found, not acted on

[`src/ServerScriptService/PlayerAllDataReset.server.luau`](../../src/ServerScriptService/PlayerAllDataReset.server.luau) hardcodes `userId = 123` and wipes that player's DataStore entries (Steals/Rebirths/Money/Things) on join — leftover dev/test debug code, not a money-routing risk itself, but has no business in production. Left in place per "don't change anything yet" until the above is resolved.
