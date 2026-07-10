# Address Review Comments — Reference

Full command detail for each step. Replace `{owner}`, `{repo}`, `{number}`, `{id}` with real values.

---

## Step 3 — Poll for Copilot review threads

Get `{owner}/{repo}` from:

```bash
gh repo view --json nameWithOwner --jq '.nameWithOwner'
```

### Capture baseline Copilot review ID (before the poll loop)

Run once before polling begins. Records the latest Copilot review ID so the loop can detect when a new review is submitted.

```bash
BASELINE_REVIEW_ID=$(gh api "repos/{owner}/{repo}/pulls/{number}/reviews?per_page=100" \
  --jq '[.[] | select(.user.login | test("copilot";"i"))] | last | .id // empty')
```

Empty result means no Copilot review exists yet — any review that appears during polling is considered new.

### Poll loop (every 60 seconds, max 10 attempts)

**Step A — Thread count check.** Use GraphQL — the REST `pulls/{number}/comments` endpoint misses threads posted as part of a review submission:

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
}' --jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | select(.comments.nodes[0].author.login | test("copilot"; "i"))] | length'
```

If count > 0 — exit the poll loop and continue to Step 4.

**Step B — Reviews check (only when thread count = 0).** Check whether the latest Copilot review ID has changed since the baseline was captured:

```bash
# Same query as baseline capture above — assigns to CURRENT_REVIEW_ID
CURRENT_REVIEW_ID=$(gh api "repos/{owner}/{repo}/pulls/{number}/reviews?per_page=100" \
  --jq '[.[] | select(.user.login | test("copilot";"i"))] | last | .id // empty')
```

Then:

If `CURRENT_REVIEW_ID` is non-empty and differs from `BASELINE_REVIEW_ID` — Copilot has submitted a new review with no actionable threads. **Go to Step 8 immediately.**

If `CURRENT_REVIEW_ID` equals `BASELINE_REVIEW_ID` (or is still empty) — no new review yet. Wait 60 seconds and repeat.

After 10 failed attempts (thread count still 0 and no new review detected), perform one final pass of Steps A and B with the same queries. If the final pass also returns 0 threads and no new review, Copilot has not yet reviewed or has nothing actionable — continue to Step 8.

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
          comments(first: 1) {
            nodes {
              author { login }
              body
              path
              line
              databaseId
            }
          }
        }
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | select(.comments.nodes[0].author.login | test("copilot"; "i")) | {threadId: .id, comment_id: .comments.nodes[0].databaseId, path: .comments.nodes[0].path, line: .comments.nodes[0].line, body: .comments.nodes[0].body}'
```

The query returns two IDs per thread — use the right one for each operation:

- `threadId` (`PRRT_...` node ID) — used with `resolveReviewThread` GraphQL mutation
- `comment_id` (numeric `databaseId`) — used with the REST reply endpoint below

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
3. **Clean review or poll exhausted** — the Step 3 poll (or Step 7 re-poll) ends with zero unresolved threads. Either a new Copilot review was detected with no comments (exits immediately to Step 8), or 10 attempts elapsed with no new review (falls through to Step 8).

In all cases the PR is considered clean and ready to merge.
