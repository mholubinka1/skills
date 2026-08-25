# Address Review Comments — Reference

Full command detail for each step. Replace `{owner}`, `{repo}`, `{number}`, `{id}` with real values.

---

## Common pitfalls

**`gh api --jq` does not accept jq's `--arg` flag.** They share a name but are unrelated —
`--jq` consumes exactly one token as its filter value. Writing `--arg foo "$bar" '<filter>'`
after it means `gh` takes `--arg` itself as that filter value, and `foo`, `"$bar"`, and the
real filter all become extra positional arguments to `gh api`, which only accepts one (the
API path) — so the failure is a `gh api` argument-count error, not a jq error:

```bash
# Doesn't work — "--arg" becomes --jq's filter value; foo, "$bar", and the real filter
# are then three extra positional args to `gh api`, which only accepts one:
gh api "repos/{owner}/{repo}/pulls/{number}/reviews" \
  --jq --arg foo "$bar" '.[] | select(.user.login == $foo)'
# fails with: accepts 1 arg(s), received 4

# Works — interpolate the shell value directly into the filter string instead:
gh api "repos/{owner}/{repo}/pulls/{number}/reviews" \
  --jq ".[] | select(.user.login == \"$bar\")"
```

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
- A step-logic edit to `SKILL.md`, `REFERENCE.md`, or `WORKFLOW.md` — a new or changed bash/GraphQL command, a decisioning rule, a branching condition, or a mutation. Skill files in this repo are markdown, but their step logic is the executable behavior the harness runs — extension alone does not make them documentation.

A diff is **exempt** only if every changed file is one of these:

- Prose-only documentation — wording, explanation, or narrative changes that don't alter what a step does (e.g. `.agent-docs/context.md`, `README.md`, a clarifying sentence added to a skill file's prose without touching its commands or branching).
- No-logic config — value or formatting changes to config files (`*.json`, `*.yaml`, `*.toml`) that don't add or change a script.
- Formatting-only — whitespace, comment wording, or markdown formatting with no semantic change.

### Worked examples

| Diff | Classification |
|---|---|
| Only `.agent-docs/specs/*.md` and `.agent-docs/issues/*.md` changed | Exempt |
| `SKILL.md` changed, but only a step's prose explanation was reworded | Exempt |
| `SKILL.md` changed: a new `gh api` command added to a step | Review-required |
| One `.agent-docs/` file and one `*.py` script changed | Review-required (not every file is exempt) |
| Diff is empty (no files changed, or rename/binary-only with no content diff) | Exempt — vacuously true that every changed file is exempt |

---

## Step 3 — Poll for Copilot review threads and suppressed comments

Get `{owner}/{repo}` from:

```bash
gh repo view --json nameWithOwner --jq '.nameWithOwner'
```

### The status-check script

Steps 3 and 7 both need the same three checks — unresolved Copilot threads, suppressed
comments folded into the review body, and whether a new review has landed — so both call one
bundled script rather than repeating the `gh api`/GraphQL/jq logic inline:
`scripts/check-review-status.sh`, resolved relative to **this skill's own base directory**
(the path shown as "Base directory for this skill" when `address-copilot-comments` was
invoked) — not the current working directory, which is the target repo being worked on:

```bash
bash "<skill-base-dir>/scripts/check-review-status.sh" {owner} {repo} {number} [baseline_review_id]
```

It prints four lines:

```text
THREAD_COUNT=<n>          (always numeric, including 0 on ERROR)
SUPPRESSED_COUNT=<n>      (always numeric, including 0 on ERROR)
CURRENT_REVIEW_ID=<id or empty>
DECISION=ACTIONABLE|CLEAN|PENDING|ERROR
```

- **`ACTIONABLE`** — `THREAD_COUNT` or `SUPPRESSED_COUNT` is non-zero. Exit the poll loop and
  go to Step 4.
- **`CLEAN`** — only possible when a `baseline_review_id` argument was supplied at all (even
  if that argument was itself an empty string, meaning no prior review existed at capture
  time): `CURRENT_REVIEW_ID` is non-empty and differs from the baseline, with nothing
  actionable. Copilot has reviewed and left nothing to address — go to Step 8 immediately.
