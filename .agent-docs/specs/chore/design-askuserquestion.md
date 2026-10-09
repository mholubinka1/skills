# Retire grill and step through design via AskUserQuestion

## Problem Statement

`/implement` runs its design session through `grill`, a one-line wrapper that only says "run the `design` skill". That's an extra hop with no behaviour of its own, plus a second name for one concept. The glossary calls the session "Grill" while the skill is called `design`.

`design` asks one question at a time with a recommended answer, but in plain text. The user has to read the recommendation, invent alternatives and type a reply for every question, which slows the session down.

## Solution

Delete `grill`. `/implement` and every other live reference call `design` directly, and the glossary term becomes **Design session**. `design` asks every interview question through `AskUserQuestion`: one question per call, the recommended answer first and labelled "(Recommended)", and 1–3 real alternatives. The user can step through the session by picking options, and the built-in "Other" is there for free text.

## User Stories

1. As a `/implement` user, I want the workflow to run `design` directly, so there's no wrapper skill in between.
2. As a skill maintainer, I want `grill` deleted, so one concept has one skill.
3. As a skill reader, I want `write-spec` and `create-worktrees` to refer to the design session rather than `/grill`, so no live text points at a skill that doesn't exist.
4. As an agent reading `context.md`, I want the glossary term to be **Design session**, with "grill" listed under _Avoid_, so I use the term that matches the skill.
5. As a design-session participant, I want each question as an `AskUserQuestion` prompt with the recommended answer first, so I can accept it with one pick.
6. As a design-session participant, I want 1–3 real alternatives beside the recommendation, so I can choose a different direction without writing it out.
7. As a design-session participant, I want questions asked one per call, so each answer can shape the next question.
8. As a design-session participant, I want to answer in free text through "Other" when no option fits, so open questions stay open.
9. As a user without `AskUserQuestion`, I want design to fall back to plain-text questions with a recommendation, so the session still works.

## Implementation Decisions

- **Delete `grill/`** completely. Historical specs, issues and ADR 0003 that mention grill stay unedited, because they record what was true when they were written.
- **`implement`**: the description lists `design` instead of `grill`. In WORKFLOW.md, the prerequisite list, the Step 0 rationale and Step 2 (retitled "Design") name `design`. Steps 3–4 refer to the design output.
- **`write-spec`**: the description's trigger becomes "Use after a /design session…", and the body's "the `/grill` session" becomes "the `/design` session".
- **`create-worktrees`**: the Step 4 note says "a `/implement` design session".
- **`context.md`**: rename the **Grill** term to **Design session**, with _Avoid_: grill, planning session, interview. Change "grill" to "design session" in the **Spec** and **wip/ placeholder** entries.
- **`design` interview discipline**:
  - Every question goes through `AskUserQuestion`, with exactly one question per call.
  - Each call has 2–4 options. The recommended answer comes first with " (Recommended)" appended to its label, followed by 1–3 real alternatives (no filler, and no hand-written "Other"). This applies even to open questions.
  - The question text carries any context the user needs, such as what was found in the codebase.
  - Without `AskUserQuestion`, ask in plain text with the recommended answer.
  - The existing rules stay: explore the codebase instead of asking, and don't act until both axes are confirmed.
  - The example exchange is rewritten to show the option shape.
- **Stale install**: `sync_claude_skills.py` never removes skills, so `~/.claude/skills/grill` is deleted by hand after merge.
- **No ADR**: the change is cheap to reverse.

## Testing Decisions

- One repo-wide grep (excluding `.agent-docs/specs/`, `.agent-docs/issues/`, `.agent-docs/adr/`, `uv.lock`, design's attribution line, and the Design session `_Avoid_` line in `context.md`) returns no `grill` references.
- Read the edited `design`, `implement`, `write-spec` and `create-worktrees` skills against the acceptance criteria above.
- `pre-commit-check` passes on the changed files.

## Out of Scope

- Changing `sync_claude_skills.py` to remove installed skills that were deleted from the repo.
- The `EnterWorktree` branch-naming bug (`worktree-wip+<slug>` instead of `wip/<slug>`), filed as #121.
- Rewriting historical specs, issues or ADRs.

## Further Notes

The design session for this change was itself run with `AskUserQuestion`, one question per call, as a live check of the new discipline.
