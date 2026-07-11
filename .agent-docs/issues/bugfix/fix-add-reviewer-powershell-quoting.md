# Issues: bugfix/fix-add-reviewer-powershell-quoting

## Fix `--add-reviewer` PowerShell quoting in REFERENCE.md Step 6

**GitHub**: #34

**Blocked by**: None

**User stories**: 1, 2, 3

### What to build

Update Step 6 of `address-copilot-comments/REFERENCE.md` with three changes:

- Quote `@copilot` as `'@copilot'` in the Option A code block
- Add a blockquote note below Option A explaining that single-quoting is required in PowerShell because bare `@copilot` is parsed as a splat operator and silently drops the argument
- Change the Option B heading from `(if Option A fails)` to `(fallback if gh pr edit is unavailable)`

### Acceptance criteria

- [ ] Option A code block reads `gh pr edit {number} --add-reviewer '@copilot'`
- [ ] A note below Option A explains the PowerShell splat-operator issue
- [ ] Option B heading reads `(fallback if gh pr edit is unavailable)`
- [ ] No other lines in REFERENCE.md are modified

---
