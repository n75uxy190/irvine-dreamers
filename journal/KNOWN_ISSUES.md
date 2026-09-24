# Known Issues / Pitfalls

Flat list, most environment/tooling gotchas first, then template-specific
constraints. Add to this when something costs real time to figure out —
especially anything with a misleading or silent symptom.

## Environment / tooling

### WSL2 MTU black hole (git clone/pull over SSH hangs forever)
**Symptom:** `ssh -T git@github.com` and `git ls-remote` succeed instantly,
but `git clone`/`git pull` of real payload hangs indefinitely — 0% CPU on the
`git`/`ssh` processes, `.git` object count stays static, no error, no
progress output.
**Cause:** WSL2's virtual `eth0` comes up with MTU 1404 instead of 1500 on
this host. Small packets (auth, `ls-remote`) get through fine; once git
tries to push a real burst of packed objects, larger packets get silently
dropped somewhere on the path (PMTU black hole — ICMP "fragmentation needed"
apparently filtered) and the connection just sits there.
**Fix:** `sudo ip link set dev eth0 mtu 1350` (or `ip link set` as root).
On 2026-09-24 a `git push` still hung at 1350 and went through at **1280**, so
if 1350 stalls, drop lower before suspecting anything else.
**This does not persist across WSL restarts** — reapply it every time WSL
cold-boots before doing any git network operation. Consider a startup hook
if this keeps biting.

### WSL2 VM full wedge under memory pressure
**Symptom:** `wsl.exe` invocations pile up (multiple processes, ~0% CPU
each, never completing), including trivial ones like `ip link show` or
`wsl --list`. `wsl --shutdown` itself hangs or returns
`RPC_S_CALL_FAILED`.
**Cause (observed once):** host was down to ~10% free RAM; the Hyper-V VM
worker process (`vmwp.exe`) became unresponsive. Regular user privileges
can't kill a SYSTEM-owned `vmwp.exe` — `Stop-Process -Force` silently no-ops.
**Fix:** run `wsl --shutdown` from an **elevated** (Administrator)
PowerShell/terminal. After it succeeds, the next `wsl` command does a cold
VM boot that's noticeably slower than normal — give it 60–90s before
assuming it's wedged again. Re-check/reapply the MTU fix above after any
restart.

