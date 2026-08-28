# `update-skills` Refresh Command

## Problem Statement

The skills in this repo reach `~/.claude/skills/` on a given machine only via the
`sync-claude-skills` post-commit hook — which fires solely when *that machine* commits in
the repo. On a machine that mostly *consumes* skills (clones the repo, rarely commits to
it), there is no single command to pull what other people have pushed to `main` and
re-sync. Today that means remembering the sequence by hand: `git checkout main`,
`git pull`, then find and run `sync_claude_skills.py` with the right interpreter — and on a
brand-new clone, also creating the `.venv` and installing the pre-commit hooks first. This
has to work the same on macOS and on Windows (Git Bash), the two environments the repo
already documents.

## Solution

A terminal command, `update-skills`, runnable from any directory, that performs the whole
refresh in order:

1. Refuse if the clone's working tree is dirty (print `git status`, exit non-zero) — never
   stash or discard the user's work.
2. Switch to `main` and fast-forward it to `origin/main` (`git pull --ff-only`; abort,
   don't force, if history has diverged).
3. First-run bootstrap, only when missing: create `.venv`, install `pre-commit` into it,
   install the git hooks.
4. Run `sync_claude_skills.py` to refresh `~/.claude/skills/`.

Plus a one-time setup step, run once after cloning:

```bash
./install.sh
```

`install.sh` puts `update-skills` on the user's `PATH` by appending a marked block to their
shell rc file that adds the repo's `bin/` directory to `PATH`. It is idempotent, tells the
user how to activate the change in their current shell, and can be re-run if the clone
moves.

## User Stories

1. As a developer on a machine that consumes skills, I want a single `update-skills`
   command, so that I can pull the latest `main` and refresh `~/.claude/skills/` without
   remembering the individual git and sync steps.
2. As a developer who just cloned the repo, I want one setup instruction (`./install.sh`),
   so that `update-skills` becomes available in my terminal without hand-editing my shell
   configuration.
3. As a developer whose first `update-skills` run is on a fresh clone, I want it to create
   the `.venv` and install the pre-commit hooks automatically, so that one command covers
   both first-run setup and the ongoing refresh.
4. As a developer with work in progress in the clone, I want `update-skills` to refuse
   while the tree is dirty, so that it never stashes, discards, or fast-forwards over my
   uncommitted changes.
5. As a developer whose local `main` has diverged from `origin/main`, I want the pull to
   abort rather than force, so that no local commits are silently lost.
6. As a developer on Windows using Git Bash, I want `update-skills` and `install.sh` to
   behave the same as on macOS, so that the same repo works across the team's machines.
7. As a maintainer, I want the two new shell scripts linted on every commit, so that
   portability mistakes are caught before they land.

## Implementation Decisions

- **Two checked-in files plus config and docs:**
  - `bin/update-skills` — the command. No file extension, so the command name is clean;
    `bin/` holds only this one entry, so adding `bin/` to `PATH` shadows nothing.
  - `install.sh` at the repo root — the one-time setup.
- **`install.sh` behaviour:**
  - Resolves its own directory as the repo root, so `./install.sh` or an absolute path both
    work.
  - Chooses the rc file from the login shell: `~/.zshrc` when `$SHELL` ends in `zsh`
    (macOS default), otherwise `~/.bashrc` (Git Bash on Windows, Linux). If the chosen file
    does not exist it is created.
  - Appends a block delimited by marker comments
    (`# >>> skills update-skills >>>` / `# <<< skills update-skills <<<`) containing
    `export PATH="<repo>/bin:$PATH"`. Idempotent: any existing marker block(s) are removed
    and one current block is appended at the end of the file (handles a moved clone;
    collapses accidental duplicates) — not a literal in-place rewrite, so a refreshed block
    moves to the end.
  - Prints that the current shell needs a new terminal or `source <rc-file>` to pick up the
    change — a child process cannot mutate its parent shell's environment.
  - If `<repo>/bin` is already on `PATH` and the marker block is already present and
    correct, reports "already set up" and makes no edit.
- **`bin/update-skills` behaviour:**
  - Resolves the repo root from its own location (`dirname "$0"/..`), with a short symlink
    resolution loop for safety; does not rely on `readlink -f` (absent/different on BSD and
    some Git Bash builds). `cd`s to the repo root before any git command.
  - Dirty-tree guard first: `test -n "$(git status --porcelain)"` → print `git status`,
    exit 1, before touching git or the sync.
  - `git checkout main` then `git pull --ff-only`. A non-fast-forward pull fails on its own;
    the script surfaces the failure and exits non-zero. No `--force`, no reset.
  - Interpreter resolution mirrors `.pre-commit-config.yaml`'s `sync-claude-skills` hook, in
    the same order: `.venv/Scripts/python` (Windows venv) → `.venv/bin/python`
    (macOS/Linux venv) → `python3` → `python`.
  - Bootstrap runs only when needed: if no `.venv`, create it with the first system
    interpreter found and `pip install pre-commit` into it; if the pre-commit hook is not
    installed (`git rev-parse --git-path hooks/pre-commit` missing), run
    `pre-commit install` from the venv. A second run finds both present and skips straight
    to the sync.
  - Final step: run `sync_claude_skills.py` with the resolved interpreter (the venv one
    after bootstrap). The sync script is unchanged — it is standard-library only and already
    walks the repo copying every `SKILL.md` directory to `~/.claude/skills/`.
  - `set -euo pipefail`; every step echoes a one-line progress marker so a failure is
    attributable.
- **`main` is hardcoded** as the branch to track (declared once as a variable at the top of
  the script) — matching the repo's actual default branch and the explicit request.
- **Lint:** add the `shellcheck-py` hook to `.pre-commit-config.yaml` so `install.sh` and
  `bin/update-skills` are checked on every commit. `.gitattributes` already forces LF on
  `*.sh`; add `bin/update-skills` to that rule so the extensionless script keeps LF too.
- **`context.md`:** add a short "Skill Distribution" subsection defining `update-skills`,
  `install.sh`, and the existing `sync-claude-skills` hook as bounded terms.
- **No ADR:** the change is a few small files and a hook line; reverting it is trivial and
  needs no context to understand.

## Testing Decisions

- The repo has **no automated test harness** — verification across existing specs is
  "review + `pre-commit-check`". Same here, with two layers:
  - **Static:** the new `shellcheck` pre-commit hook lints both scripts on every commit;
    `pre-commit-check` must pass clean.
  - **Behavioural:** the Given-When-Then scenarios below are executed by hand on macOS and
    recorded in the PR. Windows (Git Bash) is exercised on a best-effort basis by a
    reviewer with access; the platform-specific surface is limited to the rc-file choice
    and the interpreter-resolution order, both of which are read-path branches a reviewer
    can confirm.
- Good verification here checks **observable outcomes** — a line in the rc file, the branch
  after a run, files under `~/.claude/skills/`, the exit code — not the script's internal
  structure.
- Scenarios:
  1. *Fresh setup puts the command on PATH.* Given a clone whose `bin/` is not on `PATH`,
     when `./install.sh` runs, then a single marker-delimited block adding `<repo>/bin` to
     `PATH` is appended to the correct rc file, and the script prints how to activate it
     now.
  2. *Setup is idempotent.* Given `install.sh` has already run, when it runs again, then the
     rc file still contains exactly one marker block — unchanged when already current, or
     dropped and re-appended (moving to the end) if the clone moved — never stacked.
  3. *Refresh pulls and syncs.* Given `update-skills` is on `PATH` and the tree is clean,
     when it runs from any directory, then the clone is on `main`, fast-forwarded to
     `origin/main`, and `~/.claude/skills/` reflects the repo's current `SKILL.md`
     directories.
  4. *First run bootstraps.* Given a clone with no `.venv` and no installed pre-commit hook,
     when `update-skills` runs, then `.venv` is created, `pre-commit` is installed into it,
     the git hooks are installed, and the sync still completes; a second run skips the
     bootstrap.
  5. *Dirty tree is refused.* Given the clone has uncommitted changes, when `update-skills`
     runs, then it prints `git status`, changes no git state and runs no sync, and exits
     non-zero.
  6. *Diverged `main` is refused.* Given local `main` has a commit not on `origin/main`,
     when `update-skills` runs, then `git pull --ff-only` fails, the script reports it, and
     exits non-zero without forcing or resetting.
  7. *Interpreter resolution matches the hook.* Given a Windows-style `.venv/Scripts/python`
     or a POSIX `.venv/bin/python`, when `update-skills` runs the sync, then it uses the
     same interpreter the `sync-claude-skills` hook would, falling back to `python3` then
     `python` when no venv exists.

## Out of Scope

- Changing `sync_claude_skills.py` itself (unchanged).
- A native Windows entry point (`.cmd`/`.ps1`) or PowerShell support — Windows use is via
  Git Bash, consistent with the repo's existing setup instructions.
- Auto-`source`ing the rc file into the user's running shell — impossible from a child
  process; the user opens a new terminal or sources it themselves.
- Any dependency resolution beyond `pre-commit` (the sync itself needs none).
- Adding a shell test framework (e.g. `bats`) — no prior art in the repo; `shellcheck`
  plus the manual scenarios are the agreed bar.
- Making `update-skills` work against a fork/upstream whose default branch is not `main`.

## Further Notes

- The post-commit `sync-claude-skills` hook stays as-is; `update-skills` complements it for
  the consume-only workflow rather than replacing it.
- `install.sh` writing to `~/.bashrc` on Git Bash follows the Git-for-Windows convention
  where `~/.bash_profile` sources `~/.bashrc`; noted in the README setup section.
