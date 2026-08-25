# Require Step 4b to Run Synchronously in the Foreground

## Problem Statement

`address-copilot-comments/SKILL.md` Step 4b already has a "MUST NOT SKIP" callout requiring
`code-review` Steps 1–5 to run whenever a fix was applied, but it says nothing about *how*
that validation must be invoked. In a real session, Step 4b's validation was dispatched as a
background agent after the round-2 fixes had already been committed and pushed — the reverse
of the intended "validate, then commit" order. It happened to be safe that time (the
background agent only found a minor issue, fixed separately), but a background agent editing
the same files the main thread might also be touching mid-review is a real coordination
hazard: two processes could make conflicting edits to the same file with neither aware of the
other.

## Solution

Add a sentence to Step 4b's existing callout: the validation must run synchronously in the
foreground and fully complete — including any fixes it applies — before Step 4c and this
round's Step 5 commit. Never dispatched as a background agent while the main thread
continues. Note: `code-review` Steps 1–5 (what Step 4b invokes) don't themselves commit
anything — Step 5's actual instruction is "apply fixes, then re-run pre-commit hooks"; the
commit happens later, in `address-copilot-comments`' own Step 5. The requirement is that any
fixes Step 4b's validation applies land before that later commit, not that Step 4b commits
them itself.

## User Stories

1. As an agent following `address-copilot-comments`, I want Step 4b to explicitly forbid
   backgrounding its own validation, so that I don't dispatch it as a background task and
   move on to committing before it finishes.
2. As a developer relying on this skill, I want validation to always precede commit/push, so
   that a background validation agent never edits files concurrently with (or after) the main
   thread's own commit, which could silently conflict or get lost.

## Implementation Decisions

- File touched: `address-copilot-comments/SKILL.md` only, within Step 4b's existing
  `> **MUST NOT SKIP.**` callout.
- Added sentence: the validation must run synchronously in the foreground and complete
  entirely — including any fixes it applies — before Step 4c and this round's Step 5 commit;
  never dispatched as a background agent while the main thread continues.
- No REFERENCE.md change: Step 4b has no corresponding REFERENCE.md section (its content is
  fully inline in SKILL.md already), so there is nothing else to update.
- No ADR: reverting a single sentence in an existing callout is trivial.

## Testing Decisions

- No code seam; this is a workflow-instruction document. Verified by review (does the added
  sentence read clearly and sit correctly within the existing callout) and by
  `pre-commit-check` (markdown lint).

## Out of Scope

- Any other Step in `address-copilot-comments` or `code-review` — this only touches Step 4b's
  own callout.
- Enforcing this programmatically (e.g. via a hook that blocks backgrounded Agent calls) —
  this stays a documented instruction, matching how every other skill-workflow rule in this
  repo works.

## Further Notes

This is the fourth of six small fixes queued from a retrospective on a recent PR; each is
being run through its own `/implement` loop rather than bundled together.
