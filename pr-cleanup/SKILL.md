---
name: pr-cleanup
description: Pre-merge cleanup — check off acceptance criteria in .agent-docs/issues/<branch-name>.md, commit to the PR branch, close GitHub issues, and share the PR link for merging. Use when a branch has passed review and its PR is ready to merge, or as the final step of /code-review after the Copilot review loop.
---

# PR Cleanup

Commit final housekeeping to the PR branch, close GitHub issues, and share the PR link for merging.

## Process

### 1. Get the PR number

```bash
BRANCH=$(git branch --show-current)
gh pr view --json number --jq '.number'
```

Store the returned number — it is referenced as `<PR-number>` in the steps below. `gh pr view` resolves the PR for the current branch and fails fast if none exists.

### 2. Update the local issues file

Read `.agent-docs/issues/$BRANCH.md`. Extract all GitHub issue numbers referenced in the file. Mark all acceptance criteria checkboxes as checked (`- [x]`) and add a closing note at the top:

```md
> Work complete — PR ready to merge.
```

### 3. Commit and push

Stage the issues file and commit with the message `"Close <actual-branch-name> issues"` (substituting the real branch name from Step 1), then push the branch.

### 4. Close GitHub issues

For each issue number found in the issues file:

```bash
gh issue close <number> --comment "Closed: implementation complete, see PR for review."
```

### 5. Share PR link

```bash
gh pr view <PR-number> --json url --jq '.url'
```

Share the URL. The PR is ready to merge.
