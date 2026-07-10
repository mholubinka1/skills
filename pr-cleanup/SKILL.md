---
name: pr-cleanup
description: Pre-merge cleanup — check off acceptance criteria in .agent-docs/issues/<branch-name>.md, commit to the PR branch, close GitHub issues, and share the PR link for merging. Invoked automatically by /code-review after the Copilot review loop.
---

# PR Cleanup

Commit final housekeeping to the PR branch, close GitHub issues, and share the PR link for merging.

## Process

### 1. Get the PR number

```bash
git branch --show-current
gh pr list --head <branch> --json number --jq '.[0].number'
```

### 2. Update the local issues file

Read `.agent-docs/issues/<branch-name>.md`. Mark all acceptance criteria checkboxes as checked (`- [x]`).

### 3. Commit and push

Stage the issues file and commit with the message `"Close <branch-name> issues"`.

### 4. Share PR link

```bash
gh pr view <number> --json url --jq '.url'
```

Share the URL. The PR is ready to merge.
