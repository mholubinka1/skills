# Issues: chore/stale-rationale-review-check

## Flag unswept stale design-rationale comments in code review

**GitHub**: #48

**Blocked by**: None

**User stories**: 1, 2

### What to build

Add a bullet to `code-review/REVIEW-CRITERIA.md`'s `## Documentation` section instructing
the Standards reviewer: when a diff changes a documented design rationale or invariant,
search the repo for other copies of that rationale (including paraphrases, not just an
exact-phrase match) and flag any left contradicting the new code. Classification (blocking
vs. advisory) is left to the file's existing judgement-call framing rather than asserted
inline.

### Acceptance criteria

- [ ] `code-review/REVIEW-CRITERIA.md`'s Documentation section has a new bullet covering this
      check.
- [ ] The bullet specifies the trigger (a diff changes a documented rationale/invariant) and
      the action (search the repo for other copies of that rationale, including paraphrases,
      not just an exact-phrase match), and flags any left unswept.
- [ ] The bullet does not assert its own blocking/advisory verdict — classification is left
      to the file's existing judgement-call framing, matching sibling bullets.
- [ ] No existing bullet's wording changes.
- [ ] `pre-commit-check` passes on the file.

---
