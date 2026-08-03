# Add create-worktrees skill and always isolate /implement in a worktree

## Problem Statement

`/implement` currently runs its entire cycle — bootstrapping agent docs, grilling, writing specs, running the BDD loop — directly on whatever checkout is currently open. A crashed or abandoned run, a bad edit, or a failed rebase mid-loop can leave the user's primary checkout dirty or broken, requiring manual recovery. There is also no way to run two `/implement` sessions concurrently (e.g. on two different features) without them fighting over the same branch checkout.

## Solution

A new standalone skill, `create-worktrees`, gets a session into an isolated git worktree using the harness's built-in `EnterWorktree`/`ExitWorktree` tools. It resumes an existing worktree if one is found (asking the user which, if any), otherwise ensures the target repo's `.claude` directory is gitignored and creates a fresh worktree on a `wip/<slug>` placeholder branch. `/implement` is updated to run `create-worktrees` as its unconditional first step, and to remove the worktree once its final merge check confirms the PR is `MERGED`.

## User Stories

1. As a user running `/implement`, I want the entire workflow to happen in an isolated worktree, so that a bad or crashed run never leaves my primary checkout dirty or broken.
2. As a user, I want to run `/implement` on two different tasks at the same time, so that concurrent work doesn't fight over the same branch checkout.
3. As a user, I want to type `/create-worktrees` directly (outside of `/implement`) to start any task in an isolated worktree, so that isolation isn't limited to the full implementation workflow.
4. As a user re-running `/implement` to resume interrupted work, I want it to find and offer to reuse the worktree from my earlier session rather than silently starting a disconnected new one.
5. As a user, I want the worktree automatically removed once `/implement` confirms my PR has merged — when that worktree was created fresh for this task — so that I don't accumulate stale worktrees I have to clean up by hand. If the worktree was instead resumed or found already active, I want to be told it's ready to remove rather than have it force-deleted out from under me, since `/implement` can't confirm it doesn't hold other unrelated work.
6. As a user whose `/implement` session fails or is abandoned before merge, I want the worktree left in place (subject to the harness's normal session-exit keep/remove prompt), so that in-progress work is never silently discarded.
7. As a user working in a repo that doesn't yet gitignore `.claude/`, I want that fixed automatically before any worktree is created, so that the worktree directory itself is never at risk of being committed.

## Implementation Decisions

- New skill directory `create-worktrees/` with `SKILL.md` and `REFERENCE.md`, following this repo's existing skill structure convention.
- **Detect existing isolation**: `git rev-parse --git-dir`; if the output contains `worktrees/`, the session is already inside a linked worktree — no-op.
- **Resume**: `git worktree list`, ignoring the main checkout entry. If any other worktrees exist, list them and ask the user whether to resume one via `EnterWorktree(path: ...)`. This is a simple list-and-ask, not automatic slug-matching — matching by inferred slug is unreliable once the real branch name has replaced the placeholder (see `wip/` decision below).
- **Gitignore hygiene**: check for a `.claude` or `.claude/` line in `.gitignore` (`grep -qxE '\.claude/?' .gitignore`). If missing (including when `.gitignore` doesn't exist), append it and commit as a standalone commit (`chore: gitignore .claude`), running `pre-commit-check` first, before any worktree is created. On a trunk branch (`main`/`master`/`develop`), warn the user and require confirmation before committing — added during review, since committing straight to trunk conflicts with `.agent-docs/agent.md`'s branching standard.
- **Worktree creation**: `EnterWorktree(name: "wip/<slug>")`, where `<slug>` is a short kebab-case fragment of the trigger message (see `REFERENCE.md` for the slugify rule — approximate is fine, it only needs to be human-recognisable in `git worktree list`).
- **Why `wip/`**: `branch-hygiene` already classifies `wip/*` as a placeholder that "must be renamed before code is written," and its existing mismatch-resolution step (Step 6 in `branch-hygiene/SKILL.md`) already handles such branches once the real name is known. Using `wip/` means no new mismatch-detection logic is needed anywhere — `branch-hygiene`, running later inside the worktree once grill output is available, handles it via its existing flow. That flow creates the new branch from the remote default rather than literally renaming the old one, so `/implement` deletes the now-empty `wip/` placeholder (`git branch -D`) right after the switch, since nothing is ever committed to it beforehand. Recorded as [ADR 0003](../../adr/0003-worktree-created-before-branch-name-is-known.md).
- **`/implement` integration** (`implement/WORKFLOW.md`):
  - New Step 0 — run `create-worktrees` before `init-agent-docs`, since `init-agent-docs` and `grill` can both write to the repo and isolation must start before any file writes happen.
  - All subsequent steps renumber, offset by one to make room for the inserted Step 0: bootstrap agent docs (old Step 0) becomes Step 1, grill (old Step 1) becomes Step 2, branch hygiene (old Step 2) becomes Step 3, write spec (old Step 3) becomes Step 4, create issues (old Step 4) becomes Step 5, BDD loop (old Step 5) becomes Step 6, code review (old Step 6) becomes Step 7, merge (old Step 7) becomes Step 8.
  - Step 8 (merge) gains a final action: once `gh pr view --json state --jq '.state'` confirms `MERGED`, clean up. What happens depends on how Step 0 entered the worktree, since `ExitWorktree`'s `remove` action only ever operates on a worktree it created in *this* session — added during review, after catching that the original unconditional `ExitWorktree(action: "remove")` call would silently fail to remove a resumed or already-isolated worktree:
    - Fresh worktree created this session (`EnterWorktree(name: ...)`): auto-remove via `ExitWorktree(action: "remove", discard_changes: true)` — `discard_changes` is required because the branch necessarily has commits beyond its base ref, safe here since those commits were just confirmed merged, and safe to automate since this worktree is exclusively this task's.
    - Resumed (`EnterWorktree(path: ...)`) or found already-isolated with no `EnterWorktree` call this session: don't auto-remove — added during review, after catching that neither case guarantees the worktree is exclusively this task's (it could be a long-lived worktree the user is reusing, or hold unrelated uncommitted changes), so force-deleting it would risk destroying something this workflow doesn't own. Instead report its path and branch, call `ExitWorktree(action: "keep")` (safe in both cases), and let the user remove it manually when ready.
  - `implement/SKILL.md` description updated to mention the worktree step.
- **Domain docs**: `.agent-docs/context.md` gains two terms under a new "Isolation" subheading — `Worktree session` and `Placeholder branch`.

## Testing Decisions

- Skills here are Markdown instruction files with no automated test harness, consistent with the rest of this repo (e.g. the `init-agent-docs` specs).
- BDD scenarios act as the acceptance spec, verified manually by running the skill in a scratch repo:
  1. Standalone `/create-worktrees` in a repo with no existing worktrees and `.claude` already gitignored — creates a new `wip/<slug>` worktree directly.
  2. Standalone `/create-worktrees` in a repo missing the `.claude` gitignore entry — entry added and committed before the worktree is created.
  3. `/create-worktrees` run from inside an already-active worktree session — no-ops.
  4. `/create-worktrees` run when another worktree already exists — lists it and asks before proceeding.
  5. Full `/implement` run end-to-end on a throwaway change — worktree created first, `branch-hygiene` switches off the `wip/` placeholder (which is then deleted) once grill output is available, and the worktree is removed after `gh pr view` confirms `MERGED`.
- Prior art: `init-agent-docs`'s scratch-repo verification pattern (Read → apply → verify by inspection) is the template for scenarios 1–4.

## Out of Scope

- Automatic slug-based matching for worktree resume — resume is a list-and-ask, not a heuristic match.
- Special handling for abnormal session termination mid-`/implement` — the harness's existing session-exit keep/remove prompt is relied on as-is.
- Changing `worktree.baseRef` or any other harness worktree settings — the default (`fresh`, branching from `origin/<default-branch>`) already matches `branch-hygiene`'s own mismatch-resolution behaviour.
- An automated test runner or CI for skill files.

## Further Notes

- The harness ships `EnterWorktree`/`ExitWorktree` as built-in tools (worktrees live under `.claude/worktrees/`); this skill is a policy/orchestration layer on top of them, not a reimplementation.
- The post-commit sync hook in this repo propagates skill file changes to `~/.claude/skills/` automatically once committed.
