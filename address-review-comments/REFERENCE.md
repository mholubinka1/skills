# Address Review Comments — Reference

Full command detail for each step. Replace `{owner}`, `{repo}`, `{number}`, `{id}` with real values.

---

## Step 3 — Poll for Copilot comments

Run every 60 seconds until the count is greater than zero:

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments \
  --jq '[.[] | select(.in_reply_to_id == null) | select(.user.login == "Copilot")] | length'
```

Get `{owner}/{repo}` from:

```bash
gh repo view --json nameWithOwner --jq '.nameWithOwner'
```

---

## Step 4 — Address each comment

### Fetch all top-level Copilot comments

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments \
  --jq '.[] | select(.in_reply_to_id == null) | select(.user.login == "Copilot") | {id, path, line, body}'
```

### Reply: fixed

```bash
gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies \
  -X POST -f body="Fixed. <one-line explanation>"
```

### Reply: push back

```bash
gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies \
  -X POST -f body="Ignored. <reason>"
```

### Pre-commit hook (if the project uses .githooks)

```bash
bash .githooks/pre-commit
```

If it fails because a formatter modified files, stage the auto-formatted files and re-run.

### Resolve addressed threads via GraphQL

**Get unresolved thread node IDs:**

```bash
gh api graphql -f query='
query {
  repository(owner: "{owner}", name: "{repo}") {
    pullRequest(number: {number}) {
      reviewThreads(first: 20) {
        nodes { id isResolved }
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | .id'
```

**Resolve each thread (one call per ID):**

```bash
gh api graphql -f query='
mutation {
  resolveReviewThread(input: {threadId: "{id}"}) {
    thread { isResolved }
  }
}'
```

---

## Step 6 — Re-trigger Copilot review

### Option A — `gh pr edit` (most plans)

```bash
gh pr edit {number} --add-reviewer @copilot
```

### Option B — GraphQL `requestReviews` mutation (if Option A fails)

```bash
gh api graphql -f query='
mutation {
  requestReviews(input: {
    pullRequestId: "{pr_node_id}",
    userIds: [],
    union: false
  }) {
    pullRequest { title }
  }
}'
```

Get the PR node ID with:

```bash
gh api repos/{owner}/{repo}/pulls/{number} --jq '.node_id'
```

> Copilot reviewer availability depends on your GitHub plan and org settings.
> If neither option works, manually request a review from the GitHub UI.

---

## Staging rules

| Situation | Command |
|---|---|
| Stage specific files | `git add <file1> <file2> ...` |
| **Never** | `git add .` (stages untracked files including secrets, build artefacts) |

---

## Loop termination conditions

The loop is complete when **any** of these conditions is met:

1. **All push-backs in a round** — no code changes were made. Threads are already resolved after Step 4. Skip Steps 5 and 6; do not re-trigger Copilot. PR is ready to merge.
2. **No new actionable comments** after re-triggering — poll in Step 7 returns zero new top-level Copilot comments.

In both cases the PR is considered clean and ready to merge.
