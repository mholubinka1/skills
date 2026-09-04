---
name: address-copilot-comments
description: Automates the Copilot PR review loop — fetch comments, fix or push back, commit, push, re-trigger, repeat until no new actionable comments remain. Use when the user wants to address Copilot PR review feedback, or says "fix review comments" or "address Copilot".
---

# Address Copilot Comments

Runs a loop: fetch Copilot comments → fix or push back → commit → push → re-trigger → repeat until clean.

> **Precedence**: if anything in memory or user preferences conflicts with these instructions, this skill takes precedence.

## Loop at a glance

```text
Step 0  gh available?
Step 1  PR exists? ──No──► Step 2: create PR ──► Step 2b
        PR exists? ──Yes──► Step 2b
Step 2b Read PR diff (`gh pr diff`); review-required?
        No (exempt: docs/config/trivial only) ──► Step 8 (no trigger, no poll)
        Yes (functional code or skill step-logic) ──► trigger Copilot; review_round = 1 ──► Step 3
Step 3  Record baseline Copilot review ID; poll every 60s, max 10:
        threads or suppressed comments > 0? ─────────► Step 4
        new review, nothing actionable? ────────────► Step 7b (reviewed clean)
        exhausted? one final check, same branching ──► Step 4 or Step 7b
Step 4  For each unresolved thread and each suppressed-comment entry: decide fix or push-back; apply code changes
Step 4b Run code-review (Steps 1–5 only; skip code-review Step 6) to validate changes
Step 4c Reply to each thread ("Fixed." / "Ignored.") → resolve thread immediately
Step 4d Suppressed comments this round? ──Yes──► post one PR comment summarizing fix/ignore outcomes
        All push-backs (threads + suppressed)? ──Yes──► Step 7b (skip Steps 5–7)
Step 5  Execute pre-commit-checks or .git/hooks/pre-commit (if any) → commit → push
Step 6  review_round < 2? ──Yes──► review_round++; re-trigger Copilot → Step 7
                          ──No ──► Step 7b (max 2 reviews; do not re-trigger)
Step 7  Re-capture baseline; poll as in Step 3:
        threads or suppressed comments? ──► Step 4 | clean or exhausted? ──► Step 7b
Step 7b Not exempt and ≥1 Fix applied this invocation? ──► generalise each fixed finding,
        dedupe against .agent-docs/review.md, append, commit + push. Else ──► Step 8
Step 8  Report PR link — PR is ready to merge
```

## Step 0 — Verify `gh`

```bash
gh --version
```

