# Issues: chore/step4b-explicit-skip-guard

## Rewrite Step 4b with explicit skip guard

**GitHub**: #30

**Blocked by**: None

**User stories**: 1, 2

### What to build

Edit Step 4b in `address-copilot-comments/SKILL.md` to open with a `MUST NOT SKIP` blockquote that states the only valid skip condition (every decision was a push-back; zero files modified), followed by prose that explicitly rules out the Markdown-only and mostly-push-backs rationalisations.

### Acceptance criteria

- [ ] Step 4b opens with a `> **MUST NOT SKIP.**` blockquote naming the only valid skip condition.
- [ ] The prose explicitly states that Markdown and `.agent-docs/` files are not exempt.
- [ ] The all-push-backs skip condition is preserved and framed as the only exit.
- [ ] No other steps in `address-copilot-comments/SKILL.md` are modified.

---
