# Issues: chore/audit-skills-allowed-tools

> Work complete — PR ready to merge.

## allowed-tools convention: guard test, create-a-skill rule, all 16 skills (#139)

**Blocked by**: None

**User stories**: 1, 2, 3, 4, 5

### What to build

Add a stdlib unittest guard, `tests/test_skill_frontmatter.py`, that discovers every top-level
`*/SKILL.md` and checks its frontmatter `allowed-tools`. Watch it go red against the current repo,
then make it green. Give every skill the least-privilege `allowed-tools` list from the spec's table,
written as a YAML block list. Check each list against the commands the skill's files actually contain:
add missing non-destructive commands, drop entries nothing uses. Replace `pre-commit-check`'s
unscoped `Bash, Read`. Make the convention standing in `create-a-skill`: an `allowed-tools:` block in
the SKILL.md template, an *allowed-tools* section in REFERENCE.md with the convention rules, and a
pass/fail Review Checklist item (CAS-5).

### Acceptance criteria

- [x] Given a skill whose frontmatter has no `allowed-tools`, when the guard runs, then it fails
      naming that skill.
- [x] Given a skill that pre-approves unscoped `Bash`, `Bash(*)` or `Bash(git *)`, when the guard runs,
      then it fails naming the skill and the entry.
- [x] Given a skill that pre-approves a destructive pattern (`git push` + anything, `--force`,
      `reset --hard`, `branch -D`, `rm`, `git clean`, `stash pop`, `stash drop`), when the guard runs,
      then it fails naming the skill and the entry.
- [x] Given all 16 skills after this slice, when the guard runs, then it passes. Every list matches the
      spec's table, adjusted only by the verified command check.
- [x] Given `create-a-skill`, when an author follows its template and checklist, then `allowed-tools`
      is in the template, explained in REFERENCE.md, and a pass/fail checklist item.
- [x] `pre-commit run --all-files` passes and the full unittest suite is green.

---

## W fixes: workflow-chain skills (#140)

**Blocked by**: None

**User stories**: 6, 7, 8

### What to build

Apply the spec's writing-lever fixes, wording and structure only, to implement (IMP-3, IMP-4,
IMP-5), design (DES-2 to DES-7), write-spec (WS-1 to WS-5), create-issues (CI-1, CI-3, CI-4),
create-worktrees (CW-1, CW-4 to CW-10) and init-agent-docs (IAD-3, IAD-5 to IAD-10).

### Acceptance criteria

- [x] Given each listed finding ID, when its file is read, then the fix is applied as the spec and
      audit describe.
- [x] Given the design and implement descriptions, when compared, then no trigger branch appears in
      both: design triggers on designing or thinking through a change, or from /implement Step 2.
- [x] Given any edited skill, when diffed, then no command, step order or output changed.
- [x] Every edited description is two sentences, the second starting "Use when".
- [x] `pre-commit run --all-files` passes.

---

## W fixes: review-chain skills (#141)

**Blocked by**: None

**User stories**: 6, 7, 8

### What to build

Apply the spec's writing-lever fixes to code-review (CR-3, CR-4, CR-6, CR-7, CR-8, CR-9, CR-11,
CR-13), address-copilot-comments (ACC-3 to ACC-10), pr-cleanup (PRC-2, PRC-3), pre-commit-check
(PCC-3), branch-hygiene (BH-1 to BH-4) and bdd (BDD-2, BDD-3, BDD-4, BDD-5, BDD-7, BDD-8, BDD-10,
BDD-11).

### Acceptance criteria

- [x] Given each listed finding ID, when its file is read, then the fix is applied as the spec and
      audit describe.
- [x] Given address-copilot-comments, when searched, then "Single review" is its leading word and
      "never re-trigger" appears at most once.
- [x] Given bdd, when read, then vertical slicing is framed positively (tracer bullets) with no
      spelled-out banned horizontal pattern.
- [x] Given any edited skill, when diffed, then no command, step order or output changed.
- [x] Every edited description is two sentences, the second starting "Use when".
- [x] `pre-commit run --all-files` passes.

---

## W fixes: standalone skills (#142)

**Blocked by**: None

**User stories**: 6, 7, 8

### What to build

Apply the spec's writing-lever fixes to repo-harden (RH-1, RH-4 to RH-12), quiz-the-diff (QD-1 to
QD-8), update-dependencies (UD-7, UD-8, UD-9) and create-a-skill (CAS-1 to CAS-4).

### Acceptance criteria

- [x] Given each listed finding ID, when its file is read, then the fix is applied as the spec and
      audit describe.
- [x] Given create-a-skill, when asked to review or rework an existing skill, then the Process has an
      explicit branch for it, and the checklist covers Pruning, co-location and invocation choice.
- [x] Given any edited skill, when diffed, then no command, step order or output changed.
- [x] Every edited description is two sentences, the second starting "Use when".
- [x] `pre-commit run --all-files` passes.

---

## File B and R findings as follow-up issues (#143)

**Blocked by**: None

**User stories**: 9

### What to build

Create GitHub issues for every B and R finding in the spec's Out of Scope section, grouped one issue
per skill, each listing its finding IDs with the problem and the proposed fix. Record the issue
numbers here.

Filed:

- address-copilot-comments: #144
- pr-cleanup: #145
- pre-commit-check: #146
- code-review: #147
- bdd: #148
- repo-harden: #149
- init-agent-docs: #150
- update-dependencies: #151
- create-worktrees: #152
- implement: #153
- design: #154
- create-issues: #155

### Acceptance criteria

- [x] Given the spec's Out of Scope B and R lists, when the follow-up issues are listed, then every
      finding ID appears in exactly one issue.
- [x] Each follow-up issue names the problem, the proposed fix and the file:line for every ID it
      carries.

---
