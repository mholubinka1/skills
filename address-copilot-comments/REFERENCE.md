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

Copilot reviews at Balanced effort, so a review is spent only where the risk justifies it. A diff is **review-required** if it hits **any** of these:

1. **Trust-boundary change** — auth, permissions, secrets handling, CI workflows, dependency manifests or lockfiles, or anything that executes input in a shell.
2. **External mutation** — a new or changed command that writes outside the working tree: `gh api` writes, GraphQL mutations, `git push`, `gh gist edit`, file deletion.
3. **Control-flow change** — new or changed branching, guards, loop termination, step ordering, or error handling. In `SKILL.md`, `REFERENCE.md` and `WORKFLOW.md` this includes decisioning rules and branching conditions: their step logic is the executable behaviour the harness runs, so extension alone does not make them documentation.
4. **Contract change** — an interface, flag, output format or path that other files or callers depend on.
5. **Non-trivial scope** — more than about 30 changed logic lines, or logic changes across 3 or more files.

A diff is **low-risk (skip the review)** only if every changed file is one of these:

- Prose, formatting or comment-only — wording or markdown formatting that doesn't alter what a step does.
- A config value tweak (any config format, e.g. `*.json`, `*.yaml`, `*.yml`, `*.toml`, `*.ini`) that doesn't add or change a script.
- A test-only change (added or edited tests) that touches no production logic.
- A rename or move with no content change.
- A tiny isolated tweak — 10 or fewer lines in one file, such as a message string, constant or typo — that matches none of criteria 1–4.

A file that hits criteria 1–5 is review-required even when it fits a category above (e.g. a CI workflow `*.yml` is config but also a trust boundary). The low-risk list is exhaustive: anything not on it — including a logic change of 11–30 lines that hits none of criteria 1–5 — is review-required. **When unsure, trigger.** Doubt about whether a criterion applies counts as a hit.

### Worked examples

| Diff | Classification |
|---|---|
| Only `.agent-docs/specs/*.md` and `.agent-docs/issues/*.md` changed | Skip |
| `SKILL.md` changed, but only a step's prose explanation was reworded | Skip |
| One-line typo or message-string fix in a script | Skip |
| `SKILL.md` changed: a new `gh api` write added to a step | Review (criterion 2) |
| A guard or termination condition changed in a step | Review (criterion 3) |
| `uv.lock` or a dependency manifest changed | Review (criterion 1) |
| A script's output format changed that another skill parses | Review (criterion 4) |
| 40 changed logic lines in a single file | Review (criterion 5) |
| Logic changes spread across 3 files | Review (criterion 5) |
| One `.agent-docs/` file plus a change hitting any criterion | Review (not every file is low-risk) |
| Unsure whether a change touches a contract | Review (when unsure, trigger) |
| Diff is empty (no files changed), or a rename with no content change | Skip — vacuously true that every changed file is low-risk |
| A binary file was added, changed or deleted | Review (uninspectable; when unsure, trigger) |

### Trigger Copilot Review

This is the only place Copilot is requested: once per invocation, when the Review level is Lite or Balanced. Always pass the effort explicitly. Without `reviewEffort`, the repository default applies, and the level reported at Step 7 would no longer be the level the review ran at. Send only `LITE` or `BALANCED`, never `MAX` or `AUTO`. Every other way of adding Copilot as a reviewer, whether from the CLI or the REST API, takes no effort parameter, so none of them is used.

Get the PR node ID, then request the review with `{effort}` set to `LITE` or `BALANCED`:

```bash
gh api repos/{owner}/{repo}/pulls/{number} --jq '.node_id'

gh api graphql \
  -f query='mutation($pr: ID!, $effort: CopilotCodeReviewEffort!) {
    requestCopilotCodeReview(input: {pullRequestId: $pr, reviewEffort: $effort}) {
      success
      failureReason
    }
  }' \
  -f pr='{pr_node_id}' -f effort='{effort}' \
  --jq '.data.requestCopilotCodeReview'
```

Pass the values as variables, as shown. `$pr` and `$effort` sit inside single quotes, so neither Bash nor PowerShell expands them.

