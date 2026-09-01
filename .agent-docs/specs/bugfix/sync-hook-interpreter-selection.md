# Fix sync-claude-skills interpreter selection (Windows Store python3 stub)

## Problem Statement

On a fresh Windows install, `python3` resolves to the Microsoft Store "App Execution
Alias" — a real executable on `PATH` (`%LOCALAPPDATA%\Microsoft\WindowsApps\python3`) that
does nothing but print "Python was not found..." and exit non-zero.

Two places in this repo choose a Python interpreter by testing **existence on `PATH`**, not
**whether it runs**:

- `.pre-commit-config.yaml`, the `sync-claude-skills` `post-commit` hook `entry`: its
  fallback chain reaches `elif command -v python3 >/dev/null 2>&1; then python3 ...`. On this
  machine `command -v python3` succeeds (the stub is a real file), so the hook runs
  `python3 sync_claude_skills.py`, which fails with exit 49.
- `bin/update-skills`, the `sys_py` loop: `for candidate in python3 python; do if command -v
  "$candidate" ...; then sys_py="$candidate"; break; fi; done` — same test, same wrong pick.
  `sys_py` is only used to *create* `.venv`, so on a machine that already has a working
  `.venv` this is latent, but on a fresh clone `"$sys_py" -m venv .venv` fails.

User-visible effect: every `git commit` in the repo prints the `python3` stub error, and the
`post-commit` sync silently does not run, so `~/.claude/skills` drifts stale from the repo
without the committer noticing. (This is exactly what happened while shipping the uv-support
change earlier — it did not propagate to the installed skills.)

## Solution

Select the interpreter by **running** each candidate (`"$py" -c '' >/dev/null 2>&1`) instead
of by `command -v` / `[ -f ]`. A stub that exits non-zero is skipped; the loop falls through
to the next candidate. Candidate order is unchanged
(`.venv/Scripts/python[.exe]` → `.venv/bin/python` → `python3` → `python`). `bin/update-skills`
already contains exactly the right test as its `runs_ok()` helper — it is simply not applied
to `sys_py` selection.

If no candidate runs, the hook fails loudly (one-line stderr message, non-zero exit) rather
than skipping silently.

## User Stories

1. As someone committing to the skills repo on a Windows machine with no python.org Python
   installed, I want `git commit` to finish without a `python3` stub error, so that the
   commit output is clean.
2. As that same person, I want the `post-commit` sync to actually run (via whatever Python
   does work), so that `~/.claude/skills` stays current with the repo automatically.
3. As someone cloning the repo fresh on that machine and running `update-skills`, I want
   `.venv` creation to use a Python that runs, so that first-run bootstrap succeeds.
4. As someone on a healthy setup (real `.venv`, or real `python3` on `PATH`), I want the
   exact same interpreter chosen as before, so that this fix is invisible to me.
5. As a maintainer, I want a one-line comment at each call site explaining why selection is
   by execution and not `command -v`, so that nobody "simplifies" it back and reintroduces
   the bug.
6. As someone whose machine has only the broken stub, I want `update-skills` to fail with a
   message that names the real problem (no *working* Python), not "no python3 or python on
   PATH".

## Implementation Decisions

- Files touched: `.pre-commit-config.yaml`, `bin/update-skills`.
- **`.pre-commit-config.yaml`** — replace the `sync-claude-skills` `entry`'s `if/elif` chain
  with an inline `bash -c` loop over the same candidate list, each candidate guarded by
  `"$py" -c "" >/dev/null 2>&1`, then `exec "$py" sync_claude_skills.py` on the first that
  runs (`exec` so the script's exit status is what pre-commit sees). No new file — the entry
  stays inline, matching current repo style. Trailing `echo ... >&2; exit 1` when the loop
  exhausts. One `#` comment line above the hook explaining the execution-test rationale.
- **`bin/update-skills`** — hoist the existing `runs_ok()` definition above the
  "resolve Python interpreters" block and use it in the `sys_py` loop in place of
  `command -v`. Reword the subsequent `die` from
  `"no python3 or python on PATH; cannot create .venv."` to
  `"no working python3 or python found; cannot create .venv."`. Add a one-line comment on the
  `sys_py` loop mirroring the hook's.
- Candidate precedence, the `pre-commit`/`post-commit` split, and every other behaviour are
  unchanged. `[ -f ]` guards on the `.venv/...` paths become unnecessary (a non-existent
  path fails the run-test) and are dropped from the hook entry; `bin/update-skills`'s
  `pick_venv_py` keeps its `[ -x ]` guard (out of scope — it is not the buggy path).
- No ADR: the change is trivially reversible and there is no real trade-off, only a
  correctness fix. The inline comments carry the "why".
- ADR `0005-worktree-bootstrap-reinstalls-rather-than-copies-dependencies.md` (rescued from a
  deleted worktree during pre-work cleanup) is **not** part of this branch — it describes
  behaviour `create-worktrees` does not implement and belongs with a dedicated change.

## Testing Decisions

- No test files. This is a shell/YAML config fix in a repo with no shell test harness;
  adding one is out of scope.
- Verification:
  1. **Before/after reproduction on this machine** (the acceptance test): a trivial commit
     on this branch — `post-commit` sync must run via `python`, exit 0, no stub error,
     `~/.claude/skills` mtimes updated. Contrast with the pre-fix behaviour already observed
     this session (exit 49, stub message, no sync).
  2. **Manual candidate simulation**: run the extracted loop with `py` pointed at a fake
     non-zero-exit stub then a real interpreter — confirm skip-then-pick; and with only a
     failing candidate — confirm non-zero exit and the error line.
  3. **`shellcheck`** via `pre-commit run --all-files` on `bin/update-skills`. The inline
     YAML string is not shellcheck'd, so its quoting is eyeball-verified.
  4. **Healthy-path check**: confirm an earlier candidate (`.venv/...` or a real `python3`)
     still wins when present.

## Out of Scope

- `sync_claude_skills.py` itself — its unused `#!/usr/bin/env python3` shebang and its
  `os.walk` descending into `.claude/worktrees/` (which can copy in-progress skill versions)
  are separate pre-existing issues.
- `install.sh` — no Python involvement.
- Installing Python or disabling the Windows App Execution Alias — an environment change; the
  point is that the repo works regardless.
- Changing or extending the candidate list (e.g. `py -3`, versioned names).
- ADR 0005 and any `create-worktrees` dependency-bootstrap behaviour.

## Further Notes

- `bin/update-skills`'s comment block already asserts its precedence "matches
  `.pre-commit-config.yaml`'s sync-claude-skills hook" — fixing both together keeps that
  promise true.
- The rescued ADR 0005 draft remains an untracked file in the main checkout
  (`.agent-docs/adr/0005-...md`) for a future dedicated change; it must not be lost.
