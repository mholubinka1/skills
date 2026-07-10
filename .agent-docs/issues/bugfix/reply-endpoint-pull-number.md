# Issues: bugfix/reply-endpoint-pull-number

## Fix reply endpoint to include pull_number

**GitHub**: #32

**Blocked by**: None

**User stories**: 1

### What to build

Replace the broken path in both "Reply: fixed" and "Reply: push back" command blocks in `address-copilot-comments/REFERENCE.md`. The path `pulls/comments/{comment_id}/replies` returns 404; the correct path is `pulls/{number}/comments/{comment_id}/replies`.

### Acceptance criteria

- [ ] "Reply: fixed" block uses `pulls/{number}/comments/{comment_id}/replies`
- [ ] "Reply: push back" block uses `pulls/{number}/comments/{comment_id}/replies`
- [ ] No other lines in `REFERENCE.md` are changed

---
