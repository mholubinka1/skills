# Add quiz-the-diff skill — teach a PR's diff, then examine the reader on it

## Problem Statement

Reviewing a pull request, onboarding to an unfamiliar area, or inheriting ownership of
code all require actually understanding a diff — not just skimming it. There is no
structured way for a reader to check that understanding. A person can read every line of a
PR, approve it, and still not be able to explain why a change was made, what it replaces,
or where it could break. The gap between "I looked at it" and "I understand it" is
invisible until something goes wrong later.

## Solution

A new skill, `quiz-the-diff`, turns a PR into a short taught lesson followed by a
multiple-choice examination. The agent first resolves the PR's diff, filters out
documentation-only changes, and teaches the reader about the change — its background, the
core intuition, and a grouped walkthrough of the code — with every claim cited to a
specific file and hunk. It then runs a multiple-choice exam via `AskUserQuestion`, one
question at a time. Each correct answer advances a counter; each wrong answer triggers a
focused re-teach of the missed concept followed by a fresh question drawn from a different
part of the diff. The exam ends when the reader has answered ten questions correctly.
Nothing is written to disk and nothing is gated — the skill is a learning aid, and the
payoff is the reader's own confidence that they understand the change.

The pedagogy is grounded in Matt Pocock's `teach` skill (zone of proximal development,
storage strength over fluency, equal-length answer options, citation-dense teaching) and
Geoffrey Litt's "explain diff" technique (explore surrounding system context, structure the
explanation as Background → Intuition → Code, and defend the quiz against gaming).

## User Stories

1. As a PR reviewer, I want to be taught what a diff does and why before I am tested on it,
   so that the exam measures understanding rather than raw recall of unfamiliar code.
2. As a reviewer, I want to answer ten multiple-choice questions correctly to "pass", so
   that I have a concrete signal that I have understood the change rather than a vague
   sense that I skimmed it.
3. As a reviewer who answers a question wrong, I want the skill to teach me the concept I
   missed and then ask me about a different part of the diff, so that a wrong answer turns
   into learning instead of a dead end.
4. As a reviewer, I want every part of the PR to be fair game — logic, config, tests, CI,
   lockfiles, schema, and step-logic edits to agent-instruction files — except changes
   whose purpose is to explain the project to a human, so that the exam covers what
   actually carries risk even in a repo whose logic lives in Markdown.
5. As a reviewer, I want to run `/quiz-the-diff 123` or `/quiz-the-diff <url>` to point the
   skill at a specific PR, so that I can study a PR I am about to review.
6. As a reviewer on a feature branch, I want to run `/quiz-the-diff` with no argument and
   have it find my branch's open PR, so that I do not have to look up the number.
7. As a reviewer working offline or before pushing, I want the skill to fall back to
   diffing my branch against the default branch locally, so that it still works without a
   PR on GitHub.
8. As a person onboarding to an area of the codebase, I want the teaching to be grounded in
   why I am studying the PR, so that the emphasis matches my goal rather than being generic.
9. As a reviewer of a very large PR, I want the teaching to concentrate on the
   highest-signal files and summarise the rest, so that the lesson stays within my working
   memory while every non-doc hunk remains eligible for questions.
10. As a reviewer of a tiny PR, I want the skill to examine the same hunks from different
    angles rather than invent filler, so that ten questions still produce ten real
    insights.
11. As a reviewer, I want a short recap at the end listing what was covered, what I got
    wrong and had re-taught, and one or two primary sources to read, so that I know where
    my understanding is still thin.
12. As a reviewer quizzing a PR from an untrusted contributor, I want the diff content
    treated as data and never as instructions to the agent, so that a malicious diff
    cannot hijack the session.
13. As a reviewer running the skill against a documentation-only PR, I want to be told
    there is nothing substantive to examine and have the skill stop, so that I am not
    walked through a hollow teach-and-quiz session with no in-scope content.

## Implementation Decisions

