# Step 4b Explicit Skip Guard

## Problem Statement

The Step 4b instruction in `address-copilot-comments` has been incorrectly skipped in practice. Agents rationalise the skip using two loopholes in the current prose:

1. **Markdown-only loophole** — "the only changes were to Markdown/documentation files, so code-review isn't needed."
2. **Mostly-push-backs loophole** — "most decisions were push-backs, so there's nothing significant to validate."

Both rationalisations are wrong. Either can let unvalidated changes through to commit.

## Solution

Rewrite Step 4b to open with a `MUST NOT SKIP` blockquote that names the only valid skip condition (every decision was a push-back; zero files were modified), then explicitly rule out both loopholes in the prose.

## User Stories

1. As an agent running `address-copilot-comments`, I want a clear, unambiguous instruction so that I cannot rationalise skipping Step 4b when at least one fix was applied.
2. As a maintainer of this skills repo, I want the skip condition stated in one place so that future agents cannot introduce new loopholes without editing the canonical statement.

## Implementation Decisions

- Edit `address-copilot-comments/SKILL.md`, Step 4b only.
- Strip non-compliant memory-file frontmatter from `.agent-docs/context.md` (init-agent-docs Step 6 compliance fix applied in Step 0 of this workflow; no content changes to the glossary body).
- Open the step with a blockquote: `> **MUST NOT SKIP.** The only valid reason to skip this step is if every single decision in Step 4 was a push-back and zero files were modified.`
- Follow with the action sentence, then a dedicated paragraph naming Markdown, documentation, and `.agent-docs/` files as explicitly non-exempt.
- Close with the single sentence: `File type is not a skip condition.`

## Testing Decisions

- Verification is a read-through: the new Step 4b text must be unambiguous to a reader who is looking for a reason to skip.
- No automated tests apply; this is prose in a skill definition file.

## Out of Scope

- Changes to any other step in `address-copilot-comments`.
- Changes to `REFERENCE.md`.
- Fixing the reply endpoint bug noted in the handoff (separate issue).
- Fixing `context.md` frontmatter (already resolved in Step 0 of this session).

## Further Notes

The memory entry `feedback_step4b_copilot_review.md` records this rule for future conversations. This spec formalises the same intent as a durable change to the skill source.
