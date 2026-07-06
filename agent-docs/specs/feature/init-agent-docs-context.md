# Extend init-agent-docs to bootstrap context.md

## Problem Statement

When an AI agent runs `/implement` in a fresh repository, the `design` skill expects a `agent-docs/context.md` domain glossary to be present so it can maintain consistent terminology throughout a design session. Currently, `init-agent-docs` only creates `agent-docs/agent.md` and wires `CLAUDE.md` — it does not bootstrap `context.md`. This means the first design session in any new repo either finds no glossary (so the `design` skill has nothing to update inline) or the user must manually create one, knowing the correct format. This friction defeats the purpose of having a bootstrapping skill.

## Solution

Extend `init-agent-docs` to also bootstrap `agent-docs/context.md` as part of its standard run. The skill applies a three-strategy ordered approach: skip if the file already exists, move an existing `context.md` found elsewhere in the repo to the canonical location, or create a fresh one from a bundled template. The skill remains fully idempotent — every strategy either no-ops or resolves correctly on repeated runs.

## User Stories

1. As an agent running `init-agent-docs` in a repo that already has `agent-docs/context.md`, I want the skill to detect it and skip without touching it, so that an existing domain glossary is never overwritten.
2. As an agent running `init-agent-docs` in a repo that has a `context.md` at the root or in `docs/`, I want it moved to `agent-docs/context.md`, so that the glossary lands in the canonical location without me having to do it manually.
3. As an agent running `init-agent-docs` in a repo with no `context.md` anywhere, I want a well-formed empty glossary created at `agent-docs/context.md` from the bundled template, so that the `design` skill has a file to update from the first session onward.
4. As an agent running `init-agent-docs` in a repo that has multiple `context.md` files in the search scope, I want the skill to report the ambiguity and ask me to resolve it, rather than silently picking the wrong one.
5. As an agent running `init-agent-docs` when a move operation fails, I want the error reported clearly so I can diagnose it, while the rest of the skill (CLAUDE.md wiring) completes normally.

## Implementation Decisions

- `init-agent-docs/SKILL.md` gains three new steps (Steps 3, 4, 5 in the renumbered sequence) between the existing `agent.md` steps and the `CLAUDE.md` steps.
- A new `init-agent-docs/CONTEXT-TEMPLATE.md` is added alongside `SKILL.md` and `AGENT-TEMPLATE.md`. It contains a `# Project Context` heading, a one-sentence placeholder description, a `## Language` subheading, and one placeholder term entry following the format in `design/CONTEXT-FORMAT.md`.
- **Step 3 — Check for existing context.md**: if `agent-docs/context.md` exists, report and skip to the CLAUDE.md steps.
- **Step 4 — Search and move**: search root and `docs/` (non-recursively) for any `context.md` file. If exactly one found, move it: Read source → Write to `agent-docs/context.md` → delete source. If multiple found, report ambiguity with file list, skip this step, and continue. If move fails, report error, skip, and continue.
- **Step 5 — Create from template**: if no `context.md` was found or moved, read `CONTEXT-TEMPLATE.md` from the skill directory and write its contents verbatim to `agent-docs/context.md`.
- Step numbering in `SKILL.md` shifts: old Steps 3–5 become Steps 6–8. The summary step (last) is updated to include `context.md` outcomes.
- No changes to `CLAUDE.md` wiring logic — `context.md` does not get a `CLAUDE.md` reference.

## Testing Decisions

- The skill is a Markdown instruction file, not executable code. There is no automated test harness.
- BDD scenarios act as the acceptance spec. Each scenario maps to one user story and is verified manually by running the skill in a scratch repository configured to match the scenario's preconditions.
- Four scenarios to cover: (1) `agent-docs/context.md` exists — skip; (2) `context.md` found at root or `docs/` — moved; (3) multiple `context.md` files found — ambiguity reported; (4) no `context.md` anywhere — created from template.
- The move failure path (story 5) is exercised by making the destination directory read-only in the scratch repo.
- Prior art: the existing `agent.md` creation steps in `SKILL.md` establish the pattern (Read template → Write to target → report).

## Out of Scope

- Recursive search of the full repo for `context.md` — only root and `docs/` are searched.
- Validation of the contents of an existing `agent-docs/context.md`.
- Adding a `context.md` reference to `CLAUDE.md`.
- Supporting `CONTEXT-MAP.md` multi-context repos in the bootstrap — the template creates a single root glossary only.
- Automated test runner or CI for skill files.

## Further Notes

- The `design` skill finds `agent-docs/context.md` by convention, not via `CLAUDE.md`. The bootstrapped file gives the `design` skill something to update from the first session; a brand-new repo with only the template in place is a valid starting state.
- The template follows `design/CONTEXT-FORMAT.md` exactly. If that format ever changes, `CONTEXT-TEMPLATE.md` should be updated to match.
- The "search and move" strategy is a convenience for projects that already have a freestanding `context.md` not yet in the canonical location. It is not expected to be the common path.
