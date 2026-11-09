---
name: bdd
description: Drives a code change through a red-green-refactor loop of Given-When-Then scenarios. Use when adding or changing behaviour in code, or when the user asks for red-green-refactor or integration/acceptance tests.
allowed-tools:
  - Skill
  - Agent
  - Read
  - Grep
  - Glob
  - Edit
  - Write
  - Bash(git diff *)
---

# Behaviour-Driven Development

## Philosophy

**Core principle**: Tests should verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't.

Good tests are integration-style specifications that exercise real code paths through public interfaces and survive refactors; bad tests are coupled to implementation. See `tests.md` for both, with examples, and `mocking.md` for mocking guidelines.

**Ubiquitous language**: Tests should use domain vocabulary shared across the entire team — developers, testers, and business stakeholders. When tests speak the language of the business, they double as living documentation. "shopper receives confirmation when checking out with valid cart" is better than "checkout_service_returns_200_with_order_id".

**Outside-in development**: BDD is an outside-in discipline. Start from the user's perspective — acceptance criteria, user stories — and work inward toward implementation. Define what success looks like for the user before designing internal structure.

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

## Tracer Bullets

Work in vertical slices: one test → one implementation → repeat. Each test responds to what you learned from the previous cycle, so it verifies actual behavior through the public interface, and you know exactly what behavior matters because you just wrote the code.

```text
authoring context ──▸ write test1 (RED), then stop
─────────────── clean-context handoff ───────────────
implementation subagent:
  GREEN:     test1 → impl1     (make the tracer bullet pass)
  RED→GREEN: test2 → impl2
  RED→GREEN: test3 → impl3
  ...
```

### The clean-context handoff keeps the slices vertical

Unless the change is only a few lines, the implementation phase runs in a fresh subagent (see [WORKFLOW.md](WORKFLOW.md) Step 4). The first handoff carries exactly **one** failing test — the tracer bullet. The subagent then writes every remaining test one at a time, each responding to what the previous cycle taught, exactly as in the loop above. Tests arrive one at a time, in the test-authoring context and inside the subagent alike. What moves across the boundary is the design noise — the Three Amigos discussion, interface debate, false starts — not a pile of tests.

## Workflow

See [WORKFLOW.md](WORKFLOW.md) for the full step-by-step cycle: branch check → planning → tracer bullet test → clean-context handoff → implementation subagent (incremental loop + refactor) → verification.
