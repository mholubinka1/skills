# Issues: chore/init-agent-docs-audit-followups

> Work complete — PR ready to merge.

## init-agent-docs: audit follow-ups (IAD-1, IAD-2, IAD-4)

**GitHub issue**: #150

**Blocked by**: None

**User stories**: 1, 2, 3

### What to build

`init-agent-docs` carries its full procedure in `SKILL.md`, checks it is at the repository
root before writing anything, and still reviews a moved `context.md` when deleting the
source failed.

### Acceptance criteria

- [x] Given the skill is loaded, when the agent reads `SKILL.md`, then the safe-move rule
      and the full detail of Steps 1 to 6 are there and no `REFERENCE.md` exists in the
      skill (IAD-1).
- [x] Given the skill is invoked from a subdirectory, when Step 0 runs, then it stops and
      reports the subdirectory without writing anything (IAD-2).
- [x] Given the skill is invoked from the repository root, when Step 0 runs, then it
      continues to Step 1 (IAD-2).
- [x] Given the single `context.md` was written to `.agent-docs/` but its source could not
      be deleted, when Step 3 continues, then the new file is reviewed and the leftover
      source is named on the `Skipped / risk:` line (IAD-4).
- [x] Given the new Step 0 command, when the skill runs it, then `allowed-tools` scopes it,
      and the `unittest` suite passes.

---
