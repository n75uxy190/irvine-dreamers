# 004 — Lune testing setup

**Date:** 2026-09-22

## Context

The PC Repair container logic (rolling, state transitions, sabotage reset,
income-freeze) is pure data/logic with no Roblox API dependency, and the
user wants it exhaustively tested. Decision: use **Lune** (a standalone
Luau runtime) to run these tests headless, outside Studio.

## Decisions made

- **No external test framework** (no TestEZ, etc.) — a custom ~50-line
  harness, [`tests/TestRunner.luau`](../tests/TestRunner.luau), instead.
  Reason: one of the devs on the team isn't used to external Roblox
  tooling; a framework nobody can read end-to-end defeats the point.
  `TestRunner.luau` is short enough to read in one sitting, and that's
  intentional — see [`tests/README.md`](../tests/README.md) for the
  full explanation aimed at that audience.
- **Pinned via Rokit**, the same mechanism already used for `rojo` — added
  `lune = "lune-org/lune@0.10.5"` to `rokit.toml` via `rokit add lune`
  rather than hand-picking a version.
- Test files live in `tests/`, named `<Thing>.spec.luau`, one per module
  under test. `tests/example.spec.luau` is a throwaway demonstration file —
  safe to delete once real `PCRepair` spec files exist.
- No auto-discovery/run-all script yet — deliberately deferred until there
  are enough spec files for running them one-by-one to actually be annoying.

## Two real bugs hit while building this (both fixed, both worth knowing about)

1. **Luau string interpolation is `` `{expr}` ``, not `` `${expr}` `` (JS
   style).** First draft of `TestRunner.luau` used the JS syntax out of
   habit, which doesn't error — it just prints a literal `$` before every
   interpolated value. Caught by actually running the example spec instead
   of trusting it on sight.
2. **`process` is not an ambient global in this Lune version (0.10.5)** —
   it must be explicitly imported: `local process = require("@lune/process")`.
   Older Lune versions (and some docs/examples floating around) inject
   these as globals; this one doesn't.

A third apparent bug — `process.exit(1)` seemingly not setting the shell's
exit code — turned out to be a red herring caused by an unrelated WSL/shell
quirk, not Lune. See [KNOWN_ISSUES.md](KNOWN_ISSUES.md) ("Checking `$?`
inside a semicolon-chained `wsl.exe -- bash -lc '...'` string is
unreliable"). `process.exit(1)` works correctly; it just couldn't be
observed correctly with the first verification method tried.

## How to use it

See [`tests/README.md`](../tests/README.md) — written for someone who has
never touched Lune before. Short version: `lune run tests/example.spec.luau`.
