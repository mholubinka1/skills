---
name: design
description: Runs a two-axis design interview — business (what and why), then engineering (how) — recording glossary terms and ADRs as decisions land. Use when the user wants to design or think through a change before building it, or when /implement reaches its design step.
allowed-tools:
  - AskUserQuestion
  - Read
  - Grep
  - Glob
  - Edit(.agent-docs/**)
  - Write(.agent-docs/**)
attribution: Combines grilling and grill-with-docs disciplines (Matt Pocock, mattpocock/skills)
---

# Design

Run a structured two-axis design session before any implementation begins. Complete both phases before writing a single line of code.

## Interview discipline

Each answer shapes the next question, so ask every question through `AskUserQuestion` — including axis confirmations and ADR offers — with exactly one question per call, waiting for the answer before continuing:

- Give 2–4 options. Put your recommended answer first, with " (Recommended)" at the end of its label.
- Fill the remaining slots with genuine alternatives — directions a reasonable user might actually choose, not filler. Do this even for open questions. For a confirmation, the alternative is the most likely adjustment.
- Do not add an "Other" option; the tool provides one for free-text answers.
- Put whatever context the user needs to decide — what you found in the codebase, the trade-off at stake — in the question text and option descriptions.

If `AskUserQuestion` is unavailable or its call fails, ask the question in plain text with your recommended answer.

If a question can be answered by exploring the codebase, explore the codebase instead.

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

Phase 1 is complete when every bullet above is answered or marked N/A, and the user confirms the business picture.

## Phase 2 — Engineering axis

Now that the *what* is pinned, probe the *how*. Explore:

- **Approach**: What is the minimal, correct technical solution? Climb the ladder and stop at the first rung that holds: already in this codebase → standard library or platform feature → an installed dependency → one line → only then new code.
- **Affected surfaces**: What parts of the codebase change? What depends on them?
- **Trade-offs**: What are the genuine alternatives and why is this one preferred?
- **Technical edge cases**: What can go wrong in the implementation that the business view missed?
- **Backwards compatibility**: Does this break existing callers, schemas, or contracts?
- **Testing strategy**: How will correct behaviour be verified?
- **Performance**: Are there latency, memory, or concurrency risks?

Phase 2 is complete when every bullet above is answered or marked N/A, and the user confirms the engineering picture.

### Update domain docs inline

As decisions crystallise, write them down immediately — do not batch.

**Glossary** — the repo's domain glossary is `.agent-docs/context.md`, the file every other skill reads. When a domain term is introduced or sharpened, update it right there. Keep it a glossary only — no implementation details. Follow the format in [`../init-agent-docs/CONTEXT-FORMAT.md`](../init-agent-docs/CONTEXT-FORMAT.md). If the file does not exist yet, create it in that format when the first term is resolved. Never write a `CONTEXT.md` at the repo root: nothing reads it.

**ADRs** — offer one only when all three are true:

1. **Hard to reverse** — changing it later is costly
2. **Surprising without context** — a future reader would wonder "why?"
3. **A real trade-off** — genuine alternatives existed and one was chosen for specific reasons

Follow the format in `ADR-FORMAT.md`.

## Completing the session

Once both axes are resolved, summarise:

- The agreed acceptance criteria (from Phase 1)
- The chosen technical approach and any ADRs raised (from Phase 2)

Then hand back to whatever invoked this session: when that was `/implement` Step 2, continue `/implement` at Step 3; when another skill called it (e.g. `code-review` Step 5), return the summary to that skill; when the user invoked it directly, offer to run `/implement` for the change.
