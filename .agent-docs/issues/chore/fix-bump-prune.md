# Issues: chore/fix-bump-prune

<!-- markdownlint-configure-file {"MD024": {"siblings_only": true}} -->

> Work complete — PR ready to merge.

## Real worktree placeholder name — #126 (closes #121)

**Blocked by**: None

### What to build

Establish consistent naming for the placeholder worktree form created by `EnterWorktree`:

- `EnterWorktree(name: "wip/<slug>")` creates `worktree-wip+<slug>`
- `branch-hygiene` classifies `worktree-wip+*` (and `wip/*`) as the placeholder form
- Update create-worktrees, implement Step 3, bdd, ADR 0003, and glossary to name the real form

### Acceptance criteria

- [x] `EnterWorktree` creates worktrees named `worktree-wip+<slug>`
- [x] `branch-hygiene` recognizes `worktree-wip+*` and `wip/*` as placeholder names
- [x] create-worktrees, implement Step 3, bdd, ADR 0003, and glossary reference the real form consistently
- [x] Issue #121 is resolved as part of this change

---

## pip-audit audits the repo — #127

**Blocked by**: None

### What to build

Fix pip-audit hook to audit the repo's pinned dependencies instead of its own environment:

- Change hook to audit `requirements.txt` using `-r requirements.txt --no-deps`
- Expose and fix real advisories in pinned **virtualenv 21.7.10** (PYSEC-2026-4011–4014)
- Bump virtualenv to 21.14.6

### Acceptance criteria

- [x] pip-audit hook runs with `-r requirements.txt --no-deps`
- [x] Hook result is independent of the interpreter's per-environment state
- [x] virtualenv is bumped to 21.14.6 to fix exposed advisories
- [x] `pre-commit run pip-audit --all-files` passes

---

## Sync prunes stale installs — #128

**Blocked by**: None

### What to build

Enhance `sync_claude_skills.py` to clean up stale skill installs:

- Copy each skill beside its install, then swap it in atomically
- Record installed skill names in `~/.claude/skills/.skills-repo-manifest`
- On default branch only, remove manifest-listed skills the repo no longer has
- Never touch unlisted skills, symlink targets, or names outside the install dir

### Acceptance criteria

- [x] Skills are copied atomically with swap to prevent partial updates
- [x] `~/.claude/skills/.skills-repo-manifest` is written with installed skill names
- [x] Default branch removes manifest-listed skills that repo no longer has
- [x] Unlisted skills, symlinks, and out-of-dir names are preserved
- [x] `python3 -m unittest discover -s tests` passes (11 tests)
- [x] Real post-commit sync wrote the manifest correctly
- [x] Stale `init-agent-docs/REVIEW-TEMPLATE.md` was removed

---
