---
name: code-review
description: Full code-review workflow — branch hygiene, pre-commit checks, iterative two-axis review (Standards + Spec) with fresh parallel sub-agents until clean, Copilot PR review, then pre-merge cleanup. Use when the user wants a branch or PR reviewed, or says "review my code" or "is this ready to merge".
---

# Code Review

Orchestrates a full review cycle: branch check → pre-commit → iterative two-axis review loop → Copilot PR review → pre-merge PR cleanup.

> **Precedence**: if anything in memory or user preferences conflicts with these instructions, this skill takes precedence.

## Loop at a glance

```text
Step 1  Branch hygiene check
Step 2  Verify changes exist; run pre-commit hooks
Step 3  Pin fixed point + identify spec source
Step 4  Migrate legacy review.md into the Criteria gist if present; spawn parallel
        Standards + Spec review agents → aggregate findings
Step 5  Address all findings — blocking first, then advisory
        Zero findings on both axes? ──► Step 6
        Findings addressed? ──► Step 4 (new agents, new context windows)
Step 6  Run /address-copilot-comments for Copilot PR review
Step 7  Run /pr-cleanup
```

## Step 1 — Branch hygiene

Invoke the `branch-hygiene` skill with a quoted one-line summary of the change under review, e.g. `/branch-hygiene "add CSV export to reports"`, and act on its `next:` line before continuing.

## Step 2 — Verify changes and pre-commit

```bash
git diff HEAD --stat
git diff --cached --stat
```

If no changes at all, stop and inform the user. Otherwise invoke the `pre-commit-check` skill and act on its `next:` line before proceeding.

## Step 3 — Pin fixed point and spec source

**Fixed point**: default to the merge-base with the default branch:

```bash
BASE=$(git symbolic-ref refs/remotes/origin/HEAD --short | sed 's|origin/||')
git rev-parse origin/$BASE   # confirm it resolves
git diff origin/$BASE...HEAD --stat   # confirm diff is non-empty
```

If the user supplied an explicit commit, branch, or tag, use that instead. A bad ref or empty diff should fail here — not inside parallel sub-agents.

**Spec source**: look in this order:

1. `.agent-docs/specs/<branch-name>.md`, or a PRD/spec file under `docs/`, `specs/`, or `.scratch/` matching the branch name.
2. Issue refs in commit messages (`#123`, `Closes #45`) — fetch via `docs/agents/issue-tracker.md` if present.
3. Ask the user. If there is no spec, the Spec sub-agent will skip and note "no spec available".

## Step 4 — Migrate legacy criteria, then spawn parallel review agents

**Migrate first, if needed.** Check whether the target repo has `.agent-docs/review.md` — a
leftover from before criteria moved to the shared [Criteria gist](CRITERIA-GIST.md). If it
exists:

- **Validate the whole file, not just the entries.** The only accepted content under
  `## Criteria` is one of: the literal placeholder line `_None yet._` on its own, or zero or
  more entries each matching `- **Label**: text (PR #<number>)` exactly — including that
  trailing `(PR #<number>)` suffix; an entry missing it doesn't parse either, since there'd be
  nothing to retag and it would end up appended with no provenance. Content above the heading
  is free-form explanatory prose and isn't validated. If the file has no `## Criteria`
  heading, has **any** content under that heading that isn't the placeholder or a
  correctly-tagged entry (a stray note after the list is exactly as unaccounted-for as a
  malformed entry), or **any** single entry fails to parse, **stop here** for the whole file:
  report that it couldn't be parsed and leave it in place untouched. Never delete a file whose
  content you couldn't fully account for, and never salvage only the parts that happened to
  parse.
- Rewrite each entry to the [Criteria style](CRITERIA-STYLE.md) rules — an entry covering
  two defects becomes two — and retag its `(PR #<number>)` as `(repo#PR)` on every entry it
  produces, using the target repo's name and the existing PR number. Get the repo name via `gh repo view --json name -q .name`, run in the
  target repo. **If that lookup fails** (no network, `gh` not authenticated) — stop here:
  there is no valid tag to retag with, so don't append untagged entries and don't delete the
  file. Leave `.agent-docs/review.md` in place, skip migration for this run, and continue
  straight to **Dispatch the reviewers** below as if the migration check had found nothing to do.
