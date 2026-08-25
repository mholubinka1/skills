# Document the `gh api --jq` / jq `--arg` Pitfall

## Problem Statement

`address-copilot-comments/REFERENCE.md` uses `gh api ... --jq '...'` extensively, but nothing
in the doc warns that `gh`'s `--jq` flag does not accept jq's own `--arg` flag. A user who
tries `gh api ... --jq --arg foo "$bar" '...'` gets a confusing `gh` argument-count error
(`accepts 1 arg(s), received 4`) rather than a clear explanation, and can burn many failed
attempts polling before noticing the real bug — as happened in a recent PR, where this cost
10 failed poll attempts before it was diagnosed and fixed by inlining the value into the
query string instead.

## Solution

Add a single, canonical "Common pitfalls" note near the top of `REFERENCE.md` that states the
limitation plainly and shows the correct fix: inline the shell variable directly into the
query string rather than passing `--arg` through `--jq`.

## User Stories

1. As an agent following `address-copilot-comments`, I want REFERENCE.md to warn me up front
   that `gh api --jq` cannot take jq's `--arg` flag, so that I use the correct
   inline-substitution pattern the first time instead of rediscovering the failure through
   trial and error.
2. As an agent debugging a `gh api` command that unexpectedly errors with an argument-count
   message, I want a documented pitfall I can match against, so that I can diagnose the cause
   quickly instead of assuming the query itself is wrong.

## Implementation Decisions

- File touched: `address-copilot-comments/REFERENCE.md` only.
- Add one "Common pitfalls" section directly after the document's title/intro line, before
  the first step (Step 2b), so it is seen before any of the `gh api --jq` examples that
  follow.
- Content: state that `gh`'s `--jq` does not accept jq's `--arg` flag (the two are unrelated
  flags despite the shared name), show a short "doesn't work" vs "works" pair of snippets —
  the "works" side interpolating the shell variable directly into the double-quoted filter
  string (the only mechanism that both expands the shell variable and stays a single `--jq`
  argument; existing snippets elsewhere in the file don't face this problem since none of
  them interpolate a shell variable into a filter).
- No changes to any existing bash/GraphQL snippet's behavior — this is additive documentation
  only.

## Testing Decisions

- No code seam exists; this is a markdown documentation change.
- Verification is by direct review of the rendered section for accuracy and by running the
  `pre-commit-check` skill (markdown lint / formatting hooks) to confirm the file is
  well-formed.

## Out of Scope

- Extracting the polling/suppressed-comment jq logic into a bundled script (a separate,
  lower-priority follow-up).
- Any other pitfalls beyond the `--jq`/`--arg` one (future pitfalls can be appended to the
  same section later).

## Further Notes

This is the first of six small fixes queued from a retrospective on a recent PR; each is
being run through its own `/implement` loop rather than bundled together.
