---
name: pr-cleanup
description: Finalises a reviewed branch's PR so it is ready to merge. Use when a branch has passed review and its PR is ready to merge, or as the final step of /code-review.
allowed-tools:
  - Read
  - Edit
  - Bash(git branch --show-current)
  - Bash(gh pr view *)
  - Bash(git add .agent-docs/issues/*)
  - Bash(git commit *)
  - Bash(git push)
  - Bash(gh issue close *)
context: fork
agent: general-purpose
model: haiku
effort: low
background: false
---

# PR Cleanup

Commit final housekeeping to the PR branch, close GitHub issues, and share the PR link for merging.

## Process

### 1. Get the PR number

```bash
git branch --show-current
gh pr view --json number --jq '.number'
```

Note both outputs: the branch name is `<branch-name>` and the number is `<PR-number>` in the steps below. Shell variables do not survive from one Bash call to the next, so carry the two values yourself. `gh pr view` resolves the PR for the current branch and fails fast if none exists.

### 2. Update the local issues file

Read `.agent-docs/issues/<branch-name>.md`. Collect the issues this branch implements: the number on each slice's `**GitHub issue**: #<n>` line (older files spell the field `**GitHub**: #<n>`). Take numbers from those lines only. A number on a `**Blocked by**` line, or anywhere else in the file, is another branch's issue and is never closed here.

Mark all acceptance criteria checkboxes as checked (`- [x]`) and add a closing note at the top:

```md
> Work complete — PR ready to merge.
```

Done when no `- [ ]` remains in the file and the note is its first line. If the issues file does
not exist, there is nothing to commit or close: skip Steps 3 and 4, go to Step 5, and name the
missing file on the `Skipped / risk:` line.

### 3. Commit and push

Stage the issues file and commit with the message `"Close <branch-name> issues"` (substituting the real branch name from Step 1), then push the branch.

### 4. Close GitHub issues

For each issue number collected in Step 2:

```bash
gh issue close <number> --comment "Closed: implementation complete, see PR for review."
```

If Step 2 found no `**GitHub issue**` line, close nothing and say so on the `Skipped / risk:` line.

### 5. Share PR link

```bash
gh pr view <PR-number> --json url --jq '.url'
```

## Report

Reply with the PR URL, the issues closed, and one line, `Skipped / risk:`, naming anything
that failed (an issue that would not close, a push that was rejected).
