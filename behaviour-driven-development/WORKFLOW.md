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

## Step 3 — Tracer Bullet

Write ONE test that confirms ONE thing about the system:

```text
RED:   Write test for first behavior → test fails
GREEN: Write minimal code to pass → test passes
```

This is your tracer bullet - proves the path works end-to-end.

## Step 4 — Incremental Loop

For each remaining behavior:

```text
RED:   Write next test → fails
GREEN: Minimal code to pass → passes
```

Rules:

- One test at a time
- Only enough code to pass current test
- Don't anticipate future tests
- Keep tests focused on observable behavior

## Step 5 — Refactor

After all tests pass, look for refactor candidates (see `refactoring.md`):

- [ ] Extract duplication
- [ ] Deepen modules (move complexity behind simple interfaces)
- [ ] Apply SOLID principles where natural
- [ ] Consider what new code reveals about existing code
- [ ] Run tests after each refactor step

**Never refactor while RED.** Get to GREEN first.

## Checklist Per Cycle

```text
[ ] Test name uses domain vocabulary, not implementation terms
[ ] Test maps to a Given-When-Then scenario or acceptance criterion
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Test would survive internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
```
