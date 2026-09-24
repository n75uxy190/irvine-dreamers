# Journal

A running log for whoever (human or agent) picks up work on this repo. Purpose:
get oriented fast without re-deriving context from git history, or re-asking
questions that already have answers.

## How to use this

1. **Read this file first.** The table below is a semantic index — it tells
   you what each entry covers so you can jump straight to the relevant one
   instead of reading all of them.
2. **Check [KNOWN_ISSUES.md](KNOWN_ISSUES.md) before touching adjacent
   systems.** It's a flat list of gotchas discovered the hard way — tooling
   quirks, environment traps, template constraints — cross-referenced from
   entries below where relevant.
3. **Add a new entry for a checkpoint, not every commit.** A checkpoint is:
   a completed milestone, a non-obvious finding that took real investigation,
   a decision made (with the alternatives considered), or an incident and its
   resolution. Routine implementation work doesn't need an entry — the code
   and its commit messages already say what changed.
4. **Naming:** `NNN-kebab-case-topic.md`, zero-padded, sequential. Add your
   entry's row to the index table below in the same change.
5. **Keep entries factual and dated.** State what was true when written; if
   it later turns out to be wrong or superseded, correct it in
   KNOWN_ISSUES.md or a new entry rather than silently editing history here.

## Semantic index

| # | Title | Covers |
|---|---|---|
| [001](001-wsl-git-setup.md) | WSL + git setup | Connecting this repo to GitHub via WSL; the MTU/VM-wedge/DrvFs incidents hit along the way; why there are (were) two local working copies and which one is canonical |
| [002](002-pc-repair-handoff-verification.md) | PC Repair handoff verification | Cross-checked `PC_REPAIR_HANDOFF.md`'s assumptions about existing template systems (rarity, plot/base, conveyor, ProcessReceipt) against the actual codebase — what matched, what didn't, what the real names/locations are |
| [003](003-pc-repair-module-layout-plan.md) | PC Repair module layout plan | Proposed Rojo file/folder layout for the feature, mapped onto real conventions already in the repo; open decisions not yet resolved |
| [004](004-lune-testing-setup.md) | Lune testing setup | Why/how Lune + a custom minimal test harness (no framework) got added for headless testing of pure-logic modules; two real bugs hit and fixed while building it |
| [005](005-pc-container-build.md) | PC container build | The actual PCUnit/PCFactory/TransitionTable/config build, Lune-tested (30 tests passing); decisions made that weren't in the handoff; three open items not yet resolved (require-by-string unverified in Studio, missing Claimed→OnConveyor edge, debug view unwired) |
| [006](006-service-layer-stubs.md) | Service layer stubs + debug spawn | ConveyorService (real, timer-based debug spawn), RepairService/SabotageService (empty stubs) — the sanctioned front door for calling PCUnit/PCFactory; syntax-checked via selene, not yet run in Studio |
| [007](007-thing-schema-and-persistence.md) | Existing Thing schema + persistence | Mermaid diagram of how a `Thing` goes catalog → model → Base slot → DataStore and back; the 8-field catalog schema, the persisted `{Name, Mutation, Traits, Time}` record, and template quirks (model-folder requirement, no autosave, retry-queue shape mismatch). Groundwork for the PC → Thing projection; nothing decided yet |

## Canonical working copy

**`C:\Users\notko\Downloads\irvine-dreamers-main`** (this repo), accessed via
WSL for git operations (see [001](001-wsl-git-setup.md) for why). There was
briefly a second clone at `~/projects/irvine-dreamers` inside WSL created
during initial setup — it's redundant now and safe to delete; don't develop
against it.