- **`PENDING`** — no new review yet, or this was a no-baseline capture call (see below) with
  nothing already actionable. Wait 60 seconds and call again.
- **`ERROR`** — a `gh api` call itself failed (network, auth, or the PR/repo not found). Do
  not treat this as `PENDING` — stop polling and report the failure to the user instead of
  looping until exhaustion.

Exits 0 for any well-formed call, including `DECISION=ERROR` — branch on the `DECISION` line,
not the exit code. Exits 2 with a usage message on stderr for a malformed invocation (wrong
argument count, or an `{owner}`/`{repo}`/`{number}` that doesn't match GitHub's own identifier
charset).

### Capture baseline Copilot review ID (before the poll loop)

Run the script once before polling begins, with no `baseline_review_id` argument, and take
`CURRENT_REVIEW_ID` from its output as the baseline for every later call in this round:

```bash
bash "<skill-base-dir>/scripts/check-review-status.sh" {owner} {repo} {number}
```

If this first call already prints `DECISION=ACTIONABLE`, skip the poll loop entirely and go
straight to Step 4 — there's no need to wait when something is already there to address. An
empty `CURRENT_REVIEW_ID` means no Copilot review exists yet; any review that appears during
polling is considered new.

### Poll loop (every 60 seconds, max 10 attempts)

Call the script again on each iteration, passing the baseline captured above:

```bash
bash "<skill-base-dir>/scripts/check-review-status.sh" {owner} {repo} {number} {baseline_review_id}
```

`DECISION=ACTIONABLE` → exit the poll loop and continue to Step 4. `DECISION=CLEAN` → go to
Step 8 immediately. `DECISION=PENDING` → wait 60 seconds and repeat. `DECISION=ERROR` → stop
polling immediately and report the failure to the user — do not count it as a `PENDING`
attempt or keep retrying silently.

After 10 `PENDING` attempts, call the script one final time with the same arguments. If that
final call is still `PENDING`, Copilot has not yet reviewed or has nothing actionable —
continue to Step 8.

Suppressed comments have no `databaseId`/thread ID — they are markdown text embedded in the
review body's collapsible `<details>` block (GitHub's Copilot reviewer folds some findings
there instead of posting them as real review comments), not real PR review comments, so they
never appear as `reviewThreads` and `THREAD_COUNT` reads 0 even when these exist. That's why
the script checks both counts on every call rather than treating one as a fallback for the
other — a round can have both real threads and suppressed comments at once.

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

`check-review-status.sh` reports only the suppressed-comment *count*, not their text — fetch the review body itself here:

```bash
gh api "repos/{owner}/{repo}/pulls/{number}/reviews?per_page=100" \
  --jq '[.[] | select(.user.login | test("copilot";"i"))] | last | .body // empty'
```

Read the `### Suppressed comments (N)` block directly rather than parsing it with a script: each entry starts with a bold `**path:line**` header line, followed by one or more `*` bullet lines with the finding text, and optionally a fenced code block quoting the affected file content. Treat each entry as its own finding — decide Fix or Push back exactly as for a thread (including the `.agent-docs/` push-back rule), and apply any code changes the same way.

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

The loop (Steps 3–7) never starts at all if Step 2b judges the diff exempt — docs-only, config-only, or trivial. No review requested, no poll, no `review_round` set. PR is ready to merge.

Otherwise, the loop is complete when **any** of these conditions is met:

1. **All push-backs in a round** — no code changes were made. Threads are already resolved after Step 4c, and any suppressed comments are already acknowledged via the PR-level comment posted in Step 4d. Skip Steps 5–7; do not re-trigger Copilot. PR is ready to merge.
2. **Max reviews reached** — `review_round >= 2` at Step 6. Do not re-trigger. PR is ready to merge.
3. **Clean review or poll exhausted** — the Step 3 poll (or Step 7 re-poll) ends with zero unresolved threads and zero suppressed comments. Either a new Copilot review was detected with no comments (exits immediately to Step 8), or 10 attempts elapsed with no new review (falls through to Step 8).

In all cases the PR is considered clean and ready to merge.
