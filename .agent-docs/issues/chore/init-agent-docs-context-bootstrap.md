# Issues: chore/init-agent-docs-context-bootstrap

## Fix init-agent-docs context bootstrap (Steps 4, 5, 6)

**Blocked by**: None

**User stories**: 1, 2, 3, 4

### What to build

Update `init-agent-docs/SKILL.md` and `init-agent-docs/REFERENCE.md` so that the skill
always produces or validates a domain glossary, rather than copying a non-existent template.

Three step changes, two files:

- **Step 4**: remove the "skip to Step 7" branch when `context.md` already exists; route to
  Step 6 (review sub-path) instead, so every run reviews the existing glossary.
- **Step 5** (REFERENCE.md only): change the skip target after a successful file move from
  "skip to Step 7" to "continue to Step 6 (review sub-path)", so a newly moved file is
  immediately reviewed.
- **Step 6**: replace the broken `CONTEXT-TEMPLATE.md` verbatim-copy instruction with two
  sub-paths:
  - **Generate** (no `context.md` found): read `CONTEXT-FORMAT.md`, read the codebase,
    write a full domain glossary to `.agent-docs/context.md`.
  - **Review and improve** (file exists or was just moved): read `CONTEXT-FORMAT.md`, audit
    the existing file against its rules, write improvements if shortcomings are found, or
    report "no improvements needed" if already compliant.

### Acceptance criteria

- [ ] `SKILL.md` Step 4 no longer says "skip to Step 7" when `context.md` exists; it routes to Step 6.
- [ ] `REFERENCE.md` Step 4 no longer says "skip to Step 7" when `context.md` exists; it routes to Step 6.
- [ ] `REFERENCE.md` Step 5 no longer says "skip to Step 7" after a successful file move; it continues to Step 6.
- [ ] `REFERENCE.md` Step 6 defines a **generate** sub-path that reads `CONTEXT-FORMAT.md` and the codebase before writing `context.md`.
- [ ] `REFERENCE.md` Step 6 defines a **review and improve** sub-path with explicit audit criteria, an "improved" report variant, and a "no improvements needed" report variant.
- [ ] `SKILL.md` Step 6 summary reflects the two sub-paths (generate vs review-and-improve).
- [ ] Neither `SKILL.md` nor `REFERENCE.md` contains any reference to `CONTEXT-TEMPLATE.md`.

---
