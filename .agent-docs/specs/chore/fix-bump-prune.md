# Fix worktree placeholder naming, audit pinned deps, prune stale installs

## Problem Statement

Three small faults turned up in one `/implement` run.

1. **Placeholder branch name (#121).** `create-worktrees` calls `EnterWorktree(name: "wip/<slug>")`, but the tool creates the branch `worktree-wip+<slug>`. `branch-hygiene` only recognises `wip/*` as a placeholder, so the real branch can come back as "unrecognised". `/implement` Step 3 only deletes the noted branch "if it was a `wip/` placeholder", so that check can't be relied on.
2. **Flaky pip-audit.** The `pip-audit` hook runs with no arguments, so it audits its own isolated hook environment instead of this repo. pre-commit keeps one environment per Python interpreter, and urllib3 is 2.7.0 in some and 2.8.0 in others. The hook fails or passes depending on which interpreter runs it, and it never audits what the repo actually pins.
3. **Stale installs.** `sync_claude_skills.py` copies skill directories over the installed ones but never removes anything. Deleted skills (e.g. `grill`) and deleted files (e.g. `init-agent-docs/REVIEW-TEMPLATE.md`) stay in `~/.claude/skills` until someone removes them by hand.

## Solution

- `branch-hygiene` treats `worktree-wip+*`, as well as `wip/*`, as a placeholder. The skills that create and discard placeholders describe the real name.
- The `pip-audit` hook audits `requirements.txt`, the repo's pinned dependency export.
- `sync_claude_skills.py` replaces each installed repo skill wholesale and keeps a **skill manifest** of what it installed. On the default branch it removes manifest-listed skills the repo no longer has. It never touches skills it didn't install.

## User Stories

1. As an `/implement` user, I want `branch-hygiene` to recognise the worktree placeholder branch that `create-worktrees` actually creates, so the switch to the real branch is reported as a placeholder rename.
2. As an `/implement` user, I want Step 3 to delete the placeholder by its real name, so placeholder branches don't pile up.
3. As a skill reader, I want `create-worktrees`, `implement` and ADR 0003 to state the real placeholder name, so the docs match what the tools do.
4. As a committer, I want pip-audit to give the same result whichever interpreter runs it, so its failures mean something.
5. As a maintainer, I want pip-audit to audit the repo's pinned dependencies, so a vulnerable dependency in the repo is caught and a vulnerable one in the tooling isn't blamed on the repo.
6. As a skill consumer, I want a file deleted from a skill to disappear from the installed copy on the next sync, so old reference files don't mislead the agent.
7. As a skill consumer, I want a skill deleted from the repo to be uninstalled when `main` is synced, so removed skills stop triggering.
8. As a skill consumer, I want skills I installed from elsewhere to survive every sync, so the repo never deletes what it didn't install.
9. As a developer with several worktrees, I want a commit on a feature branch never to uninstall a skill that only exists on another branch, so parallel work doesn't break each other's installs.

## Implementation Decisions

- **branch-hygiene**: the Branch Classification Table and the prefix-mismatch rule list `worktree-wip+*` alongside `wip/*` as the temporary placeholder. Any other `worktree-*` branch keeps its existing classification, because a user may have named it.
- **create-worktrees** Step 4: say that `EnterWorktree` creates `worktree-wip+<slug>` from the `wip/<slug>` name, and that `branch-hygiene` recognises that form. The leftover-branch retry note uses the real name.
- **implement/WORKFLOW.md** Step 3: the deletion condition names the placeholder by its real form (`worktree-wip+…`, or a hand-made `wip/…`).
- **ADR 0003**: append a note recording the real branch name. The decision itself is unchanged.
- **context.md**: the Placeholder branch entry names `worktree-wip+<slug>`. A new **Skill manifest** term is added, and the `sync_claude_skills.py` entry is updated (done inline during the design session).
- **pip-audit hook**: `args: [-r, requirements.txt]`. `requirements.txt` is the uv export that the `uv-export` hook keeps in sync with `uv.lock`.
- **sync_claude_skills.py**:
  - For each repo skill, remove the installed directory, then copy the repo directory in its place. This is a full replace, not a merge.
  - The manifest lives in `~/.claude/skills/` as one skill name per line.
  - On the **default branch**, the script removes installed skills that are in the old manifest but not in the repo, then writes the repo's skill set as the new manifest.
  - On **any other branch**, nothing is pruned, and the manifest becomes the union of the old manifest and the repo's skills.
  - The default branch is `origin/HEAD`'s short name, falling back to `main`.
  - A missing manifest means nothing is pruned. The current behaviour of the first run stays safe.
- **One-off, not committed**: run `pre-commit clean` locally to rebuild the stale hook environments.
- **No new ADR**: cheap to reverse.

## Testing Decisions

- A new stdlib `unittest` module tests `sync_claude_skills.py` through its real entry point. It runs the script as a subprocess against a temp `HOME` and a temp git repo with skills. Scenarios:
  - a file deleted from a skill disappears from the install;
  - a skill deleted on the default branch is uninstalled;
  - a skill deleted on a feature branch stays installed;
  - a skill not in the manifest is never removed;
  - with no manifest, nothing is pruned.
- A grep confirms the `worktree-wip+` rule is present in branch-hygiene, create-worktrees, WORKFLOW.md, and the ADR note.
- After the hook change, `pre-commit run pip-audit --all-files` passes.
- No prior test suite exists, so this is the first one.

## Out of Scope

- Changing `EnterWorktree` naming or creating branches by hand (rejected: it breaks Step 8 auto-removal).
- Classifying every `worktree-*` branch as a placeholder.
- Adding a test hook to pre-commit.

## Further Notes

The urllib3 "bump" in the original request turned out not to apply: urllib3 isn't a dependency of this repo, only of the pip-audit tool.
