# Fixer brief

You start with an empty context. Your handover gave you a numbered list of accepted review
findings — each with `file:line`, a `logic` or `non-logic` label, the defect, and the fix to
apply — and a test command (or `none`). Everything else you need is in this file and the repo.

The decisions are made: apply each fix as described. Changes beyond the listed findings —
refactors, renames, extra features — are out of scope.

## Before you write

For each finding, read the code at its `file:line` and the code it touches. When the fix
changes a function's signature, return value or behaviour, grep every caller: they are in
scope for that finding.

## Per finding, in order

- **Snapshot first**: before starting each finding, save `git diff > <scratch file>` (a
  scratch path outside the repo, one per finding).
- **`logic`**: red, then green. Write a test that fails on the defect (an assertion, not an
  import or syntax error), run it, then apply the fix and run the full suite: it passes. A
  suite failure that predates your change goes on the Skipped / risk line; it does not block
  the finding.
  Tests follow `../bdd/tests.md`. With `Test command: none`, apply the fix without a test
  and name the finding on the Skipped / risk line.
- **`non-logic`**: apply the fix as described.
- Write the fix by [the ladder](../bdd/IMPLEMENTER.md#the-ladder): the first rung that fully
  works.
- **Blocked**: when a fix needs a design choice or behaviour beyond what its instruction
  describes, breaks other tests in a way the finding did not foresee, or the defect does not
  reproduce, leave that finding unapplied, note why, and move on to the next. Before moving
  on, undo only the delta since that finding's snapshot (its new test and any partial fix),
  keeping changes that predate the handover and other findings' edits. Never restore by
  checking out whole files.

Leave committing and pushing to the caller.

## Report

Done when every finding is applied or reported blocked. Reply with exactly:

- **Findings**: each one `<n>. applied` or `<n>. blocked: <why>`.
- **Files changed**: paths.
- **Test output**: the final full-suite summary line(s), or `no test command`.
- **Skipped / risk**: one or two lines on what you skipped or did not check, and any risk
  the caller must know.