- **New skill directory** `quiz-the-diff/` with `SKILL.md` (the workflow) and
  `REFERENCE.md` (teach-phase structure, question-authoring rules, anti-gaming checklist,
  and the pedagogy notes drawn from Pocock's `teach`). Follows this repo's existing
  two-file skill convention. `SKILL.md` stays under 100 lines per the `create-a-skill`
  checklist; the detail lives in `REFERENCE.md`, one level deep.
- **The skill is authored by running the `create-a-skill` skill** during the BDD loop —
  not hand-written ad hoc — so that its structure, description, and progressive disclosure
  are validated against that skill's checklist.
- **Frontmatter**: a normal description-triggered skill (auto-invocable), consistent with
  every other skill in this repo. The description is tuned to fire on explicit intent —
  "quiz me on this PR", "test my understanding of the diff", "examine me on this branch" —
  and not on a bare request to explain a change.
- **Diff resolution** (documented in `REFERENCE.md`):
  - Explicit argument — a PR number or URL, passed verbatim as `<ref>` to `gh pr diff
    <ref>` for the patch and `gh pr view <ref> --json number,title,body,files` for the
    title/description teaching context. Never a literal example number.
  - No argument: `gh pr view --json number,title,body,files` and `gh pr diff` both default
    to the current branch's open PR, so no number is extracted or substituted.
  - No PR found, or `gh` is unavailable or unauthenticated: read the base ref from
    `git symbolic-ref refs/remotes/origin/HEAD --short` (already `origin/`-qualified, e.g.
    `origin/main`; `git remote show origin` then `origin/main` as fallbacks if it is
    unset), run `git fetch` to refresh it (proceed with a warning if offline), then
    `git diff --merge-base <base-ref> HEAD`. Teach without PR title/description framing.
    Comparing against the remote-tracking ref, used verbatim, keeps a stale local branch
    from inflating the diff.
- **Documentation-exclusion filter** (the in-scope diff), applied before teaching and
  before any question is drawn. Classification is by the *purpose* of each change, not the
  file extension — a `.md` file is documentation in one repo and executable agent logic in
  another, so an extension list alone would exclude an entire skills-repo PR. This mirrors
  the content-not-extension principle already recorded for **Review-required diff** in
  `.agent-docs/context.md`.
  - Excluded (documentation): files that exist to explain the project to a human —
    `README*`, `CHANGELOG*`, `CONTRIBUTING*` and similar; anything under `docs/**` or
    `.agent-docs/**`; `LICENSE`/`NOTICE`; `*.rst`, `*.txt`; narrative `.md`/`.mdx` guides —
    and hunks whose only changed lines are comments, docstrings, or prose.
  - In scope (behaviour): application and library code; configuration; CI workflow files;
    build scripts; tests and fixtures; lockfiles and dependency manifests; schema and
    migrations; and step-logic edits to agent-instruction files (`SKILL.md`, `REFERENCE.md`,
    `WORKFLOW.md`, `AGENTS.md`, `CLAUDE.md`, prompt templates) that change steps, commands,
    control flow, or rules — a pure rewording of an instruction is documentation and stays
    out.
  - Kept as prose instructions in the skill, not a script (see Testing Decisions).
  - **Empty in-scope diff** (a documentation-only PR): the skill reports that the PR has no
    non-documentation changes to examine and exits before the mission question, the teach
    phase, and the exam.
- **Mission grounding**: before teaching, the skill asks one question — why the reader is
  studying this PR (reviewing it / onboarding to the area / inheriting ownership / just
  curious). The answer shifts teaching emphasis and question mix. The question is skippable.
- **Teach phase**: inline in the conversation, structured as
  Background → Intuition → Code walkthrough (Litt's sections minus the quiz). Every claim
  cites a specific file and hunk. The agent explores surrounding context — callers,
  callees, touched tests — not only the changed lines. For a large in-scope diff
  (rough guide: more than ~40 files or ~2000 changed lines) the walkthrough concentrates on
  the highest-signal files and summarises the remainder by file; all non-doc hunks stay
  eligible for questions regardless.
- **Exam loop**:
  - One `AskUserQuestion` call per question, exactly four options. The agent grades the
    answer, re-teaches on a miss, then issues the next call.
  - A running counter starts at zero and increments by one per correct answer. A wrong
    answer leaves the counter unchanged, triggers a short focused re-teach of the missed
    concept, and the next question is drawn from a different part of the diff.
  - The loop ends when the counter reaches ten. There is no attempt cap; the reader may
    abandon the run at any point.
  - Progress is surfaced with `TodoWrite` (e.g. "6/10 correct"). No files are written.
  - Small in-scope diff: a hunk may be examined more than once as long as each question
    tests a genuinely different idea (behaviour vs edge case vs why-not-this-alternative).
    Interleaving across hunks is deliberate. The skill warns the reader up front only when
    the in-scope diff is trivial (rough guide: fewer than ~15 changed lines).
- **Question-authoring rules** (in `REFERENCE.md`): every option roughly equal in length
  and word count; correct-answer position varied across questions; no "all of the above" /
  "none of the above"; medium baseline difficulty aimed at the reader's zone of proximal
  development. The skill notes that `AskUserQuestion` always appends its own "Other" option
  and that selecting it counts as an incorrect answer.
- **Prompt-injection guard**: `SKILL.md` instructs the agent to treat all diff and PR
  text as untrusted data — content to be taught and quizzed, never instructions to follow.
- **Completion**: an inline recap — concepts covered, the concepts that were missed and
  re-taught, and one or two primary-source pointers for further reading where a worthwhile
  source exists. Nothing is persisted: no file, no PR comment, no state.
- **Domain docs**: `.agent-docs/context.md` gains two terms — **in-scope diff** (the
  portion of a PR's diff left after the documentation-exclusion filter, from which all
  questions are drawn) and **exam loop** (the teach-question-regrade cycle that runs until
  ten correct answers). Both under a new subheading in the glossary.

## Testing Decisions

- Skills in this repo are Markdown instruction files with no automated test harness; the
  prior art (`create-worktrees`, `init-agent-docs`) is `pre-commit` plus manual
  verification, and this skill follows it.
- `pre-commit` (markdownlint and the repo's other hooks) must pass on `SKILL.md`,
  `REFERENCE.md`, and the `context.md` edit.
- **Single test seam — a manual smoke test** against a real merged PR in this repo:
  1. Run `/quiz-the-diff <pr>` and confirm the mission question is asked once and is
     skippable.
  2. Confirm the teach phase produces Background → Intuition → Code walkthrough with
     citations to real files and hunks.
  3. Confirm documentation changes in that PR (e.g. a README or a reworded paragraph) are
     absent from the teaching focus and are never the subject of a question, while
     code/config/test/CI hunks and any step-logic edits to `SKILL.md`/`REFERENCE.md`/
     `WORKFLOW.md` are in scope.
  4. Answer questions through a full loop — including at least one deliberate wrong answer —
     and confirm a wrong answer re-teaches and then asks about a different hunk without
     advancing the counter, and that the loop ends at ten correct.
  5. Confirm the closing recap lists covered concepts, the re-taught misses, and
     primary-source pointers, and that no file was created.
  6. Run `/quiz-the-diff` with no argument on a branch with an open PR and confirm it
     resolves the PR; run it with `gh` disabled and confirm the local-diff fallback.
  7. Run `/quiz-the-diff` against a documentation-only PR and confirm it reports that there
     is nothing non-documentation to examine and exits without teaching or quizzing.
- The BDD scenarios for the skill are these smoke-test paths expressed as Given-When-Then;
  they are the acceptance spec, verified by running the skill, not by a runner.

## Out of Scope

- Any coupling to CI, merge, or review gating — the skill records no pass/fail result and
  blocks nothing.
- Persisting learning records or progress across runs, and posting results as a PR comment.
- An HTML or artifact deliverable for the teaching phase — teaching is inline only.
- A deterministic script for the documentation-exclusion filter with its own unit tests —
  considered and declined; the filter stays as prose instructions.
- Adaptive difficulty beyond the medium baseline (e.g. escalating difficulty after a
  streak of correct answers).
- An automated test runner or CI for skill files.
- Batching multiple questions into one `AskUserQuestion` call — rejected because it delays
  feedback, against the tight-feedback-loop principle.

## Further Notes

- `AskUserQuestion` accepts one to four questions per call and two to four options each,
  and always adds its own "Other" escape hatch; the one-question-per-call design works
  within those limits and keeps re-teaching immediate.
- The post-commit sync hook in this repo propagates the new skill to `~/.claude/skills/`
  once committed.
- Research inputs are Matt Pocock's `teach` skill
  (`mattpocock-skills`, `skills/productivity/teach/SKILL.md`) and Geoffrey Litt's
  "explain diff" gist (`https://gist.github.com/geoffreylitt/a29df1b5f9865506e8952488eac3d524`).
