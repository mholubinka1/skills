---
name: pr-cleanup
description: Post-merge cleanup — close GitHub issues for the current branch and check them off in .agent-docs/issues/<branch-name>.md. Use when a PR has been merged and issues need closing, or when invoked by /implement after the merge confirmation loop.
---

# PR Cleanup

Close GitHub issues and update the local issues file after a PR is merged.

## Process

### 1. Verify the PR is merged

Get the current branch:

```bash
git branch --show-current
```

Confirm the PR is actually merged before proceeding. Direct user or agent confirmation is not required; use the GitHub CLI to check the PR state:

```bash
gh pr view --head $(git branch --show-current) --json state --jq '.state'
```

If the state is not `MERGED`, stop and tell the user the PR has not been merged yet.

### 2. Read the local issues file

Read `.agent-docs/issues/<branch-name>.md`. Extract all GitHub issue numbers referenced in the file.

### 3. Close GitHub issues

For each issue number found:

```bash
gh issue close <number> --comment "Closed: merged via PR."
```

### 4. Check off items in the local issues file

Update `.agent-docs/issues/<branch-name>.md` — mark all acceptance criteria checkboxes as checked (`- [x]`) and add a closing note at the top of the file:

```md
> Merged and closed.
```

### 5. Report

List the closed issue numbers and confirm the local file is updated.
