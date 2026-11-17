---
name: bdd
description: Drives a code change through a red-green-refactor loop of Given-When-Then scenarios. Use when adding or changing behaviour in code, or when the user asks for red-green-refactor or integration/acceptance tests.
allowed-tools:
  - Skill
  - Agent
  - SendMessage
  - Read
  - Grep
  - Glob
  - Edit
  - Write
  - Bash(git diff *)
---

# Behaviour-Driven Development

Work outside-in: agree what success looks like for the user as Given-When-Then scenarios, then drive the code from one failing test at a time. Follow Steps 0 to 5 in order. Commits and pushes belong to the caller; this skill makes none.

## Principles

- **Test behaviour through public interfaces, not implementation details.** The code can change entirely; the tests shouldn't. `tests.md` shows good and bad tests, and `mocking.md` covers mocking.
- **Use the domain's vocabulary.** A test name reads as a scenario title in plain English: "shopper receives confirmation when checking out with valid cart", not "checkout_service_returns_200_with_order_id".
- **One scenario is one Given-When-Then**: the starting state, the action or event, the observable outcome.

  ```gherkin
  Given a cart with one in-stock product
  When the shopper checks out with a valid payment method
  Then the order is confirmed and the shopper receives a confirmation number
  ```

- **Vertical slices, one test at a time.** One test, then the code that passes it, then the next test, each written in response to what the last cycle taught. Never write the whole test list first.

## Step 0 — Fast branch check (before planning)

Run the **branch-hygiene** skill with a one-line summary of the request (no `change_type` — it infers one), e.g. `/branch-hygiene "add CSV export to reports"`. Act on its `next:` line.

This catches the most obvious problem before planning begins: being on a trunk branch (`main`, `master`, `develop`). Step 2 re-checks once planning confirms the change type; a mismatch that is only a `wip/` or `worktree-wip+` placeholder waits for Step 2.

## Step 1 — Planning

When the issue being worked already holds Given-When-Then acceptance criteria (as `/create-issues` writes them into `.agent-docs/issues/<branch-name>.md`), show them as the scenario list together with the interface changes they need (the issues file does not record those — reconstruct them from the issue and the code, by the **interface rule** below), get the user's confirmation or adjustments to both, and go to Step 2.

**Interface rule** (both paths): design interface changes as deep modules — a small interface hiding a lot of behaviour — see [deep-modules.md](deep-modules.md). Design them for testability — taking dependencies as arguments and returning results — see [interface-design.md](interface-design.md).

Otherwise, before writing any code, run a **Three Amigos** conversation between:

- **Business** (product/stakeholder): defines the problem and acceptance criteria in plain language
- **Development**: proposes technical approach and constraints
- **Testing**: questions edge cases and missing scenarios

This produces agreed-upon scenarios that become your test plan. Then:

- [ ] Capture behaviors as user stories: "As a [role], I want [feature], so that [benefit]"
- [ ] Write acceptance criteria as Given-When-Then scenarios for each story
- [ ] Confirm with user what interface changes are needed
- [ ] Design those interfaces by the interface rule above
- [ ] Get user approval on the scenario list

Ask: "What should success look like for the user? Which scenarios are most important to get right?"

**You can't test everything.** Confirm with the user exactly which behaviors matter most. Focus testing effort on critical paths and complex logic, not every possible edge case.

## Step 2 — Full branch check (after planning)

Now that planning has produced agreed user stories, acceptance criteria, and a confirmed change type, run the **branch-hygiene** skill again, passing `change_type` first, then the summary — e.g. `/branch-hygiene feature "add CSV export to reports"`.

Determine `change_type` from the Three Amigos output — or, when Step 1 reused an issue's criteria, from that issue — as one of `feature`, `bugfix`, `hotfix`, `release`, `chore`, per the Change Type Inference Heuristics in [branch-hygiene's REFERENCE.md](../branch-hygiene/REFERENCE.md).

Act on its `next:` line. A `wip/` or `worktree-wip+` placeholder branch always reports a mismatch, so this is where it gets its proper name.

## Step 3 — Ping-pong loop

You write every test; a clean-context **implementer** writes every line of production code. The main context is saturated with planning, the Three Amigos discussion, interface debate, and false starts — production code written here would follow the shape that discussion imagined, not what the tests specify. Tests written here carry the agreed scenarios straight into code. So the loop ping-pongs: one failing test crosses the boundary, it comes back green, you write the next.

