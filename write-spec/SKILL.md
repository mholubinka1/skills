---
name: write-spec
description: Synthesise the current conversation into a spec (PRD) and write it to .agent-docs/specs/<branch-name>.md. No interview — synthesis only. Use after a /grill session when the design is agreed and ready to record.
attribution: Based on to-prd (Matt Pocock, mattpocock/skills)
---

# Write Spec

Synthesise what is already known from the conversation into a spec. Do **not** interview the user — the `/grill` session already did that.

> **Note**: The spec template (Problem Statement, Solution, User Stories, etc.) is a candidate for restructuring in the future as usage patterns become clearer.

## Process

### 1. Determine the spec filename

Get the current branch name:

```bash
git branch --show-current
```

The spec file is `.agent-docs/specs/<branch-name>.md`. Create `.agent-docs/specs/` if it does not exist.

### 2. Explore the repo

Read the codebase to understand the current state. Use the domain glossary vocabulary from `.agent-docs/context.md` (if present) throughout the spec. Respect any ADRs in `.agent-docs/adr/`.

### 3. Identify test seams

Sketch the seams at which the feature will be tested. Prefer existing seams. Use the highest seam possible. Fewer seams across the codebase is better — the ideal is one.

Check with the user that the proposed seams match their expectations before writing the spec.

### 4. Write the spec

Write `.agent-docs/specs/<branch-name>.md` using the template below.

```md
# <Feature title>

## Problem Statement

The problem the user is facing, from the user's perspective.

## Solution

The solution, from the user's perspective.

## User Stories

A numbered list of user stories. Each in the format:

1. As a <actor>, I want <feature>, so that <benefit>.

Cover all aspects of the feature extensively.

## Implementation Decisions

- Modules to be built or modified
- Interface changes
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do not include specific file paths or code snippets unless a snippet encodes a decision
more precisely than prose (e.g. a state machine or schema shape). If so, inline it and
note it came from a prototype — trim to the decision-rich parts only.

## Testing Decisions

- What makes a good test for this feature (test external behaviour, not internals)
- Which modules will be tested
- Prior art in the codebase for similar tests

## Out of Scope

What is explicitly not part of this spec.

## Further Notes

Any additional context.
```
