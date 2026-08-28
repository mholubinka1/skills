# Issues: feature/update-skills-command

> Work complete — PR ready to merge.

## `update-skills` refresh command

**GitHub**: #56

**Blocked by**: None

**User stories**: 1, 3, 4, 5, 6, 7

### What to build

A checked-in `bin/update-skills` script (no file extension) that refreshes a machine's
`~/.claude/skills/` from the repo's `main`. Run from any directory, it:

1. Resolves the repo root from its own location and `cd`s there.
2. Refuses if the working tree is dirty — prints `git status`, exits non-zero, touches
   nothing.
3. Switches to `main` and fast-forwards to `origin/main` (`git pull --ff-only`); a diverged
   history makes the pull fail and the script exits non-zero without forcing.
4. Bootstraps only when missing: creates `.venv`, installs `pre-commit` into it, installs
   the git hooks.
5. Runs `sync_claude_skills.py` with the resolved interpreter.

Interpreter resolution mirrors the `sync-claude-skills` post-commit hook, same order:
`.venv/Scripts/python` → `.venv/bin/python` → `python3` → `python`. Works identically on
macOS and Windows (Git Bash).

Supporting changes: add the `shellcheck-py` hook to `.pre-commit-config.yaml`; add
`bin/update-skills` to the `.gitattributes` LF rule; add a "Skill Distribution" subsection
to `.agent-docs/context.md` defining `update-skills`, `install.sh`, and the
`sync-claude-skills` hook.

### Acceptance criteria

- [x] **Refresh pulls and syncs** — given `update-skills` runs from any directory with a
      clean tree, the clone ends on `main` fast-forwarded to `origin/main` and
      `~/.claude/skills/` reflects the repo's current `SKILL.md` directories.
- [x] **First run bootstraps** — given no `.venv` and no installed pre-commit hook, the run
      creates `.venv`, installs `pre-commit`, installs the hooks, and still completes the
      sync; a second run skips the bootstrap.
- [x] **Dirty tree is refused** — given uncommitted changes, the run prints `git status`,
      changes no git state, runs no sync, and exits non-zero.
- [x] **Diverged `main` is refused** — given local `main` has a commit not on
      `origin/main`, `git pull --ff-only` fails, the script reports it, and exits non-zero
      without forcing or resetting.
- [x] **Interpreter resolution matches the hook** — the sync is invoked with the same
      interpreter the `sync-claude-skills` hook resolves, falling back `python3` → `python`
      when no venv exists.
- [x] `shellcheck` runs on `bin/update-skills` via pre-commit and passes clean.
- [x] `pre-commit-check` passes.

---

## `install.sh` one-time setup

**GitHub**: #57

**Blocked by**: #56

**User stories**: 2, 6

### What to build

A checked-in `install.sh` at the repo root, run once after cloning, that puts
`update-skills` on the user's `PATH`:

1. Resolves its own directory as the repo root (`./install.sh` or an absolute path both
   work).
2. Picks the rc file from the login shell: `~/.zshrc` when `$SHELL` ends in `zsh`,
   otherwise `~/.bashrc`. Creates it if absent.
3. Appends a block delimited by `# >>> skills update-skills >>>` /
   `# <<< skills update-skills <<<` markers containing `export PATH="<repo>/bin:$PATH"`.
4. Idempotent: on any change, existing marker block(s) are dropped and one current block is
   appended at the end of the file (handles a moved clone; collapses accidental duplicates).
   If exactly one well-formed block already carries the current PATH line, reports "already
   set up" and makes no edit.
5. Prints that the current shell needs a new terminal or `source <rc-file>` to pick up the
   change.

Supporting change: add a "Setup" entry to `README.md` with the `./install.sh` one-liner and
the Git Bash `~/.bashrc` note.

### Acceptance criteria

- [x] **Fresh setup puts the command on PATH** — given a clone whose `bin/` is not on
      `PATH`, running `./install.sh` appends exactly one marker-delimited block adding
      `<repo>/bin` to `PATH` to the correct rc file, and prints how to activate it now.
- [x] **Setup is idempotent** — running `./install.sh` again leaves exactly one marker
      block; a moved clone's stale block (and any accidental duplicates) are dropped and one
      current block is re-appended, never stacked.
- [x] `install.sh` is executable and passes `shellcheck` via pre-commit.
- [x] `README.md` documents the one-time step and the Git Bash `.bashrc` convention.
- [x] `pre-commit-check` passes.

---
