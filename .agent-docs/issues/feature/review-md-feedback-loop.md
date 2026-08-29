# Issues: feature/review-md-feedback-loop

> Work complete — PR ready to merge.

## 1. `.agent-docs/review.md` + `init-agent-docs` bootstrap

**GitHub**: #61

**Blocked by**: None

**User stories**: 1, 7

### What to build

Introduce the `.agent-docs/review.md` file and have `init-agent-docs` create it.

- New `init-agent-docs/REVIEW-TEMPLATE.md`: an explanatory header (what the file is; that
  `address-copilot-comments` maintains it — fixes only, never push-backs; that `code-review`
  consumes it as documented standards; that entries can be pruned or promoted into
  `REVIEW-CRITERIA.md` by hand) followed by `## Criteria` and a `_None yet._` empty state.
- New `init-agent-docs` **Step 6b — Bootstrap `review.md`**, after Step 6, before Step 7: if
  `.agent-docs/review.md` exists → report "already exists — skipping" and continue;
  else write `REVIEW-TEMPLATE.md` verbatim, report "Created `.agent-docs/review.md`"; on
  write failure report and continue to Step 7. No search-elsewhere and no review/improve
  sub-path.
- Update `init-agent-docs/SKILL.md` (`## Steps` list, frontmatter `description`, intro
  sentence) and `init-agent-docs/REFERENCE.md` (new `## Step 6b` section; Step 6 hand-offs
  to Step 7 become hand-offs to Step 6b; all three Step 10 summary examples gain a
  `review.md` line).
- Create this repo's `.agent-docs/review.md` from the template (`_None yet._`).
- Add a `review.md` term to this repo's `.agent-docs/context.md` (Agent Docs section).

### Acceptance criteria

- [x] `init-agent-docs/REVIEW-TEMPLATE.md` exists with the header + `## Criteria` +
      `_None yet._`.
- [x] `init-agent-docs` Step 6b is defined in SKILL.md (steps list) and REFERENCE.md with
      the check → skip / write-verbatim shape, matching the `agent.md` steps' style.
- [x] Re-running `init-agent-docs` when `.agent-docs/review.md` already exists is a no-op
      that reports "already exists — skipping".
- [x] `init-agent-docs` frontmatter `description`, intro sentence, and all three REFERENCE.md
      Step 10 summary examples mention `.agent-docs/review.md`.
- [x] Steps 7–10 and their cross-references are not renumbered.
- [x] This repo has `.agent-docs/review.md` (template, `_None yet._`) and a `review.md`
      entry in `.agent-docs/context.md`.
- [x] `pre-commit-check` passes.

---

## 2. `address-copilot-comments` Step 7b — distil review criteria

**GitHub**: #62

**Blocked by**: #61

**User stories**: 2, 3, 4

### What to build

New **Step 7b — Distil review criteria into `.agent-docs/review.md`**, between Step 7 and
Step 8 of `address-copilot-comments`.

- Guard: run only if `review_round` was set at Step 2b **and** ≥1 Fix was applied at any
  Step 4 across the whole invocation; otherwise skip to Step 8.
- Input: every finding this invocation whose Step 4 decision was **Fix** — real threads
  (replied "Fixed.") and suppressed entries (recorded "Fixed." in a Step 4d comment).
  Push-backs excluded.
- Generalise each fixed finding into one criterion: strip file/line/identifier/value down to
  the class of mistake; phrase as a bold-label + imperative rule in `REVIEW-CRITERIA.md`'s
  voice; tag `(PR #<this PR>)`. Findings that generalise alike collapse to one entry.
- Dedup against the target repo's existing `.agent-docs/review.md` only (match on meaning);
  skip candidates already covered. Do not read `REVIEW-CRITERIA.md`.
- If `.agent-docs/review.md` is absent, create it from the same header the `init-agent-docs`
  template uses, then append. Replace a lone `_None yet._` rather than appending after it.
- Commit on its own to the PR branch:
  `git commit -m "docs: record N review criteria from Copilot review"` → push.
- `address-copilot-comments/SKILL.md`: add `Step 7b` to the "Loop at a glance" diagram and a
  `## Step 7b` section. `address-copilot-comments/REFERENCE.md`: add a "Distil review
  criteria" section (how to generalise, the dedup rule, the first-creation header, the
  commit message).

### Acceptance criteria

- [x] Step 7b is in the SKILL.md loop diagram and has a `## Step 7b` section; REFERENCE.md
      has the "Distil review criteria" detail.
- [x] The guard is explicit: exempt PR or zero fixes → no write, skip to Step 8.
- [x] The step text states that only Fixed findings are recorded and push-backs
      (`Ignored.`) are never written.
- [x] The dedup rule (against `.agent-docs/review.md` only) and the "replace `_None yet._`"
      behaviour are specified.
- [x] The commit is a standalone commit to the PR branch with the specified message shape.
- [x] `pre-commit-check` passes.

---

## 3. `code-review` reads `.agent-docs/review.md`

**GitHub**: #63

**Blocked by**: #61

**User stories**: 5, 6

### What to build

`code-review` Step 4 also consumes the target repo's `.agent-docs/review.md`.

- Step 4: "Read `REVIEW-CRITERIA.md` in full" → "…in full, and `.agent-docs/review.md` from
  the target repo if it exists."
- Step 4 Standards sub-agent prompt: the "complete contents of REVIEW-CRITERIA.md" bullet
  gains "…and, if present, the target repo's `.agent-docs/review.md` (repo-specific criteria
  accumulated from past Copilot reviews — treat its entries as documented standards, same as
  REVIEW-CRITERIA.md)".
- No other `code-review` change. Absent file → prompt byte-identical to today.
- Cross-skill consistency: the file name, path, header wording, and the "fixes only, no
  push-backs" description must read identically across `init-agent-docs`'s template,
  `address-copilot-comments`'s REFERENCE.md, and this Step 4 text.

### Acceptance criteria

- [x] `code-review/SKILL.md` Step 4 reads `.agent-docs/review.md` when present and passes it
      to the Standards sub-agent as documented standards.
- [x] When `.agent-docs/review.md` is absent, the Standards sub-agent prompt is unchanged
      from today.
- [x] `REVIEW-CRITERIA.md`, the Fowler baseline, and the rest of `code-review/SKILL.md` are
      untouched.
- [x] Consistency check recorded: file name / path / header / "fixes only" wording match
      across all three skills (restated-fact sweep applied to this change).
- [x] `pre-commit-check` passes.

---
