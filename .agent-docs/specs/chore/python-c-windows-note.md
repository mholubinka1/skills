# Document Windows python -c Bash-Tool Gotcha

## Problem Statement

Neither `init-agent-docs/AGENT-TEMPLATE.md` nor this repo's own mirrored `.agent-docs/agent.md`
documents a previously-observed, reproducible Windows tooling gotcha: invoking a multi-line
`python -c "<script>"` through a Bash-tool-style shell can silently produce no output — no
error, just nothing. This has been reproduced more than once and cost debugging time each
time before the cause was identified.

## Solution

Add a new `## 7. Environment Notes` section to the end of both `AGENT-TEMPLATE.md` and
`.agent-docs/agent.md`, with one bullet explicitly scoped to Windows + Bash-tool-style shells,
recommending writing the script to a scratch file and running it directly instead of inlining
multi-line Python.

## User Stories

1. As an agent working on Windows via a Bash-tool-style shell, I want a documented warning
   about `python -c` silently failing on multi-line scripts, so that I default to a scratch
   file instead of losing time to a silent no-output failure.
2. As a maintainer of this skills repo, I want its own `.agent-docs/agent.md` to carry the
   same environment note as the template it stamps into other repos, matching fix #5's
   template/mirror-sync precedent.

## Implementation Decisions

- Files touched: `init-agent-docs/AGENT-TEMPLATE.md` and `.agent-docs/agent.md`, both
  identically.
- New section: `## 7. Environment Notes`, appended after the existing `## 6. Communication
  and Feedback` section — append-only, no interleaving with existing sections' bullets
  (including fix #5's new Production Code Quality bullet).
- The note is explicitly scoped to "On Windows, via a Bash-tool-style shell" in its own
  wording — this is a tooling quirk of one platform/tool combination, not a universal coding
  standard, and the template is stamped into arbitrary repos regardless of OS or which AI
  agent reads it. Confirmed with the user this belongs here rather than being dropped, given
  the scoping caveat.
- No ADR: reverting a single new section from two files is trivial.

## Testing Decisions

- No code seam; this is a behavioural-standards document. Verified by review (does the note
  read clearly and correctly scope itself to the affected platform/tool combination) and by
  `pre-commit-check` (markdown lint).

## Out of Scope

- Any other Environment Notes beyond this one Windows/`python -c` gotcha.
- Auditing for other template/mirror drift beyond this fix's own change.

## Further Notes

This is the sixth and final fix of six small fixes queued from a retrospective on a recent
PR; each was run through its own `/implement` loop rather than bundled together.
