# Issues: chore/gh-jq-arg-pitfall-doc

## Document the gh api --jq / jq --arg pitfall

**GitHub**: #44

**Blocked by**: None

**User stories**: 1, 2

### What to build

Add a "Common pitfalls" section near the top of `address-copilot-comments/REFERENCE.md`,
before Step 2b, stating that `gh api --jq` does not accept jq's own `--arg` flag. Show a
"doesn't work" vs "works" pair of snippets, where the "works" side inlines the shell value
directly into the query string — the pattern every other snippet in the file already uses.

### Acceptance criteria

- [ ] `address-copilot-comments/REFERENCE.md` has a "Common pitfalls" section placed before
      Step 2b.
- [ ] The section states plainly that `gh`'s `--jq` flag does not accept jq's `--arg` flag.
- [ ] The section shows both a non-working `--jq --arg ...` example and the correct
      inline-substitution alternative.
- [ ] No existing snippet's behavior or wording elsewhere in the file changes.
- [ ] `pre-commit-check` passes on the file.

---
