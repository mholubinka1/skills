# Issues: bugfix/sync-hook-interpreter-selection

## Select the sync interpreter by execution, not `command -v` (#75)

**Blocked by**: None

**User stories**: 1, 2, 3, 4, 5, 6

### What to build

Both `.pre-commit-config.yaml`'s `sync-claude-skills` hook entry and `bin/update-skills`'s
`sys_py` loop choose a Python interpreter by testing existence on `PATH` (`command -v`) or
on disk (`[ -f ]`). The Windows Store `python3` App Execution Alias passes those tests but
exits non-zero, so the wrong interpreter gets picked and the sync (or `.venv` creation)
fails.

Change both sites to pick the first candidate that actually **runs**
(`"$py" -c "" >/dev/null 2>&1`), keeping the candidate order
(`.venv/Scripts/python[.exe]` → `.venv/bin/python` → `python3` → `python`) exactly as it is.

- `.pre-commit-config.yaml`: rewrite the `entry` as an inline `bash -c` loop over the
  candidates, `exec`-ing the first that runs, and `echo`ing a one-line error + `exit 1` if
  none do. Stays inline (no new script file). One `#` comment above the hook explaining
  why selection is by execution.
- `bin/update-skills`: hoist the existing `runs_ok()` helper above the interpreter-resolution
  block and use it in the `sys_py` loop instead of `command -v`. Reword the follow-on `die`
  message from "no python3 or python on PATH" to "no working python3 or python found". One
  comment on the loop mirroring the hook's.

No change to candidate precedence, the pre-commit/post-commit split, `pick_venv_py`, or
`sync_claude_skills.py`. ADR 0005 is not part of this issue.

### Acceptance criteria

- [ ] `.pre-commit-config.yaml` `sync-claude-skills` `entry` selects the interpreter with
      `"$py" -c "" >/dev/null 2>&1`, not `command -v` / `[ -f ]`; candidate order unchanged;
      `exec`s the chosen interpreter.
- [ ] When no candidate runs, the hook prints `sync-claude-skills: no working python
      interpreter found` (or equivalent one-liner) to stderr and exits non-zero.
- [ ] On this machine (Store `python3` stub, no `.venv`): a real `git commit` on the branch
      triggers the `post-commit` hook, it runs the sync via `python`, exits 0 with no stub
      error, and `~/.claude/skills` is updated.
- [ ] `bin/update-skills` `sys_py` loop uses `runs_ok`; the "cannot create .venv" `die`
      message names *working* Python.
- [ ] A one-line rationale comment is present at both call sites.
- [ ] `pre-commit run --all-files` passes; `shellcheck` is clean on `bin/update-skills`.
- [ ] No behavioural change when a real `.venv` or a working `python3` is present (earlier
      candidate still wins).

---
