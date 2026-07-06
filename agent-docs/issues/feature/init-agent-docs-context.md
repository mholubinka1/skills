# Issues: feature/init-agent-docs-context

## Add CONTEXT-TEMPLATE.md to init-agent-docs

**Blocked by**: None

**User stories**: 3

### What to build

Create `init-agent-docs/CONTEXT-TEMPLATE.md` — a well-formed empty domain glossary that the skill writes verbatim to `agent-docs/context.md` when no existing `context.md` is found. The template must follow the format defined in `design/CONTEXT-FORMAT.md`: a `# Project Context` heading, a one-sentence placeholder description, a `## Language` subheading, and one placeholder term entry with a name, definition, and `_Avoid_` line.

### Acceptance criteria

- [ ] `init-agent-docs/CONTEXT-TEMPLATE.md` exists alongside `SKILL.md` and `AGENT-TEMPLATE.md`
- [ ] The template contains a `# Project Context` heading
- [ ] The template contains a one-sentence placeholder description beneath the heading
- [ ] The template contains a `## Language` subheading
- [ ] The template contains exactly one placeholder term entry with name, definition, and `_Avoid_` line
- [ ] The template structure matches the format specified in `design/CONTEXT-FORMAT.md`

---

## Add context.md bootstrap steps to SKILL.md

**Blocked by**: #4

**User stories**: 1, 2, 3, 4, 5

### Description

Extend `init-agent-docs/SKILL.md` with three new steps that bootstrap `agent-docs/context.md`, inserted between the existing `agent.md` steps and the `CLAUDE.md` steps. The new steps implement a three-strategy ordered approach:

1. If `agent-docs/context.md` already exists — report and skip.
2. If a `context.md` is found in root or `docs/` — move it (Read → Write → delete source). If multiple found, report ambiguity and skip. If move fails, report error and skip.
3. If none found — read `CONTEXT-TEMPLATE.md` from the skill directory and write it verbatim to `agent-docs/context.md`.

The existing step numbers shift: old Steps 3–5 become Steps 6–8. The summary step is updated to include `context.md` outcomes.

### Criteria

- [ ] Running the skill in a repo where `agent-docs/context.md` already exists reports "already exists — skipping" and leaves the file untouched
- [ ] Running the skill in a repo with `context.md` at root (and no `agent-docs/context.md`) moves it to `agent-docs/context.md` and deletes the source
- [ ] Running the skill in a repo with `context.md` in `docs/` (and no `agent-docs/context.md`) moves it to `agent-docs/context.md` and deletes the source
- [ ] Running the skill in a repo with multiple `context.md` files in scope reports the ambiguity with a file list, skips the step, and continues with the CLAUDE.md steps
- [ ] Running the skill in a repo with no `context.md` anywhere creates `agent-docs/context.md` from `CONTEXT-TEMPLATE.md`
- [ ] A move failure reports the error clearly, skips the step, and continues with the CLAUDE.md steps
- [ ] The skill summary reports the outcome of the `context.md` step alongside the `agent.md` and `CLAUDE.md` outcomes
- [ ] The skill remains idempotent — a second run on any repo state skips the `context.md` step cleanly
- [ ] Old CLAUDE.md steps are correctly renumbered in `SKILL.md`

---