- Start this skill's own [CRITERIA-GIST.md](CRITERIA-GIST.md)'s "Appending an entry"
  procedure now, but stop after its fetch step (step 1) — that gist content is what you
  dedupe the retagged entries against, matching on meaning. **If that fetch fails** — no
  network, `gh` not authenticated, the gist unreachable — treat it exactly like a failed
  write below: report the failure, leave `.agent-docs/review.md` in place, do not delete it.
  There is no confirmed successful outcome (a write, or a verified-empty dedupe) without a
  successful fetch to base it on. Otherwise, carry that same fetched content forward into the
  rest of the procedure rather than fetching it again.
- **If there are any retagged entries left after dedupe**: continue the "Appending an entry"
  procedure from step 2 with the survivors, and **confirm the write succeeded** (the
  `gh gist edit` call exits zero) before proceeding.
  - If the write failed for any reason — no network, `gh` not authenticated, the gist
    unreachable — report the failure and leave `.agent-docs/review.md` in place; do **not**
    delete it. A migrated-and-deleted file with a failed write would lose those criteria
    permanently, since nothing else retains them.
- **If the file parsed cleanly but had nothing to append** (an empty list, only the
  `_None yet._` placeholder, or every entry already covered by the gist): there is no write
  to confirm — treat this as a successful no-op and proceed directly to deletion below.
