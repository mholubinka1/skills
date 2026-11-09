---
name: write-spec
description: Synthesises the current conversation into a spec (PRD) at .agent-docs/specs/<branch-name>.md, asking only one test-seam question. Use after a /design session when the design is agreed and ready to record.
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write(.agent-docs/specs/**)
  - Bash(git branch --show-current)
attribution: Based on to-prd (Matt Pocock, mattpocock/skills)
---

# Write Spec

Synthesise what is already known from the conversation into a spec. The `/design` session already did the interviewing; the only question for the user is the test-seam check in step 3.

## Process

### 1. Determine the spec filename

Get the current branch name:

```bash
git branch --show-current
```

The spec file is `.agent-docs/specs/<branch-name>.md`.

### 2. Explore the repo

Read every module the spec will touch, and name each one in Implementation Decisions. Use the domain glossary vocabulary from `.agent-docs/context.md` (if present) throughout the spec. Respect any ADRs in `.agent-docs/adr/`.

### 3. Identify test seams

Sketch the seams at which the feature will be tested. Prefer existing seams. Use the highest seam possible. Fewer seams across the codebase is better — the ideal is one.

Ask the user, in one question, whether the proposed seams match their expectations before writing the spec.

### 4. Write the spec

Write `.agent-docs/specs/<branch-name>.md` using the template below. The spec is done when every design acceptance criterion maps to at least one user story.

```md
# <Feature title>

## Problem Statement

The problem the user is facing, from the user's perspective.

## Solution

The solution, from the user's perspective.

## User Stories

A numbered list of user stories. Each in the format:

1. As a <actor>, I want <feature>, so that <benefit>.

Give each design acceptance criterion at least one story.

## Implementation Decisions

- Modules to be built or modified
- Interface changes
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Describe decisions in prose, naming modules rather than file paths. Include a code snippet
only when it encodes a decision more precisely than prose (e.g. a state machine or schema
shape); then inline it, note it came from a prototype, and trim to the decision-rich parts.

## Testing Decisions

- What makes a good test for this feature (test external behaviour, not internals)
- Which modules will be tested
- Prior art in the codebase for similar tests

## Out of Scope

What is explicitly not part of this spec.

## Further Notes

Any additional context.
```
