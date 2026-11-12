# address-copilot-comments: push before PR, resolve only decided threads, enforce the poll window

## Problem Statement

Three defects in `address-copilot-comments` (GitHub issues #144 and #132):

- **ACC-1**: Step 2 runs `gh pr create` without pushing the branch first. On a branch that
  was never pushed, the create fails or prompts.
- **ACC-2**: the reference's resolve step lists **every** unresolved review thread on the
  PR and resolves each one, so a human reviewer's open thread is resolved along with
  Copilot's.
- **#132**: the Step 3 poller sub-agent sequences its own `sleep 60` calls between status
  checks. On PR #131 it skipped them and returned `PENDING` after 28 seconds. `PENDING`
  routes to Step 6, so a Copilot review that lands a minute later goes unread.

## Solution

Push before creating the PR. Resolve only the threads this run decided on. Move the waiting
into a script, so one Bash call covers a run of polls, and have the main context reject a
`PENDING` that arrives before the full poll window has run.

## User Stories

1. As a user whose branch has never been pushed, I want Step 2 to push it before creating
   the PR, so that PR creation succeeds without manual steps.
2. As a human reviewer with an open thread on the PR, I want the skill to resolve only the
   Copilot threads it decided on, so that my thread stays open.
3. As a user waiting on a Copilot review, I want the poll window to actually elapse before
   `PENDING` is accepted, so that a review landing within the window is read.
4. As a user, I want a poll that stopped short to be reported as an error, so that I know
   Copilot's review may not have been read instead of the PR being called ready to merge.

## Implementation Decisions

- **ACC-1 — SKILL Step 2**: `git push`, then `gh pr create`. The step is done when
  `gh pr view` returns the PR. `allowed-tools` already scopes the bare `git push`; no
  argument form is added, since the frontmatter guard forbids pre-approving
  `git push <args>`. A push that fails (for example no upstream and `push.autoSetupRemote`
  unset) is reported, and the step stops.
- **ACC-2 — REFERENCE, resolve subsection**: the "get unresolved thread node IDs" query is
  removed. The resolve mutation takes the `threadId` already carried on each decision. The
  Step 5 handover in SKILL says the same.
- **#132 — new poll script** `scripts/poll-review-status.sh`, beside the existing
  status-check script, which stays the single-check primitive:
  - Usage: `poll-review-status.sh <owner> <repo> <pr_number> <baseline_review_id> [max_polls]`.
    The baseline is required and may be an empty string. `max_polls` defaults to 5.
  - Each poll waits `POLL_INTERVAL_SECONDS` (default 60), then runs the status check. It
    stops at the first result other than `PENDING`.
  - Output: the last check's four lines, then `POLLS_RUN=<n>`.
  - Exit codes follow the status-check script: 0 for a well-formed call, 2 for bad usage.
- **Poll window**: one baseline capture call, then two calls of the poll script at 5 polls
  each (about 5 minutes per call, inside the 10-minute Bash limit), 10 polls in total. The
  separate "final check" goes; the tenth poll is the final one. The poller no longer runs
  `sleep` itself, so `Bash(sleep 60)` leaves `allowed-tools` and the poll script's entry
  joins it.
- **Guard in the main context**: the poller returns `POLLS_RUN` summed over its calls.
  `PENDING` with fewer than 10 polls is treated as `ERROR` — reported, and Step 7 leaves
  out "ready to merge". A Step 5b re-poll follows the same rule.

## Testing Decisions

- The poll script is executable behaviour, so it gets `unittest` coverage in `tests/`, run
  through `bash` with a stub `gh` on `PATH` (the system boundary) and a zero interval:
  pending-then-clean, pending to the cap, actionable at once, a `gh` failure, bad usage.
- The SKILL and REFERENCE changes are prose; the frontmatter guard tests cover
  `allowed-tools`.

## Out of Scope

- Other audit findings against this skill not listed in #144.
- Changing the status-check script's decisions.
- Changing the review-level rubric or the 60-second interval.

## Further Notes

Closes #144 and #132.
