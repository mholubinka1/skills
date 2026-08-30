# BDD Skill — Clean-Context Implementation Handoff

## Problem Statement

By the time the `behaviour-driven-development` skill reaches its implementation loop, the
context window is saturated with test-authoring noise: the Three Amigos conversation, design
exploration, interface debate, and false starts. Production code written in that polluted
context tends to be biased toward the shape the discussion imagined rather than what the
tests actually specify. The maintainer wants the implementation to begin from a clean
context that treats the agreed tests as the specification.

## Solution

Split the BDD workflow at a context boundary:

- **Test-authoring phase** stays in the main context: run the Three Amigos, agree the
  Given-When-Then scenario list, confirm interface changes, and write the single tracer
  bullet test (RED) — confirming it fails for the right reason. No production code is
  written here.
- **Implementation phase** runs in a fresh `general-purpose` subagent the skill spawns. It
  receives the agreed scenario list and interface changes inline in its prompt, plus the
  path to the failing tracer test. It runs the red-green-refactor loop vertically — one
  scenario at a time, test → minimal implementation → repeat — then refactors, then reports
  back per scenario with the final test output.
- The main context then verifies the result against the per-cycle checklist, runs
  `pre-commit-check`, and (under `/implement`) commits.

Vertical slicing is preserved: exactly one failing test crosses the boundary, and the
subagent writes every remaining test one at a time. What moves across the boundary is the
design noise, not a batch of tests. The "Anti-Pattern: Horizontal Slices" prohibition is
kept verbatim and clarified with an additive paragraph and a diagram tweak.

## User Stories

1. As an agent running the `bdd` skill, I want the implementation loop to run in a fresh
   subagent, so that production code is written against the agreed tests without the
   design conversation biasing it.
2. As an agent running the `bdd` skill, I want the test-authoring phase to stop after the
   tracer bullet test (RED), so that no production code is written in the polluted context.
3. As an agent spawning the implementation subagent, I want the agreed scenario list and
   interface changes passed inline in the prompt, so that the handoff survives the context
   boundary without a new on-disk artifact.
4. As an agent running the implementation subagent, I want the red-green-refactor loop
   rules and pointers to `tests.md` / `mocking.md` / `refactoring.md` in my prompt, so that
   I run the vertical loop correctly without re-invoking the `bdd` skill.
5. As an agent that has received the subagent's report, I want to verify it against the
   per-cycle checklist and run `pre-commit-check` in the main context, so that the skill's
   existing quality gates still apply.
6. As a maintainer, I want the "Anti-Pattern: Horizontal Slices" section kept intact with
   only an additive clarification, so that the prohibition on batching all tests upfront is
   not weakened by the phase split.
7. As an agent, I want the behaviour to be identical whether `bdd` is invoked standalone or
   as `/implement` Step 6, so that there is one code path to reason about.

## Implementation Decisions

- **Files changed**: `behaviour-driven-development/SKILL.md` and
  `behaviour-driven-development/WORKFLOW.md` only. Supporting `.md` files
  (`tests.md`, `mocking.md`, `refactoring.md`, `deep-modules.md`, `interface-design.md`)
  are unchanged — they are referenced by path from the subagent prompt.
- **`SKILL.md`**:
  - "Anti-Pattern: Horizontal Slices" — prohibition text unchanged. Add one paragraph:
    the clean-context handoff happens with exactly one failing test (the tracer bullet);
    the subagent writes every remaining test one at a time; batching all tests upfront
    stays forbidden in both contexts; what crosses the boundary is design noise, not tests.
  - The `WRONG`/`RIGHT` diagram gains a line showing the context boundary sitting between
    the tracer test and the loop, with the loop still `test1→impl1, test2→impl2, …` inside
    the subagent.
  - The closing "See WORKFLOW.md …" pointer line updated to name the phase split.
- **`WORKFLOW.md`**: restructure Steps 3–5.
  - **Step 3 — Tracer bullet test (authoring phase)**: write only the first scenario's
    test (RED); confirm it fails for the right reason (not a collection/import error). Do
    not write production code.
  - **Step 4 — Dispatch the implementation subagent**: one `Agent` call, `type:
    general-purpose`. Prompt contains, inline: the agreed user stories, the full
    Given-When-Then scenario list, the confirmed interface changes, the path(s) to the
    failing tracer test file(s), the core loop rules (red-green vertical, one scenario at a
    time, minimal code to pass, never refactor while red, test observable behaviour only,
    refactor once green), and pointers to `tests.md` / `mocking.md` / `refactoring.md` for
    depth. Explicit instruction: do not re-invoke the `bdd` skill. The subagent returns a
    per-scenario status (green / not satisfied + why), the refactors applied, and the final
    test-run output.
  - **Step 5 — Verify and refactor review**: main context runs the per-cycle checklist
    against the returned result, confirms every scenario is covered and green, and folds
    the former "Refactor" checklist in as a review of what the subagent did. `pre-commit-check`
    and commit remain the caller's responsibility (unchanged under `/implement` Step 6).
  - A scenario the subagent cannot satisfy: it stops and reports; the main context decides
    (fix inline, or re-dispatch a fresh subagent with a narrower brief). No automatic retry
    loop in the skill.
- **Standalone vs `/implement`**: the skill dispatches the subagent itself, so both entry
  paths behave identically. `/implement` Step 6's "run the `bdd` skill … then
  `pre-commit-check` … then commit" ordering is unaffected.
- **CONTEXT.md** (already updated in this session): `BDD loop` entry sharpened to name the
  context boundary; new `Implementation subagent` (BDD sense) term added.
- **No ADR**: fails the "hard to reverse" test — this is prose in a skill definition,
  trivially revertible. The rationale lives in the reconciliation paragraph in `SKILL.md`.

## Testing Decisions

- This repo has no automated test infrastructure; skills are prose markdown. Verification
  is a read-through against the acceptance criteria plus the `pre-commit-check` pass
  (markdownlint and the configured hooks). This matches prior doc-only chore specs in
  `.agent-docs/specs/chore/`.
- Prior art: `.agent-docs/specs/chore/step4b-explicit-skip-guard.md` and
  `.agent-docs/specs/chore/step4b-foreground-requirement.md` — same shape of change
  (restructuring workflow-step prose in a skill).
- Because the deliverable is prose, no implementation subagent is spawned for *this* issue;
  the change is made directly and verified by read-through.

## Out of Scope

- The Three Amigos / planning process itself (Step 1) — unchanged.
- `/implement`'s other steps — unchanged.
- Supporting `.md` files in the BDD skill except where they are referenced by the new
  Step 4 prompt.
- Any executable test harness for skills — none exists and none is added here.
- Retry/backoff logic for a stuck subagent beyond "stop and report".

## Further Notes

- The subagent prompt pattern mirrors `code-review/SKILL.md` Step 4, which also passes
  everything (diff, criteria) inline to `type: general-purpose` agents rather than via a
  file.
- The tracer bullet test is written in the main context (not the subagent) deliberately:
  it de-risks the handoff by proving the outside-in path is expressible as a failing test
  in this codebase's test setup before a subagent is spent on it.
