# Issues: chore/stale-rationale-review-check

## Flag unswept stale design-rationale comments in code review

**GitHub**: #48

**Blocked by**: None

**User stories**: 1, 2

### What to build

Add a bullet to `code-review/REVIEW-CRITERIA.md`'s `## Documentation` section instructing
the Standards reviewer: when a diff changes a documented design rationale or invariant, grep
the repo for the old rationale phrase and flag (blocking) any other occurrence left unswept
in the same diff.

### Acceptance criteria

- [ ] `code-review/REVIEW-CRITERIA.md`'s Documentation section has a new bullet covering this
      check.
- [ ] The bullet specifies the trigger (a diff changes a documented rationale/invariant), the
      action (grep the repo for the old phrase), and the outcome (blocking finding for any
      unswept occurrence).
- [ ] No existing bullet's wording changes.
- [ ] `pre-commit-check` passes on the file.

---
