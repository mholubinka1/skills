# Issues: chore/step4b-foreground-requirement

## Require Step 4b to run synchronously in the foreground

**GitHub**: #50

**Blocked by**: None

**User stories**: 1, 2

### What to build

Add a sentence to `address-copilot-comments/SKILL.md` Step 4b's existing "MUST NOT SKIP"
callout: the validation must run synchronously in the foreground and fully complete —
including any fixes it produces being committed — before Step 4c proceeds. Never dispatched
as a background agent while the main thread continues.

### Acceptance criteria

- [ ] Step 4b's callout in `address-copilot-comments/SKILL.md` states the validation must run
      synchronously in the foreground.
- [ ] The callout states the validation must fully complete (including committing any fixes
      it produces) before Step 4c proceeds.
- [ ] The callout explicitly forbids dispatching the validation as a background agent while
      the main thread continues.
- [ ] No other wording in Step 4b or elsewhere in SKILL.md changes.
- [ ] `pre-commit-check` passes on the file.

---
