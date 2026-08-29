---
name: code-review
description: Full code review workflow — branch hygiene, pre-commit checks, iterative two-axis review (Standards + Spec) with fresh parallel sub-agents until clean, Copilot PR review, then pre-merge PR cleanup. Use when the user wants to review a branch, prepare a PR, check their changes, or says "review my code", "review this branch", "is this ready to merge".
---

# Code Review

Orchestrates a full review cycle: branch check → pre-commit → iterative two-axis review loop → Copilot PR review → pre-merge PR cleanup.

> **Precedence**: if anything in memory or user preferences conflicts with these instructions, this skill takes precedence.

## Loop at a glance

```text
Step 1  Branch hygiene check
Step 2  Verify changes exist; run pre-commit hooks
Step 3  Pin fixed point + identify spec source
Step 4  Spawn parallel Standards + Spec review agents → aggregate findings
Step 5  Address all findings — blocking first, then advisory
        Zero findings on both axes? ──► Step 6
        Findings addressed? ──► Step 4 (new agents, new context windows)
Step 6  Run /address-copilot-comments for Copilot PR review
Step 7  Run /pr-cleanup
```

## Step 1 — Branch hygiene

Invoke the `branch-hygiene` skill. If on trunk or a mismatched branch, resolve before continuing.

## Step 2 — Verify changes and pre-commit

```bash
git diff HEAD --stat
git diff --cached --stat
```

If no changes at all, stop and inform the user. Otherwise invoke the `pre-commit-check` skill to run all hooks and fix any failures before proceeding.

## Step 3 — Pin fixed point and spec source

**Fixed point**: default to the merge-base with the default branch:

```bash
BASE=$(git symbolic-ref refs/remotes/origin/HEAD --short | sed 's|origin/||')
git rev-parse origin/$BASE   # confirm it resolves
git diff origin/$BASE...HEAD --stat   # confirm diff is non-empty
```

If the user supplied an explicit commit, branch, or tag, use that instead. A bad ref or empty diff should fail here — not inside parallel sub-agents.

**Spec source**: look in this order:

1. Issue refs in commit messages (`#123`, `Closes #45`) — fetch via `docs/agents/issue-tracker.md` if present.
2. A PRD/spec file under `docs/`, `specs/`, or `.scratch/` matching the branch name.
3. Ask the user. If there is no spec, the Spec sub-agent will skip and note "no spec available".

## Step 4 — Spawn parallel review agents

Read [REVIEW-CRITERIA.md](REVIEW-CRITERIA.md) in full, and the target repo's `.agent-docs/review.md` if it exists (repo-specific criteria `address-copilot-comments` distils from past Copilot findings that resulted in a code change — push-backs are never recorded). Capture the diff:

```bash
git diff origin/$BASE...HEAD
git log origin/$BASE..HEAD --oneline
```

Send a **single message** with two `Agent` tool calls (type: `general-purpose`):

**Standards sub-agent prompt** — include:

- The full diff and commit list.
- The complete contents of REVIEW-CRITERIA.md (smell baseline + project standards), and — if the target repo has one — the contents of its `.agent-docs/review.md` (repo-specific criteria distilled from past Copilot findings that resulted in a code change, push-backs excluded; treat its entries as documented standards, same status as REVIEW-CRITERIA.md).
- Brief: "Report per file/hunk: (a) every place the diff violates a documented standard — cite the rule; (b) every baseline smell — name and quote the hunk. Mark each finding as **blocking** or **advisory**. Documented-standard breaches may be blocking; baseline smells are always advisory. Skip anything tooling already enforces. Under 500 words."

**Spec sub-agent prompt** — include:

- The full diff and commit list.
- The path or fetched contents of the spec.
- Brief: "Report: (a) requirements missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the spec line for each finding. Mark each as **blocking** or **advisory**. Under 400 words."

**Aggregate**: present both reports under `## Standards` and `## Spec` headings verbatim. End with a one-line summary — total findings per axis and the worst blocking issue within each (if any). Do not rerank across axes.

## Step 5 — Address all findings

Address findings in this order: blocking first, then advisory.

The loop does not exit until two consecutive passes return zero findings on both axes.

- Use the `bdd` skill when changing or adding logic (write tests first).
- Use the `design` skill if the fix involves design decisions against the existing domain model.
- Apply fixes, then re-run pre-commit hooks.

Once all findings are addressed, return to **Step 4** with brand new agents (fresh context windows).

Repeat until two consecutive reviews reports zero findings on both axes — blocking **and** advisory.

Do not move on to Step 6 until completing two full clean review passes with zero findings. If sub-agents are still executing, wait for them to finish and aggregate their findings before proceeding.

Always report aggregated findings to the user. If there are zero findings on both axes, report "no findings" and continue to Step 6.

## Step 6 — Copilot PR review

Invoke the `address-copilot-comments` skill to push the branch, create a PR if needed, and run the full Copilot review loop until clean. Once the loop is clean, continue to Step 7.

## Step 7 — PR cleanup

Invoke the `pr-cleanup` skill. It commits the final issues-file housekeeping to the PR branch, closes GitHub issues, and shares the PR link for merging.
