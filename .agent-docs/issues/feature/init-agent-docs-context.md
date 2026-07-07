<!-- markdownlint-disable MD024 MD025 -->

# Issues: feature/init-agent-docs-context

## Add CONTEXT-TEMPLATE.md to init-agent-docs

**Blocked by**: None

**User stories**: 3

### What to build

Create `init-agent-docs/CONTEXT-TEMPLATE.md` — a well-formed empty domain glossary that the skill writes verbatim to `.agent-docs/context.md` when no existing `context.md` is found. The template must follow the format defined in `design/CONTEXT-FORMAT.md`: a `# Project Context` heading, a one-sentence placeholder description, a `## Language` subheading, and one placeholder term entry with a name, definition, and `_Avoid_` line.

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

Extend `init-agent-docs/SKILL.md` with three new steps that bootstrap `.agent-docs/context.md`, inserted between the existing `agent.md` steps and the `CLAUDE.md` steps. The new steps implement a three-strategy ordered approach:

1. If `.agent-docs/context.md` already exists — report and skip.
2. If a `context.md` is found in root or `docs/` — move it (Read → Write → delete source). If multiple found, report ambiguity and skip. If move fails, report error and skip.
3. If none found — read `CONTEXT-TEMPLATE.md` from the skill directory and write it verbatim to `.agent-docs/context.md`.

The existing step numbers shift: old Steps 3–5 become Steps 6–8. The summary step is updated to include `context.md` outcomes.

### Criteria

- [ ] Running the skill in a repo where `.agent-docs/context.md` already exists reports "already exists — skipping" and leaves the file untouched
- [ ] Running the skill in a repo with `context.md` at root (and no `.agent-docs/context.md`) moves it to `.agent-docs/context.md` and deletes the source
- [ ] Running the skill in a repo with `context.md` in `docs/` (and no `.agent-docs/context.md`) moves it to `.agent-docs/context.md` and deletes the source
- [ ] Running the skill in a repo with multiple `context.md` files in scope reports the ambiguity with a file list, skips the step, and continues with the CLAUDE.md steps
- [ ] Running the skill in a repo with no `context.md` anywhere creates `.agent-docs/context.md` from `CONTEXT-TEMPLATE.md`
- [ ] A move failure reports the error clearly, skips the step, and continues with the CLAUDE.md steps
- [ ] The skill summary reports the outcome of the `context.md` step alongside the `agent.md` and `CLAUDE.md` outcomes
- [ ] The skill remains idempotent — a second run on any repo state skips the `context.md` step cleanly
- [ ] Old CLAUDE.md steps are correctly renumbered in `SKILL.md`

---

## Update design/ADR-FORMAT.md canonical path

**Blocked by**: None

**User stories**: ADR migration feature — story 5

### What to build

Update `design/ADR-FORMAT.md` to reference `.agent-docs/adr/` as the canonical ADR location instead of `.agent-docs/docs/adr/`. There are three occurrences to update: the opening declaration, the lazy directory creation instruction, and the numbering scan instruction.

### Acceptance criteria

- [ ] `design/ADR-FORMAT.md` contains no references to `.agent-docs/docs/adr/`
- [ ] All three occurrences are updated to `.agent-docs/adr/`
- [ ] The directory creation instruction references `.agent-docs/adr/`
- [ ] The numbering scan instruction references `.agent-docs/adr/`

---

## Add ADR migration step to init-agent-docs/SKILL.md

**Blocked by**: #7

**User stories**: ADR migration feature — stories 1, 2, 3, 4

### What to build

Insert a new Step 6 in `init-agent-docs/SKILL.md` after the context.md steps (Steps 3–5) and before the CLAUDE.md steps. The step searches `docs/` (non-recursively) and `docs/adr/` for files matching `[0-9]*-*.md` and migrates them to `.agent-docs/adr/`. Conflict resolution uses git commit date (filesystem mtime fallback). After migration, removes empty `docs/adr/`. Renumbers old Steps 6–8 to Steps 7–9; summary becomes Step 10.

### Acceptance criteria

- [ ] New Step 6 inserted after context.md steps and before CLAUDE.md steps
- [ ] Step searches both `docs/` (non-recursively) and `docs/adr/` for `[0-9]*-*.md`
- [ ] `.agent-docs/adr/` created lazily only when at least one ADR is about to be moved
- [ ] Files are moved via Read → Write → delete source
- [ ] Conflict resolution uses git commit date (mtime fallback): source newer → overwrite; destination newer → skip and report
- [ ] Empty `docs/adr/` is removed after migration; `docs/` itself is left alone
- [ ] "no ADRs found — skipped" reported in summary when no matching files exist
- [ ] Old Steps 6–8 correctly renumbered to 7–9; summary step is Step 10
- [ ] Skill remains idempotent — second run finds no source files and reports "no ADRs found — skipped"

