---
name: create-worktrees
description: Enter an isolated git worktree for the current task so work never touches the main checkout. No-ops if the session is already isolated, resumes an existing worktree if one is found, otherwise ensures .claude is gitignored and creates a fresh worktree on a wip/<slug> placeholder branch. Use whenever starting implementation work that should be isolated from the main checkout, or as the first step of /implement.
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

Run the `pre-commit-check` skill, then commit:

```bash
git commit -m "chore: gitignore .claude/"
```

## Step 4 — Create the worktree

Slugify the current task's trigger message (see [REFERENCE.md](REFERENCE.md) for the rule) and create a placeholder branch:

```text
EnterWorktree(name: "wip/<slug>")
```

The `wip/` prefix is deliberate — `branch-hygiene` already classifies `wip/*` as a placeholder that "must be renamed before code is written," so its existing mismatch-resolution step renames this branch automatically once the real name is known from later work (e.g. a `/implement` grill session). No renaming logic is needed here.
