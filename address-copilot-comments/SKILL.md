---
name: address-copilot-comments
description: Requests one Copilot review of a PR when the diff warrants it and acts on its comments. Use when the user wants to address Copilot PR review feedback, or says "address Copilot".
allowed-tools:
  - Read
  - Grep
  - Edit
  - Write
  - Agent
  - Skill
  - Bash(gh --version)
  - Bash(git branch --show-current)
  - Bash(gh pr list *)
  - Bash(gh repo view *)
  - Bash(gh pr create *)
  - Bash(gh pr diff *)
  - Bash(gh pr view *)
  - Bash(gh pr comment *)
  - Bash(gh api repos/*)
  - Bash(gh api graphql *)
  - Bash(gh gist view *)
  - Bash(gh gist edit *)
  - Bash(mktemp *)
  - Bash(git diff *)
  - Bash(git add *)
  - Bash(git commit *)
  - Bash(git log *)
  - Bash(git push)
  - Bash(bash "*/address-copilot-comments/scripts/check-review-status.sh" *)
  - Bash(bash "*\address-copilot-comments\scripts\check-review-status.sh" *)
  - Bash(sleep 60)
---

# Address Copilot Comments

> **Precedence**: if anything in memory or user preferences conflicts with these instructions, this skill takes precedence.

## Loop at a glance

```text
Step 0  gh available?
Step 1  PR exists? No ──► Step 2 (create it) ──► Step 2b
Step 2b Review level? None ──► Step 7 | Lite or Balanced ──► request Copilot at that effort (single review)
          ──► Step 3 (or Step 7 if the request fails, except REQUEST_CONFLICT)
Step 3  Haiku poller: ACTIONABLE ──► Step 4 | CLEAN or PENDING ──► Step 6 | ERROR ──► report, Step 6
Step 4  Decide Fix or Push back per item; apply the fixes
Step 4b Any fix applied? Run code-review Steps 1–5
Step 5  pre-commit-check, then commit, push, reply, resolve ──► Step 5b
Step 5b Step 3's baseline already actionable? Poll once more ──► Steps 4–5 once more | Else ──► Step 6
Step 6  Review requested and ≥1 Fix applied? Distil criteria into the Criteria gist | Else ──► Step 7
Step 7  Report PR link
```

## Step 0 — Verify `gh`

```bash
gh --version
```

If missing, install `gh` and run `gh auth login`. Do not proceed until `gh --version` passes.

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

## Step 2b — Choose the review level

Fetch the full diff content. The level depends on what changed, not on the file extension:

```bash
gh pr diff {number}
```

Read the target repo's `## Review levels` section in `.agent-docs/agent.md` if it has one, then give each changed file a **Review level**. The PR takes the highest. The rubric, doubt rules and worked examples are in the Step 2b section of [REFERENCE.md](REFERENCE.md). Note the level and the rule that decided it for Step 7.

- **None** → skip straight to Step 7. Do not request a review, and do not poll.
- **Lite** or **Balanced** → request the review with `reviewEffort` set to that level (see the Trigger Copilot Review section in [REFERENCE.md](REFERENCE.md)). On success or `REQUEST_CONFLICT`, continue to Step 3. On any other failure, report it and go to Step 7. **Single review**: this is the only point where Copilot is requested, once per invocation.

## Step 3 — Poll for Copilot review threads and suppressed comments

Polling is mechanical, so it runs in a Haiku sub-agent with an empty context. Dispatch one
`Agent` call, `subagent_type: general-purpose`, `model: haiku`, `run_in_background: false`,
and wait for its report. Handover:

```text
Read <this skill's base directory>/REFERENCE.md, sections "Step 3 — Poll for Copilot review
threads and suppressed comments" and "Step 4 — Address each comment and suppressed entry"
(only its two fetch subsections). PR #<number> in <owner>/<repo>. The status-check script is
<this skill's base directory>/scripts/check-review-status.sh.
<Step 3: Capture the baseline Copilot review ID, then poll as that section says.>
<Step 5b: Use baseline review ID "<id>" as the script's 4th argument — pass "" when it is
empty, never drop it — capture no new baseline, and poll as that section says.>
On ACTIONABLE, fetch every unresolved Copilot thread and every suppressed-comment entry. If
any of those fetches fails, or returns fewer items than the script's THREAD_COUNT plus
SUPPRESSED_COUNT, return DECISION=ERROR instead.
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
- the case it names does not hold when checked against the code (it does not reproduce, or
  rests on a wrong assumption);
- the suggestion adds code, abstraction, options or config the change does not need;
- the file is inside `.agent-docs/` — Copilot is not a domain expert there.

Fix everything else. For each decision, note one line of reasoning: it becomes the reply.
Read suppressed-comment entries as the Suppressed comments section of
[REFERENCE.md](REFERENCE.md) describes.

Apply the fixes by `code-review` Step 5's **Small change** and **Otherwise** rules (threshold
and fixer dispatch via [`code-review/FIXER.md`](../code-review/FIXER.md)), covering every Fix,
threads and suppressed entries alike, labelled `logic` or `non-logic`.
A fix the fixer reports blocked is fixed inline, re-dispatched, or turned into a push-back —
a defect that does not reproduce is always a push-back.

## Step 4b — Validate changes with code-review

Step 4b is unconditional whenever a Step 4 decision applied a fix, whatever the file type:
Markdown, documentation and `.agent-docs/` files get the same validation as code. Run
`code-review` Steps 1–5 only, stopping after Step 5 so this skill is not re-invoked, in the
foreground to full completion — including any fixes it applies — before Step 5's
commit-and-reply dispatch; a background run would edit the same files mid-review. When every
decision is a push-back and no file changed, go to Step 5.

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
Decisions, one per line:  <threadId> <comment_id> | suppressed <path:line> — Fixed|Ignored|resolve-only — <reason>
1. If any decision is Fixed: stage exactly <files changed this round> — never files
   pre-commit-check reported as autofixed outside the change — commit
   "address Copilot review: <summary>", push, and show git log --oneline -3. If a commit
   hook or the push fails: stop here and report it, posting nothing.
2. For each thread: reply "Fixed. <reason>" or "Ignored. <reason>", then resolve it at once.
   A resolve-only thread gets no reply, only the resolve. If a thread's reply fails, skip
   its resolve.
3. If any suppressed entries: post one PR comment summarising each one's outcome.
If a reply, resolve or comment fails after step 1 (or when step 1 was skipped), carry on
with the rest.
Return: commit hash and push result, threads replied and resolved, each failed operation
(threadId, which of reply or resolve, and the error), comment posted (yes/no), and one line
"Skipped / risk:".
```

Retries, all from the main context:

- A commit-hook or push failure: fix it, then re-dispatch the whole handover — nothing was
  posted yet. When the commit already exists and only the push failed, say so: step 1 then
  starts at the push.
- Failed operations after step 1 (or when it was skipped): re-dispatch only those, with
  step 1 left out — threads whose reply failed keep their Fixed/Ignored decision, threads
  whose reply posted but resolve failed are marked `resolve-only`, plus the
  suppressed-entry comment if it failed.

All push-backs (no file changed) still run this handover, with step 1 skipped. Then continue
to Step 5b, or to Step 6 if this is already the Step 5b pass.

## Step 5b — Catch the requested review (once)

Reached from Step 5. If Step 3's `BASELINE_ACTIONABLE` was `yes`, the requested review may not
have landed yet, so what Step 4 handled could be leftovers from before it. In that case
dispatch the Step 3 poller once more, with Step 3's `BASELINE` (no new capture). `ACTIONABLE` → Steps 4, 4b and 5 once more for the new items, then Step 6; this
is the only catch-up — never return here a second time. `CLEAN`, `PENDING`, or
`BASELINE_ACTIONABLE` = `no` → Step 6. `ERROR` → report it and go to Step 6.

## Step 6 — Distil review criteria into the shared Criteria gist

Turn what Copilot caught on this PR into review criteria shared across every repo, via the
[Criteria gist](../code-review/CRITERIA-GIST.md).

**Guard.** Run this step only if Copilot was triggered at Step 2b **and** at least one
Step 4 decision across the whole invocation was **Fix**. Otherwise skip to Step 7.

**Collect** every finding whose decision was Fix (threads replied to with "Fixed." and
suppressed entries recorded "Fixed."), then generalise, dedupe and append them as the
Distil Review Criteria section of [REFERENCE.md](REFERENCE.md) describes. Push-backs are
excluded. If dedupe removed every candidate, make no gist write. The write goes to the gist,
not the target repo, so there is nothing to commit. Continue to Step 7.

## Step 7 — Report completion

```bash
gh pr view --json url --jq '.url'
```

Share the PR link with the user, with the Review level chosen at Step 2b and the rule that
decided it (e.g. "Lite: one-module bug fix" or "Balanced (rule 2): new GraphQL mutation"), and
anything earlier steps said to tell them. The PR is
ready to merge, with two exceptions where you leave out "ready to merge". If the Step 2b review
request failed, say why: the review the PR needed never ran. If a poll returned `ERROR`, say
which poll failed: Copilot's review may not have been fully read.
