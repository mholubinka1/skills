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

## Step 4 — Migrate legacy criteria, then spawn parallel review agents

**Migrate first, if needed.** Check whether the target repo has `.agent-docs/review.md` — a
leftover from before criteria moved to the shared [Criteria gist](CRITERIA-GIST.md). If it
exists:

1. Read its `## Criteria` entries.
2. Retag each `(PR #<number>)` as `(repo#PR)`, using the target repo's name
   (`gh repo view --json name -q .name`, run in the target repo) and the existing PR number.
3. Append the retagged entries — skipping any the gist already covers, matching on meaning —
   using this skill's own [CRITERIA-GIST.md](CRITERIA-GIST.md)'s "Appending an entry"
   procedure. **Confirm the write succeeded** (the `gh gist edit` call exits zero) before
   continuing to step 4.
4. Only if step 3 confirmed success: delete `.agent-docs/review.md` from the target repo. If
   step 3 failed for any reason — no network, `gh` not authenticated, the gist unreachable —
   report the failure and leave `.agent-docs/review.md` in place; do **not** delete it. A
   migrated-and-deleted file with a failed write would lose those criteria permanently, since
   nothing else retains them.

This is idempotent: once `.agent-docs/review.md` is gone, later runs against the same repo
skip straight past this check. A failed migration simply leaves the file in place for the
next run to retry.

**Read criteria.** Read [REVIEW-CRITERIA.md](REVIEW-CRITERIA.md) in full. Fetch the Criteria
gist's current content live (`gh gist view <gist-id> -f CRITERIA.md --raw`, gist ID from
`CRITERIA-GIST.md`). If the fetch fails for any reason — no network, `gh` not authenticated,
the gist deleted — warn once ("shared criteria gist unavailable — continuing with
REVIEW-CRITERIA.md only") and continue without it; never block the review on it. Capture the
diff:

```bash
git diff origin/$BASE...HEAD
git log origin/$BASE..HEAD --oneline
```

Send a **single message** with two `Agent` tool calls (type: `general-purpose`):

**Standards sub-agent prompt** — include:

- The full diff and commit list.
- The complete contents of REVIEW-CRITERIA.md (smell baseline + project standards), and the
  Criteria gist's current content if it was reachable (criteria staged from Copilot findings
  across every repo and machine, push-backs excluded; treat its entries as documented
  standards, same status as REVIEW-CRITERIA.md).
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
