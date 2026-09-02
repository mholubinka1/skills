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

Runs only after Step 4 creates a fresh worktree — the Step 1 (already isolated) and Step 2 (resume) paths stop before reaching it.

A fresh worktree is a bare checkout: none of the gitignored dependency artifacts (`.venv`, `node_modules`, NuGet caches, …) the main checkout built up are present, so code that runs on `main` may not run here. This step offers to install them — never to copy or symlink them from the main checkout.

Both prompts in this step go through `AskUserQuestion`. In a non-interactive run (no `AskUserQuestion` available), take the non-blocking default without reading stdin: *Skip* for the install question, acknowledge-and-continue for the `ACTION NEEDED` gate.

1. Detect the repo's dependency ecosystems. Apply `update-dependencies`' Detection Table marker rules (the repo root, plus one level of subdirectories for a monorepo), **and also** note any other dependency-manifest file present that the Detection Table doesn't cover (`go.mod`, `Cargo.toml`, `Gemfile`, or anything comparable). The per-ecosystem install commands, the courtesy list for the uncovered ones, and the pip-interpreter note are in the Dependency bootstrap section of [REFERENCE.md](REFERENCE.md).
2. **Nothing detected** — do nothing; continue to the caller.
3. **One or more first-class ecosystems detected** — print each one and its exact install command(s), then ask via `AskUserQuestion`: *"Install dependencies in this worktree now?"* with options *Install* / *Skip*. No interactive user → **Skip**, per the note above; likewise any answer that is not a clear *Install*.
   - **Skip** — leave the printed commands as a copy-paste hint; continue.
   - **Install** — run each detected ecosystem's install command, recording pass/fail per ecosystem. An install that fails — tool not on `PATH`, no network, unsatisfiable lockfile, venv creation unavailable, compile error — is reported on one line (the failing command and its first error line) and does **not** abort: the worktree is created and is usable for work that doesn't execute the code.
4. **Uncovered ecosystem(s)** — any marker from step 1 that is not a first-class Detection Table ecosystem:
   - If it is on the courtesy list in REFERENCE.md, attempt that conventional install — best-effort, non-fatal, reported as in step 3. Otherwise attempt nothing.
   - Then print once, covering every uncovered ecosystem found:
     `ACTION NEEDED: add <ecosystem>[, <ecosystem>…] as a first-class entry in create-worktrees/REFERENCE.md`
     and use `AskUserQuestion` a single time to make the user acknowledge it before the workflow continues (no interactive user → print and continue, per the note above).
