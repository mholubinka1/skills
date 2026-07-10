# Fix Skill Checklist Compliance

## Problem Statement

Thirteen skills in the repository fail validation against the `create-a-skill` checklist. Twelve distinct issues span missing trigger sentences, oversized SKILL.md files, provisional language, absent examples, and a redundant description sentence. As a result, skill descriptions give the agent insufficient signal to select the right skill, and SKILL.md files are harder to read and maintain than the standard allows.

## Solution

Fix all 12 issues so every skill passes the `create-a-skill` checklist. Oversized SKILL.md files are reduced to under 100 lines by extracting detail into REFERENCE.md or WORKFLOW.md companions. Missing "Use when..." trigger sentences are added. Provisional and redundant language is removed. Concrete examples are added where required. All changes are documentation-only — no skill behaviour changes.

## User Stories

1. As a skill author, I want every skill description to include a "Use when..." trigger, so that the agent can reliably select the right skill from the installed list.
2. As a skill reader, I want each SKILL.md to stay under 100 lines, so that the core instructions are easy to scan without scrolling through reference detail.
3. As a skill author, I want provisional language removed from skill files, so that the documentation reads as stable and authoritative.
4. As a skill user, I want concrete examples in design/SKILL.md and grill/SKILL.md, so that I understand what a grilling question looks like in practice.
5. As a skill author, I want redundant trigger sentences removed from bdd's description, so that the description is concise and non-repetitive.
6. As a skill maintainer, I want extracted detail in REFERENCE.md or WORKFLOW.md to be clearly linked from the parent SKILL.md, so that nothing is lost and readers can follow the reference chain.

## Implementation Decisions

Twelve targeted edits across thirteen skill files, grouped by issue type:

**P1 — Missing "Use when" (hard criterion):**

- `pr-cleanup/SKILL.md`: append "Use when a PR has been merged and issues need closing, or when invoked by /implement after the merge confirmation loop." to the frontmatter description.
- `init-agent-docs/SKILL.md`: extract the per-step migration prose (Steps 1–7 body) to a new `init-agent-docs/REFERENCE.md`; replace with an intro paragraph, a step-overview list, and a link to REFERENCE.md. Target: under 100 lines.
- `write-spec/SKILL.md`: delete the `> **Note**: ...candidate for restructuring...` block.
- `design/SKILL.md`: add a one-line example of a grilling question and recommended answer inside the Phase 1 section.
- `grill/SKILL.md`: add a see-also line pointing to `design/SKILL.md` for examples.

**P2 — Over 100-line limit:**

- `behaviour-driven-development/SKILL.md`: extract the Workflow section (Steps 0–5 and Checklist) to a new `behaviour-driven-development/WORKFLOW.md`; keep Philosophy and Scenarios sections in SKILL.md with a link to WORKFLOW.md.
- `address-copilot-comments/SKILL.md`: collapse Steps 3–7 inline body to one-liner summaries with links to existing REFERENCE.md anchors.
- `branch-hygiene/SKILL.md`: move validation tables (Steps 2, 4) and mismatch resolution logic (Steps 5–6) to a new `branch-hygiene/REFERENCE.md`; keep the two-mode overview and step headers in SKILL.md.
- `create-issues/SKILL.md`: move GitHub CLI command blocks and issue template body (Steps 6–7) to a new `create-issues/REFERENCE.md`; keep process steps as one-liners.
- `implement/SKILL.md`: extract the embedded "Implementation workflow" block (Steps 0–8) to a new `implement/WORKFLOW.md`; SKILL.md keeps Step 1 (capture context), Step 2 (spawn sub-agent referencing WORKFLOW.md), Step 3 (monitor).
- `create-a-skill/SKILL.md`: move "Description Requirements" and "Review Checklist" sections to a new `create-a-skill/REFERENCE.md`; keep Process and Skill Structure sections in SKILL.md.

**P3 — Redundant sentence:**

- `behaviour-driven-development/SKILL.md` description: remove third sentence "This skill should be used whenever code is modified."

All reference files are linked from their parent SKILL.md at the point where the extracted content would have appeared. Reference depth remains one level (SKILL.md → REFERENCE.md or WORKFLOW.md, never deeper).

## Testing Decisions

No runtime code is changed. Verification is by inspection:

- Line count: `wc -l` on each edited SKILL.md must be under 100.
- Trigger presence: grep for "Use when" in each skill's frontmatter description.
- Provisional language: grep for "candidate for restructuring" or "in the future" — must be absent.
- Example presence: read `design/SKILL.md` and `grill/SKILL.md` for at least one concrete example or see-also pointer.
- Redundant sentence: grep for "This skill should be used whenever code is modified" — must be absent.
- Reference links: each new REFERENCE.md / WORKFLOW.md must be linked from its parent SKILL.md.

## Out of Scope

- Changes to skill behaviour, logic, or step content (beyond moving text to companion files)
- Adding new skills
- Updating skills not listed in the 12 issues
- Changes to scripts, templates, or non-SKILL.md files other than the new REFERENCE.md / WORKFLOW.md companions

## Further Notes

`behaviour-driven-development/SKILL.md` has two issues (P2 line-length and P3 redundant sentence) — both are addressed in a single edit pass. The `address-copilot-comments` skill already has a REFERENCE.md; the P2 fix collapses inline step detail to point at existing anchors rather than creating a new file.
