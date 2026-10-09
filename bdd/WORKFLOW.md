# BDD Workflow

Full step-by-step workflow. The philosophy and scenario format are in [SKILL.md](SKILL.md).

## Step 0 — Fast Branch Check (before planning)

Run the **branch-hygiene** skill with a one-line summary of the request (no `change_type` — it infers one), e.g. `/branch-hygiene "add CSV export to reports"`. Act on its `next:` line.

This catches the most obvious problem before planning begins: being on a trunk branch (`main`, `master`, `develop`). Step 2 re-checks once planning confirms the change type; a mismatch that is only a `wip/` or `worktree-wip+` placeholder waits for Step 2. **Do not push or commit.**

## Step 1 — Planning

When the issue being worked already holds Given-When-Then acceptance criteria (as `/create-issues` writes them into `.agent-docs/issues/<branch-name>.md`), show them as the scenario list together with the interface changes they need (the issues file does not record those — reconstruct them from the issue and the code), get the user's confirmation or adjustments to both, and go to Step 2.

Otherwise, before writing any code, run a **Three Amigos** conversation between:

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

Now that planning has produced agreed user stories, acceptance criteria, and a confirmed change type, run the **branch-hygiene** skill again, passing `change_type` first, then the summary — e.g. `/branch-hygiene feature "add CSV export to reports"`.

Determine `change_type` from the Three Amigos output — or, when Step 1 reused an issue's criteria, from that issue:

- **feature**: new capability or behaviour ("As a user I want to add X")
- **bugfix**: restoring broken behaviour ("X should work but doesn't")
- **hotfix**: urgent production fix ("prod is down", "blocking users", "critical")
- **release**: version bump, changelog, release preparation
- **chore**: refactor, tooling, dependency update, test-only change with no behaviour change

Act on its `next:` line. A `wip/` or `worktree-wip+` placeholder branch always reports a mismatch, so this is where it gets its proper name. **Do not push or commit to any new branch.**

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

**Small change?** When the whole scenario list needs only a few lines of production code (one file, roughly 20 lines or fewer), finish the loop inline instead — the handover would cost more than the work. Follow [IMPLEMENTER.md](IMPLEMENTER.md)'s loop and ladder, then go to Step 5.

Otherwise dispatch **one** `Agent` call, `subagent_type: general-purpose`, `model: sonnet`, `run_in_background: false`, and wait for its report. The subagent starts with an empty context, and its standing rules live in [IMPLEMENTER.md](IMPLEMENTER.md), so the prompt is a short handover:

```text
Read <this skill's base directory>/IMPLEMENTER.md and follow it. Do not invoke the bdd skill.
Scenarios: <.agent-docs/issues/<branch-name>.md, issue #<n> — or, when no issues file
           holds them, the agreed Given-When-Then list from Step 1, in order>
Interface changes: <the confirmed changes, one line each>
Failing test: <path from Step 3>   Run: <test command from Step 3>
```

If the subagent reports a scenario as blocked, the main context decides what to do next — fix it inline, or re-dispatch a fresh subagent with a narrower brief, dispatched as above (`model: sonnet`, `run_in_background: false`). There is no automatic retry loop.

## Step 5 — Verify the returned work

Back in the main context, read the actual change, not just the report: `git diff`, then the important changed code. Check it against the agreed scenarios:

- [ ] Every scenario from Step 1 has a corresponding test, and the full suite is green
- [ ] Each test uses domain vocabulary, maps to one scenario, and goes through the public interface
- [ ] The code takes the first rung of [IMPLEMENTER.md](IMPLEMENTER.md)'s ladder that works, and adds nothing beyond the agreed scenarios
- [ ] Every item on the report's **Skipped / risk** line is acceptable or resolved

If anything fails the check, address it in the main context or re-dispatch a subagent as in Step 4 (`model: sonnet`, `run_in_background: false`).

`pre-commit-check` and the commit are the caller's responsibility — under `/implement` they are Step 6's next actions, run once this skill returns.
