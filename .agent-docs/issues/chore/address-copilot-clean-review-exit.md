# Issues: chore/address-copilot-clean-review-exit

> Work complete — PR ready to merge.

## Add clean-review early exit to Step 3 polling loop

**Blocked by**: None

**User stories**: 1, 2, 3, 4

### What to build

Update `address-copilot-comments/SKILL.md` and `address-copilot-comments/REFERENCE.md` so the Step 3 polling loop (and the Step 7 re-poll) can detect when Copilot has reviewed clean and exit to Step 8 immediately, rather than exhausting all 10 attempts.

Before the poll loop begins, capture the latest Copilot review ID as a baseline. Within each iteration, after the existing thread-count check returns 0, compare the current latest Copilot review ID against the baseline. If a new review has been submitted (IDs differ), Copilot reviewed clean — skip to Step 8. If no new review, continue polling as today.

### Acceptance criteria

- [x] The loop diagram in `SKILL.md` shows the new clean-review (new review + 0 threads) path exiting to Step 8.
- [x] Step 3 prose in `SKILL.md` describes recording a baseline review ID before polling and the early Step 8 exit condition.
- [x] `REFERENCE.md` Step 3 opens with a baseline capture command (`gh api .../reviews`) before the poll loop.
- [x] The 0-thread branch in `REFERENCE.md` includes the reviews ID comparison and an explicit "go to Step 8" instruction.
- [x] The thread count > 0 path exits to Step 4 unchanged.
- [x] Step 7's "poll as in Step 3" delegation is confirmed to inherit the new behaviour without a separate change to Step 7.

---
