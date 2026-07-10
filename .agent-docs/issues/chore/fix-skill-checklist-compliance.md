# Issues: chore/fix-skill-checklist-compliance

<!-- markdownlint-configure-file {"MD024": {"siblings_only": true}} -->

> Merged and closed.

## Fix P3 and P1 description issues (pr-cleanup, write-spec, bdd) — #14

**Blocked by**: None

**User stories**: 1, 3, 5

### What to build

Three small targeted edits with no extraction needed:

- Remove the redundant third sentence "This skill should be used whenever code is modified." from the bdd frontmatter description.
- Append "Use when a PR has been merged and issues need closing, or when invoked by /implement after the merge confirmation loop." to the pr-cleanup frontmatter description.
- Delete the provisional note block from write-spec/SKILL.md: the `> **Note**: ...candidate for restructuring in the future...` paragraph.

### Acceptance criteria

- [x] `behaviour-driven-development/SKILL.md` description has exactly two sentences (no third sentence about code modification)
- [x] `pr-cleanup/SKILL.md` description ends with the specified "Use when" sentence
- [x] `write-spec/SKILL.md` contains no mention of "candidate for restructuring" or "in the future"

---

## Add examples to design and grill — #15

**Blocked by**: None

**User stories**: 4

### What to build

Add at least one concrete example to each of two skills:

- `design/SKILL.md`: insert a one-line sample Phase 1 question and recommended answer inside the Phase 1 section.
- `grill/SKILL.md`: add a see-also note pointing to `design/SKILL.md` for examples, or add a one-line illustrative question.

### Acceptance criteria

- [x] `design/SKILL.md` contains at least one concrete example of a grilling question with a recommended answer
- [x] `grill/SKILL.md` contains either a see-also reference to `design/SKILL.md` or a one-line example question
- [x] Both files remain under 100 lines

---

## Extract init-agent-docs step prose to REFERENCE.md — #16

**Blocked by**: None

**User stories**: 2, 6

### What to build

`init-agent-docs/SKILL.md` is 288 lines — far over the 100-line limit. Extract the detailed per-step migration prose (the body of Steps 1–7) to a new `init-agent-docs/REFERENCE.md`. Keep in SKILL.md: the intro paragraph, a numbered step-overview list (one line per step), and a link to REFERENCE.md for full detail.

### Acceptance criteria

- [x] `init-agent-docs/SKILL.md` is under 100 lines
- [x] `init-agent-docs/REFERENCE.md` exists and contains the full step detail
- [x] SKILL.md links to REFERENCE.md
- [x] All step names are still represented (as one-liners) in SKILL.md

---

## Extract bdd workflow steps to WORKFLOW.md — #17

**Blocked by**: None

**User stories**: 2, 6

### What to build

`behaviour-driven-development/SKILL.md` is 164 lines. Extract the Workflow section (Steps 0–5 and the Checklist Per Cycle) to a new `behaviour-driven-development/WORKFLOW.md`. Keep in SKILL.md: the Philosophy section, the Scenarios: Given-When-Then section, the Anti-Pattern: Horizontal Slices section, and a brief "Workflow" pointer linking to WORKFLOW.md.

### Acceptance criteria

- [x] `behaviour-driven-development/SKILL.md` is under 100 lines
- [x] `behaviour-driven-development/WORKFLOW.md` exists and contains the workflow steps
- [x] SKILL.md links to WORKFLOW.md
- [x] The three core conceptual sections (Philosophy, Scenarios, Anti-Pattern) remain in SKILL.md

---

## Collapse address-copilot-comments Steps 3–7 to REFERENCE.md links — #18

**Blocked by**: None

**User stories**: 2, 6

### What to build

`address-copilot-comments/SKILL.md` is 158 lines and already has a REFERENCE.md. Collapse the inline body of Steps 3–7 to one-liner summaries with links to the corresponding REFERENCE.md anchors. The Loop at a glance diagram and Steps 0–2 stay in full.

### Acceptance criteria

- [x] `address-copilot-comments/SKILL.md` is under 100 lines
- [x] Steps 3–7 each have a one-liner summary and a link to REFERENCE.md
- [x] REFERENCE.md is unchanged (or only minimally adjusted for anchor names if needed)
- [x] Loop at a glance and Steps 0–2 remain intact in full

---

## Extract branch-hygiene validation detail to REFERENCE.md — #19

**Blocked by**: None

**User stories**: 2, 6

### What to build

`branch-hygiene/SKILL.md` is 134 lines. Move the validation tables (branch classification table in Step 2, prefix-validation table in Step 4) and the mismatch resolution logic (Steps 5–6 body) to a new `branch-hygiene/REFERENCE.md`. Keep in SKILL.md: the two-mode overview, step headers with one-liner summaries, and links to REFERENCE.md.

### Acceptance criteria

- [x] `branch-hygiene/SKILL.md` is under 100 lines
- [x] `branch-hygiene/REFERENCE.md` exists and contains the tables and resolution logic
- [x] SKILL.md links to REFERENCE.md
- [x] Two-mode overview and all step headers remain in SKILL.md

---

## Extract create-issues CLI commands to REFERENCE.md — #20

**Blocked by**: None

**User stories**: 2, 6

### What to build

`create-issues/SKILL.md` is 115 lines. Move the full GitHub CLI command blocks and the issue template body (the content of Steps 5–6) to a new `create-issues/REFERENCE.md`. Keep process steps as one-liner summaries in SKILL.md with a link to REFERENCE.md for the full commands and template.

### Acceptance criteria

- [x] `create-issues/SKILL.md` is under 100 lines
- [x] `create-issues/REFERENCE.md` exists and contains the CLI commands and template body
- [x] SKILL.md links to REFERENCE.md
- [x] All six process steps are still represented (as one-liners) in SKILL.md

---

## Extract implement workflow to WORKFLOW.md — #21

**Blocked by**: None

**User stories**: 2, 6

### What to build

`implement/SKILL.md` is 118 lines. Extract the embedded "Implementation workflow" block (the full Step 0–8 sub-agent instructions) to a new `implement/WORKFLOW.md`. SKILL.md keeps three steps: Step 1 (capture trigger context), Step 2 (spawn sub-agent with a prompt that references WORKFLOW.md), Step 3 (monitor).

### Acceptance criteria

- [x] `implement/SKILL.md` is under 100 lines
- [x] `implement/WORKFLOW.md` exists and contains the full Step 0–8 workflow
- [x] SKILL.md Step 2 instructs the spawned sub-agent to reference WORKFLOW.md
- [x] All three SKILL.md steps (capture, spawn, monitor) remain

---

## Extract create-a-skill reference sections to REFERENCE.md — #22

**Blocked by**: None

**User stories**: 2, 6

### What to build

`create-a-skill/SKILL.md` is 117 lines. Move the "Description Requirements" section and the "Review Checklist" section to a new `create-a-skill/REFERENCE.md`. Keep in SKILL.md: the Process section, the Skill Structure section, and links to REFERENCE.md for description requirements and the checklist.

### Acceptance criteria

- [x] `create-a-skill/SKILL.md` is under 100 lines
- [x] `create-a-skill/REFERENCE.md` exists and contains Description Requirements and Review Checklist
- [x] SKILL.md links to REFERENCE.md
- [x] Process and Skill Structure sections remain in SKILL.md

---
