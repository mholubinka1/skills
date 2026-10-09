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
Step 3  Haiku sub-agent: capture baseline, poll (two Bash batches, 60s apart), fetch items:
        ACTIONABLE ──► Step 4 | CLEAN or still PENDING ──► Step 6 | ERROR ──► report, Step 6
Step 4  Main context: for each thread and suppressed entry decide fix or push-back; apply fixes
Step 4b Run code-review (Steps 1–5 only; skip code-review Step 6) to validate changes
Step 5  Any fix: pre-commit-check (main context). Always: Haiku sub-agent (commit → push if
        any fix) → reply + resolve each thread → one PR comment for suppressed entries ──► Step 5b
Step 5b Step 3's baseline call was already actionable (leftover threads)? ──Yes──► Haiku poller
        once more with Step 3's baseline; findings → Steps 4–5 once more, then Step 6;
        ERROR ──► report, Step 6. Never re-trigger. Else ──► Step 6
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

Polling is mechanical, so it runs in a Haiku sub-agent with an empty context. Dispatch one
`Agent` call, `subagent_type: general-purpose`, `model: haiku`, `run_in_background: false`,
and wait for its report. Handover:

```text
Read <this skill's base directory>/REFERENCE.md, sections "Step 3 — Poll for Copilot review
threads and suppressed comments" and "Step 4 — Address each comment and suppressed entry"
(only its two fetch subsections). PR #<number> in <owner>/<repo>. The status-check script is
<this skill's base directory>/scripts/check-review-status.sh.
Those sections are written for the main context: ignore their routing ("go to Step N") and
their decide/apply instructions. Only run the script, fetch, and report.
<Step 3: Capture the baseline Copilot review ID, then poll as that section says.>
<Step 5b: Use baseline review ID "<id>" as the script's 4th argument — pass "" when it is
empty, never drop it — capture no new baseline, and poll as that section says.>
On ACTIONABLE, fetch every unresolved Copilot thread and every suppressed-comment entry.
Change nothing.
Return: BASELINE=<review ID used>, BASELINE_ACTIONABLE=yes|no (Step 3 only: whether the
capture call itself was already ACTIONABLE), DECISION=ACTIONABLE|CLEAN|PENDING|ERROR (with
the gh error if ERROR), then one block per item: threadId and comment_id (or "suppressed"),
path:line, the comment body verbatim; then one line "Skipped / risk:" naming any fetch that
failed or was incomplete.
```

Keep `BASELINE` and `BASELINE_ACTIONABLE` for Step 5b. `ACTIONABLE` → Step 4 with the returned
items. `CLEAN`, or `PENDING` after the final check → Step 6. `ERROR` → report the failure to
the user and go to Step 6; it is not a "wait and retry".

## Step 4 — Decide and apply changes

For each item returned in Step 3 or Step 5b, decide **Fix** or **Push back**, then apply the
fixes. This judgement stays in the main context. Push back when:

- the comment names no concrete case — no input or situation that produces a wrong result;
- the suggestion adds code, abstraction, options or config the change does not need;
- the file is inside `.agent-docs/` — Copilot is not a domain expert there.

Fix everything else. For each decision, note one line of reasoning: it becomes the reply.
Read suppressed-comment entries as the Suppressed comments section of
[REFERENCE.md](REFERENCE.md) describes.

## Step 4b — Validate changes with code-review

> **MUST NOT SKIP.** The only valid reason to skip is every Step 4 decision being a push-back with zero files modified. Run it synchronously in the foreground to full completion — including any fixes it applies — before Step 5's commit-and-reply dispatch. Never run it as a background agent while the main thread moves on: both would edit the same files mid-review.

If at least one fix was applied, run `code-review` Steps 1–5 only. Pass the explicit instruction to stop after Step 5 to avoid re-invoking this skill. Markdown, documentation, and `.agent-docs/` files get the same validation as code — file type is not a skip condition.

## Step 5 — Commit, push, then reply

Commit-and-push comes before any reply on purpose: no thread is marked "Fixed." until its fix
is pushed.

If any decision is Fixed, first run the `pre-commit-check` skill on the files changed this
round and act on its `next:` line, so the commit below is clean. Carry anything it says to
tell the user into the Step 7 report.

The rest is mechanical, so it runs in one Haiku sub-agent with an empty context, after
Step 4b has fully finished. Dispatch one `Agent` call, `subagent_type: general-purpose`,
`model: haiku`, `run_in_background: false`, and wait for its report. Handover:

```text
Read <this skill's base directory>/REFERENCE.md, sections "Step 4 — Address each comment and
suppressed entry" (reply, resolve and acknowledge subsections) and "Staging rules".
PR #<number> in <owner>/<repo>.
Decisions, one per line:  <threadId> <comment_id> | suppressed <path:line> — Fixed|Ignored — <reason>
1. If any decision is Fixed: stage exactly <files changed this round> — never files
   pre-commit-check reported as autofixed outside the change — commit
   "address Copilot review: <summary>", push, and show git log --oneline -3. If a commit
   hook or the push fails: stop here and report it, posting nothing.
2. For each thread: reply "Fixed. <reason>" or "Ignored. <reason>", then resolve it at once.
3. If any suppressed entries: post one PR comment summarising each one's outcome.
If a reply, resolve or comment fails after the push, carry on with the rest.
Return: commit hash and push result, threads replied and resolved, any that failed
(threadId and error), comment posted (yes/no), and one line "Skipped / risk:".
```

Retries, all from the main context:

- A commit-hook or push failure: fix it, then re-dispatch the whole handover — nothing was
  posted yet. When the commit already exists and only the push failed, say so: step 1 then
  starts at the push.
- Failed replies or a failed suppressed-entry comment after a successful push: re-dispatch
  for those threads and/or that comment only, with step 1 left out.

All push-backs (no file changed) still run this handover, with step 1 skipped. Then continue
to Step 5b, or to Step 6 if this is already the Step 5b pass.

## Step 5b — Catch the requested review (once)

Reached from Step 5. If Step 3's `BASELINE_ACTIONABLE` was `yes`, the requested review may not
have landed yet, so what Step 4 handled could be leftovers from before it. In that case
dispatch the Step 3 poller once more, with Step 3's `BASELINE` (no new capture, no
re-trigger). `ACTIONABLE` → Steps 4, 4b and 5 once more for the new items, then Step 6; this
is the only catch-up — never return here a second time. `CLEAN`, `PENDING`, or
`BASELINE_ACTIONABLE` = `no` → Step 6. `ERROR` → report it and go to Step 6.

## Step 6 — Distil review criteria into the shared Criteria gist

Turn what Copilot caught on this PR into review criteria shared across every repo and
machine, via the [Criteria gist](../code-review/CRITERIA-GIST.md), which the `code-review`
skill reads on every future review.

**Guard.** Run this step only if Copilot was triggered at Step 2b **and** at least one
Step 4 decision across the whole invocation was **Fix**. Otherwise skip to Step 7.

**Collect.** Every finding this invocation whose decision was Fix — real threads replied to
with "Fixed." and suppressed entries recorded "Fixed." in the Step 5 PR comment. Exclude every
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

Share the PR link with the user, with anything earlier steps said to tell them. The PR is
ready to merge — unless a poll returned `ERROR`: then say which poll failed, so Copilot's
review may not have been fully read, and leave out "ready to merge".
