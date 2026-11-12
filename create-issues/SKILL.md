---
name: create-issues
description: Turns a spec into vertical-slice issues, recorded locally and mirrored to GitHub. Use after /write-spec when the spec is ready to be broken into implementation work.
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write(.agent-docs/issues/**)
  - Edit(.agent-docs/issues/**)
  - Agent
  - Bash(git branch --show-current)
  - Bash(gh --version)
  - Bash(gh issue create *)
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

Break the spec into tracer bullet issues — each a thin vertical slice cutting through all integration layers end-to-end. Each slice must be demoable on its own and have any required prefactoring as its own preceding slice. This step is done when every user story in the spec is covered by at least one slice.

### 4. Write the acceptance criteria

For each slice, draw Given-When-Then scenarios from the spec's user stories as its acceptance criteria. Show the user the slices and their scenarios, and get approval on the list before writing the issues file. `/bdd` owns interface and test-design work when it picks up each slice.

### 5. Write the local issues file

Create `.agent-docs/issues/<branch-name>.md` using the Local Issues File Template in [REFERENCE.md](REFERENCE.md). Each acceptance criterion is one of the Given-When-Then scenarios approved in Step 4, unchanged.

### 6. Push to GitHub

Publishing is mechanical, so it runs in a Haiku sub-agent with an empty context. Dispatch one `Agent` call, `subagent_type: general-purpose`, `model: haiku`, `run_in_background: false`, and wait for its report. Handover:

```text
Read <this skill's base directory>/REFERENCE.md, section "GitHub issue creation command".
Verify gh is available (gh --version). Publish every slice in .agent-docs/issues/<branch-name>.md
to GitHub in dependency order (blockers first), then write the real issue numbers back into
that file: each slice's own number in its "GitHub issue" field, blockers' numbers in the
"Blocked by" fields. Change no other wording in it.
Return: slice title → issue number, one per line, and one line "Skipped / risk:".
```
