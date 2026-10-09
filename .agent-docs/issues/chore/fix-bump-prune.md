# Issues: chore/fix-bump-prune

<!-- markdownlint-configure-file {"MD024": {"siblings_only": true}} -->

## Recognise the real worktree placeholder branch — #126

**Blocked by**: None

**User stories**: 1, 2, 3

### What to build

`EnterWorktree(name: "wip/<slug>")` creates `worktree-wip+<slug>`. Make `branch-hygiene` classify `worktree-wip+*`, as well as `wip/*`, as the temporary placeholder. Make `create-worktrees` Step 4 and `implement/WORKFLOW.md` Step 3 name the real form, and append a note to ADR 0003 recording it. Closes #121.

### Acceptance criteria

- [ ] Given the branch `worktree-wip+foo`, when `branch-hygiene` runs, then it classifies it as a temporary placeholder and reports a mismatch
- [ ] Given a user-named branch `worktree-bar`, when `branch-hygiene` runs, then it is not classified as a placeholder
- [ ] Given `/implement` Step 3 after a fresh worktree, when the switch is done, then the `worktree-wip+…` branch is the one deleted
- [ ] Given `create-worktrees`, WORKFLOW.md and ADR 0003, when read, then they name `worktree-wip+<slug>` as the branch `EnterWorktree` creates

---

## pip-audit audits requirements.txt — #127

**Blocked by**: None

**User stories**: 4, 5

### What to build

Give the `pip-audit` hook `args: [-r, requirements.txt]`, so it audits the repo's pinned dependency export instead of its own hook environment. Then rebuild the local hook environments once with `pre-commit clean` (not committed).

### Acceptance criteria

- [ ] Given the pip-audit hook, when it runs, then it audits `requirements.txt`, not pip-audit's own environment
- [ ] Given `pre-commit run pip-audit --all-files`, when it runs, then it passes

---

## Sync prunes stale installed skills — #128

**Blocked by**: None

**User stories**: 6, 7, 8, 9

### What to build

`sync_claude_skills.py` replaces each repo skill wholesale in `~/.claude/skills` and records installed skill names in a skill manifest there.

- On the default branch, it removes skills that are in the old manifest but no longer in the repo, then rewrites the manifest.
- On any other branch, it never prunes, and the manifest becomes a union.
- Skills not in the manifest are never touched, and a missing manifest means no prune.

A stdlib `unittest` module covers this through the script's real entry point, against a temp `HOME` and a temp git repo.

### Acceptance criteria

- [ ] Given a skill whose repo copy lost a file, when sync runs, then the installed copy no longer has that file
- [ ] Given a manifest-listed skill deleted from the repo on the default branch, when sync runs, then it is uninstalled
- [ ] Given a manifest-listed skill deleted on a feature branch, when sync runs, then it stays installed
- [ ] Given an installed skill not in the manifest, when sync runs on the default branch, then it is never removed
- [ ] Given no manifest exists, when sync runs on the default branch, then nothing is pruned and a manifest is written

---
