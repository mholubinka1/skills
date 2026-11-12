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

## Step 2b — Choose the review level

### Fetch the diff

```bash
gh pr diff {number}
```

This reads the full diff of every changed file in one call. The classification below depends on what changed inside each file, not on the file's extension.

Empty output is an empty diff only when `gh pr diff` exits 0. If it exits non-zero, for any reason (a diff too large for GitHub to return, or a network or auth error), fetch the file list instead:

```bash
gh pr view {number} --json files --jq '.files[] | "\(.additions)\t\(.deletions)\t\(.path)"'
```

Without the content, the PR is Lite at least, as for a binary file. It is Balanced if the list has 100 or more entries (it may be truncated), if the counts pass rule 6, or if any path hits a Balanced rule. If the file list fetch also fails, report the error and go to Step 7.

### Read the repo's listed paths

Before classifying, check the target repo's `.agent-docs/agent.md` for a `## Review levels` section. If it has one, note the paths it lists for Balanced rule 7. Each entry is a directory prefix or a glob, matched against the file's repo-relative path. In a glob, `*` stays within one directory and `**` crosses directories. If the file or the section doesn't exist, use rules 1–6 only.

### Classification rule

The Review level depends on two things: how bad a missed defect would be, and how hard it would be to spot from the diff alone. Lite catches obvious bugs and vulnerabilities visible in the changed lines. Balanced reasons across files and through complex logic.

- **None:** the change doesn't alter behaviour.
- **Lite:** behaviour changes, but a defect would stay local, be recoverable, and be visible in the diff.
- **Balanced:** a defect would be costly or irreversible, or would only show up by reasoning beyond the changed lines.

Give each changed file a level. The PR takes the highest level of any file. In a skill, the step logic of `SKILL.md`, `REFERENCE.md` and `WORKFLOW.md` is the behaviour the harness runs, so judge those files by what a step does, not as documentation.

#### Balanced: any one of these

1. **Security boundary:** authentication or permissions, handling untrusted input (parsing, validation, deserialisation), building SQL, shell or HTML from input, file paths from input, crypto, secrets, CORS/CSP. *Skills:* `allowed-tools`, or running input in a shell.
2. **Data integrity or irreversible actions:** schema migrations, deletes or backfills, writes to persistent stores, money, personal data. *Skills:* new or changed `gh api` writes, GraphQL mutations, `git push`, `gh gist edit`, deleting files.
3. **Concurrency and state:** async code, races, locks, retries and idempotency, transactions, caching and invalidation, scheduling and timers, dates and time zones. *Skills:* poll loops, retries, waits and their timeouts.
4. **Contract:** a public API, schema, event or message format, CLI flags, a library's exported interface, a config schema that others consume. *Skills:* an output format or path that another skill parses.
5. **Deploy and runtime:** CI/CD workflows, Dockerfiles, infra-as-code, production config, adding a new dependency (supply-chain risk). *Skills:* git hooks, and install or sync scripts.
6. **Large scope:** over about 300 changed logic lines, or logic changes across 5 or more modules.
7. **Repo-listed path:** a file under a path listed in the repo's `## Review levels` section. The list only ever moves a file up to Balanced, never down.

#### Lite

Any behaviour change that hits no Balanced rule: a feature or bug fix contained in one module, a refactor, new branching or error handling inside a function, moderate size. Also a major dependency version bump. *Skills:* step logic, guards, step ordering, decision rules, branching conditions.

#### None: every changed file is one of these

A file that hits any Balanced rule is Balanced, even when it also fits a bullet below. For example, a generated migration still hits rule 2.

- Docs, comments or formatting, including page copy and styling that change no logic.
- A test-only change.
- A rename or move with no content change.
- A generated file, other than a lockfile. Lockfiles follow the dependency rules: a lockfile whose versions change only by patch or minor, or not at all, is None. One with a major bump, direct or transitive, is Lite. One that adds a package is Balanced (rule 5).
- A patch or minor dependency bump that only changes a lockfile or a version pin in a dependency manifest.
- A config value tweak outside production or security config.
- A tiny edit of 10 lines or fewer, such as a message string, constant or typo, that changes no logic and no dependency version and hits no Balanced rule. A one-line guard change or major bump is still Lite.

*Skills:* reworded prose that doesn't change what a step does. The None list is exhaustive: a file that fits none of it is Lite at least.

#### Doubt and edge cases

