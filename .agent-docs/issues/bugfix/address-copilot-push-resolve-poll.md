# Issues: bugfix/address-copilot-push-resolve-poll

## address-copilot-comments: Haiku poller can return PENDING before the poll window elapses

**GitHub**: #132

**Blocked by**: None

**User stories**: 3, 4

### What to build

A poll script that owns the waits between status checks and reports how many polls it ran.
The poller sub-agent calls it instead of sequencing sleeps, and the main context rejects a
`PENDING` that arrives with fewer than the full number of polls.

### Acceptance criteria

- [ ] Given no new review for two polls and a clean one on the third, when the poll script
      runs, then it prints `DECISION=CLEAN` and `POLLS_RUN=3`.
- [ ] Given no review within the cap, when the poll script runs, then it prints
      `DECISION=PENDING` and `POLLS_RUN` equal to the cap.
- [ ] Given a `gh` failure, when the poll script runs, then it stops at once with
      `DECISION=ERROR`.
- [ ] Given a poller that returns `PENDING` with fewer than 10 polls, when Step 3 or
      Step 5b reads its report, then the result is handled as `ERROR`, not routed to Step 6
      as a finished wait.
- [ ] `allowed-tools` scopes the poll script and no longer lists `sleep 60`.

---

## address-copilot-comments: audit follow-ups (ACC-1, ACC-2)

**GitHub**: #144

**Blocked by**: None

**User stories**: 1, 2

### What to build

Step 2 pushes the branch before creating the PR. The resolve step resolves only the threads
named in this run's decisions.

### Acceptance criteria

- [ ] Given a branch that was never pushed, when Step 2 runs, then it pushes before
      `gh pr create`, and is done when `gh pr view` returns the PR (ACC-1).
- [ ] Given a PR with an unresolved human thread, when Step 5 resolves threads, then only
      the `threadId`s in the decisions are resolved (ACC-2).
- [ ] `allowed-tools` matches the commands the skill runs.

---
