# Issues: chore/code-review-audit-followups

> Work complete — PR ready to merge.

## code-review: audit follow-ups (CR-1, CR-2, CR-5, CR-10, CR-12)

**GitHub**: #147

**Blocked by**: None

**User stories**: 1, 2, 3, 4, 5, 6

### What to build

Fix the five audit findings in the `code-review` skill: detect committed work in Step 2,
disclose the legacy `review.md` migration to its own file, add the stop-after-Step-5 branch,
make the coverage criterion conditional on the repo's CI, and have the fixer snapshot the
working-tree status as well as the diff. Keep `allowed-tools` matching the commands run.

### Acceptance criteria

- [x] Given a branch whose work is fully committed and a clean working tree, when Step 2
      runs, then the review continues (CR-1).
- [x] Given no commits ahead of the fixed point and a clean working tree, when Step 2 runs,
      then the review stops and tells the user (CR-1).
- [x] Given a repo without `.agent-docs/review.md`, when Step 4 runs, then the agent reads
      no migration procedure; given one with it, Step 4 points to
      `MIGRATE-LEGACY-REVIEW.md`, which holds the full procedure (CR-2).
- [x] Given a caller that asked for Steps 1–5 only, when the Step 5 exit rule is met, then
      `code-review` stops and returns without running Steps 6 or 7 (CR-5).
- [x] Given a repo whose CI enforces no coverage threshold, when the Standards reviewer
      applies the coverage criterion, then it flags untested new paths without citing a
      threshold (CR-10).
- [x] Given a blocked finding that created a new untracked file, when the fixer rolls back,
      then the snapshot's status identifies that file for removal (CR-12).
- [x] `allowed-tools` matches the commands the skill runs, and the `unittest` suite passes.

---
