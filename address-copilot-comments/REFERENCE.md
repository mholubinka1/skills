# Address Review Comments — Reference

Full command detail for each step. Replace `{owner}`, `{repo}`, `{number}`, `{id}` with real values.

---

## Step 3 — Poll for Copilot review threads

Get `{owner}/{repo}` from:

```bash
gh repo view --json nameWithOwner --jq '.nameWithOwner'
```

Run every 60 seconds until the count is greater than zero. Use GraphQL — the REST `pulls/{number}/comments` endpoint misses threads posted as part of a review submission:

```bash
gh api graphql -f query='
query {
  repository(owner: "{owner}", name: "{repo}") {
    pullRequest(number: {number}) {
      reviewThreads(first: 100) {
        nodes {
          isResolved
          comments(first: 1) {
            nodes { author { login } }
          }
        }
      }
    }
  }
}' --jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | select(.comments.nodes[0].author.login == "Copilot")] | length'
```

After 10 failed attempts (count still 0), perform one final direct check with the same query. If the final check also returns 0, Copilot has not reviewed or has nothing actionable — continue to Step 8.

---

## Step 4 — Address each comment

### Fetch all unresolved Copilot review threads

```bash
gh api graphql -f query='
query {
  repository(owner: "{owner}", name: "{repo}") {
    pullRequest(number: {number}) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          comments(first: 10) {
            nodes {
              author { login }
              body
              path
              line
            }
          }
        }
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | select(.comments.nodes[0].author.login == "Copilot") | {id, path: .comments.nodes[0].path, line: .comments.nodes[0].line, body: .comments.nodes[0].body}'
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

### Resolve the thread — do this immediately after replying, one thread at a time

**Get unresolved thread node IDs:**

```bash
gh api graphql -f query='
query {
  repository(owner: "{owner}", name: "{repo}") {
    pullRequest(number: {number}) {
      reviewThreads(first: 100) {
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

1. **All push-backs in a round** — no code changes were made. Threads are already resolved after Step 4c. Skip Steps 5–7; do not re-trigger Copilot. PR is ready to merge.
2. **Max reviews reached** — `review_round >= 2` at Step 6. Do not re-trigger. PR is ready to merge.
3. **No new unresolved threads** after re-triggering — poll in Step 7 returns zero unresolved Copilot threads.

In all cases the PR is considered clean and ready to merge.
