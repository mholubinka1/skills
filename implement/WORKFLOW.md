# Implementation Workflow

This is the full implementation workflow run inline by [SKILL.md](SKILL.md).

---

Work through the steps below in order.

> **Prerequisite skills**: all skills referenced in this workflow live in this same skills
> repo and are installed automatically via the post-commit sync hook:
> `create-worktrees`, `init-agent-docs`, `grill`, `write-spec`, `create-issues`, `branch-hygiene`,
> `bdd`, `pre-commit-check`, `code-review`,
> `address-copilot-comments`, `pr-cleanup`.

## Step 0 — Enter an isolated worktree

Run the `create-worktrees` skill. This must happen before anything else — later steps
(`init-agent-docs`, `grill`) can write to the repo, and the main checkout must stay
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

| State | Action |
|---|---|
| `.agent-docs/issues/<branch-name>.md` exists | Resume at the BDD loop (Step 6) for any unchecked issues |
| `.agent-docs/specs/<branch-name>.md` exists only | Resume at `/create-issues` (Step 5) |
| Neither exists | Continue to Step 2 below |

## Step 2 — Grill

Run the `grill` skill. Use the trigger context as the starting point — you already know what to build, so the grilling session sharpens and validates it rather than starting from scratch.

## Step 3 — Branch hygiene

Run the `branch-hygiene` skill. Derive the change type and branch slug from the grill output in context. If the current branch is wrong (including the `wip/` placeholder branch created in Step 0), suggest and create the correct one — its existing mismatch-resolution flow creates the new branch from the remote default the same as any other mismatch. Since nothing is ever committed to a `wip/` placeholder before this point, delete it once the switch is done (`git branch -D wip/<slug>`) so it doesn't linger.

## Step 4 — Write spec

Run the `write-spec` skill. It will synthesise the grill output into `.agent-docs/specs/<branch-name>.md`.

## Step 5 — Create issues

Run the `create-issues` skill. It will break the spec into vertical slices, quiz you on the breakdown, write `.agent-docs/issues/<branch-name>.md`, and push to GitHub.

## Step 6 — BDD loop (per issue, in dependency order)

For each unchecked issue in `.agent-docs/issues/<branch-name>.md`, in dependency order (no blockers first):

1. Run the `bdd` skill for this issue.
2. Run the `pre-commit-check` skill on all changed files.
3. Commit with a single pithy line:

   ```bash
   git add <changed files>
   git commit -m "<one-line summary>"
   ```

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

  - **Step 0 created a fresh worktree this session** (`EnterWorktree(name: ...)`): it's
    exclusively this task's, so remove it automatically. Its branch will have commits beyond
    the base ref by design, so `ExitWorktree` will refuse to remove it unless told to discard
    those changes — safe here specifically because the PR carrying them was just confirmed
    merged:

    ```text
    ExitWorktree(action: "remove", discard_changes: true)
    ```

  - **Step 0 resumed an existing worktree, or found the session already isolated with no
    `EnterWorktree` call this session**: don't auto-remove. Neither `create-worktrees` nor
    this step ever confirmed the worktree is exclusively this task's — it could be a
    long-lived worktree the user is reusing for other work, or have uncommitted changes of
    its own — so force-deleting it here would risk destroying something this workflow
    doesn't own. `ExitWorktree`'s `remove` action can't help either way (it only ever
    operates on a worktree it created in the current session — an explicit no-op on removal
    for a `path`-entered worktree, and a full no-op if `EnterWorktree` was never called this
    session). Instead, report the path and branch so the user can decide:

    ```bash
    git rev-parse --show-toplevel
    git branch --show-current
    ```

    Then call `ExitWorktree(action: "keep")` — safe either way, since it returns a resumed
    session to its original directory and is a harmless no-op if `EnterWorktree` was never
    called — and tell the user the worktree at that path is done and ready to remove
    whenever they want (`git worktree remove <path>`, adding `--force` only if it reports
    uncommitted changes they're fine discarding, then `git branch -D <branch>`).

  The workflow is complete.
