# Issues: chore/copilot-review-once-gated

> Work complete — PR ready to merge.

## Copilot reviews once per invocation

**GitHub issue**: #113

**Blocked by**: None

**User stories**: 1, 6

### What to build

Make `address-copilot-comments` request Copilot at most once per invocation. Remove `review_round`, Step 6 (re-trigger) and Step 7 (re-poll). After fixes are committed and pushed (Step 5) the flow goes to Step 6 (distil criteria, formerly 7b) then Step 7 (report, formerly 8). Step 6's guard keys on "a review was requested at Step 2b". Move the trigger command and its PowerShell/GraphQL notes into Step 2b's own REFERENCE.md section. Update the loop-at-a-glance diagram and Loop termination conditions. Check other skills and README for mentions of the two-round cap.

### Acceptance criteria

- [x] Given a review-required PR whose first review yields fixes, when Step 5 completes, then the skill goes to Step 6/7 without re-triggering or re-polling.
- [x] Given a clean first review, then the skill goes to Step 6/7 as before.
- [x] No reference to `review_round`, the 2-review cap, or "Re-trigger" remains in the skill, REFERENCE.md, or other skills.
- [x] The trigger command (with PowerShell and GraphQL fallback notes) is documented once, under Step 2b.
- [x] The loop-at-a-glance diagram and Loop termination conditions match the single-review flow.

---

## Gate Copilot review on risk criteria

**GitHub issue**: #114

**Blocked by**: #113

**User stories**: 2, 3, 4, 5, 7

### What to build

Replace Step 2b's classification rule (SKILL.md summary and REFERENCE.md section) with the risk criteria: review-required on any of trust-boundary change, external mutation, control-flow change, contract change, or non-trivial scope (over about 30 logic lines or 3+ files); low-risk only if every changed file is prose/formatting, no-logic config, test-only, pure rename, or a tiny isolated tweak (10 or fewer lines, one file, no criterion hit). When unsure, trigger. Update the worked-examples table. Do not attempt to select a review effort level.

### Acceptance criteria

- [x] Given a docs-only diff, or a one-line message-string typo, when Step 2b runs, then it skips the review.
- [x] Given a new `gh api` write, a changed guard condition, or a lockfile change, then it triggers a review.
- [x] Given a 40-line logic change in one file, or logic changes across 3 files, then it triggers a review.
- [x] Given a mixed diff with docs plus one criterion hit, then it triggers a review.
- [x] Given doubt about a criterion, then it triggers.
- [x] The worked-examples table covers each of the above.

---