#### Result

| Result | Next |
|---|---|
| `success: true` | Step 3 |
| `failureReason: REQUEST_CONFLICT`: a Copilot review is already pending | Step 3. That pending review is the one to poll. |
| Any other `failureReason` (`ACTOR_INELIGIBLE`, `REPOSITORY_INELIGIBLE`, `APP_NOT_INSTALLED`, `NO_QUOTA_REMAINING`, `LICENSED_ORGANIZATION_UNAVAILABLE`), `success: false` with no reason, or a non-zero `gh` exit (GraphQL or network error) | Report the reason or error, then go to Step 7. No review was requested, so Step 7 leaves out "ready to merge". |

---

## Step 3 — Poll for Copilot review threads and suppressed comments

Get `{owner}/{repo}` from:

```bash
gh repo view --json nameWithOwner --jq '.nameWithOwner'
```

### The status-check script

Step 3 needs the same three checks — unresolved Copilot threads, suppressed
comments folded into the review body, and whether a new review has landed — so it calls one
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

- **`ACTIONABLE`** — `THREAD_COUNT` or `SUPPRESSED_COUNT` is non-zero. Exit the poll loop.
- **`CLEAN`** — only possible when a `baseline_review_id` argument was supplied at all (even
  if that argument was itself an empty string, meaning no prior review existed at capture
  time): `CURRENT_REVIEW_ID` is non-empty and differs from the baseline, with nothing
  actionable. Copilot has reviewed and left nothing to address.
- **`PENDING`** — no new review yet, or this was a no-baseline capture call (see below) with
  nothing already actionable. Wait 60 seconds and call again.
- **`ERROR`** — a `gh api` call itself failed (network, auth, or the PR/repo not found). Do
  not treat this as `PENDING` — stop polling and return the `gh` error.

Exits 0 for any well-formed call, including `DECISION=ERROR` — branch on the `DECISION` line,
not the exit code. Exits 2 with a usage message on stderr for a malformed invocation (wrong
argument count, or an `{owner}`/`{repo}`/`{number}` that doesn't match GitHub's own identifier
charset).

### Capture baseline Copilot review ID (before the poll loop)

Run the script once before polling begins, with no `baseline_review_id` argument, and take
`CURRENT_REVIEW_ID` from its output as the baseline for every later call in this invocation:

```bash
bash "<skill-base-dir>/scripts/check-review-status.sh" {owner} {repo} {number}
```

If this first call already prints `DECISION=ACTIONABLE`, skip the poll loop entirely. An
empty `CURRENT_REVIEW_ID` means no Copilot review exists yet; any review that appears during
polling is considered new.

### Poll loop (every 60 seconds, max 10 attempts)

The baseline call, 10 polls and the final check are 12 script calls, too long for one Bash
call (600000 ms limit). Run them in two Bash calls of at most 6 script calls each — baseline
and 5 polls, then 5 polls and the final check — with `sleep 60` between script calls and at
the start of the second Bash call, and a Bash timeout of 600000 ms. Stop early on any result
other than `PENDING`. A Step 5b re-poll uses its given baseline and skips the capture call.

Call the script again on each iteration, passing the baseline captured above:

```bash
bash "<skill-base-dir>/scripts/check-review-status.sh" {owner} {repo} {number} {baseline_review_id}
```

`DECISION=ACTIONABLE` or `CLEAN` → exit the poll loop. `DECISION=PENDING` → wait 60 seconds
and repeat. `DECISION=ERROR` → stop polling immediately and return the failure — do not count
it as a `PENDING` attempt or keep retrying silently.

After 10 `PENDING` attempts, call the script one final time with the same arguments. If that
final call is still `PENDING`, Copilot has not yet reviewed or has nothing actionable.

Suppressed comments have no `databaseId`/thread ID — they are markdown text embedded in the
review body's collapsible `<details>` block (GitHub's Copilot reviewer folds some findings
there instead of posting them as real review comments), not real PR review comments, so they
never appear as `reviewThreads` and `THREAD_COUNT` reads 0 even when these exist. That's why
the script checks both counts on every call rather than treating one as a fallback for the
other — a poll can return both real threads and suppressed comments at once.

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
  --jq '[.[] | select((.user.login // "") | test("copilot";"i"))] | last | .body // empty'
