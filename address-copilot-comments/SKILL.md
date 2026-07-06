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
Step 1  PR exists? ──No──► Step 2: create PR
Step 3  Poll for Copilot comments (60s)
Step 4  Fix or push back each comment → resolve threads
        All push-backs? ──Yes──► Step 8 (skip Steps 5–7)
Step 5  Commit and push
Step 6  Re-trigger Copilot review
Step 7  Poll again → new comments? ──Yes──► Step 4 | No ──► Step 8
Step 8  Report PR link
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

PR found → note the number, skip to Step 3.
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

Note the PR number. The first Copilot review triggers automatically.

## Step 3 — Poll for comments

Derive owner and repo once:

```bash
gh repo view --json nameWithOwner --jq '.nameWithOwner'
```

Poll every 60 seconds until count > 0. Before each wait, output a keep-alive message so the UI does not appear frozen, e.g.:

> Waiting for Copilot review comments — checking again in 60s (attempt N)...

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments \
  --jq '[.[] | select(.in_reply_to_id == null) | select(.user.login == "Copilot")] | length'
```

## Step 4 — Address each comment

See [REFERENCE.md](REFERENCE.md#step-4--address-each-comment) for fetch, fix, push-back, and resolve-thread commands.

For each comment, work through this sequence in order:

1. Decide: **Fix** or **Push back**
   - **Fix** — make the code change, run pre-commit hooks, then reply: `"Fixed. <one-line explanation>"`
   - **Push back** — reply: `"Ignored. <reason>"`, no code change
2. **Immediately resolve the thread** via GraphQL — do not wait until all comments are done. Resolve each thread right after replying to it (see REFERENCE.md for the `resolveReviewThread` mutation).

Every addressed thread — whether fixed or pushed back — must be marked resolved before moving to the next comment. A reply without a resolve leaves the thread open and clutters the PR.

After addressing all comments, check whether any fixes were made:

- **All push-backs** (no code changes) → threads are resolved, skip to Step 8.
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

## Step 6 — Re-trigger Copilot

```bash
gh pr edit {number} --add-reviewer @copilot
```

> If this fails (plan/org restriction), use the GraphQL `requestReviews` mutation — see [REFERENCE.md](REFERENCE.md#step-6--re-trigger-copilot-review).

## Step 7 — Check for new comments

Wait 60 seconds, then poll as in Step 3. Compare newly fetched top-level Copilot comments against those already replied to.

- New unresolved comments → return to Step 4.
- No new actionable comments → continue to Step 8.

## Step 8 — Report completion

```bash
gh pr view --json url --jq '.url'
```

Share the PR link with the user. The PR is ready to merge.
