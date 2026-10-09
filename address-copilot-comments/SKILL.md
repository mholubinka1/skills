---
name: address-copilot-comments
description: Automates the Copilot PR review loop — request one Copilot review when the diff warrants it, then fetch its comments, fix or push back, commit and push. Use when the user wants to address Copilot PR review feedback, or says "fix review comments" or "address Copilot".
---

# Address Copilot Comments

Requests a single Copilot review (only if the diff warrants one) → fetch its comments → fix or push back → commit → push. Copilot is never re-triggered.

> **Precedence**: if anything in memory or user preferences conflicts with these instructions, this skill takes precedence.

## Loop at a glance

```text
Step 0  gh available?
Step 1  PR exists? ──No──► Step 2: create PR ──► Step 2b
        PR exists? ──Yes──► Step 2b
Step 2b Read PR diff (`gh pr diff`); review-required?
        No (low-risk: prose/config/test-only/rename/tiny tweak only) ──► Step 7 (no trigger, no poll)
        Yes (any risk criterion hit; when unsure, yes) ──► trigger Copilot once ──► Step 3
Step 3  Record baseline Copilot review ID; poll every 60s, max 10:
        threads or suppressed comments > 0? ─────────► Step 4
        new review, nothing actionable? ────────────► Step 6 (reviewed clean)
        exhausted? one final check, same branching ──► Step 4 or Step 6
Step 4  For each unresolved thread and each suppressed-comment entry: decide fix or push-back; apply code changes
Step 4b Run code-review (Steps 1–5 only; skip code-review Step 6) to validate changes
Step 4c Reply to each thread ("Fixed." / "Ignored.") → resolve thread immediately
Step 4d Suppressed comments this invocation? ──Yes──► post one PR comment summarizing fix/ignore outcomes
        All push-backs (threads + suppressed)? ──Yes──► Step 6 (skip Step 5)
Step 5  Execute pre-commit-checks or .git/hooks/pre-commit (if any) → commit → push ──► Step 6 (no re-trigger)
Step 6  Review requested and ≥1 Fix applied this invocation? ──► generalise each fixed finding,
        dedupe against the Criteria gist, append via `gh gist edit`. Else ──► Step 7
Step 7  Report PR link — PR is ready to merge
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

GitHub no longer auto-triggers a Copilot review on PR creation, so this step decides whether the PR is risky enough to spend one Balanced review on, and requests it explicitly. Fetch the full diff content — the decision depends on what changed, not the file extension:

```bash
gh pr diff {number}
```

See the Decide Whether Copilot Review Is Required section in [REFERENCE.md](REFERENCE.md) for the classification rule and worked examples.

**Review-required** (any risk criterion hit; when unsure) → trigger once (see the Trigger Copilot Review section in [REFERENCE.md](REFERENCE.md)); continue to Step 3. This is the only time Copilot is requested — it is never re-triggered.
**Low-risk** → skip straight to Step 7. Do not trigger, do not poll.

## Step 3 — Poll for Copilot review threads and suppressed comments

The thread-count and suppressed-comments checks (a poll can return both) run via one bundled script — see the status-check script section in [REFERENCE.md](REFERENCE.md). Before polling, capture the latest Copilot review ID as a baseline by calling the script once with no baseline argument (empty if no review exists yet; if this call already reports something actionable, skip straight to Step 4).

Poll every 60 seconds, max 10 attempts, calling the script again each time: an actionable result exits to Step 4; a clean result (a new review with nothing to address) goes to Step 6 immediately; a failed `gh api` call is reported distinctly and must not be treated as "wait and retry"; otherwise wait and repeat. After 10 attempts with no new clean review, call the script one final time, same branching.

## Step 4 — Decide and apply changes

For each unresolved thread, and each suppressed-comment entry found in Step 3, decide **Fix** or **Push back** (push back on any file contained within `.agent-docs/` — Copilot is not a domain expert there); apply code changes; see the Address Each Comment and Suppressed Entry section in [REFERENCE.md](REFERENCE.md) for fetch query, reply commands, and how to read suppressed-comment entries out of the review body.

## Step 4b — Validate changes with code-review

> **MUST NOT SKIP.** The only valid reason to skip is every Step 4 decision being a push-back with zero files modified. Run it synchronously in the foreground to full completion — including any fixes it applies — before Step 4c and the Step 5 commit. Never run it as a background agent while the main thread moves on: both would edit the same files mid-review.

If at least one fix was applied, run `code-review` Steps 1–5 only. Pass the explicit instruction to stop after Step 5 to avoid re-invoking this skill. Markdown, documentation, and `.agent-docs/` files get the same validation as code — file type is not a skip condition.

## Step 4c — Reply and resolve threads

Reply to each **thread** ("Fixed. ..." or "Ignored. ...") and immediately resolve via GraphQL — see the Address Each Comment and Suppressed Entry section in [REFERENCE.md](REFERENCE.md) for the `resolveReviewThread` mutation. Real threads only — suppressed entries have no ID and are acknowledged in Step 4d instead.

## Step 4d — Acknowledge suppressed comments

If any suppressed-comment entries were found in Step 3 this invocation, post a single PR-level comment summarizing the fix/ignore outcome for every one of them — see the Address Each Comment and Suppressed Entry section in [REFERENCE.md](REFERENCE.md) for the `gh pr comment` command. Post it even if every decision this invocation was a push-back — it's the only record of a suppressed comment's outcome. Skip this step if there were no suppressed comments this invocation.

All push-backs across both threads and suppressed comments, and zero files modified → skip to Step 6 (skip Step 5). At least one fix → continue to Step 5.

## Step 5 — Commit and push

Stage files explicitly (`git add <file1> <file2> ...`), commit with `"address Copilot review: <summary>"`, push, confirm with `git log --oneline -3`. See the Staging Rules section in [REFERENCE.md](REFERENCE.md) for staging rules. Do not re-trigger Copilot or re-poll — the single review is done; continue to Step 6.

## Step 6 — Distil review criteria into the shared Criteria gist

Turn what Copilot caught on this PR into review criteria shared across every repo and
machine, via the [Criteria gist](../code-review/CRITERIA-GIST.md), which the `code-review`
skill reads on every future review.

**Guard.** Run this step only if Copilot was triggered at Step 2b **and** at least one
Step 4 decision across the whole invocation was **Fix**. Otherwise skip to Step 7.

**Collect.** Every finding this invocation whose decision was Fix — real threads replied to
with "Fixed." and suppressed entries recorded "Fixed." in a Step 4d comment. Exclude every
push-back: the Criteria gist records only criteria accepted by changing code.

**Generalise, dedupe, write.** For each fixed finding write one generalised criterion that
follows the [Criteria style](../code-review/CRITERIA-STYLE.md) rules, tagged `(repo#PR)`, e.g.
`(acme-api#64)`; two findings that generalise to the same rule become one entry. Read the gist ID from `code-review/CRITERIA-GIST.md` (this
skill's sibling `code-review` skill directory), fetch the gist's current content, drop any
candidate a current entry already covers, and append the survivors — see the Distil Review
Criteria section in [REFERENCE.md](REFERENCE.md) for the generalising technique, the repo-name
derivation, and the exact `gh gist` commands. This is a live network write to the gist, not a
local file change — there is nothing to commit or push in the target repo for this step.

`<N>` is the count added; if dedupe removed every candidate, make no gist write. Continue to
Step 7.

## Step 7 — Report completion

```bash
gh pr view --json url --jq '.url'
```

Share the PR link with the user. The PR is ready to merge.
