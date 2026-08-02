<!-- markdownlint-disable MD024 MD025 -->

# Issues: feature/create-worktrees-skill

## Add create-worktrees skill (#36)

**Blocked by**: None

**User stories**: 1, 3, 4, 5, 6, 7

### What to build

A new standalone skill, `create-worktrees` (`create-worktrees/SKILL.md` + `REFERENCE.md`), that gets a session into an isolated git worktree via the harness's `EnterWorktree`/`ExitWorktree` tools:

- Detects whether the session is already inside a linked worktree (`git rev-parse --git-dir` contains `worktrees/`) and no-ops if so.
- Lists existing worktrees (`git worktree list`, ignoring the main checkout) and asks the user which, if any, to resume via `EnterWorktree(path: ...)`.
- Ensures `.claude` is present in the target repo's `.gitignore`, adding and committing it as a standalone commit if missing, before any worktree is created.
- Creates a new worktree on a `wip/<slug>` placeholder branch (`EnterWorktree(name: "wip/<slug>")`), where the slug is a short kebab-case fragment of the trigger message.

Also update `.agent-docs/context.md` with two new terms under an "Isolation" subheading (`Worktree session`, `Placeholder branch`), and record `.agent-docs/adr/0003-worktree-created-before-branch-name-is-known.md` explaining the `wip/` placeholder decision.

### Acceptance criteria

- [x] Standalone `/create-worktrees` in a repo with no existing worktrees and `.claude` already gitignored creates a new `wip/<slug>` worktree directly.
- [x] Standalone `/create-worktrees` in a repo missing the `.claude` gitignore entry adds and commits the entry before creating the worktree.
- [x] `/create-worktrees` run from inside an already-active worktree session no-ops.
- [x] `/create-worktrees` run when another worktree already exists lists it and asks before proceeding.
- [x] `.agent-docs/context.md` has `Worktree session` and `Placeholder branch` terms.
- [x] ADR 0003 exists and explains the `wip/` placeholder decision.

---

## Wire create-worktrees into /implement (#37)

**Blocked by**: #36

**User stories**: 1, 2, 5

### What to build

Update `implement/WORKFLOW.md` to insert a new Step 0 that runs `create-worktrees` before `init-agent-docs`, since later steps (`init-agent-docs`, `grill`) can write to the repo and isolation must start before any file writes happen. Renumber all subsequent steps accordingly. Update Step 8 (merge) so that once `gh pr view --json state --jq '.state'` confirms `MERGED`, it removes the worktree — via `ExitWorktree(action: "remove", discard_changes: true)` when Step 0 created a fresh worktree this session, or via `git worktree remove --force` + `git branch -D` when Step 0 resumed an existing worktree or found the session already isolated, since `ExitWorktree` can't remove either of those. Update `implement/SKILL.md`'s description to mention the worktree step.

### Acceptance criteria

- [x] `implement/WORKFLOW.md` Step 0 runs `create-worktrees` before any other step.
- [x] All steps after the inserted Step 0 are renumbered correctly and internal cross-references (e.g. "Resume at the BDD loop (Step 6)") are updated to match.
- [x] Step 8 (merge) removes the worktree only after `MERGED` is confirmed, using `ExitWorktree(action: "remove", discard_changes: true)` for a freshly-created worktree and `git worktree remove --force` + `git branch -D` for a resumed or already-isolated one.
- [x] `implement/SKILL.md` description mentions the worktree step.
- [ ] Full `/implement` run end-to-end on a throwaway change: worktree created first, `branch-hygiene` switches off the `wip/` placeholder (which is then deleted) once grill output is available, and the worktree is removed after merge is confirmed.

---
