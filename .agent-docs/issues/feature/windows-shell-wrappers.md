# Issues: feature/windows-shell-wrappers

## `update-skills.ps1` native reimplementation

**GitHub issue**: #103

**Blocked by**: None

**User stories**: 2, 3, 6

### What to build

A PowerShell script at `bin/update-skills.ps1` that reimplements `bin/update-skills`'s full
behaviour natively, with no Git Bash dependency:

- Resolve the repo root from the script's own location.
- Sanity-check that `sync_claude_skills.py` exists at the repo root and that the directory is
  a git work tree; fail clearly otherwise.
- Refuse to run on a dirty working tree: print `git status`, exit non-zero, before any git
  mutation or sync.
- Switch to `main` and fast-forward it to `origin/main`; surface a non-fast-forward failure
  verbatim and exit non-zero — never force, never reset.
- First-run bootstrap (only when missing): create `.venv` with a working `py`/`python`
  interpreter, install `pre-commit` into it, install the git hooks. A second run skips
  straight past this.
- Run `sync_claude_skills.py` with the venv interpreter.
- Print a one-line progress marker at each step, matching the bash script's `==>` style.

### Acceptance criteria

- [ ] Given a clean tree, running `powershell -File bin\update-skills.ps1` fast-forwards to
      `origin/main` and leaves `~/.claude/skills/` matching the repo's current `SKILL.md`
      directories.
- [ ] Given no `.venv`, running it creates `.venv`, installs `pre-commit` into it, installs
      the git hooks, and completes the sync; a second run skips the bootstrap.
- [ ] Given uncommitted changes, running it prints `git status`, changes no git state, runs
      no sync, and exits non-zero.
- [ ] Given local `main` has diverged from `origin/main`, the fast-forward fails, is reported,
      and the script exits non-zero without forcing or resetting.
- [ ] `pre-commit-check` passes clean on the new file.

---

## `update-skills.cmd` delegation shim

**GitHub issue**: #104

**Blocked by**: #103

**User stories**: 1, 3

### What to build

A one-line `bin/update-skills.cmd` that invokes the `.ps1` script
(`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update-skills.ps1" %*`), so
`cmd.exe` gets identical behaviour without a second logic implementation.

### Acceptance criteria

- [ ] Given the same clean-tree setup as Slice 1's happy path, running
      `.\bin\update-skills.cmd` from `cmd.exe` produces the same outcome and equivalent output
      to running the `.ps1` directly.
- [ ] Given a dirty tree, running `.\bin\update-skills.cmd` refuses the same way the `.ps1`
      does (prints `git status`, exits non-zero).
- [ ] `-ExecutionPolicy Bypass` is scoped to this one invocation only — no machine-wide
      policy change.
- [ ] `pre-commit-check` passes clean on the new file.

---

## `install.sh` Windows PATH wiring

**GitHub issue**: #105

**Blocked by**: #103, #104

**User stories**: 4, 5, 7

### What to build

On Windows (detected via `$OS = Windows_NT`), `install.sh` additionally persists the repo's
`bin/` directory onto the per-user `PATH` environment variable — via
`[Environment]::SetEnvironmentVariable('Path', ..., 'User')` through `powershell.exe`, not
`setx` — alongside the existing Git Bash rc-file wiring it already does on every platform.
Idempotency is content-based: any existing `PATH` directory containing both
`update-skills.cmd` and `update-skills.ps1` is treated as a stale prior entry, removed, and
replaced with one current `bin_dir` entry. Non-Windows behaviour is unchanged. The
`context.md` glossary entry for `install.sh` is updated to describe both mechanisms (already
drafted during the design session, included in this slice's commit).

### Acceptance criteria

- [ ] Given a clean Windows machine, running `./install.sh` adds the Git Bash rc-file block
      (as before) **and** adds `bin_dir` to the per-user `PATH`; a freshly opened `cmd.exe`
      and a freshly opened PowerShell window both resolve `update-skills`.
- [ ] Given `install.sh` has already run once, re-running it unchanged leaves exactly one
      `PATH` entry for this repo's `bin/` (no duplicate) and an unchanged rc-file block.
- [ ] Given the repo was re-cloned to a new path and `install.sh` is re-run from there, the
      per-user `PATH` no longer contains the old path's `bin/` directory and contains the new
      one instead.
- [ ] Given a non-Windows machine, running `install.sh` executes no `PATH`-environment-variable
      logic and behaves identically to before this change.
- [ ] `.agent-docs/context.md`'s `install.sh` entry describes both the rc-file and Windows
      `PATH` mechanisms.
- [ ] `pre-commit-check` passes clean on all changed files.

---
