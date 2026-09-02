---
name: create-worktrees
description: Enter an isolated git worktree for the current task so work never touches the main checkout. No-ops if the session is already isolated, resumes an existing worktree if one is found, otherwise ensures .claude is gitignored and creates a fresh worktree on a wip/<slug> placeholder branch, then optionally bootstraps the repo's detected dependency ecosystems into it on a prompt. Use whenever starting implementation work that should be isolated from the main checkout, or as the first step of /implement.
---

# Create Worktrees

Get into an isolated worktree before any repository writes happen. Runs standalone (`/create-worktrees`) or as the first step of `/implement` — same behaviour either way.

## Step 1 — Already isolated?

Check whether the current directory is already a linked worktree:

```bash
git rev-parse --git-dir
```

If the output contains `worktrees/`, the session is already isolated. Stop here — nothing to do.

## Step 2 — Check for existing worktrees to resume

```bash
git worktree list
```

Ignore the entry for the main checkout (the first line). If one or more other worktrees are listed, show them to the user and ask whether to resume one:

> Found an existing worktree on branch `<branch>` at `<path>` — resume there, or start a new one?

If the user picks one:

```text
EnterWorktree(path: "<worktree-path>")
```

Stop here. If none exist, or the user opts to start fresh, continue to Step 3.

## Step 3 — Ensure `.claude` is gitignored

```bash
grep -qxE '\.claude/?' .gitignore 2>/dev/null && echo present || echo missing
```

If `missing` (including when `.gitignore` doesn't exist yet), the entry must be added and committed before Step 4, so the worktree that Step 4 creates is never at risk of being committed. Check the current branch first:

```bash
git branch --show-current
```

- **Trunk branch** (`main`, `master`, `develop`): warn the user before committing — e.g. "`.claude` isn't gitignored yet, and the fix would land directly on `<branch>`. Commit it there?" — since this repo's standards call for branching from `main` rather than committing to it directly. Proceed only on confirmation.
- **Any other branch**: commit directly, no confirmation needed.

Either way, once cleared to proceed:

```bash
echo '.claude' >> .gitignore
git add .gitignore
```

Run the `pre-commit-check` skill. If it surfaces an error, stop and resolve it before continuing. Once clean, commit:

```bash
git commit -m "chore: gitignore .claude"
```

## Step 4 — Create the worktree

Slugify the current task's trigger message (see [REFERENCE.md](REFERENCE.md) for the rule) and create a placeholder branch:

```text
EnterWorktree(name: "wip/<slug>")
```

The `wip/` prefix is deliberate — `branch-hygiene` already classifies `wip/*` as a placeholder that "must be renamed before code is written," so its existing mismatch-resolution step already moves work off this branch automatically once the real name is known from later work (e.g. a `/implement` grill session). No new mismatch-detection logic is needed here.

If `EnterWorktree` errors because a branch of that name already exists (e.g. a leftover `wip/<slug>` from an earlier aborted run that was never cleaned up), append a short disambiguating suffix to the slug and retry.

## Step 5 — Bootstrap dependencies (optional)

Runs only when Step 4 created a fresh worktree. Skip it entirely on the Step 1 (already isolated) and Step 2 (resume) paths.

A fresh worktree is a bare checkout with none of the gitignored dependency artifacts (`.venv`, `node_modules`, NuGet caches, …) the main checkout accumulated, so code that runs on `main` may not run here. This step offers to close that gap by installing — never by copying or symlinking artifacts from the main checkout.

1. Detect which dependency ecosystems the repo uses, applying the marker rules in `update-dependencies`' Detection Table — repo root and one level of subdirectories. The per-ecosystem install commands are in the Dependency bootstrap section of [REFERENCE.md](REFERENCE.md).
2. **No ecosystem detected** — do nothing, continue to the caller.
3. **One or more detected** — print each detected ecosystem and its exact install command(s), then ask once: *"Install dependencies in this worktree now? (y/n)"*.
   - **Cannot prompt** (non-interactive / no TTY) — treat as **n**; never block waiting for input.
   - **n** — leave the printed commands as a copy-paste hint and continue.
   - **y** — run each detected ecosystem's install command, recording pass/fail per ecosystem. An install that fails — tool not on `PATH`, no network, unsatisfiable lockfile, compile error — is reported on one line (the failing command and its first error line) and does **not** abort: the worktree is already created and is usable for work that doesn't execute the code.
4. **Unrecognised ecosystem** — a dependency marker that is not in the Detection Table:
   - If it is on the courtesy list in REFERENCE.md (`go.mod`, `Cargo.toml`, `Gemfile`), attempt that conventional install — best-effort, non-fatal, reported the same way as step 3.
   - Whether or not an install ran, print this line prominently:
     `ACTION NEEDED: add <ecosystem> as a first-class entry in create-worktrees/REFERENCE.md`
   - Then use `AskUserQuestion` to make the user acknowledge that line before the workflow continues.
