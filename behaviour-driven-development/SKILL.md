---
name: bdd
description: Behaviour-driven development with red-green-refactor loop and Given-When-Then scenarios. Use whenever a user wants to build features, make changes or fix bugs, mentions "red-green-refactor", wants integration or acceptance tests, or asks for test-first or behaviour-first development. This skill should be used whenever code is modified.
---

# Behaviour-Driven Development

## Philosophy

**Core principle**: Tests should verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't.

**Good tests** are integration-style: they exercise real code paths through public APIs. They describe _what_ the system does, not _how_ it does it. A good test reads like a specification — "user can checkout with valid cart" tells you exactly what capability exists. These tests survive refactors because they don't care about internal structure.

**Bad tests** are coupled to implementation. They mock internal collaborators, test private methods, or verify through external means (like querying a database directly instead of using the interface). The warning sign: your test breaks when you refactor, but behavior hasn't changed. If you rename an internal function and tests fail, those tests were testing implementation, not behavior.

**Ubiquitous language**: Tests should use domain vocabulary shared across the entire team — developers, testers, and business stakeholders. When tests speak the language of the business, they double as living documentation. "shopper receives confirmation when checking out with valid cart" is better than "checkout_service_returns_200_with_order_id".

**Outside-in development**: BDD is an outside-in discipline. Start from the user's perspective — acceptance criteria, user stories — and work inward toward implementation. Define what success looks like for the user before designing internal structure.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

## Scenarios: Given-When-Then

Structure every behavior as a scenario using the Given-When-Then format:

- **Given**: Initial context — the state of the system before the action
- **When**: The triggering event or action
- **Then**: The expected outcome

This format enforces that tests describe behavior from the outside, not internal mechanics, and provides a natural structure for acceptance criteria agreed on before implementation.

**User story** (written before any code):
> As a shopper, I want to checkout my cart, so that I can receive my order.

**Scenario** (executable specification):

```gherkin
Given a cart with one in-stock product
When the shopper checks out with a valid payment method
Then the order is confirmed and the shopper receives a confirmation number
```

Test names should read as scenario titles — plain English, domain vocabulary, no implementation detail. See [tests.md](tests.md) for how to translate scenarios into code.

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.** This is "horizontal slicing" - treating RED as "write all tests" and GREEN as "write all code."

This produces **crap tests**:

- Tests written in bulk test _imagined_ behavior, not _actual_ behavior
- You end up testing the _shape_ of things (data structures, function signatures) rather than user-facing behavior
- Tests become insensitive to real changes - they pass when behavior breaks, fail when behavior is fine
- You outrun your headlights, committing to test structure before understanding the implementation

**Correct approach**: Vertical slices via tracer bullets. One test → one implementation → repeat. Each test responds to what you learned from the previous cycle. Because you just wrote the code, you know exactly what behavior matters and how to verify it.

```text
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
  ...
```

## Workflow

### 0. Fast Branch Check (before planning)

A quick fail-fast check to catch the most obvious branch problems before any work begins.

#### a. Check autoSetupRemote

Run:

```bash
git config push.autoSetupRemote
```

If the output is not `true`, warn the user:

> `push.autoSetupRemote` is not enabled. New branches won't be tracked upstream automatically when pushed. Run `git config --global push.autoSetupRemote true` to enable it, or branches will need `--set-upstream` on first push.

Ask if they want it set before continuing.

#### b. Trunk branch check

Run:

```bash
git branch --show-current
```

If the current branch is `main`, `master`, or `develop`, warn immediately:

> You're on `<branch>` — this is a trunk branch. You should work on a feature, bugfix, hotfix, release, or chore branch. A better branch name will be confirmed after planning. Want to continue on a temporary branch now, or wait until after planning to name it properly?

If the user wants to move now, create a placeholder (e.g. `wip/description`) and note that Step 2 will rename it. **Do not push or commit.**

### 1. Planning

Before writing any code, run a **Three Amigos** conversation between:

- **Business** (product/stakeholder): defines the problem and acceptance criteria in plain language
- **Development**: proposes technical approach and constraints
- **Testing**: questions edge cases and missing scenarios

This produces agreed-upon scenarios that become your test plan. Then:

- [ ] Capture behaviors as user stories: "As a [role], I want [feature], so that [benefit]"
- [ ] Write acceptance criteria as Given-When-Then scenarios for each story
- [ ] Confirm with user what interface changes are needed
- [ ] Identify opportunities for [deep modules](deep-modules.md) (small interface, deep implementation)
- [ ] Design interfaces for [testability](interface-design.md)
- [ ] Get user approval on the scenario list

Ask: "What should success look like for the user? Which scenarios are most important to get right?"

**You can't test everything.** Confirm with the user exactly which behaviors matter most. Focus testing effort on critical paths and complex logic, not every possible edge case.

### 2. Full Branch Check (after planning)

Now that the change type is clear from the agreed user stories and scenarios, validate the branch properly.

#### a. Infer change type from planning output

Classify the work as one of: **feature**, **bugfix**, **hotfix**, **release**, **chore**.

Use the agreed user stories, acceptance criteria, and Three Amigos output as the primary signal:

- **feature**: new capability or behaviour ("As a user I want to add X")
- **bugfix**: restoring broken behaviour ("X should work but doesn't")
- **hotfix**: urgent production fix ("prod is down", "blocking users", "critical")
- **release**: version bump, changelog, release preparation
- **chore**: refactor, tooling, dependency update, test-only change with no behaviour change

#### b. Validate current branch prefix

| Change type | Valid branch prefixes |
|---|---|
| feature | `feature/` |
| bugfix | `bugfix/`, `hotfix/` |
| hotfix | `hotfix/` |
| release | `release/` |
| chore | `chore/`, `feature/` |

Check the current branch against this table. A mismatch means either:

- The branch prefix doesn't match the change type (e.g. implementing a feature on `bugfix/`)
- The branch is still a trunk branch or a `wip/` placeholder from Step 0

#### c. Resolve mismatch

On any mismatch, suggest a well-formed branch name derived from the agreed work description:

> You're on `bugfix/fix-login` but planning confirmed this is a new feature. Suggested branch: `feature/add-oauth-login`. Create it and move your work there? (yes/no)

If the user confirms:

```bash
git checkout -b <suggested-branch>
```

Any uncommitted changes carry over automatically. **Do not push or commit to the new branch.**

If Step 0 already moved the user off trunk and the new branch name is valid, confirm it and move on.

### 3. Tracer Bullet

Write ONE test that confirms ONE thing about the system:

```text
RED:   Write test for first behavior → test fails
GREEN: Write minimal code to pass → test passes
```

This is your tracer bullet - proves the path works end-to-end.

### 4. Incremental Loop

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

### 5. Refactor

After all tests pass, look for [refactor candidates](refactoring.md):

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
