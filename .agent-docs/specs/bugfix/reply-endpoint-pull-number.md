# Fix Reply Endpoint Pull Number

## Problem Statement

The reply command blocks in `address-copilot-comments/REFERENCE.md` use a GitHub API path that returns 404:

```bash
gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies
```

The working path requires the PR number:

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies
```

This causes every reply attempt in the `address-copilot-comments` loop to fail silently or with a 404 error, blocking the agent from acknowledging Copilot comments.

## Solution

Replace the broken path in both "Reply: fixed" and "Reply: push back" command blocks with the correct path that includes `{number}`.

## User Stories

1. As an agent running `address-copilot-comments`, I want the reply endpoint to work so that I can post "Fixed." and "Ignored." replies without getting a 404.

## Implementation Decisions

- Edit `address-copilot-comments/REFERENCE.md` only.
- Change `pulls/comments/{comment_id}/replies` to `pulls/{number}/comments/{comment_id}/replies` in both the "Reply: fixed" and "Reply: push back" blocks.
- No other lines change.

## Testing Decisions

- Verification is a read-through: both blocks must use the corrected path.
- No automated tests apply.

## Out of Scope

- Changes to `SKILL.md`.
- Any other section of `REFERENCE.md`.
