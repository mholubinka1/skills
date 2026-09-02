# Issues: chore/skill-compliance-followups

> Work complete — PR ready to merge.

## Rename behaviour-driven-development/ to bdd/ (#81)

**Blocked by**: None

**User stories**: 1, 2, 3, 5

### What to build

Rename the skill directory `behaviour-driven-development/` to `bdd/` with `git mv` (all
seven files move, contents unchanged) so it matches its own `name: bdd` frontmatter and the
name every other skill already uses for it. Update the repo's **live** references: the two
`.agent-docs/context.md` glossary entries (the "BDD loop" definition and the
"Implementation subagent" definition) that currently say "the `behaviour-driven-development`
skill". Leave the old string untouched in history-of-record files — the merged
`bdd-clean-context-impl` and `fix-skill-checklist-compliance` spec/issue files and the
out-of-scope bullet in the `improve-create-a-skill` spec.

### Acceptance criteria

- [x] `bdd/` contains all seven files (`SKILL.md`, `WORKFLOW.md`, `deep-modules.md`,
      `interface-design.md`, `mocking.md`, `refactoring.md`, `tests.md`); no
      `behaviour-driven-development/` directory remains.
- [x] `git log --follow bdd/SKILL.md` shows commits from before the rename (history
      preserved).
- [x] `bdd/SKILL.md` frontmatter `name:` value equals the directory basename `bdd`; the
      skill's step content is byte-for-byte unchanged.
- [x] `.agent-docs/context.md`'s "BDD loop" and "Implementation subagent" glossary
      entries name "the `bdd` skill"; neither sentence still contains a bare
      `behaviour-driven-development`.
- [x] `grep -rn "behaviour-driven-development"` over the repo (excluding `.git/` and the
      untracked `.claude/settings.local.json`) returns only: the five history-of-record files
      — `.agent-docs/{specs,issues}/chore/bdd-clean-context-impl.md`,
      `.agent-docs/{specs,issues}/chore/fix-skill-checklist-compliance.md`,
      `.agent-docs/specs/chore/improve-create-a-skill.md` — plus this branch's own
      `.agent-docs/{specs,issues}/chore/skill-compliance-followups.md`, which describe the
      rename itself.
- [x] `pre-commit run --all-files` passes.

---

## Add a "Use when" trigger to pr-cleanup's description (#82)

**Blocked by**: None

**User stories**: 4

### What to build

Rewrite the second sentence of `pr-cleanup/SKILL.md`'s frontmatter `description` from the
provenance note "Invoked automatically by /code-review after the Copilot review loop" into a
"Use when [triggers]" sentence, keeping the `/code-review` call-site context. No change to
the skill's steps.

### Acceptance criteria

- [x] `pr-cleanup/SKILL.md` `description` is exactly two sentences; the second begins "Use
      when".
- [x] The trigger sentence still records that `/code-review` runs it as its final step.
- [x] `description` stays third person and under 1024 characters.
- [x] The skill body (everything below the frontmatter) is unchanged.
- [x] `pre-commit run --all-files` passes.

---
