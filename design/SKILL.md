---
name: design
description: Two-axis design session before any repository change — interviews from the business angle (what and why) then the engineering angle (how), updating CONTEXT.md and ADRs inline as decisions crystallise. Use whenever a user wants to change the codebase, technical documents, skills, or configuration.
attribution: Combines grilling and grill-with-docs disciplines (Matt Pocock, mattpocock/skills)
---

# Design

Run a structured two-axis design session before any implementation begins. Complete both phases before writing a single line of code.

## Interview discipline

Ask questions **one at a time**, waiting for feedback before continuing. Asking multiple questions at once is bewildering, and each answer should shape the next question.

Ask every question through `AskUserQuestion`, with exactly one question per call, so the user can step through the session by picking options:

- Give 2–4 options. Put your recommended answer first, with " (Recommended)" at the end of its label.
- Fill the remaining slots with genuine alternatives — directions a reasonable user might actually choose, not filler. Do this even for open questions.
- Do not add an "Other" option; the tool provides one for free-text answers.
- Put whatever context the user needs to decide — what you found in the codebase, the trade-off at stake — in the question text and option descriptions.

If `AskUserQuestion` is unavailable, ask the question in plain text with your recommended answer.

If a question can be answered by exploring the codebase, explore the codebase instead.

Do not enact the plan until the user confirms a shared understanding across **both** axes.

## Phase 1 — Business axis

Probe the *what* and *why* before thinking about the *how*. Open with the first question every change must survive — **does this need to exist at all?** Push back on any part of the request the need does not justify. Then explore:

- **Desired behaviour**: What should the system do differently? What does success look like?
- **Motivation**: What pain point or opportunity drives this? Who benefits?
- **Acceptance criteria**: What specific outcomes confirm this is done?
- **Constraints**: What must not change? What is explicitly out of scope?
- **Failure modes**: What does broken look like from a user's perspective?
- **Edge cases**: Probe boundaries — empty states, concurrent users, partial failure.

**Example question** — "What does success look like for the user?", with options:

1. **Merged PR, no manual git (Recommended)** — a developer runs `/implement` and gets a merged PR without writing any git commands.
2. **Reviewed PR, user merges** — the workflow stops at an approved PR and leaves the merge to the user.
3. **Local commits only** — the workflow commits locally; pushing and the PR stay manual.

Do not move to Phase 2 until the business picture is complete and agreed.

## Phase 2 — Engineering axis

Now that the *what* is pinned, probe the *how*. Explore:

- **Approach**: What is the minimal, correct technical solution? Climb the ladder and stop at the first rung that holds: already in this codebase → standard library or platform feature → an installed dependency → one line → only then new code.
- **Affected surfaces**: What parts of the codebase change? What depends on them?
- **Trade-offs**: What are the genuine alternatives and why is this one preferred?
- **Technical edge cases**: What can go wrong in the implementation that the business view missed?
- **Backwards compatibility**: Does this break existing callers, schemas, or contracts?
- **Testing strategy**: How will correct behaviour be verified?
- **Performance**: Are there latency, memory, or concurrency risks?

### Update domain docs inline

As decisions crystallise, write them down immediately — do not batch.

**CONTEXT.md** — when a domain term is introduced or sharpened, update it right there. Keep it a glossary only — no implementation details. Follow the format in `CONTEXT-FORMAT.md`.

**ADRs** — offer one only when all three are true:

1. **Hard to reverse** — changing it later is costly
2. **Surprising without context** — a future reader would wonder "why?"
3. **A real trade-off** — genuine alternatives existed and one was chosen for specific reasons

Follow the format in `ADR-FORMAT.md`.

## Completing the session

Once both axes are resolved, summarise:

- The agreed acceptance criteria (from Phase 1)
- The chosen technical approach and any ADRs raised (from Phase 2)

Only then proceed to implementation.