```text
main context                         implementer (one agent, resumed each cycle)
RED:   test1 ──────────────────────▸ GREEN: impl1
       read diff ◂──────────────────  report
RED:   test2 ──────────────────────▸ GREEN: impl2
       ...
all green: "refactor" ──────────────▸ REFACTOR, final report   (Step 4)
```

**Small change?** When the whole scenario list needs only a few lines of production code (one file, roughly 20 lines or fewer), play both sides inline — the handover would cost more than the work. Write each test as below, make it pass by [IMPLEMENTER.md](IMPLEMENTER.md)'s ladder, refactor by its [refactor rules](IMPLEMENTER.md#refactor), run the full suite green, then go to Step 5.

For each scenario, in order:

1. **Red.** Write ONE test for the scenario, plus any fixture or helper it needs — test files are yours, never the implementer's. It uses domain vocabulary, maps to this one scenario, goes through the public interface ([tests.md](tests.md), [mocking.md](mocking.md)), and is none of tests.md's [Tests that never earn their place](tests.md#tests-that-never-earn-their-place). Run it: it fails *for the right reason* — an assertion failure, or a missing function / endpoint / module — not an import error, a syntax error, or a test-collection failure. A test that errors before it runs has proven nothing. Write no production code.
2. **Hand over.** For the first scenario, dispatch **one** `Agent` call, `subagent_type: general-purpose`, `model: sonnet`, `run_in_background: false`, and wait for its report. Its standing rules live in [IMPLEMENTER.md](IMPLEMENTER.md), so the prompt is short:

   ```text
   Read <this skill's base directory>/IMPLEMENTER.md and follow it. Do not invoke the bdd skill.
   Scenarios: <.agent-docs/issues/<branch-name>.md, issue #<n> — or, when no issues file
              holds them, the agreed Given-When-Then list from Step 1, in order>
   Interface changes: <the confirmed changes, one line each>
   Failing test: <path and test name>   Run: <command that runs the suite>
   ```

   For every later scenario, resume the same implementer with `SendMessage` — it keeps what it learned of the code — and wait for its report:

   ```text
   Failing test: <path and test name>   Run: <command that runs the suite>
   Changed since your last report: <files you edited inline — omit the line when none>
   ```

   When the implementer can't be resumed, dispatch a fresh one with the first-scenario prompt, its **Failing test** set to the current one; it reads the code as it stands.
3. **Learn.** Read the production code the cycle changed: every file its report names, new ones included. Write the next test in response to what that code taught — test n+1 starts only after test n is green and read.

A cycle reported **blocked** comes back to you: rewrite the test if it was wrong, fix the code inline, or narrow the brief in your next message. There is no automatic retry loop.

Done when every scenario's test is green.

## Step 4 — Refactor

Resume the implementer once more:

```text
All scenarios green. Refactor now.
Changed since your last report: <files you edited inline — omit the line when none>
```

When the implementer can't be resumed, dispatch a fresh one with the first-scenario prompt, its **Failing test** set to `none` and its **Run** command kept.

It refactors to the repo's standards, keeps the full suite green, and sends its final report. Done when that report arrives.

## Step 5 — Verify the returned work

Back in the main context, read the actual change, not just the report: `git diff`, then the important changed code. Check it against the agreed scenarios:

- [ ] Every scenario from Step 1 has a corresponding test, and the full suite is green — by the final report's test output, or your own run on the inline path
- [ ] Each test uses domain vocabulary, maps to one scenario, and goes through the public interface
- [ ] Every test file, fixture and helper is as you wrote it — no cycle report or final report names one in **Files changed**
- [ ] The code takes the first rung of [IMPLEMENTER.md](IMPLEMENTER.md)'s ladder that works, and adds nothing beyond the agreed scenarios
- [ ] Every test still earns its place by [tests.md](tests.md)'s list, judged across the whole set (repeats only show there) and against the report's **Prune candidates**; delete each one that doesn't and re-run the suite green
- [ ] Every item on the report's **Skipped / risk** line is acceptable or resolved

If anything fails the check, address it in the main context or resume the implementer with a narrower brief.

Then hand back:

- **Another skill invoked this one** (such as `/implement`): return to it. `pre-commit-check` and the commit are that caller's next actions.
- **No caller — the user invoked `bdd` directly**: run the `pre-commit-check` skill on the changed files and act on its `next:` line. Leave the commit to the user.
