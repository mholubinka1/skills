# Issues: chore/bdd-inline-workflow

> Work complete — PR ready to merge.

## bdd: audit follow-ups (BDD-1, BDD-6, BDD-9)

**GitHub issue**: #148

**Blocked by**: None

**User stories**: 1, 2, 3, 4, 5

### What to build

`bdd` carries its steps in `SKILL.md` and ends with a hand-back that works with or without
a caller. BDD-6 is declined: `deep-modules.md` and `interface-design.md` stay, so the skill
depends on nothing outside this repo.

### Acceptance criteria

- [x] Given the `bdd` skill is loaded, when the agent reads `SKILL.md`, then Steps 0 to 5
      are there and no `WORKFLOW.md` exists in the skill (BDD-1).
- [x] Given only this skills repo is installed, when `bdd` runs, then every file and skill
      it names is in this repo, and `deep-modules.md` and `interface-design.md` are
      unchanged (BDD-6 declined).
- [x] Given an issue that already holds Given-When-Then criteria, when Step 1 reconstructs
      the interface changes, then it applies the same interface rule as the Three Amigos
      path.
- [x] Given the user invoked `bdd` directly, when Step 5 finishes, then `bdd` runs
      `pre-commit-check` on the changed files (BDD-9).
- [x] Given another skill invoked `bdd`, when Step 5 finishes, then control returns to that
      skill and no step number of another skill is named (BDD-9).

---
