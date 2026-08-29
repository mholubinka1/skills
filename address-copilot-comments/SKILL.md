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
Step 1  PR exists? ──No──► Step 2: create PR ──► Step 2b
        PR exists? ──Yes──► Step 2b
Step 2b Read PR diff (`gh pr diff`); review-required?
        No (exempt: docs/config/trivial only) ──► Step 8 (no trigger, no poll)
        Yes (functional code or skill step-logic) ──► trigger Copilot; review_round = 1 ──► Step 3
Step 3  Record baseline Copilot review ID; poll every 60s:
        thread count > 0? ─────────────────────────────────────────► Step 4
        suppressed comments > 0 in latest review body? ─────────────► Step 4
        both 0 + new Copilot review (IDs differ)? ───────────────────► Step 7b (reviewed clean)
        Poll exhausted? one final pass: threads > 0 or suppressed > 0? ► Step 4
                        final pass: both 0, no new review? ──────────► Step 7b
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

If missing, install: `winget install --id GitHub.cli` (Windows) / `brew install gh` (macOS) / <https://cli.github.com>
Then `gh auth login`. Do not proceed until `gh --version` passes.

## Step 1 — Check for existing PR

```bash
gh pr list --head $(git branch --show-current) --json number,title,url
```

PR found → note the number. Continue to Step 2b.
No PR → go to Step 2.

## Step 2 — Create the PR

```bash
BASE=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')
gh pr create --base "$BASE" --title "<title>" --body "<summary and test plan>"
```

Note the PR number. Continue to Step 2b.

## Step 2b — Decide whether Copilot review is required

GitHub no longer auto-triggers a Copilot review on PR creation, so this step decides whether the PR needs one and, if so, requests it explicitly.

Fetch the full diff content — not just changed filenames, since the decision depends on what changed, not the file extension (a prose edit and a step-logic edit to the same `SKILL.md` file must be classified differently):

```bash
gh pr diff {number}
```

See the Decide Whether Copilot Review Is Required section in [REFERENCE.md](REFERENCE.md) for the classification rule and worked examples.

**Review-required** → trigger via the same command Step 6 uses (see the Re-trigger Copilot Review section in [REFERENCE.md](REFERENCE.md)); set `review_round = 1`; continue to Step 3.
**Exempt** → skip straight to Step 8. Do not trigger, do not set `review_round`, do not poll.

## Step 3 — Poll for Copilot review threads and suppressed comments

Both the thread-count check and the suppressed-comments check (a round can have both at once — suppressed comments are actionable Copilot findings folded into the review body's markdown instead of posted as real reviewThreads, so they never show up in the thread count even though they're unaddressed) run via one bundled script rather than inline commands — see the status-check script section in [REFERENCE.md](REFERENCE.md).

Before polling, capture the latest Copilot review ID as a baseline by calling the script once with no baseline argument (empty if no review exists yet; if this call already reports something actionable, skip straight to Step 4).

Poll every 60 seconds, max 10 attempts, calling the script again each time: an actionable result exits to Step 4; a clean result (a new review with nothing to address) goes to Step 7b immediately; a failed `gh api` call is reported distinctly and must not be treated as "wait and retry"; otherwise wait and repeat.

After 10 attempts with no new clean review, call the script one final time following the same branching. See the status-check script section in [REFERENCE.md](REFERENCE.md) for the full command and output contract.

## Step 4 — Decide and apply changes

For each unresolved thread, and each suppressed-comment entry found in Step 3/7, decide **Fix** or **Push back** (push back on any file contained within `.agent-docs/` — Copilot is not a domain expert there); apply code changes; see the Address Each Comment and Suppressed Entry section in [REFERENCE.md](REFERENCE.md) for fetch query, reply commands, and how to read suppressed-comment entries out of the review body.

## Step 4b — Validate changes with code-review

> **MUST NOT SKIP.** The only valid reason to skip this step is if every single decision in Step 4 was a push-back and zero files were modified. Run it synchronously in the foreground and let it fully complete — including any fixes it applies — before continuing to Step 4c and this round's Step 5 commit. Never dispatch it as a background agent while the main thread moves on: a background agent editing the same files the main thread might also touch mid-review is a coordination hazard.

If at least one fix was applied, run `code-review` Steps 1–5 only. Pass the explicit instruction to stop after Step 5 to avoid re-invoking this skill.

Markdown files, documentation files, and `.agent-docs/` files are not exempt — they require the same validation as code changes.

File type is not a skip condition.

## Step 4c — Reply and resolve threads

Reply to each **thread** ("Fixed. ..." or "Ignored. ...") and immediately resolve via GraphQL — see the Address Each Comment and Suppressed Entry section in [REFERENCE.md](REFERENCE.md) for the `resolveReviewThread` mutation. This step applies only to real threads — suppressed-comment entries have no thread or comment ID, so there is nothing to reply to or resolve; they are acknowledged instead in Step 4d.

## Step 4d — Acknowledge suppressed comments

If any suppressed-comment entries were found in Step 3/7 this round, post a single PR-level comment summarizing the fix/ignore outcome for every one of them — see the Address Each Comment and Suppressed Entry section in [REFERENCE.md](REFERENCE.md) for the `gh pr comment` command. Post this regardless of whether this round's decisions (threads and suppressed comments together) were all push-backs — it's the only record of a suppressed comment's outcome, since it has no per-comment reply target. Skip this step entirely if there were no suppressed comments this round.

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

**Guard.** Run this step only if `review_round` was set at Step 2b (an exempt PR triggered
no review, so there is nothing to learn) **and** at least one Step 4 decision across the
whole invocation — any round — was **Fix**. Otherwise skip to Step 8.

**Collect.** Take every finding this invocation whose decision was Fix: real threads you
replied to with "Fixed.", and suppressed entries recorded as "Fixed." in a Step 4d PR
comment. Exclude every push-back ("Ignored.") — `.agent-docs/review.md` records only
criteria the team accepted by changing code.

**Generalise.** For each fixed finding, write one criterion: drop the specifics — the file
name, the line number, the concrete identifier or literal value — and keep the *class* of
mistake, phrased as a bold-label + imperative rule in the voice of the `code-review` skill's
`REVIEW-CRITERIA.md` bullets, ending with `(PR #<this PR number>)`. Two findings that
generalise to the same rule become one entry.

**Dedupe.** Read the target repo's existing `.agent-docs/review.md` (only that file — not
the `code-review` skill's `REVIEW-CRITERIA.md`) and drop any candidate whose meaning an
entry there already covers.

**Write and commit.** See the Distil Review Criteria section in [REFERENCE.md](REFERENCE.md)
for the append rules and the header to use when the file must be created. Then commit the
file on its own:

```bash
git add .agent-docs/review.md
git commit -m "docs: record <N> review criteria from Copilot review"
git push
```

`<N>` is the number of criteria actually added. If dedupe removed every candidate, make no
commit. Continue to Step 8.

## Step 8 — Report completion

```bash
gh pr view --json url --jq '.url'
```

Share the PR link with the user. The PR is ready to merge.