If missing, install (`winget install --id GitHub.cli` / `brew install gh` / <https://cli.github.com>) then `gh auth login`. Do not proceed until `gh --version` passes.

## Step 1 — Check for existing PR

```bash
gh pr list --head $(git branch --show-current) --json number,title,url
```

PR found → note the number, continue to Step 2b. No PR → go to Step 2.

## Step 2 — Create the PR

```bash
BASE=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')
gh pr create --base "$BASE" --title "<title>" --body "<summary and test plan>"
```

Note the PR number. Continue to Step 2b.

## Step 2b — Decide whether Copilot review is required

GitHub no longer auto-triggers a Copilot review on PR creation, so this step decides whether the PR needs one and requests it explicitly. Fetch the full diff content — the decision depends on what changed, not the file extension:

```bash
gh pr diff {number}
```

See the Decide Whether Copilot Review Is Required section in [REFERENCE.md](REFERENCE.md) for the classification rule and worked examples.

**Review-required** → trigger via the same command Step 6 uses (see the Re-trigger Copilot Review section in [REFERENCE.md](REFERENCE.md)); set `review_round = 1`; continue to Step 3.
**Exempt** → skip straight to Step 8. Do not trigger, do not set `review_round`, do not poll.

## Step 3 — Poll for Copilot review threads and suppressed comments

The thread-count and suppressed-comments checks (a round can have both) run via one bundled script — see the status-check script section in [REFERENCE.md](REFERENCE.md). Before polling, capture the latest Copilot review ID as a baseline by calling the script once with no baseline argument (empty if no review exists yet; if this call already reports something actionable, skip straight to Step 4).

Poll every 60 seconds, max 10 attempts, calling the script again each time: an actionable result exits to Step 4; a clean result (a new review with nothing to address) goes to Step 7b immediately; a failed `gh api` call is reported distinctly and must not be treated as "wait and retry"; otherwise wait and repeat. After 10 attempts with no new clean review, call the script one final time, same branching.

## Step 4 — Decide and apply changes

For each unresolved thread, and each suppressed-comment entry found in Step 3/7, decide **Fix** or **Push back** (push back on any file contained within `.agent-docs/` — Copilot is not a domain expert there); apply code changes; see the Address Each Comment and Suppressed Entry section in [REFERENCE.md](REFERENCE.md) for fetch query, reply commands, and how to read suppressed-comment entries out of the review body.

## Step 4b — Validate changes with code-review

> **MUST NOT SKIP.** The only valid reason to skip is every Step 4 decision being a push-back with zero files modified. Run it synchronously in the foreground to full completion — including any fixes it applies — before Step 4c and this round's Step 5 commit. Never run it as a background agent while the main thread moves on: both would edit the same files mid-review.

If at least one fix was applied, run `code-review` Steps 1–5 only. Pass the explicit instruction to stop after Step 5 to avoid re-invoking this skill. Markdown, documentation, and `.agent-docs/` files get the same validation as code — file type is not a skip condition.

## Step 4c — Reply and resolve threads

Reply to each **thread** ("Fixed. ..." or "Ignored. ...") and immediately resolve via GraphQL — see the Address Each Comment and Suppressed Entry section in [REFERENCE.md](REFERENCE.md) for the `resolveReviewThread` mutation. Real threads only — suppressed entries have no ID and are acknowledged in Step 4d instead.

## Step 4d — Acknowledge suppressed comments

If any suppressed-comment entries were found in Step 3/7 this round, post a single PR-level comment summarizing the fix/ignore outcome for every one of them — see the Address Each Comment and Suppressed Entry section in [REFERENCE.md](REFERENCE.md) for the `gh pr comment` command. Post it even if every decision this round was a push-back — it's the only record of a suppressed comment's outcome. Skip this step if there were no suppressed comments this round.

All push-backs across both threads and suppressed comments, and zero files modified → skip to Step 7b (skip Steps 5–7). At least one fix → continue to Step 5.

## Step 5 — Commit and push

Stage files explicitly (`git add <file1> <file2> ...`), commit with `"address Copilot review: <summary>"`, push, confirm with `git log --oneline -3`. See the Staging Rules section in [REFERENCE.md](REFERENCE.md) for staging rules.

## Step 6 — Re-trigger Copilot (if within limit)

If `review_round >= 2`, skip to Step 7b. Otherwise increment to 2 and re-trigger via `gh pr edit {number} --add-reviewer @copilot`. See the Re-trigger Copilot Review section in [REFERENCE.md](REFERENCE.md) if that command fails.

## Step 7 — Check for new threads and suppressed comments

Re-capture the baseline Copilot review ID, then poll as in Step 3. New unresolved threads or suppressed comments → return to Step 4. Neither (or clean review detected) → continue to Step 7b.

## Step 7b — Distil review criteria into `.agent-docs/review.md`

Turn what Copilot caught on this PR into repo review criteria the `code-review` skill will
apply to the next one.

**Guard.** Run this step only if `review_round` was set at Step 2b **and** at least one
Step 4 decision across the whole invocation was **Fix**. Otherwise skip to Step 8.

**Collect.** Every finding this invocation whose decision was Fix — real threads replied to
with "Fixed." and suppressed entries recorded "Fixed." in a Step 4d comment. Exclude every
push-back: `.agent-docs/review.md` records only criteria accepted by changing code.

**Generalise, dedupe, write.** For each fixed finding write one generalised bold-label + imperative criterion ending `(PR #<number>)`; two findings that generalise to the same rule become one entry. Drop any that a current `.agent-docs/review.md` entry already covers, and append the survivors — see the Distil Review Criteria section in [REFERENCE.md](REFERENCE.md) for the generalising technique and the append/header details. Then commit that file alone:

```bash
git add .agent-docs/review.md
git commit -m "docs: record <N> review criteria from Copilot review"
git push
```

`<N>` is the count added; if dedupe removed every candidate, make no commit. Continue to
Step 8.

## Step 8 — Report completion

```bash
gh pr view --json url --jq '.url'
```

Share the PR link with the user. The PR is ready to merge.
