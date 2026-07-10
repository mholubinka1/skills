# address-copilot-comments: Early exit for clean Copilot review

## Problem Statement

When Copilot reviews a PR and finds nothing to comment on (a "clean" review), the `address-copilot-comments` skill's Step 3 polling loop has no way to detect this. It polls for unresolved threads every 60 seconds for up to 10 attempts, finds zero threads each time, and only exits after the full 10-minute wait. The skill wastes time and gives the user no signal that Copilot has already finished reviewing.

## Solution

Before the polling loop begins, record the latest Copilot review ID as a baseline. Within each poll iteration, after detecting zero unresolved threads, check whether a new Copilot review has been submitted (latest review ID differs from baseline). If yes, Copilot reviewed clean — exit to Step 8 immediately rather than continuing to poll. This applies to both the initial Step 3 poll and the Step 7 re-poll, which delegates to the same logic.

## User Stories

1. As an engineer running `address-copilot-comments` after a PR push, I want the skill to detect when Copilot has reviewed clean, so that I am not blocked waiting 10 minutes for a result that is already available.
2. As an engineer iterating on a PR, I want the same early-exit behaviour to apply after re-triggering Copilot in Step 6, so that a second clean review also exits promptly.
3. As an engineer whose PR has real Copilot comments, I want the existing loop behaviour (exit to Step 4 when threads > 0) to remain unchanged, so that fixes are not skipped.
4. As an engineer whose PR is reviewed by Copilot before the baseline is captured, I want the skill to fall through safely to the existing 10-attempt exhaustion path and Step 8, so that correctness is maintained even in the fast-review edge case.

## Implementation Decisions

- **Baseline capture**: at the start of each polling window (Step 3 entry and Step 7 re-poll entry), run `GET /repos/{owner}/{repo}/pulls/{number}/reviews`, filter to Copilot-authored reviews, and record the ID of the last one. An empty result means no Copilot review exists yet; any review that subsequently appears is considered new.
- **Per-iteration sequence**: thread count check runs first (unchanged). If thread count > 0, exit to Step 4 as today. If thread count = 0, run the reviews check: if the latest Copilot review ID differs from the baseline, exit to Step 8 (clean review). If the ID matches or is still empty, continue polling.
- **Scope**: applies to both Step 3 and Step 7. Step 7 already delegates to "poll as in Step 3", so the same baseline-capture-then-poll pattern is followed on re-entry.
- **No change to termination conditions**: the 10-attempt exhaustion + final check + Step 8 fallthrough is preserved for cases where no new review arrives within the polling window.
- **Files changed**: `address-copilot-comments/SKILL.md` (loop diagram and Step 3 prose) and `address-copilot-comments/REFERENCE.md` (baseline capture command block and 0-thread branch reviews check).

### Baseline capture command

```bash
gh api repos/{owner}/{repo}/pulls/{number}/reviews \
  --jq '[.[] | select(.user.login | test("copilot";"i"))] | last | .id // empty'
```

Store the result as `BASELINE_REVIEW_ID`. Empty means no Copilot review yet.

### Per-iteration 0-thread branch (new logic)

```bash
CURRENT_REVIEW_ID=$(gh api repos/{owner}/{repo}/pulls/{number}/reviews \
  --jq '[.[] | select(.user.login | test("copilot";"i"))] | last | .id // empty')

if [ "$CURRENT_REVIEW_ID" != "$BASELINE_REVIEW_ID" ] && [ -n "$CURRENT_REVIEW_ID" ]; then
  # Copilot reviewed clean — go to Step 8
fi
```

## Testing Decisions

Skills are Markdown instruction files with no executable test harness. Correctness is verified by human review of the updated files against the acceptance criteria:

1. The loop diagram in `SKILL.md` shows the new clean-review exit path from Step 3.
2. `REFERENCE.md` Step 3 opens with the baseline capture command before the poll loop.
3. The existing GraphQL thread-count query runs first in each iteration.
4. The 0-thread branch in `REFERENCE.md` includes the reviews ID comparison and the Step 8 exit instruction.
5. Step 7's description ("poll as in Step 3") is confirmed to inherit the new behaviour without a separate change.

## Out of Scope

- Changes to Step 4, Step 5, Step 6, or Step 8 logic.
- Handling network errors or API failures in the reviews check — the skill already tolerates poll failures by counting them as non-matches and continuing.
- Reducing the 10-attempt maximum or the 60-second interval.
- Any changes to skills other than `address-copilot-comments`.

## Further Notes

The reviews check is intentionally placed in the 0-thread branch (Option B from the design session) to avoid an extra API call on the happy path where threads are already present. The clean-review case is the only ambiguous one: thread count = 0 could mean "Copilot hasn't reviewed yet" or "Copilot reviewed and found nothing" — the reviews endpoint is what disambiguates it.
