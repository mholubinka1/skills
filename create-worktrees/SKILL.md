---
name: create-worktrees
description: Enter an isolated git worktree for the current task so work never touches the main checkout. Resumes an existing worktree if one is found, otherwise ensures .claude is gitignored and creates a fresh worktree on a wip/<slug> placeholder branch. Use whenever starting implementation work that should be isolated from the main checkout, or as the first step of /implement.
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
grep -qxF '.claude' .gitignore 2>/dev/null && echo present || echo missing
```

If `missing` (including when `.gitignore` doesn't exist yet), add the entry and commit it as a standalone commit on whatever branch is currently checked out — this must happen before Step 4, so the worktree that Step 4 creates is never at risk of being committed:

```bash
echo '.claude' >> .gitignore
git add .gitignore
git commit -m "chore: gitignore .claude/"
```

## Step 4 — Create the worktree

Slugify the current task's trigger message (see [REFERENCE.md](REFERENCE.md) for the rule) and create a placeholder branch:

```text
EnterWorktree(name: "wip/<slug>")
```

The `wip/` prefix is deliberate — `branch-hygiene` already classifies `wip/*` as a placeholder that "must be renamed before code is written," so its existing mismatch-resolution step renames this branch automatically once the real name is known from later work (e.g. a `/implement` grill session). No renaming logic is needed here.
