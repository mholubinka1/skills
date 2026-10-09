# Copilot Review Once, Gated by Risk

## Problem Statement

`address-copilot-comments` requests up to two Copilot reviews per PR (a re-trigger after the first round of fixes) and gates the first one only coarsely: any functional or step-logic change is review-required. Copilot now reviews at Balanced effort by default, which costs more per review, so a second review and reviews of low-risk changes are wasted spend. GitHub documents no per-request way to choose Lite, so cost cannot be managed by effort level from the skill.

## Solution

Copilot reviews at most once per invocation, and only when the diff is risky enough to warrant it. Step 2b applies explicit risk criteria; low-risk diffs skip the review entirely, and everything else gets one Balanced review (the repository default). After that review's comments are addressed the skill commits, pushes, and finishes without re-triggering.

## User Stories

1. As an agent running `address-copilot-comments`, I want exactly one Copilot review per invocation, so that no second Balanced review is spent after fixes are applied.
2. As a maintainer, I want low-risk PRs (prose, formatting, no-logic config, test-only, pure renames, tiny isolated tweaks) to skip Copilot entirely, so that review spend goes where risk is.
3. As a maintainer, I want any trust-boundary, external-mutation, control-flow, contract or non-trivial-scope change to trigger a review, so that risky changes are never skipped.
4. As a maintainer, I want doubt to resolve towards reviewing, so that the gate fails safe.
5. As an agent, I want the criteria applied from diff content with concrete thresholds, so that the decision is repeatable rather than a judgment call.
6. As a caller of the skill (`code-review`, `implement`), I want the PR still reported ready at the end either way, so that the external contract is unchanged.
7. As a maintainer, I want the skill to never try to select a review effort level, so that it does not depend on undocumented API fields.

## Implementation Decisions

- **Step 2b criteria** replace the current classification rule. Review-required if the diff has any of: (1) trust-boundary change — auth, permissions, secrets handling, CI workflows, dependency manifests or lockfiles, shell execution of input; (2) external mutation — a new or changed command that writes outside the working tree (`gh api` writes, GraphQL mutations, `git push`, `gist edit`, file deletion); (3) control-flow change — new or changed branching, guards, loop termination, step ordering or error handling, including decisioning rules in skill files; (4) contract change — an interface, flag, output format or path that other files or callers depend on; (5) non-trivial scope — more than about 30 changed logic lines, or logic changes across 3 or more files.
- **Low-risk (skip)** only if every changed file is one of: prose / formatting / comment-only; config value tweak with no new script; test-only addition touching no production logic; rename or move with no content change; tiny isolated tweak (10 or fewer lines in one file, e.g. message string, constant, typo) matching none of criteria 1–4.
- **When unsure, trigger.**
- Worked-examples table in REFERENCE.md updated to match.
- **Single review**: remove `review_round` entirely; remove Step 6 (re-trigger) and Step 7 (re-poll). After Step 5 (commit and push) go to Step 7b. Renumber nothing else — retire Steps 6 and 7 cleanly, keeping Step 7b and Step 8 labels stable, or renumber consistently throughout; the loop-at-a-glance diagram, Step 7b guard (now keyed on "a review was requested at Step 2b" rather than `review_round`), and Loop termination conditions (drop "Max reviews reached") all updated.
- The trigger command and its PowerShell/GraphQL notes in REFERENCE.md move from "Step 6 — Re-trigger" to Step 2b's own section (the trigger is now used only once).
- No effort selection: the trigger stays `gh pr edit {number} --add-reviewer '@copilot'`; effort is the repository default (Balanced). Lite is out of the skill.
- Domain docs already updated: `.agent-docs/context.md` (**Single review** replaces **Review round**; **Review-required diff** sharpened) and an amendment to ADR 0004.
- Other skills referencing the two-round cap or re-trigger (`code-review`, `implement`, README) are checked and updated if they mention it.

## Testing Decisions

- No automated tests exist for these markdown skills. Seam: a dry-run trace of Step 2b against representative diffs, plus a trace of the post-fix path to confirm it ends at Step 7b/8 with no re-trigger.
- Representative diffs: docs-only (skip); typo in one SKILL.md string (skip); new `gh api` write (review); changed guard condition in a step (review); lockfile change (review); 40-line logic change in one file (review); mixed docs plus one criterion hit (review).
- A `code-review` pass over the change before merge.

## Out of Scope

- Choosing Lite or any effort level per request.
- Changes to Steps 3–5 poll/fix/push-back/commit mechanics beyond removing the second round.
- A live end-to-end PR run.
- Changes to how callers invoke the skill.

## Further Notes

Sources for the effort-level findings: GitHub changelog 2026-10-02 (API support, Balanced default) and 2026-09-23 (UI/settings); the REST requested_reviewers docs list no effort parameter and GraphQL introspection shows none.
