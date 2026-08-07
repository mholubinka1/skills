# Issues: chore/address-copilot-review-trigger-decisioning

> Work complete — PR ready to merge.

## Add Step 2b review-required decisioning to address-copilot-comments

**GitHub issue**: #42

**Blocked by**: None

**User stories**: 1, 2, 3, 4

### What to build

A new Step 2b in `address-copilot-comments/SKILL.md`, inserted after Step 1/2 (PR exists/create) and before Step 3's poll loop, that decides from the PR's diff content (`gh pr diff {number}`) whether an initial Copilot review is required, and explicitly triggers one when it is — replacing the auto-trigger assumption GitHub no longer honors.

Classify by content, not file extension: functional code changes or `SKILL.md`/`REFERENCE.md` step-logic edits (commands, decisioning, mutations, branching) are review-required; prose-only docs, no-logic config, and formatting-only diffs are exempt. A diff is exempt overall only if every changed file is exempt.

Not required → skip straight to Step 8, no poll, no `review_round` set. Required → trigger via the same mechanism Step 6 already uses, set `review_round = 1`, continue to Step 3.

Remove Step 1/2's unconditional `review_round = 1` and Step 2's now-false "the first Copilot review triggers automatically" line. Update the "Loop at a glance" diagram to show the new branch. Add a `REFERENCE.md` section documenting the `gh pr diff` command and the classification rule, cross-referenced from Step 2b and reusing (not duplicating) Step 6's existing trigger section.

### Acceptance criteria

- [x] Given a PR whose diff is entirely within `.agent-docs/`, when Step 2b runs, then it classifies as exempt and skips straight to Step 8 without triggering or polling.
- [x] Given a PR whose diff includes a step-logic edit to `SKILL.md`/`REFERENCE.md`, when Step 2b runs, then it classifies as review-required, triggers Copilot, sets `review_round = 1`, and continues to Step 3.
- [x] Given a PR whose diff mixes exempt files with one functional code file, when Step 2b runs, then it classifies as review-required (not every file exempt).
- [x] Given a review-required PR completes round 1 with unresolved threads, when Step 6 runs, then it still re-triggers for round 2, unaffected by Step 2b.
- [x] The "Loop at a glance" diagram reflects the new Step 2b branch.
- [x] `REFERENCE.md` documents the `gh pr diff` command and classification rule without duplicating Step 6's trigger command section.

---
