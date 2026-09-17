# Native `update-skills` Entry Points for cmd.exe and PowerShell

## Problem Statement

`update-skills` today is a bash script (`bin/update-skills`), and `install.sh` only wires it
onto `PATH` via the user's shell rc file (`~/.zshrc` or `~/.bashrc`). On Windows this means
`update-skills` only works from Git Bash — running it from `cmd.exe` or PowerShell fails with
`'update-skills' is not recognized as an internal or external command`, even after
`install.sh` has been run, because neither shell sources `~/.bashrc`.

## Solution

Two new native entry points, plus an `install.sh` change to put them on `PATH` for both
Windows shells:

- `bin/update-skills.ps1` — a PowerShell reimplementation of `bin/update-skills`'s full
  behaviour (dirty-tree guard, fast-forward to `origin/main`, first-run `.venv`/pre-commit
  bootstrap, `sync_claude_skills.py`). No Git Bash dependency.
- `bin/update-skills.cmd` — a thin shim that invokes the `.ps1` script, so `cmd.exe` gets the
  same behaviour without a second logic implementation.
- `install.sh`, when run on Windows, additionally persists the repo's `bin/` directory onto
  the per-user `PATH` environment variable — the single mechanism both `cmd.exe` and
  PowerShell read — alongside the existing Git Bash rc-file wiring it already does on every
  platform.

## User Stories

1. As a developer on Windows who prefers `cmd.exe`, I want `update-skills` to work there
   directly, so that I don't need to open Git Bash just to refresh my skills.
2. As a developer on Windows who prefers PowerShell, I want `update-skills` to work there
   directly, so my normal terminal covers the whole workflow.
3. As a developer on Windows who still uses Git Bash for other things, I want it to keep
   working there too, so switching shells doesn't break anything that worked before.
4. As a developer running `install.sh` a second time (moved clone, or re-running after a
   fresh checkout), I want the Windows `PATH` entry to be replaced rather than duplicated, so
   `PATH` doesn't accumulate stale directories across re-installs.
5. As a developer on macOS or Linux, I want `install.sh` to behave exactly as it does today,
   so this change introduces no new setup step or behaviour on non-Windows platforms.
6. As a developer with uncommitted changes in the clone, I want `update-skills.ps1` to refuse
   to run — printing `git status` and exiting non-zero — exactly like the bash version, so
   the safety guarantee doesn't depend on which shell I used.
7. As a maintainer, I want the domain glossary (`context.md`) to describe `install.sh`'s
   actual cross-shell behaviour, so future readers aren't misled by a bash-only description.

## Implementation Decisions

- **`bin/update-skills.ps1`** mirrors `bin/update-skills` step for step:
  - Resolve the repo root from `$PSScriptRoot`'s parent (the PowerShell equivalent of the
    bash script's symlink-following `dirname` loop — `$PSScriptRoot` already resolves through
    a `PATH`-found script, so no separate symlink-walk is needed).
  - Sanity check: `sync_claude_skills.py` exists at the repo root, and the directory is a git
    work tree (`git rev-parse --is-inside-work-tree`). Fail with a clear message otherwise.
  - Dirty-tree guard: `git status --porcelain` non-empty → print `git status`, exit 1, before
    any git mutation or sync.
  - `git checkout main`, then `git pull --ff-only origin main`. A non-fast-forward failure is
    surfaced verbatim and exits non-zero — no force, no reset, matching the bash version's
    guarantee.
  - Interpreter/venv resolution: look for `.venv\Scripts\python.exe`; if absent, create it
    with `py`/`python` (whichever runs), matching the bash script's system-interpreter probe
    but using Windows-native candidates. Used only to create the venv — pip installs and the
    sync itself always run through the venv interpreter.
  - Bootstrap only when needed: install `pre-commit` into the venv if missing; run
    `pre-commit install` if the git hooks aren't present yet (checked the same way as the
    bash script — both `pre-commit` and `post-commit` hook files must exist and be
    pre-commit-generated).
  - Final step: run `sync_claude_skills.py` with the venv interpreter.
  - Every step prints a one-line `==>` progress marker, matching the bash script's `say()`
    output style, so failures are attributable the same way in either shell.
- **`bin/update-skills.cmd`** is a thin delegation shim (three lines — `@echo off`, the
  `powershell` call, and an explicit `exit /b %ERRORLEVEL%`):

  ```bat
  @echo off
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update-skills.ps1" %*
  exit /b %ERRORLEVEL%
  ```

  `-ExecutionPolicy Bypass` is scoped to this one invocation only (not a machine-wide policy
  change) — it's the standard pattern for shipping a runnable `.ps1` alongside a `.cmd` shim
  without requiring the user to have already loosened their execution policy. The explicit
  `exit /b %ERRORLEVEL%` guarantees the shim's own exit code always matches the `.ps1`'s,
  rather than relying on cmd.exe's implicit last-command behaviour.
