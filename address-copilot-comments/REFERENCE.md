# Address Review Comments — Reference

Full command detail for each step. Replace `{owner}`, `{repo}`, `{number}`, `{id}` with real values.

---

## Step 2b — Decide whether Copilot review is required

### Fetch the diff

```bash
gh pr diff {number}
```

Reads the full diff content of every changed file, in one call — the classification below depends on what changed inside each file, not the file's extension.

### Classification rule

A diff is **review-required** if any changed file contains either of these:

- A functional code change — new or modified logic, control flow, or scripts.
- A step-logic edit to `SKILL.md` or `REFERENCE.md` — a new or changed bash/GraphQL command, a decisioning rule, a branching condition, or a mutation. Skill files in this repo are markdown, but their step logic is the executable behavior the harness runs — extension alone does not make them documentation.

A diff is **exempt** only if every changed file is one of these:

- Prose-only documentation — wording, explanation, or narrative changes that don't alter what a step does (e.g. `.agent-docs/context.md`, `README.md`, a clarifying sentence added to a skill file's prose without touching its commands or branching).
- No-logic config — value or formatting changes to config files (`*.json`, `*.yaml`, `*.toml`) that don't add or change a script.
- Formatting-only — whitespace, comment wording, or markdown formatting with no semantic change.

**Worked examples:**

| Diff | Classification |
|---|---|
| Only `.agent-docs/specs/*.md` and `.agent-docs/issues/*.md` changed | Exempt |
| `SKILL.md` changed, but only a step's prose explanation was reworded | Exempt |
| `SKILL.md` changed: a new `gh api` command added to a step | Review-required |
| One `.agent-docs/` file and one `*.py` script changed | Review-required (not every file is exempt) |

---

## Step 3 — Poll for Copilot review threads and suppressed comments

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

**Step A2 — Suppressed comments check.** Run every iteration alongside Step A — do not skip this because Step A already found threads. A round can have both real threads and suppressed comments at once, and Step 4 relies on this check having actually run to know about any suppressed entries. Fetch the latest Copilot review body and check for a `### Suppressed comments (N)` block:

```bash
REVIEW_BODY=$(gh api "repos/{owner}/{repo}/pulls/{number}/reviews?per_page=100" \
  --jq '[.[] | select(.user.login | test("copilot";"i"))] | last | .body // empty')

SUPPRESSED_COUNT=$(printf '%s' "$REVIEW_BODY" | grep -oE 'Suppressed comments \([0-9]+\)' | grep -oE '[0-9]+' | head -1)
SUPPRESSED_COUNT=${SUPPRESSED_COUNT:-0}
```

Suppressed comments have no `databaseId`/thread ID — they are markdown text embedded in the review body's collapsible `<details>` block (GitHub's Copilot reviewer folds some findings there instead of posting them as real review comments), not real PR review comments, so they never appear as `reviewThreads` and Step A's count reads 0 even when these exist.

**Decision.** If the Step A count > 0 **or** `SUPPRESSED_COUNT` > 0 — exit the poll loop and continue to Step 4, carrying forward `$REVIEW_BODY` for Step 4's suppressed-entry handling.

**Step B — Reviews check (only when thread count = 0 and suppressed count = 0).** Check whether the latest Copilot review ID has changed since the baseline was captured. This re-fetches the same reviews endpoint as Step A2 rather than reusing its result — `gh api --jq` uses `gh`'s bundled jq internally, but combining Step A2 and Step B's extractions into a single call would require piping through a standalone `jq` binary, which isn't guaranteed to be on `PATH` even where `gh` is. The extra request is the safer trade:

```bash
# Same query as baseline capture above — assigns to CURRENT_REVIEW_ID
CURRENT_REVIEW_ID=$(gh api "repos/{owner}/{repo}/pulls/{number}/reviews?per_page=100" \
  --jq '[.[] | select(.user.login | test("copilot";"i"))] | last | .id // empty')
```

Then:

If `CURRENT_REVIEW_ID` is non-empty and differs from `BASELINE_REVIEW_ID` — Copilot has submitted a new review with no actionable threads. **Go to Step 8 immediately.**

If `CURRENT_REVIEW_ID` equals `BASELINE_REVIEW_ID` (or is still empty) — no new review yet. Wait 60 seconds and repeat.

After 10 failed attempts (thread count still 0, suppressed count still 0, and no new review detected), perform one final pass of Steps A, A2, and B with the same queries. If the final pass also returns 0 threads, 0 suppressed comments, and no new review, Copilot has not yet reviewed or has nothing actionable — continue to Step 8.

---

## Step 4 — Address each comment and suppressed entry

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

### Suppressed comments (no thread ID)

Suppressed comments come from the same review body already fetched in Step A2 (`$REVIEW_BODY`) — re-fetch it here if it's out of scope. Read the `### Suppressed comments (N)` block directly rather than parsing it with a script: each entry starts with a bold `**path:line**` header line, followed by one or more `*` bullet lines with the finding text, and optionally a fenced code block quoting the affected file content. Treat each entry as its own finding — decide Fix or Push back exactly as for a thread (including the `.agent-docs/` push-back rule), and apply any code changes the same way.

Suppressed entries have no `threadId` or `comment_id` — the reply and resolve steps below apply only to real threads. Skip straight to the "Acknowledge suppressed comments" section for these instead.

### Reply: fixed

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies \
  -X POST -f body="Fixed. <one-line explanation>"
```

### Reply: push back

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies \
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

### Acknowledge suppressed comments

Suppressed comments have no per-comment reply target, so post one PR-level comment covering all of this round's suppressed entries once Fix/Push-back decisions have been made for the round — same timing as Step 4c's thread replies, before Step 5 commits and pushes:

```bash
gh pr comment {number} --body "$(cat <<'EOF'
Addressed this round's suppressed Copilot comments:

- path/to/file.md:158 — Fixed. <one-line explanation>
- path/to/other.json:1021 — Ignored. <reason>
EOF
)"
```

One line per suppressed entry, same "Fixed."/"Ignored." phrasing used for thread replies. Post this whenever suppressed comments existed this round, even if every decision (threads and suppressed comments together) was a push-back — see Loop termination conditions below.

---

## Step 6 — Re-trigger Copilot review

### Option A — `gh pr edit` (most plans)

```bash
gh pr edit {number} --add-reviewer '@copilot'
```

> In PowerShell, bare `@copilot` is parsed as a splat operator and consumed before arguments are passed to `gh`, so `gh` never receives the reviewer value and errors with `flag needs an argument: --add-reviewer`. Single-quote `'@copilot'` to prevent this.

### Option B — GraphQL `requestReviews` mutation (fallback if `gh pr edit` is unavailable)

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

0. **Exempt at Step 2b** — the PR's diff is docs-only, config-only, or trivial. No review requested, no poll, no `review_round` set. PR is ready to merge.
1. **All push-backs in a round** — no code changes were made. Threads are already resolved after Step 4c, and any suppressed comments are already acknowledged via the PR-level comment posted in Step 4d. Skip Steps 5–7; do not re-trigger Copilot. PR is ready to merge.
2. **Max reviews reached** — `review_round >= 2` at Step 6. Do not re-trigger. PR is ready to merge.
3. **Clean review or poll exhausted** — the Step 3 poll (or Step 7 re-poll) ends with zero unresolved threads and zero suppressed comments. Either a new Copilot review was detected with no comments (exits immediately to Step 8), or 10 attempts elapsed with no new review (falls through to Step 8).

In all cases the PR is considered clean and ready to merge.
