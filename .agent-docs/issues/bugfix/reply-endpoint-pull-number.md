# Issues: bugfix/reply-endpoint-pull-number

> Work complete — PR ready to merge.

## Fix reply endpoint to include pull_number

**GitHub**: #32

**Blocked by**: None

**User stories**: 1

### What to build

Replace the broken path in both "Reply: fixed" and "Reply: push back" command blocks in `address-copilot-comments/REFERENCE.md`. The path `pulls/comments/{comment_id}/replies` returns 404; the correct path is `pulls/{number}/comments/{comment_id}/replies`.

### Acceptance criteria

- [x] "Reply: fixed" block uses `pulls/{number}/comments/{comment_id}/replies`
- [x] "Reply: push back" block uses `pulls/{number}/comments/{comment_id}/replies`
- [x] No other lines in `REFERENCE.md` are changed

---