- **`install.sh` Windows PATH wiring:**
  - Detect Windows via `[ "${OS:-}" = "Windows_NT" ]` (set by Windows itself, inherited into
    Git Bash's environment — `install.sh` is always run via Git Bash per the README, even on
    Windows).
  - On Windows only, in addition to the existing rc-file block, persist `bin_dir` onto the
    per-user `PATH` environment variable via
    `[Environment]::SetEnvironmentVariable('Path', ..., 'User')`. This runs from a small
    generated `.ps1` helper written to a temp file and invoked via
    `powershell.exe -NoProfile -ExecutionPolicy Bypass -File`, not a `-Command` one-liner —
    the helper's logic (scanning and rebuilding the `PATH` list) is easier to get right as a
    real script than as an inline string passed across the bash/PowerShell quoting boundary.
    Not `setx`: avoids `setx`'s ~1024-character truncation risk on an already-long `PATH`,
    while still triggering the same `WM_SETTINGCHANGE` broadcast `setx` relies on, so freshly
    opened `cmd.exe`/PowerShell windows pick it up without a reboot. A failure at any point
    (`cygpath` or `powershell.exe` missing, the helper erroring, unexpected output) is a hard
    `install.sh` failure (non-zero exit, clear message) rather than a silent degrade — the
    rc-file wiring may have already succeeded, but the user must not be left believing the
    Windows PATH was set when it wasn't.
  - Idempotency without marker comments (a `PATH` string has nowhere to put them): scan the
    current per-user `PATH` for any directory that contains both `update-skills.cmd` and
    `update-skills.ps1` — remove all such entries, then append the current `bin_dir` once.
    Identifying "our" entry by contents (not by an assumed folder name like `...\skills\bin`)
    keeps this correct even if the clone is renamed or relocated — as long as the old
    directory still exists at its (possibly stale) `PATH` location. One that's been deleted
    or moved away entirely has nothing left to inspect for the two marker files, so it can't
    be identified this way and is left in place; an accepted limitation of content-based
    detection over a folder-naming convention.
  - Report what changed, same spirit as the existing rc-file report: "already set up" when
    the `PATH` entry is already exactly current, otherwise "added" / "replaced stale entry".
- **`context.md`:** the `install.sh` glossary entry is updated (already done during the design
  session) to describe both the rc-file mechanism (all platforms) and the Windows `PATH`
  mechanism.
- **No ADR:** switching between delegation and native reimplementation later is a contained,
  reversible change to two files — fails the "hard to reverse" bar.
- **Lint:** no new pre-commit hook for `.ps1`/`.cmd` — see Testing Decisions. `.gitattributes`
  should gain an `eol=lf`-avoiding entry if needed so `.ps1`/`.cmd` keep native CRLF-tolerant
  handling consistent with how git already treats non-`.sh` files (verify current
  `.gitattributes` doesn't force LF onto them; it currently only targets `*.sh` and the
  extensionless `bin/update-skills`, so no change is expected to be needed there).

## Testing Decisions

- Same bar as the original `update-skills` spec: this repo has no automated test harness.
  Verification is `pre-commit-check` (static) plus hand-executed Given-When-Then scenarios
  recorded in the PR.
- No PowerShell static-analysis hook (e.g. PSScriptAnalyzer) is added: unlike `shellcheck-py`,
  which bundles its own binary, a PSScriptAnalyzer pre-commit hook would require `pwsh`
  pre-installed on every contributor's machine to run at all — not a fair assumption for this
  repo's mixed macOS/Linux/Windows contributor base. Manual review covers the new scripts.
- Scenarios (executed by hand, Windows):
  1. *Fresh install wires all three shells.* Given a clean Windows machine with none of
     `bin/` on any `PATH`, when `./install.sh` runs (from Git Bash), then: the Git Bash
     rc-file block is added as before, **and** the per-user `PATH` environment variable gains
     `bin_dir`. A freshly opened `cmd.exe` window and a freshly opened PowerShell window both
     resolve `update-skills`.
  2. *Re-running is idempotent.* Given `install.sh` has already run once, when it runs again
     unchanged, then the per-user `PATH` still contains exactly one entry for this repo's
     `bin/` (no duplicate) and the rc-file block is unchanged.
  3. *Moved clone replaces the stale entry.* Given the repo was re-cloned to a new path and
     `install.sh` is re-run from there, when it completes, then the per-user `PATH` no longer
     contains the old path's `bin/` directory, and contains the new one instead.
  4. *`update-skills.ps1` matches the bash version's happy path.* Given a clean tree and
     PowerShell, when `update-skills` runs, then it fast-forwards to `origin/main` and
     `~/.claude/skills/` reflects the repo's current `SKILL.md` directories.
  5. *`update-skills.ps1` bootstraps on first run.* Given no `.venv`, when `update-skills`
     runs, then `.venv` is created, `pre-commit` is installed into it, the git hooks are
     installed, and the sync completes; a second run skips straight to the sync.
  6. *Dirty tree is refused, PowerShell.* Given uncommitted changes, when `update-skills`
     runs from PowerShell, then it prints `git status`, changes no git state, runs no sync,
     and exits non-zero.
  7. *`update-skills.cmd` delegates correctly.* Given the same clean-tree setup as scenario 4,
     when `update-skills` runs from `cmd.exe`, then behaviour and output match the PowerShell
     run.
  8. *macOS/Linux `install.sh` is unchanged.* Given a non-Windows machine, when `install.sh`
     runs, then no `PATH`-environment-variable logic executes and behaviour is identical to
     before this change.

## Out of Scope

- Changing `bin/update-skills` (bash) or `sync_claude_skills.py` — both unchanged.
- Automated PowerShell/batch linting (PSScriptAnalyzer or similar) — see Testing Decisions.
- Any change to how `main` is tracked, or to the dirty-tree/fast-forward safety guarantees —
  this spec only ports existing behaviour to two new shells.
- Removing or deprecating the Git Bash path on Windows — it stays, per the business decision
  to support all three shells.
- CI automation for any of this (the repo has no CI workflows today).

## Further Notes

- This spec supersedes the "Out of Scope" line in the original `update-skills-command.md`
  spec that excluded native `.cmd`/`.ps1` entry points.
- `install.sh` remains a bash script run via Git Bash on Windows (per the README); only its
  *effects* gain a Windows-specific branch, not its own implementation language.
- `README.md` is also touched: its Windows setup instructions and interpreter-resolution list
  were stale (still describing Git-Bash-only usage), so they're corrected alongside the code.