- **None or a review:** when unsure, review.
- **Lite or Balanced:** doubt about rule 1 or 2 means Balanced. Any other doubt means Lite.
- **Tests never lower the level.** Tests added alongside a change leave that change's level as it is.
- **Empty diff, or renames only:** None. **A binary file added, changed or deleted:** Lite at least, because it can't be inspected.
- **Never** `MAX` or `AUTO`: `AUTO`'s cost is unpredictable, and Step 7 couldn't report the level it got.

Note the level and the rule that decided it (a Balanced rule number, the Lite category, or the None category). Step 7 reports both.

### Worked examples

| Change | Level |
|---|---|
| Dev-dependency patch bump, lockfile only (e.g. ruff) | None |
| Major dependency bump with no code change | Lite |
| New dependency added | Balanced (5) |
| Configure logging once at startup | Lite |
| Feature warning before a subscription renews or lapses (date logic) | Balanced (3) |
| The same warning, message text only | None at 10 lines or fewer, otherwise Lite |
| One validated entry point for app settings (config consumed elsewhere) | Balanced (4) |
| Dockerfile or CI workflow edit | Balanced (5) |
| Form handler taking user input or storing guest personal data | Balanced (1, 2) |
| Page copy or styling only | None |
| Only `.agent-docs/specs/*.md` and `.agent-docs/issues/*.md` | None |
| `SKILL.md` step prose reworded only | None |
| `SKILL.md` guard or termination condition changed (not a poll loop, retry or wait, which is rule 3) | Lite |
| `SKILL.md` gains a new `gh api` write | Balanced (2) |
| `allowed-tools` changed | Balanced (1) |
| Script output format another skill parses changes | Balanced (4) |
| 40 logic lines in one module | Lite |
| 350 logic lines, or logic across 5+ modules | Balanced (6) |

### Trigger Copilot Review

This is the only place Copilot is requested: once per invocation, when the Review level is Lite or Balanced. Always pass the effort explicitly. Without `reviewEffort`, the repository default applies, and the level reported at Step 7 would no longer be the level the review ran at. Send only `LITE` or `BALANCED`, never `MAX` or `AUTO`. The CLI's add-reviewer flag and the REST `requested_reviewers` endpoint take no effort parameter (checked 2026-11-10), so neither is used.

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
| `failureReason: REQUEST_CONFLICT`: a Copilot review is already pending | Step 3. That pending review is the one to poll. This run didn't set its effort, so Step 7 reports the level chosen and says that a review was already pending at an effort this run didn't set. |
| Any other `failureReason` (`ACTOR_INELIGIBLE`, `REPOSITORY_INELIGIBLE`, `APP_NOT_INSTALLED`, `NO_QUOTA_REMAINING`, `LICENSED_ORGANIZATION_UNAVAILABLE`), `success: false` with no reason, `null` or unparsable output, or a non-zero `gh` exit from either call (the node-ID fetch or the mutation) | Report the reason or error, then go to Step 7. No review was requested, so Step 7 leaves out "ready to merge". |

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
  nothing already actionable. The poll script (below) waits and checks again.
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

### Poll loop (every 60 seconds, 10 polls)

The waiting belongs to `scripts/poll-review-status.sh`, beside the status-check script. Never
run `sleep` between status checks yourself: a skipped wait ends the poll window early and
the review lands unread.

```bash
bash "<skill-base-dir>/scripts/poll-review-status.sh" {owner} {repo} {number} "{baseline_review_id}"
```

The baseline argument is required. Pass `""` when the baseline is empty; never drop it. Each
call makes up to 5 polls: it waits 60 seconds, runs the status check with the baseline, and
stops at the first result other than `PENDING`. It prints the last check's four lines, then
`POLLS_RUN=<n>`.

Ten polls are too long for one Bash call (600000 ms limit), so make two calls, each with a
Bash timeout of 600000 ms:

1. Call the poll script. `DECISION=ACTIONABLE`, `CLEAN` or `ERROR` → stop and return it.
2. On `PENDING`, call it once more with the same arguments and return that result.

Return `POLLS_RUN` as the two calls' values added together (0 when the capture call was
already `ACTIONABLE` and the poll script never ran). `PENDING` is a valid result only when
that total is 10: the main context treats a lower total as a failed poll. `DECISION=ERROR`
is never retried or counted as a `PENDING` poll. A Step 5b re-poll uses its given baseline
and skips the capture call.

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

Resolve only the `threadId`s named in the decisions you were handed. Never list the PR's
unresolved threads to find IDs: that list includes human reviewers' threads, which are not
this skill's to resolve.

**Resolve each decided thread (one call per `threadId`):**

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
