# Issues: chore/design-askuserquestion

> Work complete — PR ready to merge.

<!-- markdownlint-configure-file {"MD024": {"siblings_only": true}} -->

## Retire grill; run design directly — #122

**Blocked by**: None

**User stories**: 1, 2, 3, 4

### What to build

Delete the `grill` wrapper skill, and point every live reference at `design`:

- `implement`'s description, plus WORKFLOW.md's prerequisites, Step 0 rationale, and Steps 2–4.
- `write-spec`'s description and body.
- `create-worktrees`' Step 4 note.

Rename the glossary term **Grill** to **Design session** (with grill under _Avoid_) and update the Spec and wip/ placeholder entries to match. Historical specs, issues and ADRs stay unedited.

### Acceptance criteria

- [x] Given `/implement` reaches its design step, when WORKFLOW.md is followed, then it runs `design` directly
- [x] Given the repo, when grepped for `grill` outside historical specs/issues/ADRs, `uv.lock`, design's attribution and the Design session `_Avoid_` line, then nothing matches, and `grill/` does not exist
- [x] Given `context.md`, when an agent looks up the session term, then it finds **Design session** with grill under _Avoid_

---

## Design asks every question via AskUserQuestion — #123

**Blocked by**: None

**User stories**: 5, 6, 7, 8, 9

### What to build

Rewrite `design`'s interview discipline so that every question goes through `AskUserQuestion`:

- One question per call.
- 2–4 options: the recommended answer first with " (Recommended)" appended, then 1–3 real alternatives (no filler, no hand-written "Other").
- Any context the user needs goes in the question text.

Keep a plain-text fallback with a recommendation for when the tool isn't available. Update the example exchange to show the option shape.

### Acceptance criteria

- [x] Given a design question, when it is asked, then it is a single `AskUserQuestion` call with 2–4 options and the first option labelled "(Recommended)"
- [x] Given an open question, when it is asked, then it still offers options, and free text goes through the built-in "Other"
- [x] Given `AskUserQuestion` is unavailable, when a question is asked, then it is asked in plain text with the recommended answer

---
