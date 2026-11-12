# Issues: bugfix/create-worktrees-gitignore-check

## create-worktrees: audit follow-ups (CW-2, CW-3)

**GitHub issue**: #152

**Blocked by**: None

**User stories**: 1, 2, 3

### What to build

Step 3 of `create-worktrees` asks git whether `.claude` is ignored instead of grepping the
root `.gitignore`, and appends the entry so that it always lands on its own line.

### Acceptance criteria

- [x] Given a repo that ignores `.claude` as `/.claude` or through a global excludes file,
      when Step 3 checks, then it finds it ignored and adds nothing (CW-2).
- [x] Given a repo that does not ignore `.claude`, when Step 3 checks, then it reports it
      as not ignored (CW-2).
- [x] Given a `.gitignore` whose last line has no trailing newline, when Step 3 appends the
      entry, then `.claude` is on its own line (CW-3).
- [x] Given the entry has been appended, when Step 3 checks again, then it continues only
      if git reports `.claude` ignored.
- [x] Given the new commands, when the skill runs them, then `allowed-tools` scopes them,
      and the `unittest` suite passes.

---