### DrvFs (`/mnt/c/...`) false permission-diff on `git checkout`
**Symptom:** `git checkout <branch>` (or `-B`) refuses with "The following
untracked working tree files would be overwritten by checkout," listing
nearly every file in the tree — even when the content is actually
byte-identical (verify with `git diff --no-index <file> <(git show
<ref>:<file>)`).
**Cause:** files accessed through `/mnt/c/...` from WSL get uniform,
Windows-derived mode bits from DrvFs, which don't match the mode git has
recorded for those blobs. `core.filemode false` alone did **not** resolve
this in practice.
**Fix:** spot-check that content genuinely matches (don't skip this step —
it's the difference between a safe force and clobbering real work), then
`git checkout -f`.

### Checking `$?` inside a semicolon-chained `wsl.exe -- bash -lc '...'` string is unreliable
**Symptom:** `wsl.exe -- bash -lc 'false; echo "RESULT=$?"'` prints
`RESULT=0` — wrong, `false` should set `$?` to `1`. This isn't specific to
`false`; it reproduced the same way checking the exit code of a real
program (`lune run some.spec.luau`) run the same semicolon-chained way,
which briefly looked like `process.exit(1)` wasn't working at all when it
actually was.
**Cause:** not fully root-caused, but reproduces specifically when `$?` is
read inside the *same* single-quoted string passed through an outer
Git-Bash shell to `wsl.exe`, chained after another command with `;`. Almost
certainly some argument re-tokenization happening at the Git-Bash →
`wsl.exe` boundary rather than a real bash/WSL bug — a bare
`wsl.exe -- bash -lc 'exit 1'`, checked from a **separate**, subsequent tool
call, correctly reports exit 1.
**Fix:** never trust `$?` read inside the same chained WSL command string.
Run the command you care about as the *entire* content of one `wsl.exe`
call, then check its real exit code from the outside (a separate shell
invocation, or whatever your tooling reports as that call's own exit
status).

### Bash's `$_` corrupts PowerShell one-liners passed through it
**Symptom:** a `powershell.exe -Command "... $_.Foo ..."` invocation run
through a bash/Git-Bash shell produces garbage like `unsetenv.Foo` instead of
the intended `$_.Foo`.
**Cause:** the outer bash shell expands its own special `$_` variable before
`powershell.exe` ever sees the string, since the command was double-quoted
in a bash context.
**Fix:** run PowerShell one-liners containing `$_` through an actual
PowerShell shell/tool, never piped through `bash -c "..."`.

## Template constraints (this codebase specifically)

### Exactly one `MarketplaceService.ProcessReceipt`
Roblox allows one callback per game. It already lives in
[`src/ServerScriptService/ProcessReceipt.server.luau`](../src/ServerScriptService/ProcessReceipt.server.luau)
as a flat, numbered (`1️⃣2️⃣3️⃣...`) dispatch keyed by `ReceiptInfo.ProductId`.
Any new purchasable product is a new numbered section in that same file, or
a dispatch-table entry — never a second `ProcessReceipt` assignment
anywhere else.

### No receipt idempotency guard exists yet
The current handler does not write consumed `receiptId`s anywhere before
granting. Roblox retries a non-granted (or slow) receipt indefinitely, so
today a retry can double-grant money/luck. Any new purchase flow added
(e.g. a consumable, a sabotage charge) **must bring its own** idempotency
store — don't assume the template already guards this, because it doesn't.

### `StarterPlayer` and `StarterGui` are currently binary `.rbxm` blobs
`default.project.json` maps both straight to their `src/` folders, but every
file inside those two folders today is an opaque `.rbxm` (e.g.
`StarterPlayerScripts.rbxm`, `AdminPanelGUI.rbxm`) — not loose, Rojo-synced
`.luau`/`.json`. Editing them means round-tripping through Studio, and none
of it is git-diffable. Every other system in this repo (config, services,
server logic, `ReplicatedStorage` modules) is loose files. If you're adding
non-trivial new client code or GUI, converting just your feature's slice to
loose files (leaving the rest of the blobs alone) is worth the one-time
setup cost — see [003](003-pc-repair-module-layout-plan.md) for a concrete
instance of this decision.

### The "conveyor" isn't called that anywhere in code
See [002](002-pc-repair-handoff-verification.md) — it's `workspace.Waypoints`
plus the tween-walk loop in `Module.Spawn`
([`src/ServerStorage/Modules/Things.luau`](../src/ServerStorage/Modules/Things.luau)).
Grepping for "Conveyor," "Spawn," or "Belt" as standalone systems will miss
it; grep for `Waypoint` instead.

### "Plot" is called `Base`
`Player.Configuration.Base.Value` — not a `Plot` folder/attribute anywhere.
See [002](002-pc-repair-handoff-verification.md).

### A `Thing` needs a real pre-built model or it silently doesn't exist
`Module.Create` looks up `ServerStorage.Things.<Mutation>.<Rarity>.<Name>`.
If that model is missing (or has no `PrimaryPart`) it `warn()`s and returns
nothing; `Module.Add` then quietly bails. Adding a catalog entry without
adding its model looks like "nothing happens." See
[007](007-thing-schema-and-persistence.md).

### Things persist only on leave/shutdown, and the retry path looks broken
`SaveThings` runs only from `PlayerRemoving` and `BindToClose` — no
periodic autosave. The `FailedSavesQueue` retry loop writes to a nested
`Profile.Things[slot]` while normal saves and `LoadThings` use a flat
top-level slot map, so retried saves are likely never loaded. Static read
only, not reproduced. See [007](007-thing-schema-and-persistence.md).
