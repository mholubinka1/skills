# Copilot Review Trigger Decisioning

## Problem Statement

`address-copilot-comments` Step 2 assumes "the first Copilot review triggers automatically" when a PR is created. GitHub no longer auto-triggers a Copilot review on PR creation, so this assumption is false: the skill would create a PR, then poll forever (or until exhaustion) for a review that was never requested.

## Solution

Add a new Step 2b that decides, from the PR's diff content, whether the PR needs an initial Copilot review at all, and explicitly requests one when it does — replacing the auto-trigger the skill used to rely on. PRs limited to prose documentation, no-logic config, or trivial/formatting changes skip the trigger and the poll loop entirely; PRs with functional code or skill step-logic changes get an explicit review request before Step 3's poll begins.

## User Stories

1. As an agent running `address-copilot-comments` on a PR with functional or step-logic changes, I want the skill to explicitly request a Copilot review, so that the review loop still runs even though GitHub no longer triggers it automatically.
2. As an agent running `address-copilot-comments` on a docs-only or config-only PR, I want the skill to skip the review request and poll, so that trivial PRs aren't held up waiting for a review that has nothing to check.
3. As a maintainer of this skills repo, I want the review-required decision made from diff content rather than file extension, so that a `SKILL.md`/`REFERENCE.md` step-logic edit — this repo's actual "code" — isn't misclassified as documentation just because it's a `.md` file.
4. As a caller of `address-copilot-comments` (`code-review` Step 6, `implement` `WORKFLOW.md`), I want the loop to still terminate with the PR reported ready either way, so that the new decisioning doesn't change the skill's external contract.

## Implementation Decisions

- New **Step 2b — Decide whether Copilot review is required**, inserted in `address-copilot-comments/SKILL.md` after Step 1/2 (a PR number is guaranteed to exist by this point) and before Step 3's poll loop.
- Reads the full diff via `gh pr diff {number}` — content, not just changed filenames, since classification must distinguish a prose edit to `SKILL.md` from a step-logic edit to the same file.
- **Review-required**: any functional code change, or any `SKILL.md`/`REFERENCE.md` step-logic edit (commands, decisioning, GraphQL mutations, branching).
- **Exempt**: prose-only documentation, no-logic config, or formatting/whitespace/comment-only diffs. A diff is exempt overall only if every changed file is exempt.
- **Not required** → skip straight to Step 8 (report PR ready). No poll, no `review_round` set.
- **Required** → trigger via the same mechanism Step 6 already uses (`gh pr edit {number} --add-reviewer '@copilot'`, PowerShell quoting caveat and GraphQL fallback documented in `REFERENCE.md`'s existing Step 6 section — reused, not duplicated), set `review_round = 1`, continue to Step 3.
- Remove `review_round = 1` from Step 1 and Step 2's text (currently set unconditionally there) — it is now set only in Step 2b, only when a trigger fires.
- Remove Step 2's now-false line: "The first Copilot review triggers automatically."
- Update the "Loop at a glance" ASCII diagram to show the new Step 2b branch (required → Step 3; not required → Step 8).
- Add a short section to `REFERENCE.md` documenting the `gh pr diff` command and the review-required/exempt classification, cross-referenced from Step 2b.
- Step 6's existing re-trigger logic (`review_round >= 2` → skip; otherwise increment and re-trigger) is unchanged — the new decisioning only gates the initial trigger, not round 2.
- Domain docs already updated (not part of this implementation pass): `.agent-docs/context.md` has a "Review-required diff" term; `.agent-docs/adr/0004-explicit-copilot-trigger-gated-by-review-required-diff.md` records why unconditional triggering and extension-based classification were rejected.

## Testing Decisions

- No automated test suite exists for these skills — they are markdown instructions, not executable code.
- Verification is a dry-run trace of Step 2b's decisioning against representative example diffs: a pure `.agent-docs/`-only PR (exempt), a `SKILL.md` step-logic PR (required), and a mixed PR touching both (required, since not every file is exempt).
- A `code-review` skill pass over the change itself before merge, consistent with how other changes to this skill (e.g. `step4b-explicit-skip-guard`, `address-copilot-clean-review-exit`) were verified.

## Out of Scope

- Changes to Step 6's round-2 re-trigger logic.
- Changes to Step 3–7's poll/fix/push-back/commit mechanics.
- A live end-to-end test PR run through the actual loop.
- Any change to how `code-review` or `implement` invoke `address-copilot-comments` — the external contract (push branch, create PR if needed, run the loop until clean, report PR ready) is unchanged.

## Further Notes

This spec's domain-doc changes (`context.md` term, ADR 0004) were already written during the `/design` session earlier in this conversation, before `/implement`'s worktree was created, then ported into this worktree since it branched fresh from `origin/main`.
