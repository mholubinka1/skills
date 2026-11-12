# bdd: inline the steps and hand back correctly

## Problem Statement

Three audit findings (#143) against `bdd` (GitHub issue #148):

- **BDD-1**: `SKILL.md` holds about 70 lines of philosophy, and the steps the agent must
  follow sit behind "See WORKFLOW.md". An agent can act on the philosophy without ever
  opening the steps.
- **BDD-6**: `deep-modules.md` and `interface-design.md` restate what the
  `codebase-design` skill owns. The audit proposed deleting both and pointing at that
  skill.
- **BDD-9**: the last step says `pre-commit-check` and the commit are "`/implement`
  Step 6's next actions". That caches another skill's step number, and when the user runs
  `bdd` directly nobody runs `pre-commit-check` at all.

## Solution

Put Steps 0 to 5 in `SKILL.md` with the philosophy cut to a short Principles list, and
delete `WORKFLOW.md`. End Step 5 with a hand-back that names no step number and runs
`pre-commit-check` when there is no caller. **Decline BDD-6**: keep both files.

## User Stories

1. As an agent loading `bdd`, I want the steps in `SKILL.md` itself, so that I follow the
   workflow without opening a second file.
2. As a user installing only this skills repo, I want `bdd` to work without any skill from
   elsewhere, so that the repo stands on its own.
3. As a user running `bdd` directly, I want `pre-commit-check` run on the change, so that
   hooks are not skipped just because no orchestrating skill called it.
4. As a maintainer of `/implement`, I want `bdd` not to name my step numbers, so that
   renumbering them does not leave `bdd` wrong.
5. As a user whose issue already holds the scenarios, I want the interface changes designed
   by the same guidance as on the Three Amigos path, so that the usual `/implement` route
   does not skip it.

## Implementation Decisions

- **`bdd` SKILL (BDD-1)**: one opening paragraph, a four-bullet Principles list (behaviour
  through public interfaces, domain vocabulary, the Given-When-Then shape with its example,
  vertical slices), then Steps 0 to 5 with their existing wording and numbers. The
  tracer-bullet diagram and the one-failing-test rule move into Step 4, where the handoff
  happens. `WORKFLOW.md` in the `bdd` skill is deleted.
- **BDD-6 is declined.** This skills repo must work on its own, with no dependency on a
  skill that lives outside it, and `codebase-design` is installed separately.
  `deep-modules.md` and `interface-design.md` stay, unchanged, and `bdd` names no external
  skill.
- **Step 1, interface rule**: the two checklist items that pointed at those files become
  one **interface rule**, linking both files, that applies on both planning paths: when an
  issue already supplies the scenarios (the usual path under `/implement`) and when Three
  Amigos produces them. Before, only the Three Amigos checklist reached the two files.
- **Step 5 (BDD-9)**: a caller gets control back and owns `pre-commit-check` and the
  commit; with no caller, `bdd` runs `pre-commit-check` and leaves the commit to the user.
  No other skill's step number is named.
- **`allowed-tools`**: unchanged. `Skill` already covers `pre-commit-check`.
- The glossary's WORKFLOW.md entry is removed: no skill in this repo has such a file now.

## Testing Decisions

- Prose changes to a skill definition; there is no executable behaviour to test red-green.
- The `unittest` suite and the Markdown link check must pass.
- Steps 0 to 5 were compared with the deleted `WORKFLOW.md` to confirm the only wording
  changes are the Step 1 interface rule, the Step 5 hand-back, the diagram moved into
  Step 4, and sentence-case step headings.

## Out of Scope

- `IMPLEMENTER.md`, `tests.md`, `mocking.md`, `refactoring.md`, `deep-modules.md` and
  `interface-design.md`.
- Other audit findings against `bdd`.

## Further Notes

Closes #148, with BDD-6 recorded on the issue as declined.
