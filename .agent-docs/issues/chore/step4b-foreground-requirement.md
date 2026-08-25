# Issues: chore/step4b-foreground-requirement

## Require Step 4b to run synchronously in the foreground

**GitHub**: #50

**Blocked by**: None

**User stories**: 1, 2

### What to build

Add a sentence to `address-copilot-comments/SKILL.md` Step 4b's existing "MUST NOT SKIP"
callout: the validation must run synchronously in the foreground and fully complete —
including any fixes it applies — before Step 4c and this round's Step 5 commit. Never
dispatched as a background agent while the main thread continues. Note that `code-review`
Steps 1–5 don't themselves commit anything (Step 5 there is "apply fixes, then re-run
pre-commit hooks") — the commit happens later, in `address-copilot-comments`' own Step 5, so
the requirement is that Step 4b's fixes land before that commit, not that Step 4b commits
them.

### Acceptance criteria

- [ ] Step 4b's callout in `address-copilot-comments/SKILL.md` states the validation must run
      synchronously in the foreground.
- [ ] The callout states the validation (including any fixes it applies) must fully complete
      before Step 4c and this round's Step 5 commit, without claiming Step 4b itself commits.
- [ ] The callout explicitly forbids dispatching the validation as a background agent while
      the main thread continues.
- [ ] No other wording in Step 4b or elsewhere in SKILL.md changes.
- [ ] `pre-commit-check` passes on the file.

---
