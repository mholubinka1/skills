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
Step 3  Record baseline Copilot review ID; poll every 60s:
        thread count > 0? ─────────────────────────────────────────► Step 4
        thread count = 0 + new Copilot review (IDs differ)? ───────► Step 8 (reviewed clean)
        Poll exhausted (no new review, 0 threads, 10 attempts)? ───► Step 8
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
gh pr create --base "$BASE" --title "<title>" --body "<summary and test plan>"
```

Note the PR number. Set `review_round = 1`. The first Copilot review triggers automatically.

## Step 3 — Poll for Copilot review threads

Before polling, capture the latest Copilot review ID as a baseline (empty if no review exists yet). Poll every 60 seconds (max 10 attempts): run the thread count check first; if > 0, exit to Step 4. If 0, check whether the latest Copilot review ID differs from the baseline — if yes, Copilot reviewed clean, go to Step 8 immediately. One final check after 10 attempts; if still no new clean review, go to Step 8. See the Poll for Copilot Review Threads section in [REFERENCE.md](REFERENCE.md) for the queries.

## Step 4 — Decide and apply changes

For each unresolved thread decide **Fix** or **Push back** (push back on any file contained within `.agent-docs/` — Copilot is not a domain expert there); apply code changes; see the Address Each Comment section in [REFERENCE.md](REFERENCE.md) for fetch query and reply commands.

## Step 4b — Validate changes with code-review

If at least one fix was applied, run `code-review` Steps 1–5 only — pass the explicit instruction to stop after Step 5 to avoid re-invoking this skill. Skip if all decisions were push-backs.

## Step 4c — Reply and resolve threads

Reply to each thread ("Fixed. ..." or "Ignored. ...") and immediately resolve via GraphQL — see the Address Each Comment section in [REFERENCE.md](REFERENCE.md) for the `resolveReviewThread` mutation. All push-backs → skip to Step 8; at least one fix → continue to Step 5.

## Step 5 — Commit and push

Stage files explicitly (`git add <file1> <file2> ...`), commit with `"address Copilot review: <summary>"`, push, confirm with `git log --oneline -3`. See the Staging Rules section in [REFERENCE.md](REFERENCE.md) for staging rules.

## Step 6 — Re-trigger Copilot (if within limit)

If `review_round >= 2`, skip to Step 8. Otherwise increment to 2 and re-trigger via `gh pr edit {number} --add-reviewer @copilot`. See the Re-trigger Copilot Review section in [REFERENCE.md](REFERENCE.md) if that command fails.

## Step 7 — Check for new threads

Re-capture the baseline Copilot review ID, then poll as in Step 3. New unresolved threads → return to Step 4. None (or clean review detected) → continue to Step 8.

## Step 8 — Report completion

```bash
gh pr view --json url --jq '.url'
```

Share the PR link with the user. The PR is ready to merge.
