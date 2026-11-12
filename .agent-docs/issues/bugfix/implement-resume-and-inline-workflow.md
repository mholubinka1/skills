# Issues: bugfix/implement-resume-and-inline-workflow

> Work complete — PR ready to merge.

## implement: audit follow-ups (IMP-1, IMP-2)

**GitHub issue**: #153

**Blocked by**: None

**User stories**: 1, 2, 3

### What to build

`implement` carries its whole workflow in `SKILL.md`. Step 6 ticks each slice's acceptance
criteria as the slice is committed, and state detection resumes at code review once every
slice is done.

### Acceptance criteria

- [x] Given a slice whose work has just passed `pre-commit-check`, when Step 6 commits it,
      then that slice's criteria are ticked in the issues file in the same commit (IMP-1).
- [x] Given an issues file with one slice done and one not, when a run resumes, then the
      BDD loop runs for the slice that is not done only (IMP-1).
- [x] Given an issues file in which every slice is done, when a run resumes, then it
      continues at Step 7 (IMP-1).
- [x] Given the `implement` skill is loaded, when the agent reads `SKILL.md`, then every
      step is there and no `WORKFLOW.md` exists in the skill (IMP-2).
- [x] Given the new Step 6, when the skill edits the issues file, then `allowed-tools`
      scopes that edit, and the `unittest` suite passes.

---