---

## Record ADR for canonical ADR path decision in skills repo

**Blocked by**: #7

**User stories**: ADR migration feature — story 5

### What to build

Create `.agent-docs/adr/0001-adr-canonical-location.md` in the skills repo, documenting the decision that `.agent-docs/adr/` is the canonical ADR location (not `.agent-docs/docs/adr/` as previously stated in `design/ADR-FORMAT.md`).

### Acceptance criteria

- [ ] `.agent-docs/adr/0001-adr-canonical-location.md` exists in the skills repo
- [ ] ADR records the context: `design/ADR-FORMAT.md` previously specified `.agent-docs/docs/adr/` but actual usage and the init-agent-docs skill use `.agent-docs/adr/`
- [ ] ADR records the decision: `.agent-docs/adr/` is the canonical location
- [ ] ADR records the rationale: shorter path, no redundant `docs/` nesting, consistent with how the skill creates the directory

---

## Rename .agent-docs/ to ..agent-docs/ in skills repo and update all references

**Blocked by**: #7, #8, #9

**User stories**: Rename feature — stories 1, 5

### What to build

Rename the `.agent-docs/` directory to `..agent-docs/` in the skills repo using `git mv`, then do a bulk find-and-replace of `.agent-docs/` → `..agent-docs/` across all `.md` files in the repo. After the rename, no file in the skills repo should reference `.agent-docs/`.

### Acceptance criteria

- [ ] `.agent-docs/` directory no longer exists; `..agent-docs/` exists in its place
- [ ] Git history is preserved via `git mv`
- [ ] Zero occurrences of `.agent-docs/` remain in any `.md` file in the skills repo (verified by grep)
- [ ] All skill instruction files (`*/SKILL.md`, `design/ADR-FORMAT.md`, etc.) use `..agent-docs/`
- [ ] The `..agent-docs/specs/`, `..agent-docs/issues/`, `..agent-docs/adr/` subdirectories are intact

---

## Add migration Step 1 to init-agent-docs/SKILL.md for .agent-docs/ → ..agent-docs/

**Blocked by**: #10

**User stories**: Rename feature — stories 2, 3, 4

### What to build

Add a new Step 1 to `init-agent-docs/SKILL.md` that detects and migrates existing `.agent-docs/` content in target repos to `..agent-docs/`. Runs before all other steps. Shifts all existing step numbers up by 1. Also updates the CLAUDE.md idempotency check to handle old `.agent-docs/agent.md` references (replace in-place, not append duplicate).

### Acceptance criteria

- [ ] New Step 1 runs before all other steps
- [ ] `.agent-docs/agent.md` migrated to `..agent-docs/agent.md` when old exists and new does not
- [ ] `.agent-docs/context.md` migrated to `..agent-docs/context.md` when old exists and new does not
- [ ] `.agent-docs/adr/` migrated to `..agent-docs/adr/` when old exists and new does not
- [ ] When both old and new exist: `..agent-docs/` version kept, old `.agent-docs/` copy removed
- [ ] Empty `.agent-docs/` directory removed after migration
- [ ] All existing steps correctly renumbered (old Step 1 → Step 2, etc.)
- [ ] CLAUDE.md idempotency check handles old `.agent-docs/agent.md` reference: replaces in-place, does not append duplicate
- [ ] Skill is idempotent — second run on a migrated repo: Step 1 finds nothing to migrate and reports nothing

---

## Record ADR for .agent-docs/ to ..agent-docs/ hidden directory rename

**Blocked by**: #10

**User stories**: Rename feature — stories 1, 5

### What to build

Create `..agent-docs/adr/0002-hidden-agent-docs-directory.md` in the skills repo, documenting the decision to rename `.agent-docs/` to `..agent-docs/`.

### Acceptance criteria

- [ ] `..agent-docs/adr/0002-hidden-agent-docs-directory.md` exists in the skills repo
- [ ] ADR records the context: `.agent-docs/` appeared as a first-class source directory in file browsers
- [ ] ADR records the decision: rename to `..agent-docs/` (hidden directory convention)
- [ ] ADR records the rationale: consistent with `.github/`, `.husky/`, `.vscode/` tooling directory convention; keeps AI agent documentation accessible to tools but out of casual sight
- [ ] ADR records the rejected alternative: keeping the visible `.agent-docs/` name

---
