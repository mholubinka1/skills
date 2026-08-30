---
name: bdd
description: Behaviour-driven development with red-green-refactor loop and Given-When-Then scenarios. Use whenever a user wants to build features, make changes or fix bugs, mentions "red-green-refactor", wants integration or acceptance tests, or asks for test-first or behaviour-first development.
---

# Behaviour-Driven Development

## Philosophy

**Core principle**: Tests should verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't.

**Good tests** are integration-style: they exercise real code paths through public APIs. They describe _what_ the system does, not _how_ it does it. A good test reads like a specification — "user can checkout with valid cart" tells you exactly what capability exists. These tests survive refactors because they don't care about internal structure.

**Bad tests** are coupled to implementation. They mock internal collaborators, test private methods, or verify through external means (like querying a database directly instead of using the interface). The warning sign: your test breaks when you refactor, but behavior hasn't changed. If you rename an internal function and tests fail, those tests were testing implementation, not behavior.

**Ubiquitous language**: Tests should use domain vocabulary shared across the entire team — developers, testers, and business stakeholders. When tests speak the language of the business, they double as living documentation. "shopper receives confirmation when checking out with valid cart" is better than "checkout_service_returns_200_with_order_id".

**Outside-in development**: BDD is an outside-in discipline. Start from the user's perspective — acceptance criteria, user stories — and work inward toward implementation. Define what success looks like for the user before designing internal structure.

See `tests.md` for examples and `mocking.md` for mocking guidelines.

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

Test names should read as scenario titles — plain English, domain vocabulary, no implementation detail. See `tests.md` for how to translate scenarios into code.

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.** This is "horizontal slicing" - treating RED as "write all tests" and GREEN as "write all code."

This produces **crap tests**:

- Tests written in bulk test _imagined_ behavior, not _actual_ behavior
- You end up testing the _shape_ of things (data structures, function signatures) rather than user-facing behavior
- Tests become insensitive to real changes - they pass when behavior breaks, fail when behavior is fine
- You outrun your headlights, committing to test structure before understanding the implementation

**Correct approach**: Vertical slices via a tracer bullet, then one test → one implementation → repeat. Each test responds to what you learned from the previous cycle. Because each test and the code that passes it are written in the same pass, you know exactly what behavior matters and how to verify it.

```text
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  authoring context ──▸ write test1 (RED), then stop
  ─────────────── clean-context handoff ───────────────
  implementation subagent:
    GREEN:     test1 → impl1     (make the tracer bullet pass)
    RED→GREEN: test2 → impl2
    RED→GREEN: test3 → impl3
    ...
```

### The clean-context handoff is not horizontal slicing

The implementation phase runs in a fresh subagent (see [WORKFLOW.md](WORKFLOW.md) Step 4). The first handoff carries exactly **one** failing test — the tracer bullet. The subagent then writes every remaining test one at a time, each responding to what the previous cycle taught, exactly as in the vertical model above. Batching all tests upfront stays forbidden — in the test-authoring context and inside the subagent alike. What moves across the boundary is the design noise — the Three Amigos discussion, interface debate, false starts — not a pile of tests.

## Workflow

See [WORKFLOW.md](WORKFLOW.md) for the full step-by-step cycle: branch check → planning → tracer bullet test → clean-context handoff → implementation subagent (incremental loop + refactor) → verification.
