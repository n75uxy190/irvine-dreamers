# 001 — WSL + git setup

**Date:** 2026-09-22

## Context

Repo was downloaded from GitHub as a zip (`irvine-dreamers-main.zip` →
unzipped to `C:\Users\notko\Downloads\irvine-dreamers-main`), which strips
`.git` entirely. Goal: get it properly connected to
`git@github.com:n75uxy190/irvine-dreamers.git` with a working WSL setup.

## What happened

1. Confirmed the unzipped folder had no `.git` and was byte-identical to
   what's already on GitHub (`main` and `buyable-npcs` branches both existed
   remotely already, from earlier work).
2. WSL (Ubuntu) already had a git identity and an SSH key registered with
   GitHub as `n75uxy190` — no new auth setup needed there.
3. `git clone` into `~/projects/irvine-dreamers` (WSL-native filesystem)
   hung for ~28 minutes before being diagnosed as the WSL2 MTU black hole
   (see [KNOWN_ISSUES.md](KNOWN_ISSUES.md)). Fixed, clone completed in
   seconds afterward.
4. Later, a `pc-repair-minigame` branch was created off `main` in that WSL
   clone — **this was never pushed to origin.**
5. Separately, the user accidentally ran VS Code's "Initialize Repository"
   on the Downloads folder directly (a plain, empty `git init`, zero commits,
   no remote). Removed — nothing was lost, there was nothing to lose.
6. Attempted to wire the Downloads folder up as its own independent
   Windows-native git repo (separate SSH key, never registered with GitHub).
   Abandoned in favor of a simpler path: do the git operations on the
   Downloads folder **through WSL**, via its `/mnt/c/...` view, reusing the
   already-authorized WSL SSH key. No new credentials, no key copying
   (an attempt to copy the WSL private key into the Windows-side `~/.ssh`
   was correctly blocked by Claude Code's own safety layer —
   "Credential Materialization" — and wasn't needed anyway).
7. Hit the WSL2 VM full-wedge issue mid-session (see
   [KNOWN_ISSUES.md](KNOWN_ISSUES.md)) — required an elevated
   `wsl --shutdown` from the user, then a cold VM boot.
8. Hit the DrvFs false-permission-diff issue attaching the Downloads folder's
   existing files to `origin/main`'s history (see
   [KNOWN_ISSUES.md](KNOWN_ISSUES.md)) — resolved with a verified
   `git checkout -f`.

## Outcome

- **Canonical working copy:** `C:\Users\notko\Downloads\irvine-dreamers-main`
  — a real repo, `origin` = `git@github.com:n75uxy190/irvine-dreamers.git`,
  on local branch `pc-repair-minigame` (tracking-equivalent to `main`, no
  commits yet), working tree clean.
- All git operations on this folder go through WSL (`wsl.exe -- bash -lc
  '...'` or a WSL-aware terminal in VS Code), because the repo was attached
  to history via `/mnt/c` and that's what git/SSH is configured for. Do not
  run git commands against this folder from a plain Windows PowerShell/CMD
  prompt — there's no working GitHub auth wired up on that side.
- `~/projects/irvine-dreamers` inside WSL is a **redundant leftover clone**
  from step 3–4 above. It also has a local, unpushed `pc-repair-minigame`
  branch, independent of the Downloads copy's branch of the same name. Not
  deleted yet, but should not be developed against — pick the Downloads copy
  for all future work to avoid the two diverging.
- Neither copy's `pc-repair-minigame` branch has been pushed to GitHub yet.
  Once real commits land, push from the Downloads copy so GitHub becomes the
  single source of truth, and consider deleting `~/projects/irvine-dreamers`
  at that point.
