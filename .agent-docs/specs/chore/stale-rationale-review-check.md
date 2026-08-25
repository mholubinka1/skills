# Flag Unswept Stale Design-Rationale Comments in Code Review

## Problem Statement

`code-review/REVIEW-CRITERIA.md`'s Documentation section checks that READMEs/runbooks and
environment variables stay current, but has no check for a narrower, previously-observed
failure mode: a diff changes a documented design rationale or invariant (e.g. a "singleton
returned by reference" comment), but other copies of that same rationale — a class comment,
an inline comment, a test comment, a spec doc — are left stale, still describing the old
behavior. In a real PR, this required a reviewer (GitHub Copilot) to flag all 4 stale copies
individually across a review, rather than catching them together in one pass.

## Solution

Add a Documentation bullet to `REVIEW-CRITERIA.md` instructing the Standards reviewer: when a
diff changes a documented design rationale or invariant, grep the repo for the old rationale
phrase and flag (blocking, per the existing "documented-standard breaches may be blocking"
rule) any other occurrence left unswept in the same diff.

## User Stories

1. As a Standards reviewer (sub-agent) running code-review, I want an explicit instruction to
   grep for stale copies of a changed rationale, so that I catch all of them in one review
   pass instead of requiring multiple review rounds to surface each one individually.
2. As a developer whose diff changes a documented invariant, I want the review to flag every
   other place that invariant is documented, so that I sweep them all in the same commit
   rather than leaving contradictory documentation behind.

## Implementation Decisions

- File touched: `code-review/REVIEW-CRITERIA.md` only, under the existing `## Documentation`
  section.
- New bullet: when a diff changes or removes a comment/doc line explaining a design rationale
  or invariant (the *why*, not the *what*), grep the repo for the phrase being changed and
  check every match; any other occurrence left contradicting the new code is a blocking
  finding, since REVIEW-CRITERIA.md's existing rule already treats documented-standard
  breaches as blocking (this bullet itself is now such a standard).
- No new section, no new tooling, no automation — this is an instruction to the sub-agent
  reviewer, who already has full repo search tools (Bash/Grep) available when spawned by
  `code-review` Step 4.
- No ADR: a single-bullet addition to an existing criteria doc is trivial to revert.

## Testing Decisions

- No code seam; this is a review-instruction document. Verified by review (does the bullet
  read clearly and match the intended trigger condition) and by `pre-commit-check` (markdown
  lint) — same verification method as fix #1's REFERENCE.md addition.

## Out of Scope

- Automating the grep itself (e.g. a git hook) — this stays a reviewer instruction, not
  tooling, matching how every other REVIEW-CRITERIA.md bullet works.
- Any change to non-Documentation sections of REVIEW-CRITERIA.md.

## Further Notes

This is the third of six small fixes queued from a retrospective on a recent PR; each is
being run through its own `/implement` loop rather than bundled together.
