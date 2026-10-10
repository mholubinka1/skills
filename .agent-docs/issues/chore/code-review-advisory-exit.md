# Issues: chore/code-review-advisory-exit

> Work complete — PR ready to merge.

## code-review exits on two consecutive clean passes

**Blocked by**: None

**User stories**: 1, 2, 3, 4, 5, 6

### What to build

Redefine `code-review`'s Step 4/5 loop exit around the **Clean pass**: zero findings, or
every finding advisory and rejected with a reason. Step 5 states the rule once — blocking
finding or accepted fix resets the count to 0, a clean pass adds 1, and at 2 the loop
proceeds to Step 6 without asking. The loop diagram and the duplicated exit sentences are
rewritten to match, and the glossary gains the **Clean pass** term.

### Acceptance criteria

- [x] Given two consecutive passes each with only advisory findings, all rejected with
      reasons, when Step 5 finishes the second, then the loop proceeds to Step 6 without
      asking the user.
- [x] Given a zero-finding pass followed by an all-rejected-advisory pass, then the loop
      exits (mixed clean passes count).
- [x] Given a clean pass followed by a pass with one accepted advisory fix, then the count
      resets to 0 and the loop continues.
- [x] Given a pass with a blocking finding that is rejected, then the count resets to 0.
- [x] Given a pass with one advisory rejected and one fixed, then it is not clean and the
      count resets.
- [x] The loop diagram shows two consecutive clean passes as the exit to Step 6, and no
      remaining text requires zero findings as the only exit condition.
- [x] `.agent-docs/context.md` defines **Clean pass** consistently with Step 5.

---
