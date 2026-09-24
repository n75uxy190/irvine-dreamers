# Tests

Pure-logic code (config rolling, state machines, math — anything that isn't
actually touching a live `Instance` in the DataModel) gets a test here. This
runs outside Roblox/Studio entirely, in seconds, via **Lune**.

## What Lune is

Lune is a standalone Luau runtime — it runs `.luau` files directly, the same
language Roblox scripts are written in, just without Roblox itself attached.
No DataModel, no `game:GetService(...)`, no Studio. That's exactly what we
want for testing plain data/logic modules: fast, no Studio round-trip.

It's already set up as a project tool, the same way Rojo is — see
`rokit.toml` at the repo root. If a fresh checkout doesn't have it yet, run:

```bash
rokit install
```

## Running a test

```bash
lune run tests/example.spec.luau
```

That's it — no build step, no config. Run it now, it'll show one deliberate
failure (see below) to demonstrate what failing output looks like.

## Basic structure

Two things to know about Lune scripts specifically, since they differ from
normal Roblox Luau:

1. **`require` uses relative paths**, not Roblox instances:
   `require("./TestRunner")` — the `./` is required, and the `.luau`
   extension is implied.
2. **Standard libraries are explicit imports**, not ambient globals:
   `local process = require("@lune/process")`. There's no automatic
   `process`/`fs`/`task` sitting around — you `require` the ones you use.
   (`tests/TestRunner.luau` does this once, for `process.exit`, if you're
   looking for an example.)

Everything else — `local`, `function`, `if`, string interpolation with
`` `{name}` `` — is exactly the Luau you already know from the rest of this
codebase.

## Writing a test

There's no external test framework here on purpose — `tests/TestRunner.luau`
is a ~50-line file you can read start to finish, and it's the whole thing.
It gives you three functions:

- `TestRunner.test(name, fn)` — runs `fn`, catches any error, records
  pass/fail, and prints one line per test.
- `TestRunner.expectEqual(actual, expected, message?)` — errors (failing the
  enclosing `test`) if the two don't match.
- `TestRunner.expectTrue(value, message?)` — errors if `value` isn't `true`.
- `TestRunner.finish()` — call this once, at the end of the file. Prints the
  pass/fail total and exits with a non-zero code if anything failed (so this
  is already CI-ready, if that ever gets wired up).

A full example, [`tests/example.spec.luau`](example.spec.luau):

```lua
local TestRunner = require("./TestRunner")

local function add(a: number, b: number): number
	return a + b
end

TestRunner.test("add(2, 3) equals 5", function()
	TestRunner.expectEqual(add(2, 3), 5)
end)

TestRunner.test("this one is written to fail, on purpose, to show what that looks like", function()
	TestRunner.expectEqual(add(1, 1), 3)
end)

TestRunner.finish()
```

Naming convention: `<ThingBeingTested>.spec.luau`, one file per module under
test, living in this folder (subfolders are fine once there are enough of
them to warrant it — not yet).

## Running more than one file

Right now, run each `*.spec.luau` file individually — there's no
auto-discovery script yet. Once there are enough spec files that this gets
annoying, add a small runner that globs `tests/*.spec.luau` and shells out to
`lune run` for each (worth doing later, not worth the complexity for one
file).
