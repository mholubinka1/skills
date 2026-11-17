# bdd: ping-pong between the main context and the implementer

## Problem Statement

`bdd` hands the implementation subagent one failing tracer-bullet test, and the subagent
writes every remaining test itself alongside the code that passes it. That has two costs:

- The agent writing a test is the agent about to pass it, so tests drift toward the code's
  shape. `IMPLEMENTER.md` carried a long list of tests "that never earn their place" to
  push back on that.
- `.agent-docs/agent.md` §7 places test cases with Opus in the main session, yet on the
  normal path Sonnet wrote all but the first.

## Solution

Ping-pong across the context boundary. The main context writes each failing test, one at a
time, and confirms it fails for the right reason. One implementer — spawned for the first
scenario and resumed with `SendMessage` for each later one — makes that test pass and
reports. The main context reads the cycle's diff before writing the next test. Once every
scenario is green, the implementer refactors to the repo's standards and sends a final
report. The main context verifies the change and prunes tests.

## User Stories

1. As a maintainer, I want the main context to write every test, so that tests come from
   the context that holds the agreed scenarios, not from the agent passing them.
2. As an agent running `bdd`, I want one implementer resumed across cycles, so that each
   cycle avoids a cold start.
3. As an agent running `bdd`, I want to read each cycle's diff before the next test, so
   that each test answers what the last cycle taught and the loop stays vertical.
4. As an implementer, I want to leave tests untouched and report a test I can't pass, so
   that the specification can't be bent to fit the code.
5. As a maintainer, I want the refactor to follow the repo's own standards docs, so that
   refactored code meets the same bar as the rest of the codebase.
6. As an agent verifying the change, I want prune candidates in the final report, so that
   test pruning stays with the context that wrote the tests.

## Implementation Decisions

- **`bdd/SKILL.md`**: Steps 3 and 4 (tracer bullet, single handoff) become Step 3, the
  ping-pong loop (red in the main context, hand over, learn from the diff, repeat), and
  Step 4, a resume message telling the implementer to refactor. The small-change inline
  path stays, now at the head of Step 3. Step 5 adds two checks: no test file appears in
  the implementer's **Files changed**, and every test still earns its place across the
  whole set. `SendMessage` joins `allowed-tools`.
- **Resume fallback**: when the implementer can't be resumed, the main context dispatches
  a fresh one with the first-scenario prompt.
- **`bdd/IMPLEMENTER.md`**: per-cycle green with a short cycle report; tests are
  read-only, and a test that can't pass as written comes back as a blocked cycle; the
  refactor reads the repo's `CLAUDE.md` and the standards docs it points at; the final
  report gains **Prune candidates**.
- **`bdd/tests.md`**: gains *Tests that never earn their place*, moved verbatim from
  `IMPLEMENTER.md`, because the main context now writes the tests.
- **`.agent-docs/context.md`**: *BDD loop* and *Implementation subagent* redefined.
- **No ADR**: prose in a skill definition, trivially revertible.

## Testing Decisions

- Prose changes to a skill definition, with no executable behaviour to test red-green.
- The `unittest` suite (including the `allowed-tools` frontmatter guard) and the
  pre-commit hooks (markdownlint, Markdown link check, codespell) must pass.

## Out of Scope

- Steps 0 to 2 (branch checks, planning).
- `/implement`, which calls `bdd` per slice exactly as before.
- `mocking.md`, `refactoring.md`, `deep-modules.md`, `interface-design.md`.
