# Explicitly trigger Copilot review, gated by a content-based review-required check

GitHub no longer auto-triggers a Copilot review on PR creation — `address-copilot-comments` Step 2 previously relied on that ("the first Copilot review triggers automatically"). We now trigger it ourselves at a new Step 2b, but only when the diff is judged a [[review-required diff]]: functional code or skill step-logic changes require review; prose-only docs, no-logic config, and formatting-only diffs are exempt and skip straight to Step 8 with no `review_round` consumed. The check reads diff *content* (`gh pr diff`), not file extension, because this repo's skills are `.md` files whose prose and executable step logic share an extension.

## Considered Options

- **Always trigger unconditionally**, matching the old auto-trigger's blanket behavior. Rejected: this repo's own changes are frequently docs/spec/issue-only (`.agent-docs/`), and burning a Copilot review round on every one of those wastes the 2-round cap on PRs that have nothing for Copilot to review.
- **Classify by file extension alone** (`.md` = docs, exempt). Rejected: would let a broken `SKILL.md`/`REFERENCE.md` step-logic edit — the actual "code" in this repo — through with no review, since it shares an extension with genuinely prose-only files like `context.md`.
