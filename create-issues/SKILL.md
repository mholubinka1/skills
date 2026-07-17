---
name: create-issues
description: Break a spec into vertical-slice issues, write them to .agent-docs/issues/<branch-name>.md, and mirror to GitHub. Use after /write-spec when the spec is ready to be broken into implementation work.
attribution: Based on to-issues (Matt Pocock, mattpocock/skills)
---

# Create Issues

Break the spec into independently-grabbable vertical slice issues. Write locally first, then push to GitHub.

See [REFERENCE.md](REFERENCE.md) for the local issues file template and the GitHub CLI command.

## Process

### 1. Read the spec

Get the current branch with `git branch --show-current`. Read `.agent-docs/specs/<branch-name>.md` — if it does not exist, tell the user to run `/write-spec` first.

### 2. Explore the codebase

Read the codebase if not already done. Use domain glossary vocabulary from `.agent-docs/context.md`. Look for prefactoring opportunities — "make the change easy, then make the easy change."

### 3. Draft vertical slices

Break the spec into tracer bullet issues — each a thin vertical slice cutting through all integration layers end-to-end. Each slice must be demoable on its own and have any required prefactoring as its own preceding slice.

### 4. Three amigos review

Run a **Three Amigos** conversation between:

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

### 5. Write the local issues file

Create `.agent-docs/issues/<branch-name>.md` using the Local Issues File Template in [REFERENCE.md](REFERENCE.md).

### 6. Push to GitHub

Verify `gh` is available (`gh --version`). Publish issues in dependency order using the GitHub Issue Creation Command in [REFERENCE.md](REFERENCE.md). Update the local file with real issue numbers.
