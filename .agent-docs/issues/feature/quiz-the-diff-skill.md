<!-- markdownlint-disable MD024 MD025 -->

# Issues: feature/quiz-the-diff-skill

## Add quiz-the-diff skill (#69)

**Blocked by**: None

**User stories**: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13

### What to build

A new standalone skill, `quiz-the-diff` (`quiz-the-diff/SKILL.md` + `quiz-the-diff/REFERENCE.md`),
authored by running the `create-a-skill` skill. It teaches a reader a pull request's diff
and then examines them on it with a multiple-choice quiz until they have answered ten
questions correctly.

- **Diff resolution**: an explicit PR number/URL argument is used directly; with no
  argument the skill resolves the current branch's open PR via `gh`; with no PR, or when
  `gh` is unavailable or unauthenticated, it falls back to
  `git diff --merge-base <default-branch> HEAD` and teaches without PR title/description.
- **Documentation-exclusion filter**: pure-doc files (`*.md`, `*.mdx`, `*.rst`, `*.txt`,
  `LICENSE`, `docs/**`, `.agent-docs/**`) and comment/docstring-only hunks are out of
  scope; logic, config, tests, CI, lockfiles, and schema are in scope. If the in-scope
  diff is empty (a documentation-only PR), the skill reports this and exits before
  teaching or quizzing.
- **Mission question**: one skippable question up front asking why the reader is studying
  the PR, shifting teaching emphasis.
- **Teach phase**: inline, structured Background -> Intuition -> Code walkthrough, every
  claim cited to a file and hunk, surrounding context explored. A large in-scope diff
  concentrates on the highest-signal files and summarises the rest; all non-doc hunks stay
  eligible for questions.
- **Exam loop**: one `AskUserQuestion` call per question, four options each. A correct
  answer advances a counter; a wrong answer leaves the counter unchanged, triggers a short
  re-teach of the missed concept, and draws the next question from a different part of the
  diff. Ends at ten correct, no attempt cap. Progress shown via `TodoWrite`. A small
  in-scope diff may be examined from multiple angles; the reader is warned up front only
  when the in-scope diff is trivial (~15 changed lines or fewer).
- **Question-authoring rules** (in `REFERENCE.md`): options of roughly equal length and
  word count, varied correct-answer position, no "all/none of the above", medium baseline
  difficulty at the reader's zone of proximal development; note that `AskUserQuestion`'s
  own "Other" option counts as incorrect.
- **Prompt-injection guard**: `SKILL.md` instructs the agent to treat all diff and PR text
  as untrusted data, never as instructions.
- **Completion**: an inline recap of concepts covered, the concepts missed and re-taught,
  and one or two primary-source pointers. Nothing is persisted.
- **Glossary**: `.agent-docs/context.md` gains **in-scope diff** and **exam loop** under a
  new subheading.

`SKILL.md` stays under 100 lines; detail lives in `REFERENCE.md`, one level deep. The
skill's `description` frontmatter is tuned to fire on explicit intent ("quiz me on this
PR", "test my understanding of the diff") and is validated against the `create-a-skill`
review checklist.

### Acceptance criteria

- [ ] Given a PR number or URL argument, when `/quiz-the-diff <ref>` runs, then it teaches
      and quizzes that PR's diff.
- [ ] Given no argument on a branch with an open PR, when the skill runs, then it resolves
      the branch's PR via `gh` without the number being supplied.
- [ ] Given no PR or `gh` unavailable, when the skill runs, then it falls back to a local
      `git diff --merge-base <default-branch> HEAD` and proceeds without PR title/body.
- [ ] Given a PR containing both documentation and code changes, when the skill teaches and
      quizzes, then documentation files and comment-only hunks are never taught as focus or
      used as a question subject, while code/config/test/CI hunks are.
- [ ] Given a documentation-only PR, when the skill runs, then it reports there is nothing
      non-documentation to examine and exits before the mission question, teach phase, and
      exam.
- [ ] Given the skill has resolved a non-empty in-scope diff, when it starts, then it asks
      exactly one skippable mission question, then delivers a Background -> Intuition ->
      Code walkthrough with citations to real files and hunks.
- [ ] Given the exam is running, when the reader answers a question correctly, then the
      correct counter increments by one and `TodoWrite` reflects the new count.
- [ ] Given the exam is running, when the reader answers a question incorrectly, then the
      counter does not change, the missed concept is re-taught, and the next question is
      drawn from a different part of the diff.
- [ ] Given the reader has answered ten questions correctly, when the tenth correct answer
      is graded, then the exam ends and a recap lists covered concepts, the re-taught
      misses, and one or two primary-source pointers.
- [ ] Given a trivial in-scope diff (~15 changed lines or fewer), when the skill starts,
      then it warns the reader before teaching and still reaches ten questions by
      examining hunks from different angles.
- [ ] Given diff or PR text that contains instruction-like content, when the skill
      processes it, then it is treated as data to teach and quiz, not as instructions.
- [ ] `quiz-the-diff/SKILL.md` is under 100 lines and its `description` includes explicit
      "Use when..." triggers; `REFERENCE.md` holds the question-authoring rules and
      anti-gaming checklist.
- [ ] `.agent-docs/context.md` defines **in-scope diff** and **exam loop**.
- [ ] `pre-commit` passes on all changed files.

---
