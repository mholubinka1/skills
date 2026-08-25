# Extract Copilot Review Poll Logic Into a Bundled Script

## Problem Statement

`address-copilot-comments/REFERENCE.md`'s poll logic — baseline review-ID capture, an
unresolved-thread GraphQL query, a suppressed-comment body fetch plus regex count, and a
current-review-ID re-fetch — is written out as inline bash blocks twice: once for Step 3's
initial poll loop and again (by reference, "poll as in Step 3") for Step 7's re-poll after a
re-triggered review. Because it's markdown prose rather than a single source of truth, the
same class of subtle `gh`/jq bug that already cost 10 failed poll attempts in a real PR (see
the `chore/gh-jq-arg-pitfall-doc` fix) has two places it could be introduced or drift between.

## Solution

Extract the three checks (thread count, suppressed-comment count, review-ID-changed) into one
bundled script, `address-copilot-comments/scripts/check-review-status.sh`, that both Step 3
and Step 7 call. The script also centralizes the branching decision the two steps currently
spell out identically, reporting it as a single `DECISION` value.

## User Stories

1. As an agent following `address-copilot-comments`, I want the poll check to live in one
   script instead of duplicated bash blocks, so that a bug in the check logic only needs
   fixing in one place.
2. As an agent running Step 3 or Step 7, I want a single command that tells me whether to
   proceed to Step 4, Step 8, or wait and retry, so that I don't have to re-derive the
   three-way branching from prose each time.

## Implementation Decisions

- New file: `address-copilot-comments/scripts/check-review-status.sh`.
- Interface: `check-review-status.sh <owner> <repo> <pr_number> [baseline_review_id]`,
  invoked as `bash "<skill-base-dir>/scripts/check-review-status.sh" ...` — always via `bash
  <path>`, never relying on the shebang/execute bit, since skill files sync across OSes and
  the execute bit isn't guaranteed to survive that sync.
- `<skill-base-dir>` is the path already shown as "Base directory for this skill" when
  `address-copilot-comments` is invoked — not the caller's working directory, which is the
  target repo being worked on, not the skills repo.
- Output: four `KEY=value` lines on stdout — `THREAD_COUNT`, `SUPPRESSED_COUNT`,
  `CURRENT_REVIEW_ID`, and a computed `DECISION` (`ACTIONABLE` | `CLEAN` | `PENDING`). Always
  exits 0; callers branch on the `DECISION` line, not the exit code.
- The one-time "capture baseline before polling" step becomes a single no-baseline call to
  the same script, using its `CURRENT_REVIEW_ID` output as the baseline for later calls. If
  that first call already reports `DECISION=ACTIONABLE`, the poll loop is skipped entirely.
- The script does not return the Copilot review body text (only the suppressed-comment
  count) — Step 4 re-fetches the body itself when it needs to read suppressed-comment entries
  for real, since embedding arbitrary multi-line markdown into single-line `KEY=value` output
  is fragile to parse reliably.
- No ADR: reverting to inline bash later is a low-cost change if this pattern doesn't pan
  out, so it fails the "hard to reverse" bar for recording a decision.

## Testing Decisions

- No shell-test harness (bats, shellspec, etc.) exists in this repo, and `gh api` is the
  script's only real dependency — building a mocking harness for one script is out of
  proportion to the script itself.
- Verified manually against a real PR (`mholubinka1/skills#45`, already merged) during
  implementation: confirmed `CLEAN` (thread resolved, review ID present) and `PENDING`
  (explicit baseline equal to current ID) outputs against live `gh api` data. `ACTIONABLE`
  was already exercised live during that PR's own review round.

## Out of Scope

- A shell-testing framework for this repo generally.
- Changing Step 4's suppressed-comment handling beyond re-fetching the review body itself
  (previously it reused a `$REVIEW_BODY` shell variable set inline in Step 3's own bash,
  which no longer exists once that logic moves into a separate script process).

## Further Notes

This is the second of six small fixes queued from a retrospective on a recent PR; each is
being run through its own `/implement` loop rather than bundled together. Unlike fix #1
(pure documentation), this one is scoped down from its original "nice-to-have" framing after
confirming with the user that the motivating bug is already fixed and this is purely a
DRY/robustness improvement.
