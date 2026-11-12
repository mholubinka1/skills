# Issues: chore/bdd-inline-workflow

> Work complete — PR ready to merge.

## bdd: audit follow-ups (BDD-1, BDD-6, BDD-9)

**GitHub issue**: #148

**Blocked by**: None

**User stories**: 1, 2, 3, 4

### What to build

`bdd` carries its steps in `SKILL.md`, defers module and interface design to the
`codebase-design` skill, and ends with a hand-back that works with or without a caller.

### Acceptance criteria

- [x] Given the `bdd` skill is loaded, when the agent reads `SKILL.md`, then Steps 0 to 5
      are there and no `WORKFLOW.md` exists in the skill (BDD-1).
- [x] Given Step 1 planning, when interfaces are designed, then the step runs the
      `codebase-design` skill, and `deep-modules.md` and `interface-design.md` no longer
      exist (BDD-6).
- [x] Given an issue that already holds Given-When-Then criteria, when Step 1 reconstructs
      the interface changes, then it applies the same interface rule.
- [x] Given `codebase-design` is not installed, when Step 1 reaches that item, then the
      step still states the rule to hold to.
- [x] Given the user invoked `bdd` directly, when Step 5 finishes, then `bdd` runs
      `pre-commit-check` on the changed files (BDD-9).
- [x] Given another skill invoked `bdd`, when Step 5 finishes, then control returns to that
      skill and no step number of another skill is named (BDD-9).

---
