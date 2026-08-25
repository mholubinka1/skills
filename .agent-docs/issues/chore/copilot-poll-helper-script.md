# Issues: chore/copilot-poll-helper-script

## Extract Copilot review poll logic into a bundled script

**GitHub**: #46

**Blocked by**: None

**User stories**: 1, 2

### What to build

Add `address-copilot-comments/scripts/check-review-status.sh`, taking
`<owner> <repo> <pr_number> [baseline_review_id]` and printing `THREAD_COUNT`,
`SUPPRESSED_COUNT`, `CURRENT_REVIEW_ID`, and `DECISION` (`ACTIONABLE`/`CLEAN`/`PENDING`).
Update `REFERENCE.md`'s Step 3 (baseline capture + poll loop) to call this script instead of
the inline bash blocks it currently repeats, and update Step 4's suppressed-comment section
to re-fetch the review body directly (it can no longer reuse a `$REVIEW_BODY` variable set by
Step 3's own inline bash, since that logic now lives in a separate script process).

### Acceptance criteria

- [ ] `address-copilot-comments/scripts/check-review-status.sh` exists, is invoked via
      `bash <path>`, and outputs the four documented `KEY=value` lines.
- [ ] The script correctly reports `ACTIONABLE`, `CLEAN`, `PENDING`, and `ERROR` against real
      `gh api` data (verified manually against a real PR), including that a 3-argument
      (no-baseline) call never reports `CLEAN` even when a prior review already exists.
- [ ] Owner/repo/pr_number are validated against GitHub's identifier charset and passed as
      bound GraphQL variables (not string-concatenated into the query), and a malformed
      invocation exits 2 with a usage message rather than crashing under `set -u`.
- [ ] `REFERENCE.md`'s Step 3 baseline capture and poll loop call the script instead of
      repeating the inline `gh api`/GraphQL/jq blocks.
- [ ] `REFERENCE.md`'s Step 4 suppressed-comments section fetches the review body itself
      rather than referencing a `$REVIEW_BODY` variable from Step 3.
- [ ] `pre-commit-check` passes on all changed files.

---
