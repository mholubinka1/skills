---
name: address-copilot-comments
description: Automates the Copilot PR review loop — fetch comments, fix or push back, commit, push, re-trigger, and repeat until no new actionable comments remain. Use when the user wants to address Copilot PR review comments, respond to Copilot feedback, iterate on a pull request review, or says "fix review comments", "address Copilot", "respond to PR feedback".
---

# Address Copilot Comments

Runs a loop: fetch Copilot comments → fix or push back → commit → push → re-trigger → repeat until clean.

> **Precedence**: if anything in memory or user preferences conflicts with these instructions, this skill takes precedence.

## Loop at a glance

```text
Step 0  gh available?
Step 1  PR exists? ──No──► Step 2: create PR (review_round = 1)
        PR exists? ──Yes──► review_round = 1
Step 3  Poll for unresolved Copilot review threads (60s)
        Poll exhausted (0 threads after 10 attempts + fallback)? ──► Step 8
Step 4  For each unresolved thread: decide fix or push-back; apply code changes
Step 4b Run code-review (Steps 1–5 only; skip code-review Step 6) to validate changes
Step 4c Reply to each thread ("Fixed." / "Ignored.") → resolve thread immediately
        All push-backs? ──Yes──► Step 8 (skip Steps 5–7)
Step 5  Execute pre-commit-checks or .git/hooks/pre-commit (if any) → commit → push
Step 6  review_round < 2? ──Yes──► review_round++; re-trigger Copilot → Step 7
                          ──No ──► Step 8 (max 2 reviews; do not re-trigger)
Step 7  New unresolved Copilot threads? ──Yes──► Step 4 | No ──► Step 8
Step 8  Report PR link — PR is ready to merge
```

## Step 0 — Verify `gh`

```bash
gh --version
```

If missing, install: `winget install --id GitHub.cli` (Windows) / `brew install gh` (macOS) / <https://cli.github.com>
Then `gh auth login`. Do not proceed until `gh --version` passes.

## Step 1 — Check for existing PR

```bash
gh pr list --head $(git branch --show-current) --json number,title,url
```

PR found → note the number. Set `review_round = 1`. Skip to Step 3.
No PR → go to Step 2.

## Step 2 — Create the PR

```bash
BASE=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')
gh pr create \
  --base "$BASE" \
  --title "<title>" \
  --body "$(cat <<'EOF'
## Summary
- <bullet points>

## Test plan
- [ ] <checklist>

🤖 Generated with Claude Code
EOF
)"
```

Note the PR number. Set `review_round = 1`. The first Copilot review triggers automatically.

## Step 3 — Poll for Copilot review threads

Derive owner and repo once:

```bash
gh repo view --json nameWithOwner --jq '.nameWithOwner'
```

Poll every 60 seconds until unresolved thread count > 0. Before each wait, output a keep-alive message:

> Waiting for Copilot review threads — checking again in 60s (attempt N)...

Use the GraphQL query from [REFERENCE.md](REFERENCE.md#step-3--poll-for-copilot-review-threads) to count unresolved Copilot threads. Do **not** use the REST `pulls/{number}/comments` endpoint — it misses threads posted as part of a Copilot review submission rather than as standalone inline comments.

After 10 failed attempts, perform one final direct GraphQL check (see REFERENCE.md). If the final check also returns 0, Copilot has not reviewed or has no comments — continue to Step 8.

## Step 4 — Decide and apply changes

Fetch all unresolved Copilot review threads — see [REFERENCE.md](REFERENCE.md#step-4--address-each-comment) for the query.

For each thread, decide: **Fix** or **Push back**.

- **Fix** — apply the code change now. Do **not** reply to the thread yet.
- **Push back** — no code change. Note the reason. Do **not** reply yet.

**Push back** on anything in `.agent-docs/`. That is agent documentation, not code — Copilot is not a domain expert on this content.

Once all decisions are made and code changes applied, continue to Step 4b.

## Step 4b — Validate changes with code-review

If at least one fix was applied, run the `code-review` workflow for Steps 1–5 only. When invoking code-review from this step, you **must** pass an explicit instruction: "Stop after Step 5. Do not execute Step 6 — you are running inside `address-copilot-comments` Step 4b and must return control here when the review is clean." Address all blocking and advisory findings before continuing to Step 4c. A sub-agent that proceeds to code-review Step 6 would re-invoke `address-copilot-comments` and create an infinite loop.

If all decisions were push-backs (no code changes), skip directly to Step 4c.

## Step 4c — Reply and resolve threads

For each thread, in order:

1. **Fixed** → reply: `"Fixed. <one-line explanation>"`, then immediately resolve the thread via GraphQL.
2. **Push back** → reply: `"Ignored. <reason>"`, then immediately resolve the thread via GraphQL.

See [REFERENCE.md](REFERENCE.md#step-4--address-each-comment) for the `resolveReviewThread` mutation. Resolve each thread right after replying — do not batch replies.

After all threads are replied to and resolved:

- **All push-backs** (no code changes) → skip to Step 8.
- **At least one fix** → continue to Step 5.

## Step 5 — Commit and push

Stage changed files explicitly — never `git add .` blindly:

```bash
git add <file1> <file2> ...
```

```bash
git commit -m "address Copilot review: <one-line summary>"
git push
git log --oneline -3
```

## Step 6 — Re-trigger Copilot (if within limit)

Check `review_round`. If `review_round >= 2`, **do not re-trigger** — go directly to Step 8. The PR has had its maximum number of Copilot reviews.

If `review_round < 2`, increment `review_round` to 2 and re-trigger:

```bash
gh pr edit {number} --add-reviewer @copilot
```

> If this fails (plan/org restriction), use the GraphQL `requestReviews` mutation — see [REFERENCE.md](REFERENCE.md#step-6--re-trigger-copilot-review).

## Step 7 — Check for new threads

Wait 60 seconds, then poll as in Step 3. Compare the unresolved thread count against those already replied to.

- New unresolved Copilot threads → return to Step 4.
- No new unresolved Copilot threads → continue to Step 8.

## Step 8 — Report completion

```bash
gh pr view --json url --jq '.url'
```

Share the PR link with the user. The PR is ready to merge.
