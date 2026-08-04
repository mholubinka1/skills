# Issues: bugfix/address-copilot-suppressed-comments

## Detect suppressed comments during polling

**GitHub issue**: #39

**Blocked by**: None

**User stories**: 1, 4

### What to build

Add a second check to the Step 3/7 poll (and its final pass after poll exhaustion): fetch the latest Copilot review body and check for a non-zero `### Suppressed comments (N)` block, alongside the existing thread-count check. Either check being non-zero exits the poll to Step 4 instead of declaring the PR clean. Document this in SKILL.md's Step 3 prose and the "Loop at a glance" diagram, and add a "Step A2 — Suppressed comments check" to REFERENCE.md alongside the existing Step A/B detail. The existing thread-count-only path (0 threads, 0 suppressed comments) must keep working exactly as before — no regression to the current clean-declaration behavior when there really is nothing to address.

### Acceptance criteria

- [ ] Step 3 and Step 7 poll logic (SKILL.md) check both thread count and suppressed-comment count before considering the PR reviewed clean
- [ ] REFERENCE.md documents the suppressed-comment count extraction (Step A2) with a runnable command, alongside the existing Step A/B detail
- [ ] The "Loop at a glance" diagram in SKILL.md reflects the new branch
- [ ] Dry-run: piping the real sample review body (from the spec's Further Notes) through the new extraction command correctly returns 3 for the multi-entry example and would return 0 for a body with no `Suppressed comments` block
- [ ] A review body with 0 threads and 0 suppressed comments still routes to Step 8 (clean) exactly as before

---

## Decide, act on, and acknowledge suppressed comments

**GitHub issue**: #40

**Blocked by**: #39 (needs the poll to route here before there's anything to act on)

**User stories**: 2, 3, 4

### What to build (issue 2)

Extend Step 4 so each suppressed-comment entry (identified by its bold `**path:line**` header and following bullet text) gets the same Fix/Push-back decision as a real thread — including the existing push-back-on-`.agent-docs/`-files rule — but skips the reply/`resolveReviewThread` mechanism, since suppressed entries have no thread or comment ID. Document the entry shape as instructional prose in REFERENCE.md (not a rigid parser), matching how the skill already hands full comment bodies to the agent for real threads. Add a new Step 4d: after Step 4c, if any suppressed comments existed this round, post a single `gh pr comment` summarizing the fix/ignore outcome for each — firing regardless of whether the round's decisions were all push-backs (which otherwise skip Steps 5–7 entirely), since this is the only place a suppressed comment's outcome is ever recorded. Update the loop termination conditions in REFERENCE.md and the "Loop at a glance" diagram to reflect Step 4d.

### Acceptance criteria (issue 2)

- [ ] SKILL.md Step 4 and REFERENCE.md's "Address each comment" section describe deciding Fix/Push-back per suppressed entry, using the same push-back rule as threads
- [ ] REFERENCE.md documents suppressed-entry shape (bold path:line header, bullet text, optional fenced code quote) as prose, not a script
- [ ] SKILL.md and REFERENCE.md explicitly state that suppressed entries are excluded from the Step 4c reply/`resolveReviewThread` mechanism
- [ ] New Step 4d is documented in SKILL.md (prose + diagram) and REFERENCE.md: posts one PR-level comment per round summarizing every suppressed comment's outcome, fires whenever suppressed comments existed that round regardless of fix/push-back mix, and is skipped when there were none
- [ ] Loop termination condition 1 in REFERENCE.md (all push-backs, no code changes) is updated to note both thread resolution (Step 4c) and suppressed-comment acknowledgment (Step 4d) happen before the skip to Step 8
- [ ] Consistency read-through: step numbering (4a/4b/4c/4d), the diagram, and cross-references between SKILL.md and REFERENCE.md all agree

---
