# BDD Workflow

Full step-by-step workflow. The philosophy and scenario format are in [SKILL.md](SKILL.md).

## Step 0 — Fast Branch Check (before planning)

Run the **branch-hygiene** skill in fast mode (no `change_type` — infers from request heuristics).

This catches the most obvious problem before planning begins: being on a trunk branch (`main`, `master`, `develop`). It also checks `autoSetupRemote`.

If the user is on trunk and wants to move now, branch-hygiene may suggest a `wip/` placeholder when the change type or slug is still unclear. Note that Step 2 will replace it with a properly-named branch once the change type is confirmed by planning. **Do not push or commit.**

## Step 1 — Planning

Before writing any code, run a **Three Amigos** conversation between:

- **Business** (product/stakeholder): defines the problem and acceptance criteria in plain language
- **Development**: proposes technical approach and constraints
- **Testing**: questions edge cases and missing scenarios

This produces agreed-upon scenarios that become your test plan. Then:

- [ ] Capture behaviors as user stories: "As a [role], I want [feature], so that [benefit]"
- [ ] Write acceptance criteria as Given-When-Then scenarios for each story
- [ ] Confirm with user what interface changes are needed
- [ ] Identify opportunities for deep modules (small interface, deep implementation) — see `deep-modules.md`
- [ ] Design interfaces for testability — see `interface-design.md`
- [ ] Get user approval on the scenario list

Ask: "What should success look like for the user? Which scenarios are most important to get right?"

**You can't test everything.** Confirm with the user exactly which behaviors matter most. Focus testing effort on critical paths and complex logic, not every possible edge case.

## Step 2 — Full Branch Check (after planning)

Now that planning has produced agreed user stories, acceptance criteria, and a confirmed change type, run the **branch-hygiene** skill in full mode — passing the inferred `change_type` explicitly.

Determine `change_type` from the Three Amigos output:

- **feature**: new capability or behaviour ("As a user I want to add X")
- **bugfix**: restoring broken behaviour ("X should work but doesn't")
- **hotfix**: urgent production fix ("prod is down", "blocking users", "critical")
- **release**: version bump, changelog, release preparation
- **chore**: refactor, tooling, dependency update, test-only change with no behaviour change

Pass this to branch-hygiene so it can accurately validate the branch prefix and suggest a correctly-named branch if needed. If Step 0 already moved the user to a `wip/` placeholder, branch-hygiene will detect this as a mismatch and prompt for a proper name. **Do not push or commit to any new branch.**

## Step 3 — Tracer Bullet Test (authoring phase)

Still in the main context, write ONE test for the **first scenario** — and stop there. **Do not write any production code in this phase.**

```text
RED: Write the test for the first behaviour → run it → it fails
```

Confirm it fails *for the right reason* — an assertion failure, or a missing function / endpoint / module — not an import error, a syntax error, or a test-collection failure. A test that errors before it runs has proven nothing about the path.

Note the exact command that runs the suite (or this test alone); Step 4 passes it to the subagent verbatim.

This is your tracer bullet: it proves the first scenario is expressible as a failing test in this codebase's test setup, which de-risks the handoff that follows.

## Step 4 — Hand off to the implementation subagent (clean context)

The main context is now saturated with planning, the Three Amigos discussion, interface debate, and false starts. Production code written here would be biased toward the shape that discussion imagined rather than what the tests specify. So the implementation loop runs in a **fresh subagent** that treats the agreed scenarios as its specification.

Dispatch **one** `Agent` call, `type: general-purpose`. Everything the subagent needs goes **inline in the prompt** — no handoff file is written to disk:

- The agreed user stories.
- The full Given-When-Then scenario list from Step 1, in order.
- The confirmed interface changes.
- The path to the failing tracer bullet test file from Step 3, and the test command noted there.
- The loop rules, verbatim:
  - Work one scenario at a time, in order. RED: write the next test → it fails. GREEN: write the minimal code to pass it → it passes. Scenario 1's test already exists from Step 3 — start at GREEN for it.
  - Only enough code to pass the current test. Don't anticipate later scenarios.
  - Test observable behaviour through the public interface, not internals.
  - Never refactor while RED — get to GREEN first.
  - After every scenario is green, refactor (checklist below), running the full suite after each step.
- The per-cycle checklist, for the subagent to apply to every scenario:
  - Test name uses domain vocabulary, not implementation terms
  - Test maps to a Given-When-Then scenario or acceptance criterion
  - Test describes behaviour, not implementation
  - Test uses the public interface only
  - Test would survive an internal refactor
  - Code is minimal for this test
  - No speculative features added
- The refactor checklist, to apply once green (see `refactoring.md`):
  - Extract duplication
  - Deepen modules (move complexity behind simple interfaces)
  - Apply SOLID principles where natural
  - Consider what new code reveals about existing code
- Pointers, by path, for depth: `tests.md`, `mocking.md`, `refactoring.md` in the skill directory.
- An explicit instruction: **do not re-invoke the `bdd` skill** — it would recurse.
- A request to report back: for each scenario, whether it is green or could not be satisfied (and why); the refactors applied; and the final full test-run output.

If the subagent reports a scenario it could not satisfy, it stops there. The main context decides what to do next — fix it inline, or re-dispatch a fresh subagent with a narrower brief. There is no automatic retry loop.

## Step 5 — Verify the returned work

Back in the main context, check the subagent's report:

- [ ] Every scenario from Step 1 has a corresponding test, and the full suite is green
- [ ] Every item of the Step 4 per-cycle checklist holds for the tests the subagent wrote
- [ ] The refactors applied are sound and the suite is still green after them
- [ ] No speculative features beyond the agreed scenarios

If anything fails the check, address it in the main context or re-dispatch a subagent.

`pre-commit-check` and the commit are the caller's responsibility — under `/implement` they are Step 6's next actions, run once this skill returns.
