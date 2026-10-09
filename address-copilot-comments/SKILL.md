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
Step 3  Haiku sub-agent: capture baseline, poll every 60s (max 10), fetch items:
        ACTIONABLE ──► Step 4 | CLEAN or still PENDING ──► Step 7b | ERROR ──► report
Step 4  Main context: for each thread and suppressed entry decide fix or push-back; apply fixes
Step 4b Run code-review (Steps 1–5 only; skip code-review Step 6) to validate changes
Step 4c Haiku sub-agent: reply + resolve each thread; one PR comment for suppressed entries;
        if any fix: pre-commit → commit → push
        All push-backs (threads + suppressed)? ──Yes──► Step 7b (skip Steps 6–7)
Step 6  review_round < 2? ──Yes──► review_round++; re-trigger Copilot → Step 7
                          ──No ──► Step 7b (max 2 reviews; do not re-trigger)
Step 7  Re-dispatch the Step 3 polling sub-agent:
        ACTIONABLE ──► Step 4 | otherwise ──► Step 7b
Step 7b Not exempt and ≥1 Fix applied this invocation? ──► generalise each fixed finding,
        dedupe against the Criteria gist, append via `gh gist edit`. Else ──► Step 8
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

Polling is mechanical, so it runs in a Haiku sub-agent with an empty context. Dispatch one
`Agent` call, `subagent_type: general-purpose`, `model: haiku`, with this handover:

```text
Read <this skill's base directory>/REFERENCE.md, sections "Step 3 — Poll for Copilot review
threads and suppressed comments" and "Step 4 — Address each comment and suppressed entry"
(only its two fetch subsections). PR #<number>.
Capture the baseline Copilot review ID, then poll as that section says (every 60s, max 10,
one final check). On ACTIONABLE, fetch every unresolved Copilot thread and every
suppressed-comment entry. Change nothing.
Return: DECISION=ACTIONABLE|CLEAN|PENDING|ERROR (with the gh error if ERROR), then one block
per item: threadId and comment_id (or "suppressed"), path:line, the comment body verbatim.
```

`ACTIONABLE` → Step 4 with the returned items. `CLEAN`, or `PENDING` after the final check →
Step 7b. `ERROR` → report the failure to the user; it is not a "wait and retry".

## Step 4 — Decide and apply changes

For each item returned in Step 3/7, decide **Fix** or **Push back**, then apply the fixes. This judgement stays in the main context. Push back when:

- the comment names no concrete case — no input or situation that produces a wrong result;
- the suggestion adds code, abstraction, options or config the change does not need;
- the file is inside `.agent-docs/` — Copilot is not a domain expert there.

Fix everything else. For each decision, note one line of reasoning: it becomes the reply.

## Step 4b — Validate changes with code-review

> **MUST NOT SKIP.** The only valid reason to skip is every Step 4 decision being a push-back with zero files modified. Run it synchronously in the foreground to full completion — including any fixes it applies — before Step 4c's reply-and-commit dispatch. Never run it as a background agent while the main thread moves on: both would edit the same files mid-review.

If at least one fix was applied, run `code-review` Steps 1–5 only. Pass the explicit instruction to stop after Step 5 to avoid re-invoking this skill. Markdown, documentation, and `.agent-docs/` files get the same validation as code — file type is not a skip condition.

## Step 4c — Reply, acknowledge, commit and push

These steps are mechanical, so they run in one Haiku sub-agent with an empty context, after
Step 4b has fully finished. Dispatch one `Agent` call, `subagent_type: general-purpose`,
`model: haiku`, with this handover:

```text
Read <this skill's base directory>/REFERENCE.md, sections "Step 4 — Address each comment and
suppressed entry" (reply, resolve and acknowledge subsections) and "Staging rules". PR #<number>.
Decisions, one per line:  <threadId> <comment_id> | suppressed <path:line> — Fixed|Ignored — <reason>
1. For each thread: reply "Fixed. <reason>" or "Ignored. <reason>", then resolve it at once.
2. If any suppressed entries: post one PR comment summarising each one's outcome.
3. If any decision is Fixed: run the repo's pre-commit hooks (or .git/hooks/pre-commit) on
   <files changed>, stage exactly those files, commit "address Copilot review: <summary>",
   push, and show git log --oneline -3. A hook failure that needs a code change: stop and
   report it.
Return: threads replied and resolved, comment posted (yes/no), commit hash and push result,
and one line "Skipped / risk:".
```

A reported hook failure is fixed in the main context and the commit step re-dispatched.
All push-backs across threads and suppressed comments, and zero files modified → skip to
Step 7b (skip Steps 6–7). At least one fix → continue to Step 6.

## Step 6 — Re-trigger Copilot (if within limit)

If `review_round >= 2`, skip to Step 7b. Otherwise increment to 2 and re-trigger via `gh pr edit {number} --add-reviewer @copilot`. See the Re-trigger Copilot Review section in [REFERENCE.md](REFERENCE.md) if that command fails.

## Step 7 — Check for new threads and suppressed comments

Dispatch the Step 3 polling sub-agent again (it captures a fresh baseline). `ACTIONABLE` → return to Step 4. Anything else → continue to Step 7b, reporting an `ERROR` to the user.

## Step 7b — Distil review criteria into the shared Criteria gist

Turn what Copilot caught on this PR into review criteria shared across every repo and
machine, via the [Criteria gist](../code-review/CRITERIA-GIST.md), which the `code-review`
skill reads on every future review.

**Guard.** Run this step only if `review_round` was set at Step 2b **and** at least one
Step 4 decision across the whole invocation was **Fix**. Otherwise skip to Step 8.

**Collect.** Every finding this invocation whose decision was Fix — real threads replied to
with "Fixed." and suppressed entries recorded "Fixed." in the Step 4c PR comment. Exclude every
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
Step 8.

## Step 8 — Report completion

```bash
gh pr view --json url --jq '.url'
```

Share the PR link with the user. The PR is ready to merge.
