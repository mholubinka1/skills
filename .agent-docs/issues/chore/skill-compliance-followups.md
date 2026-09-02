# Issues: chore/skill-compliance-followups

## Rename behaviour-driven-development/ to bdd/ (#81)

**Blocked by**: None

**User stories**: 1, 2, 3, 5

### What to build

Rename the skill directory `behaviour-driven-development/` to `bdd/` with `git mv` (all
seven files move, contents unchanged) so it matches its own `name: bdd` frontmatter and the
name every other skill already uses for it. Update the repo's **live** references: the two
`.agent-docs/context.md` glossary entries (the "red-green-refactor" definition and the
"implementation subagent" definition) that currently say "the `behaviour-driven-development`
skill". Leave the old string untouched in history-of-record files — the merged
`bdd-clean-context-impl` and `fix-skill-checklist-compliance` spec/issue files and the
out-of-scope bullet in the `improve-create-a-skill` spec.

### Acceptance criteria

- [ ] `bdd/` contains all seven files (`SKILL.md`, `WORKFLOW.md`, `deep-modules.md`,
      `interface-design.md`, `mocking.md`, `refactoring.md`, `tests.md`); no
      `behaviour-driven-development/` directory remains.
- [ ] `git log --follow bdd/SKILL.md` shows commits from before the rename (history
      preserved).
- [ ] `bdd/SKILL.md` frontmatter `name:` value equals the directory basename `bdd`; the
      skill's step content is byte-for-byte unchanged.
- [ ] `.agent-docs/context.md`'s "red-green-refactor" and "implementation subagent" glossary
      entries name "the `bdd` skill"; neither sentence still contains a bare
      `behaviour-driven-development`.
- [ ] `grep -rn "behaviour-driven-development"` over the repo (excluding `.git/`) returns
      only: `.agent-docs/specs/chore/bdd-clean-context-impl.md`,
      `.agent-docs/issues/chore/bdd-clean-context-impl.md`,
      `.agent-docs/specs/chore/fix-skill-checklist-compliance.md`,
      `.agent-docs/issues/chore/fix-skill-checklist-compliance.md`, and
      `.agent-docs/specs/chore/improve-create-a-skill.md`.
- [ ] `pre-commit run --all-files` passes.

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

- [ ] `pr-cleanup/SKILL.md` `description` is exactly two sentences; the second begins "Use
      when".
- [ ] The trigger sentence still records that `/code-review` runs it as its final step.
- [ ] `description` stays third person and under 1024 characters.
- [ ] The skill body (everything below the frontmatter) is unchanged.
- [ ] `pre-commit run --all-files` passes.

---
