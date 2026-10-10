# code-review exits on two consecutive clean passes

## Problem Statement

`code-review`'s Standards + Spec loop only exits after two consecutive passes with zero
findings. Each pass uses fresh reviewers, and they keep raising new advisory nits that the
main context rejects. A rejected advisory still counts as a finding, so the loop can run
indefinitely without converging, even though nothing is being changed.

## Solution

A pass counts towards the exit when it is a **Clean pass**: zero findings, or every finding
is advisory and was rejected with a reason. Two consecutive clean passes exit the loop
straight to the Copilot step, without asking the user. A blocking finding (even one that is
rejected) or any accepted fix resets the count.

## User Stories

1. As an engineer running `/code-review`, I want the loop to exit after two consecutive
   passes that raise only advisory findings I rejected, so that review converges instead of
   chasing endless nits.
2. As an engineer, I want a pass with zero findings to still count towards the exit, so that
   the existing clean path is unchanged.
3. As an engineer, I want any accepted fix to reset the count, so that every change is seen
   by two passes that raise nothing worth acting on.
4. As an engineer, I want a blocking finding to reset the count even when I reject it, so
   that disputed blocking issues never slip through on the relaxed rule.
5. As an engineer, I want the loop to proceed to Step 6 on its own once the rule is met, so
   that I am not asked for permission to exit.
6. As an agent reading the skill, I want the exit rule stated once, in Step 5, so that the
   diagram and prose cannot drift apart.

## Implementation Decisions

- Modify `code-review`'s `SKILL.md` only:
  - Step 5 defines the clean pass and the count: blocking finding or accepted fix → 0;
    clean pass → +1; at 2 → Step 6. Rejected findings are still carried into the next
    pass's "Already decided" line, as today.
  - The "Loop at a glance" diagram's exit line refers to two consecutive clean passes.
  - The three duplicated exit sentences in Step 5 ("does not exit until…", "Repeat until…",
    "Do not move on to Step 6 until…") collapse into the single rule; the "Always report
    aggregated findings" instruction remains.
  - The frontmatter description's "until clean" stays: "clean" now has a defined meaning.
- Add **Clean pass** to the PR Review Loop section of the domain glossary
  (`.agent-docs/context.md`).
- No ADR: the rule is cheap to reverse.

## Testing Decisions

Skills are Markdown instruction files with no executable test harness. Correctness is
verified by reviewing the updated files against the acceptance criteria, plus pre-commit
(markdownlint) for formatting:

1. The loop diagram shows two consecutive clean passes as the exit to Step 6.
2. Step 5 defines a clean pass (zero findings, or all findings advisory and rejected with a
   reason) and the reset/increment rule.
3. No remaining text in `code-review` requires zero findings as the only exit condition.
4. `.agent-docs/context.md` defines **Clean pass** consistently with Step 5.

Prior art: `.agent-docs/specs/chore/address-copilot-clean-review-exit.md` uses the same
read-through verification.

## Out of Scope

- `address-copilot-comments` and its Copilot loop.
- Any bound on loops that keep producing blocking findings.
- Changes to how findings are classified as blocking or advisory.

## Further Notes

This codifies a rule previously held only in the user's agent memory. The skill's
precedence note says the skill wins over memory, so the memory alone could not change the
behaviour. Delete that memory once this merges.
