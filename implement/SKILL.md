---
name: implement
description: Carries a repository change from request to merged PR inline in the current conversation. Use when the user wants to make any change to a repository.
allowed-tools:
  - Skill
  - Read
  - Glob
  - Edit(.agent-docs/issues/**)
  - ExitWorktree
  - Bash(git branch --show-current)
  - Bash(git add *)
  - Bash(git commit *)
  - Bash(gh pr view *)
  - Bash(git rev-parse --show-toplevel)
---

# Implement

Run the full implementation workflow inline in the current conversation, step by step.

> **Prerequisite skills**: all skills referenced in this workflow live in this same skills
> repo and are installed automatically via the post-commit sync hook:
> `create-worktrees`, `init-agent-docs`, `design`, `write-spec`, `create-issues`, `branch-hygiene`,
> `bdd`, `pre-commit-check`, `code-review`,
> `address-copilot-comments`, `pr-cleanup`.

## Step 0 — Enter an isolated worktree

Run the `create-worktrees` skill. This must happen before anything else — later steps
(`init-agent-docs`, `design`) can write to the repo, and the main checkout must stay
untouched. Whether `create-worktrees` created a new worktree, resumed an existing one, or
found the session already isolated, continue to Step 1 as normal — `init-agent-docs` is
idempotent, so re-running it against an already-bootstrapped worktree is harmless.

## Step 1 — Bootstrap agent docs

Run the `init-agent-docs` skill. This bootstraps `.agent-docs/agent.md` and ensures
`CLAUDE.md` references it. The skill is idempotent — it reports what was created or
skipped on each run. If it surfaces an error, stop and resolve it before continuing.

## State detection — resume from where work left off

After Step 1, check what already exists for the current branch:

```bash
git branch --show-current
```

A slice in the issues file is **done** when none of its acceptance criteria is still
`- [ ]`. Step 6 ticks them as each slice is committed. Take the first row that matches:

| State | Action |
|---|---|
| `.agent-docs/issues/<branch-name>.md` exists and at least one slice is not done | Resume at the BDD loop (Step 6), for the slices that are not done only |
| `.agent-docs/issues/<branch-name>.md` exists and every slice is done | Resume at code review (Step 7) |
| `.agent-docs/specs/<branch-name>.md` exists only | Resume at `/create-issues` (Step 5) |
| Neither exists | Continue to Step 2 below |

## Step 2 — Design

Run the `design` skill. Use the trigger context as the starting point — you already know what to build, so the design session sharpens and validates it rather than starting from scratch.

## Step 3 — Branch hygiene

Before running `branch-hygiene`, note the current branch name (`git branch --show-current`). Run the `branch-hygiene` skill with the change type and a one-line summary taken from the design output, e.g. `/branch-hygiene feature "add CSV export to reports"`, and act on its `next:` line — on a mismatch that creates the correct branch from the remote default. If Step 0 created a fresh worktree this session and the noted branch is a placeholder — `worktree-wip+<slug>` (the form `EnterWorktree` creates) or a hand-made `wip/<slug>` — delete it once the switch is done (`git branch -D <noted-branch>`) — nothing is ever committed to it before this point, so it's always safe to discard. If Step 0 instead resumed an existing worktree or found the session already isolated, the noted branch may be real work — do not delete it even if `branch-hygiene` flags and resolves a mismatch for some other reason.

## Step 4 — Write spec

Run the `write-spec` skill. It will synthesise the design output into `.agent-docs/specs/<branch-name>.md`.

## Step 5 — Create issues

Run the `create-issues` skill. It will break the spec into vertical slices, quiz you on the breakdown, write `.agent-docs/issues/<branch-name>.md`, and push to GitHub.

## Step 6 — BDD loop (per slice, in dependency order)

For each slice in `.agent-docs/issues/<branch-name>.md` that is not done, in dependency order (no blockers first):

1. Run the `bdd` skill for this slice.
2. Run the `pre-commit-check` skill on all changed files and act on its `next:` line.
3. Tick the slice: in the issues file, change each of this slice's acceptance criteria from `- [ ]` to `- [x]`. Tick a criterion only when the slice's work meets it; if one is not met, the slice is not finished — go back to 1. The ticks are what a resumed run reads to skip this slice, so never leave them for later.
4. Commit the slice's work and the ticked issues file together, with a single pithy line:

   ```bash
   git add <changed files> .agent-docs/issues/<branch-name>.md
   git commit -m "<one-line summary>"
   ```

When every slice is done, continue to Step 7.

## Step 7 — Code review

Run the `code-review` skill.

## Step 8 — Merge

The PR link was shared by `/pr-cleanup` at the end of `/code-review`. Prompt the user to merge it:

> Please merge the PR when you're ready and let me know.

- If the response is not a clear confirmation, press the user again.
- Once confirmation is given, verify:

  ```bash
  gh pr view --json state --jq '.state'
  ```

- If the state is not `MERGED`, tell the user and press them again.
- Once verified as `MERGED`, clean up. How depends on how Step 0 entered the worktree:

  - **Step 0 created a fresh worktree this session** (`EnterWorktree(name: ...)`): remove it.
    The merged PR carries its commits, so discard them:

    ```text
    ExitWorktree(action: "remove", discard_changes: true)
    ```

  - **Step 0 resumed an existing worktree, or found the session already isolated with no
    `EnterWorktree` call this session**: keep it and report its path and branch:

    ```bash
    git rev-parse --show-toplevel
    git branch --show-current
    ```

    Then call `ExitWorktree(action: "keep")` and tell the user the worktree at that path is
    done and ready to remove whenever they want (`git worktree remove <path>`, adding
    `--force` only if it reports uncommitted changes they're fine discarding, then
    `git branch -D <branch>`).

  The workflow is complete.
