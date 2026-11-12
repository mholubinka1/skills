# Issues: bugfix/pr-cleanup-close-own-issues

## create-issues: audit follow-ups (CI-2)

**GitHub issue**: #155

**Blocked by**: None

**User stories**: 4

### What to build

Both `create-issues` templates show acceptance criteria as Given-When-Then scenarios, and
the local template gives each slice a `**GitHub issue**` field for its own issue number.

### Acceptance criteria

- [ ] Given a spec ready to slice, when `create-issues` writes the local issues file, then
      every acceptance criterion in the template is a Given-When-Then scenario.
- [ ] Given a slice published to GitHub, when its number is written back, then it goes in
      that slice's `**GitHub issue**` field.

---

## pr-cleanup: audit follow-ups (PRC-1, PRC-4)

**GitHub issue**: #145

**Blocked by**: #155

**User stories**: 1, 2, 3

### What to build

`pr-cleanup` closes only the issues named on `**GitHub issue**` lines, and carries the
branch name as a noted value instead of a shell variable.

### Acceptance criteria

- [ ] Given an issues file whose slice is blocked by another issue, when `pr-cleanup` closes
      issues, then the blocking issue stays open (PRC-1).
- [ ] Given an issues file with `**GitHub issue**` lines, when `pr-cleanup` closes issues,
      then each of those issues is closed (PRC-1).
- [ ] Given an older issues file that spells the field `**GitHub**`, when `pr-cleanup`
      closes issues, then those issues are closed.
- [ ] Given Step 1 has run, when Step 2 reads the issues file in a later Bash call, then
      the path uses the noted branch name, not `$BRANCH` (PRC-4).

---
