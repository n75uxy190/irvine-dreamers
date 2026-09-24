# 006 — Service layer stubs + debug spawn

**Date:** 2026-09-22
**Status:** written, syntax-checked via `selene`, **not yet run in Studio**
(uses `game`/`workspace`/`task`/`CFrame` — none of this is Lune-testable,
unlike everything in journal/005).

## What got built

- [`ConveyorService.luau`](../src/ServerScriptService/Services/ConveyorService.luau)
  — the only real logic this pass. `Start()` loops every 15s, calls
  `PCFactory.roll()`, renders it via `PCUnitDebugView.render()`, parents
  into `workspace` at a fixed, **unverified** `CFrame.new(0, 15, 0)`.
- [`RepairService.luau`](../src/ServerScriptService/Services/RepairService.luau),
  [`SabotageService.luau`](../src/ServerScriptService/Services/SabotageService.luau)
  — empty stubs, registered but doing nothing. Deliberate: neither is needed
  to make the container visible, so neither got built yet.
- `ServicesManager.server.luau` updated to require + `task.spawn(:Start())`
  all three, alongside the existing `LikeService`.

## Why this shape

This is the service-layer boundary discussed earlier in chat: `PCUnit`/
`PCFactory` are the rule engine's internals; these three services are meant
to be the *only* sanctioned callers of them going forward. `ConveyorService`
is now the front door for "make a visible PC appear" — nothing else should
call `PCFactory.roll()` or `PCUnitDebugView.render()` directly once this
exists. Luau has no real access control to enforce that mechanically (same
as everywhere else in this codebase — no closures/metatable privacy tricks
used here either); it's a documented convention, not a compiler guarantee.

## Verification done vs. not done

- **Done:** `selene` (no `std=roblox` configured for this project yet, so
  only "undefined global" noise on `game`/`task`/`workspace`/`CFrame` — no
  actual parse errors on any of the four files).
- **Not done, and can't be from here:** actually running this in Studio.
  Specifically unverified:
  - `DEBUG_SPAWN_CFRAME = CFrame.new(0, 15, 0)` — arbitrary, may be inside
    terrain, off the map, or overlapping something. First thing to check.
  - Whether `ConveyorService`'s `require(ServerStorage.Modules.PCRepair.PCFactory)`
    (Instance-based, this codebase's normal convention) actually resolves —
    this one *should* be fine since it's the existing convention, not the
    experimental relative-require pattern from journal/005, but still
    unverified until Studio actually loads it.

## Nice-to-have, not built

`selene.toml` with `std = "roblox"` would give this whole codebase real
linting (actual bugs, not just Roblox-global noise) instead of the
undefined-global spam seen when running it ad hoc. Didn't set this up —
it's a repo-wide tooling decision beyond this feature's scope, not
something to slip in unasked.

## Correction: `selene` can't be trusted for syntax-checking typed Luau here

Found while fixing `ConveyorService`'s debug-spawn position (see below):
`selene`, run with no config in this repo, throws `parse_error` on ordinary
Luau type annotations (`player: Player`, `:: BasePart?`) — the exact same
style already proven valid by Lune actually running `PCUnit.luau`. This is
`selene`'s own parser limitation in its default mode, not a real bug. For
any Roblox-only file that can't run under Lune, the more reliable
syntax-check is: run it under `lune run` anyway and confirm it fails at the
*expected* spot (a `game`/`workspace`/etc. being nil), not at a parse error.
If Lune gets past parsing and only dies on a nil Roblox global, the syntax
itself is fine. Don't trust a bare `selene` parse error on a typed file
without cross-checking this way first.

## Fixed: debug spawn position was an arbitrary world coordinate

Original `ConveyorService` spawned at a fixed `CFrame.new(0, 15, 0)` — an
unverified guess with no principled reason behind it, correctly called out
as pointless for a *debug* spawner. Changed to spawn 10 studs in front of
each connected player's character (`HumanoidRootPart.CFrame * CFrame.new(0,
0, -10)`, recomputed fresh each tick since players move), skipping any
player without a spawned character that tick rather than erroring. Verified
past the type-annotation edit via the Lune-parses-then-dies-on-`game`
technique above — still needs an actual Studio run to confirm it looks
right.