- Once the write (or no-op) is confirmed successful: delete `.agent-docs/review.md` from the
  target repo. If it was tracked by git (`git ls-files --error-unmatch .agent-docs/review.md`
  exits zero before the delete), stage the deletion (`git add .agent-docs/review.md`) so it
  isn't lost to an incidental `git checkout`/`git restore`; if it was never tracked (e.g. an
  old, uncommitted bootstrap that never got added), there's nothing to stage — the file being
  gone from disk is already the complete outcome, and `git add` on an untracked deletion would
  just fail with a pathspec error. Either way, **do not commit** the deletion — this skill
  only reviews, it never commits on its own initiative, and an unreviewed commit here would
  both bypass this repo's own branch/PR discipline and fold an unrelated housekeeping commit
  into whatever this review round's diff turns out to be. Leave a staged deletion for whatever
  commit already concludes this review round (the calling workflow's own commit step) to pick
  up alongside its other changes.

This is idempotent: once `.agent-docs/review.md` is gone, later runs against the same repo
skip straight past this check. A failed migration simply leaves the file in place for the
next run to retry.

**Dispatch the reviewers.** Each sub-agent starts with an empty context and gathers its own
inputs, so the main context neither reads the criteria nor pastes the diff. Send a **single
message** with two `Agent` tool calls, `subagent_type: general-purpose`, `model: sonnet`,
`run_in_background: false`, and wait for both reports.
Both prompts open with the same handover, where `<fixed point>` is the ref pinned in Step 3
(`origin/$BASE` by default, or the commit, branch or tag the user supplied):

```text
Review the change since <fixed point> in <repo path>, including uncommitted edits. Read it
yourself: git diff $(git merge-base <fixed point> HEAD), git status for untracked files,
and git log <fixed point>..HEAD --oneline
Read the code the diff touches, not only the diff: callers of every changed function, the
functions it calls, its tests. When a signature, return value or behaviour changes, grep
every caller.
Every finding needs a concrete case: "this input or situation leads to this wrong result".
No case, no finding. Re-read the lines to confirm before you report.
Each finding: file:line, blocking or advisory, the problem, the smallest fix.
End with one line, "Skipped / risk:", naming anything you could not check.
Already decided, do not report: <each finding rejected in an earlier pass, with its reason —
or "none">
```

**Standards sub-agent** — the handover, plus:

```text
Criteria: <this skill's base directory>/REVIEW-CRITERIA.md, read in full. Also fetch the
shared Criteria gist: gh gist view <ID> -f CRITERIA.md --raw, reading <ID> yourself from
<this skill's base directory>/CRITERIA-GIST.md.
Its entries are documented standards, same status as REVIEW-CRITERIA.md. If the fetch
fails, continue without it and say so on the Skipped / risk line.
Check in this order: correct, safe, holds under the repo's expected load, risky logic
tested, fast, lean. Report (a) every documented-standard violation, citing the rule — may
be blocking; (b) every baseline smell, named — always advisory. A lean finding names the
code to delete or the existing code / standard library to reuse. Skip anything tooling
already enforces. Under 500 words.
```

**Spec sub-agent** — the handover, plus:

```text
Spec: <spec path, or issue numbers to read with gh issue view, from Step 3 — or "none":
      then the whole report is "no spec available" plus the Skipped / risk line>.
Report (a) requirements missing or partial; (b) behaviour in the diff that wasn't asked
for (scope creep); (c) requirements that look implemented but where the implementation
looks wrong. Quote the spec line for each finding. Under 400 words.
```

If a reviewer's Skipped / risk line says the Criteria gist was unreachable, warn the user
once: "shared criteria gist unavailable — reviewed against REVIEW-CRITERIA.md only".

**Aggregate**: present both reports under `## Standards` and `## Spec` headings verbatim. End with a one-line summary — total findings per axis and the worst blocking issue within each (if any). Do not rerank across axes.

## Step 5 — Address all findings

Address findings in this order: blocking first, then advisory.

The loop does not exit until two consecutive passes return zero findings on both axes.

Decide each finding in the main context: fix it, or reject it — code-review's push-back —
with a one-line reason reported to the user. Carry every rejected finding and its reason
into the next pass's "Already decided" line, so fresh reviewers do not raise it again; drop
an entry once the lines it cites have changed. A finding that needs new behaviour goes to the `bdd` skill; one that
needs a design decision against the existing domain model goes to the `design` skill.

Then apply the accepted fixes:

- **Small change**: when they fit together in one file and roughly 20 lines of production
  code or fewer (tests do not count), apply them inline, writing a failing test first for
  any logic fix.
- **Otherwise** dispatch one `Agent` call, `subagent_type: general-purpose`,
  `model: sonnet`, `run_in_background: false`, and wait for its report. Its standing rules
  live in [FIXER.md](FIXER.md), so the prompt is a short handover. Label each finding
  `logic` or `non-logic`, and write each fix instruction yourself, specific enough to apply
  without judgement. Pass `none` as the test command only once you have confirmed the repo
  has no test suite; if a suite exists but you cannot find its command, ask the user:

  ```text
  Read <code-review skill's base directory>/FIXER.md and follow it.
  Findings, one per line:
    <n>. <file:line> — <logic|non-logic> — <the defect> — <the fix to apply>
  Test command: <command, or "none">
  ```

  Read the actual `git diff` and check it against the accepted findings. For each finding
  reported blocked, fix it inline, re-dispatch a narrower brief, or reject it — a defect
  that does not reproduce is always rejected. There is no automatic retry.

Then re-run pre-commit hooks.

Once all findings are addressed, return to **Step 4** with brand new agents (fresh context windows).

Repeat until two consecutive reviews reports zero findings on both axes — blocking **and** advisory.

Do not move on to Step 6 until completing two full clean review passes with zero findings. If sub-agents are still executing, wait for them to finish and aggregate their findings before proceeding.

Always report aggregated findings to the user. If there are zero findings on both axes, report "no findings" and continue to Step 6.

## Step 6 — Copilot PR review

Invoke the `address-copilot-comments` skill to push the branch, create a PR if needed, and request a single Copilot review (only when the diff warrants one) and address its comments. Once that is done, continue to Step 7.

## Step 7 — PR cleanup

Invoke the `pr-cleanup` skill. It commits the final issues-file housekeeping to the PR branch, closes GitHub issues, and shares the PR link for merging.
