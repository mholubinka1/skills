# implement: tick slices as they finish, and inline the workflow

## Problem Statement

Two audit findings (#143) against `implement` (GitHub issue #153):

- **IMP-1**: state detection resumes "at the BDD loop for any unchecked issues", but
  nothing in Step 6 ticks an issue. Every slice is still unticked when a run resumes, so
  the BDD loop runs again on slices that are already built and committed. There is also no
  row for "every slice is done", so a run interrupted during review restarts the BDD loop.
- **IMP-2**: `SKILL.md` is one sentence pointing at `WORKFLOW.md`. The whole sequence sits
  behind a link the agent has to follow before it knows any step.

## Solution

Step 6 ticks a slice's acceptance criteria in the issues file and commits that with the
slice. State detection gains an "every slice is done → Step 7" row. The workflow moves into
`SKILL.md` and `WORKFLOW.md` is deleted.

## User Stories

1. As a user resuming an interrupted `/implement` run, I want finished slices skipped, so
   that BDD does not rebuild work that is already committed.
2. As a user resuming after every slice was built, I want the run to continue at code
   review, so that it does not re-enter the BDD loop.
3. As an agent loading `implement`, I want the steps in `SKILL.md` itself, so that I can
   act without first opening a second file.

## Implementation Decisions

- **`implement` SKILL** now holds the full workflow, Steps 0 to 8, with the same step
  numbers, so references from other skills ("`/implement` Step 2", "Step 6") still hold.
  `WORKFLOW.md` in the `implement` skill is deleted.
- **Done**: a slice is done when none of its acceptance criteria is still `- [ ]`. This is
  stated once, in state detection.
- **Step 6** becomes four actions per slice: `bdd`, `pre-commit-check`, tick the slice's
  criteria, then commit the work and the issues file together. A criterion is ticked only
  when met; an unmet one means the slice goes back to `bdd`.
- **State detection** has four rows, first match wins: issues file with a slice not done →
  Step 6 for those slices; issues file with every slice done → Step 7; spec only → Step 5;
  neither → Step 2.
- **`allowed-tools`** gains `Edit(.agent-docs/issues/**)` for the ticking.
- `pr-cleanup` still ticks every box and adds its closing note at the end; after this
  change that is a no-op for the boxes on a normal run.
- The glossary's WORKFLOW.md entry names `bdd` as its example instead of `implement`.

## Testing Decisions

- Prose changes to a skill definition; there is no executable behaviour to test red-green.
- The frontmatter guard tests cover the new `allowed-tools` entry, and the Markdown link
  check covers the removed file.
- This branch's own issues file is ticked in the same commit as the work, as the new
  Step 6 requires.

## Out of Scope

- `bdd`'s own `WORKFLOW.md` (#148).
- Changing any other step's behaviour.

## Further Notes

Closes #153.
