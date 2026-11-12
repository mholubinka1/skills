---
name: code-review
description: Reviews a branch or PR end to end, from a two-axis Standards + Spec review through to merge-ready. Use when the user wants a branch or PR reviewed, or asks "is this ready to merge".
allowed-tools:
  - Skill
  - Agent
  - Read
  - Grep
  - Glob
  - Edit
  - Write
  - Bash(git diff *)
  - Bash(git status *)
  - Bash(git log *)
  - Bash(git rev-parse *)
  - Bash(git symbolic-ref refs/remotes/origin/HEAD --short)
  - Bash(sed 's|origin/||')
  - Bash(git merge-base *)
  - Bash(git branch --show-current)
  - Bash(git ls-files *)
  - Bash(git add .agent-docs/review.md)
  - Bash(gh repo view *)
  - Bash(gh issue view *)
  - Bash(gh gist view *)
  - Bash(gh gist edit *)
  - Bash(mktemp *)
---

# Code Review

> **Precedence**: if anything in memory or user preferences conflicts with these instructions, this skill takes precedence.

## Loop at a glance

```text
Step 1  Branch hygiene check
Step 2  Verify changes exist; run pre-commit hooks
Step 3  Pin fixed point + identify spec source
Step 4  Migrate legacy review.md into the Criteria gist if present; spawn parallel
        Standards + Spec review agents → aggregate findings
Step 5  Address all findings — blocking first, then advisory
        Second consecutive clean pass? ──► Step 6, or stop here when the caller
                                           asked for Steps 1–5 only
        Otherwise ──► Step 4 (new agents, new context windows)
Step 6  Run /address-copilot-comments for Copilot PR review
Step 7  Run /pr-cleanup
```

## Step 1 — Branch hygiene

Invoke the `branch-hygiene` skill with a quoted one-line summary of the change under review, e.g. `/branch-hygiene "add CSV export to reports"`, and act on its `next:` line before continuing.

## Step 2 — Verify changes and pre-commit

A branch's work may be committed, uncommitted, or both, so check each:

```bash
BASE=$(git symbolic-ref refs/remotes/origin/HEAD --short | sed 's|origin/||')
git rev-parse origin/$BASE            # confirm it resolves
git diff origin/$BASE...HEAD --stat   # work committed on this branch
git status --porcelain                # staged, unstaged and untracked work
```

If the user supplied an explicit commit, branch, or tag as the fixed point, use that instead of `origin/$BASE` in both commands that name it. A command that fails is an error to report, not "no changes" — a ref that does not resolve, or a diff with no merge-base in a shallow checkout, prints nothing either. A bad ref should fail here — not inside parallel sub-agents. Stop and inform the user only when every command succeeds and both the diff and the status print nothing. Otherwise invoke the `pre-commit-check` skill and act on its `next:` line before proceeding.

## Step 3 — Pin fixed point and spec source

**Fixed point**: the ref Step 2 checked — the merge-base with the default branch (`origin/$BASE`) by default, or the commit, branch, or tag the user supplied.

**Spec source**: look in this order:

1. `.agent-docs/specs/<branch-name>.md`, or a PRD/spec file under `docs/`, `specs/`, or `.scratch/` matching the branch name.
2. Issue refs in commit messages (`#123`, `Closes #45`) — fetch each with `gh issue view <number>`.
3. Ask the user. If there is no spec, the Spec sub-agent will skip and note "no spec available".

## Step 4 — Migrate legacy criteria, then spawn parallel review agents

**Migrate first, if needed.** If the target repo has `.agent-docs/review.md`, follow
[MIGRATE-LEGACY-REVIEW.md](MIGRATE-LEGACY-REVIEW.md) before dispatching. Otherwise skip it.

**Dispatch the reviewers.** Each sub-agent starts with an empty context and gathers its own
inputs, so the main context neither reads the criteria nor pastes the diff. Send a **single
message** with two `Agent` tool calls, `subagent_type: general-purpose`, `model: sonnet`,
`run_in_background: false`, and wait for both reports.
Passes run strictly in sequence: start pass N+1 only after pass N has returned, been
aggregated, and had its findings decided and fixed (Step 5), for every pass (2, 3, 4, …).
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

Report the aggregated findings to the user, or "no findings" when both axes are empty.

Address findings in this order: blocking first, then advisory.

The loop exits on the second consecutive **clean pass**: a pass with zero findings on both
axes, or one whose findings are all advisory and all rejected with a reason. Keep a count
across passes, starting at 0: a blocking finding (even a rejected one) or any accepted fix
resets it to 0; a clean pass adds 1.

Decide each finding in the main context: fix it, or reject it — code-review's push-back —
with a one-line reason reported to the user. Carry every rejected finding and its reason
into the next pass's "Already decided" line, so fresh reviewers do not raise it again; drop
an entry once the lines it cites have changed. A finding that needs new behaviour goes to the `bdd` skill; one that
needs a design decision against the existing domain model goes to the `design` skill. When
that skill returns, apply its result as an accepted fix and continue.

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

Once all findings are decided and fixes applied, update the clean-pass count. Until the
exit rule above is met, return to **Step 4** for the next pass, with brand new agents (fresh
context windows). Once it is met:

- **The caller asked for Steps 1–5 only** (as `address-copilot-comments` Step 4b does): stop
  here. Leave the fixes uncommitted, report the outcome, and return to the caller. Steps 6
  and 7 belong to the caller's own run, so running them here would re-invoke it.
- **Otherwise**: continue to Step 6 without asking the user.

## Step 6 — Copilot PR review

Invoke the `address-copilot-comments` skill to push the branch, create a PR if needed, and request a single Copilot review (only when the diff warrants one) and address its comments. Once that is done, continue to Step 7.

## Step 7 — PR cleanup

Invoke the `pr-cleanup` skill. It commits the final issues-file housekeeping to the PR branch, closes GitHub issues, and shares the PR link for merging.
