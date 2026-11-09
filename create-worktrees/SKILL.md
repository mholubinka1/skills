---
name: create-worktrees
description: Enters an isolated git worktree for the current task, creating one (optionally bootstrapping its dependencies) or resuming an existing one. Use when starting implementation work that must not touch the main checkout, or as the first step of /implement.
allowed-tools:
  - Read
  - Glob
  - Skill
  - AskUserQuestion
  - EnterWorktree
  - Agent
  - Bash(git rev-parse --git-dir)
  - Bash(git worktree list *)
  - Bash(grep -qxE *)
  - Bash(echo present)
  - Bash(echo missing)
  - Bash(git branch --show-current)
  - Bash(git add .gitignore)
  - Bash(git commit -m *)
  - Bash(uv sync)
  - Bash(poetry install)
  - Bash(pdm install)
  - Bash(pipenv sync)
  - Bash(.venv/bin/pip install -r *)
  - Bash(.venv/Scripts/pip install -r *)
  - Bash(dotnet restore)
  - Bash(npm ci)
  - Bash(yarn --version)
  - Bash(yarn install --immutable)
  - Bash(yarn install --frozen-lockfile)
  - Bash(pnpm install --frozen-lockfile)
  - Bash(go mod download)
  - Bash(cargo fetch)
  - Bash(bundle install)
---

# Create Worktrees

Get into an isolated worktree before any repository writes happen. Runs standalone (`/create-worktrees`) or as the first step of `/implement` — same behaviour either way.

Every prompt goes through `AskUserQuestion`. In a non-interactive run (no `AskUserQuestion` available), don't read stdin or block: take the default each prompt names.

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

Ignore the entry for the main checkout (the first line). If one or more other worktrees are listed, ask via `AskUserQuestion`: *"Found an existing worktree on branch `<branch>` at `<path>` — resume there, or start a new one?"* with one option for each of the first three listed worktrees, plus *Start new*. Default: *Start new*.

If the user picks a worktree:

```text
EnterWorktree(path: "<worktree-path>")
```

Stop here. If none exist, or the answer is *Start new*, continue to Step 3.

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

Run the `pre-commit-check` skill and act on its `next:` line. Commit only when it reads `none — ready to commit.` or lists only pre-existing failures or outside-the-change autofixes; otherwise stop and report. Then commit:

```bash
git commit -m "chore: gitignore .claude"
```

## Step 4 — Create the worktree

Slugify the current task's trigger message (see [REFERENCE.md](REFERENCE.md) for the rule) and create a placeholder branch:

```text
EnterWorktree(name: "wip/<slug>")
```

`EnterWorktree` turns that name into the branch `worktree-wip+<slug>`. `branch-hygiene` treats it as a placeholder and moves work off it once the real name is known.

If `EnterWorktree` errors because a branch of that name already exists (e.g. a leftover `worktree-wip+<slug>` from an earlier aborted run that was never cleaned up), append a short disambiguating suffix to the slug and retry.

## Step 5 — Bootstrap dependencies (optional)

Runs only after Step 4 creates a fresh worktree — the Step 1 (already isolated) and Step 2 (resume) paths stop before reaching it.

A fresh worktree is a bare checkout: none of the gitignored dependency artifacts (`.venv`, `node_modules`, NuGet caches, …) from the main checkout are present, so code that runs on `main` may not run here. This step offers to install them, never to copy or symlink them from the main checkout.

1. Detect the repo's dependency ecosystems: the first-class ones from `../update-dependencies/REFERENCE.md` "Detection Table" (marker rules and scan scope), plus any other dependency manifest present (`go.mod`, `Cargo.toml`, `Gemfile`, or anything comparable).
2. **Nothing detected** — do nothing; continue to the caller.
3. **One or more ecosystems detected** — print each one and its exact install command(s) from [REFERENCE.md](REFERENCE.md) "Dependency bootstrap", then ask: *"Install dependencies in this worktree now?"* with options *Install* / *Skip*. Default: *Skip*, as for any answer that is not a clear *Install*.
   - **Skip** — leave the printed commands as a copy-paste hint; continue.
   - **Install** — dispatch the install sub-agent per [REFERENCE.md](REFERENCE.md) "Install handover", and report its result. A failed install does **not** abort: the worktree is usable for work that doesn't execute the code.
4. **Uncovered ecosystem(s)** — any marker that is not a first-class Detection Table ecosystem: follow [REFERENCE.md](REFERENCE.md) "Uncovered ecosystems".
