# Warn Against Unanchored sed Renames in Agent Standards

## Problem Statement

Neither `init-agent-docs/AGENT-TEMPLATE.md` (the behavioural-standards template stamped into
every repo's `.agent-docs/agent.md` by the `init-agent-docs` skill) nor this repo's own
mirrored `.agent-docs/agent.md` warns against a specific, previously-observed failure mode:
using unanchored `sed`/regex find-replace for identifier renames. In a real session,
`sed -i 's/_parse_window_date/parse_window_date/g'` mangled unrelated test names as collateral
damage — `test_parse_window_date_x` became `testparse_window_date_x` — because the pattern
wasn't anchored against the `test_` prefix's word boundary, eating the underscore. Fixing the
damage required rewriting the whole affected file.

## Solution

Add a bullet under "Production Code Quality" in both `AGENT-TEMPLATE.md` and this repo's own
`.agent-docs/agent.md`, warning against unanchored `sed`/regex find-replace for identifier
renames and recommending word-boundary-anchored patterns or a proper multi-file rename tool
instead.

## User Stories

1. As an agent renaming an identifier across multiple files in any repo bootstrapped with
   `init-agent-docs`, I want a documented warning against unanchored `sed` renames, so that I
   use word-boundary-anchored patterns (or a proper rename tool) and don't silently mangle
   unrelated identifiers that happen to contain the same substring.
2. As a maintainer of this skills repo, I want its own `.agent-docs/agent.md` to carry the
   same guidance as the template it stamps into other repos, so this repo doesn't drift from
   the standard it distributes — the exact class of staleness fix #3
   (`chore/stale-rationale-review-check`) was built to catch.

## Implementation Decisions

- Files touched: `init-agent-docs/AGENT-TEMPLATE.md` and `.agent-docs/agent.md`, both
  identically, under the existing `## 2. Production Code Quality` section.
- New bullet placed near the existing naming bullet ("Name everything descriptively..."),
  since it's about the same class of concern (identifier naming/renaming), not about git
  practice — renaming an identifier is a code-quality operation, not a source-control one.
- Bullet content: never use unanchored `sed`/regex find-replace for identifier renames — a
  pattern like `_parse_window_date` also matches inside `test_parse_window_date_x`. Anchor on
  word boundaries or use a proper multi-file rename tool instead. Trimmed after review to one
  concrete example and a short recommendation, matching the terse, single-clause style of the
  file's other Production Code Quality bullets rather than the initial longer draft.
- Both files updated in the same commit, matching fix #3's own lesson: when a template and
  its mirrored copy both need to change, sweep them together rather than letting one drift.
- No ADR: reverting a single bullet from two files is trivial.

## Testing Decisions

- No code seam; this is a behavioural-standards document. Verified by review (does the bullet
  read clearly, is it placed correctly in both files, do both files match) and by
  `pre-commit-check` (markdown lint).

## Out of Scope

- Auditing `init-agent-docs` for other places `AGENT-TEMPLATE.md` and `.agent-docs/agent.md`
  might already have drifted apart (not observed in this session; out of scope for this
  narrow fix).
- Any other Production Code Quality bullet.

## Further Notes

This is the fifth of six small fixes queued from a retrospective on a recent PR; each is
being run through its own `/implement` loop rather than bundled together.