```

Read the `### Suppressed comments (N)` block directly rather than parsing it with a script: each entry starts with a bold `**path:line**` header line, followed by one or more `*` bullet lines with the finding text, and optionally a fenced code block quoting the affected file content. Each entry is its own finding.

Suppressed entries have no `threadId` or `comment_id`, so the reply and resolve subsections apply only to real threads; these get the "Acknowledge suppressed comments" subsection instead.

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

Suppressed comments have no per-comment reply target, so post one PR-level comment covering all of this invocation's suppressed entries once Fix/Push-back decisions have been made for the invocation — same timing as Step 5's thread replies: after its commit and push succeed, or straight away when no fix was made:

```bash
gh pr comment {number} --body "$(cat <<'EOF'
Addressed this invocation's suppressed Copilot comments:

- path/to/file.md:158 — Fixed. <one-line explanation>
- path/to/other.json:1021 — Ignored. <reason>
EOF
)"
```

One line per suppressed entry, same "Fixed."/"Ignored." phrasing used for thread replies. Post this whenever suppressed comments existed this invocation, even if every decision (threads and suppressed comments together) was a push-back.

---

## Distil review criteria (Step 6)

### What generalising looks like

A fixed finding names a specific mistake in a specific place. The criterion is the reusable
shape of it. Strip, in order: the file path, the line number, the concrete identifier or
literal value, and the specific tool or command — keep the failure mode and the check that
catches it. Read the `code-review` skill's `CRITERIA-STYLE.md` and write every entry to its
rules — one defect per entry, a label naming the defect, then trigger, consequence, and fix in
30–60 words. The one exception is its "generic, not traceable to a source" rule: in the gist,
end each entry with `(repo#PR)` — the current repo's name (not the full `owner/repo`, just the
repo name: `gh repo view --json name -q .name`) and the current PR number. The tag is removed
when the entry is collated.

| Fixed finding (specific) | Criterion (general) |
|---|---|
| `install.sh` checked `hooks/pre-commit` only and missed a needed `hooks/post-commit` | `- **Partial checks for compound state**: flag a readiness check that inspects one artefact when the state it gates has several parts — the operation proceeds with the unchecked parts missing. Check every part the operation needs. (acme-api#58)` |
| A `git pull` error message asserted "history has diverged" when a network failure hits the same path | `- **Single-cause error text**: flag an error message that names one cause when the same failure has several — the reader chases the named cause while the real one goes unfixed. Name every likely cause, or none. (acme-api#58)` |

### Dedupe

Start the "Appending an entry" procedure in `code-review/CRITERIA-GIST.md` now, but stop
after its fetch step (step 1) —
that gist content is what you compare each candidate against here: match on meaning rather
than wording, and skip any that a current entry already covers. Carry that same fetched
content forward into "Writing the gist" rather than fetching it again. Dedupe against the gist
only: the `code-review` skill's `REVIEW-CRITERIA.md` is a separate, curated list, and a little
overlap between the two is acceptable.

### Writing the gist

Read the gist ID from `code-review/CRITERIA-GIST.md` (this skill's sibling `code-review`
skill directory — do not paste a copy of that ID here), then append the surviving criteria
using the "Appending an entry" procedure documented there.

If dedupe removed every candidate, skip this step entirely — make no gist write. This is a
live network write to a resource outside the target repo; there is nothing to `git add`,
commit, or push for it. If the fetch or the write fails — no network, `gh` not authenticated,
the gist unreachable — report the failure plainly and continue to Step 7 regardless; there is
no local file at risk here, so a failed write simply means this run's criteria go
unrecorded rather than being lost from something that already existed.

---

## Staging rules

| Situation | Command |
|---|---|
| Stage specific files | `git add <file1> <file2> ...` |
| **Never** | `git add .` (stages untracked files including secrets, build artefacts) |
