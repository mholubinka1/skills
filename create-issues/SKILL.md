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

Present the breakdown as a numbered list showing title, blocked-by, and user stories covered. Ask the user if the granularity, dependencies, and split/merge feel right. Iterate until approved.

### 5. Write the local issues file

Create `.agent-docs/issues/<branch-name>.md` using the template in [REFERENCE.md](REFERENCE.md#local-issues-file-template-step-5).

### 6. Push to GitHub

Verify `gh` is available (`gh --version`). Publish issues in dependency order using the command in [REFERENCE.md](REFERENCE.md#github-issue-creation-command-step-6). Update the local file with real issue numbers.
