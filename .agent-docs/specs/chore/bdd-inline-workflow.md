# bdd: inline the steps, defer module design to codebase-design, hand back correctly

## Problem Statement

Three audit findings (#143) against `bdd` (GitHub issue #148):

- **BDD-1**: `SKILL.md` holds about 70 lines of philosophy, and the steps the agent must
  follow sit behind "See WORKFLOW.md". An agent can act on the philosophy without ever
  opening the steps.
- **BDD-6**: `deep-modules.md` and `interface-design.md` restate what the
  `codebase-design` skill owns, so the two can drift apart.
- **BDD-9**: the last step says `pre-commit-check` and the commit are "`/implement`
  Step 6's next actions". That caches another skill's step number, and when the user runs
  `bdd` directly nobody runs `pre-commit-check` at all.

## Solution

Put Steps 0 to 5 in `SKILL.md` with the philosophy cut to a short Principles list, and
delete `WORKFLOW.md`. Point planning at the `codebase-design` skill and delete the two
restating files. End Step 5 with a hand-back that names no step number and runs
`pre-commit-check` when there is no caller.

## User Stories

1. As an agent loading `bdd`, I want the steps in `SKILL.md` itself, so that I follow the
   workflow without opening a second file.
2. As a maintainer, I want deep-module and interface guidance kept in one skill, so that
   `bdd` cannot contradict it.
3. As a user running `bdd` directly, I want `pre-commit-check` run on the change, so that
   hooks are not skipped just because no orchestrating skill called it.
4. As a maintainer of `/implement`, I want `bdd` not to name my step numbers, so that
   renumbering them does not leave `bdd` wrong.

## Implementation Decisions

- **`bdd` SKILL (BDD-1)**: one opening paragraph, a four-bullet Principles list (behaviour
  through public interfaces, domain vocabulary, the Given-When-Then shape with its example,
  vertical slices), then Steps 0 to 5 with their existing wording and numbers. The
  tracer-bullet diagram and the one-failing-test rule move into Step 4, where the handoff
  happens. `WORKFLOW.md` in the `bdd` skill is deleted.
- **Step 1 (BDD-6)**: the two checklist items pointing at `deep-modules.md` and
  `interface-design.md` become one item that runs the `codebase-design` skill. That skill
  is not part of this repo, so the item carries a one-sentence fallback for when it is not
  installed. Both files are deleted. `refactoring.md` keeps its "shallow modules" bullet.
- **Step 5 (BDD-9)**: a caller gets control back and owns `pre-commit-check` and the
  commit; with no caller, `bdd` runs `pre-commit-check` and leaves the commit to the user.
  No other skill's step number is named.
- **`allowed-tools`**: unchanged. `Skill` already covers `pre-commit-check` and
  `codebase-design`.
- The glossary's WORKFLOW.md entry is removed: no skill in this repo has such a file now.

## Testing Decisions

- Prose changes to a skill definition; there is no executable behaviour to test red-green.
- The `unittest` suite and the Markdown link check (three files removed) must pass.
- Steps 0 to 5 were compared with the deleted `WORKFLOW.md` to confirm the only wording
  changes are the Step 1 checklist item, the Step 5 hand-back, the diagram moved into
  Step 4, and sentence-case step headings.

## Out of Scope

- `IMPLEMENTER.md`, `tests.md`, `mocking.md` and `refactoring.md`.
- Other audit findings against `bdd`.
- Bringing `codebase-design` into this repo.

## Further Notes

Closes #148.
