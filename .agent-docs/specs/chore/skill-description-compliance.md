# Skill checklist compliance: descriptions, sprawl, step-heading consistency

## Problem Statement

Auditing all 16 skills against the reworked `create-a-skill` Review Checklist (merged in
PR #80) surfaced four groups of violations. None of them change what a skill *does*; all are
discoverability / legibility defects that make the skills fail the checklist `create-a-skill`
now holds every skill to.

- **A — `description` is not "exactly two sentences" (6 skills).** `branch-hygiene` (4
  sentences), `create-worktrees` (3), `grill` (3), `implement` (4), `init-agent-docs` (3),
  `write-spec` (3). Each carries one or two middle sentences that restate the body
  ("Accepts an optional change_type …", "Always starts by entering …", "Idempotent — reports
  …", "No interview — synthesis only"). The rule: sentence 1 = what the skill does,
  sentence 2 = "Use when [triggers]", nothing else.
- **B — `description` breaks "one trigger per branch" (7 skills).**
  `address-copilot-comments`, `bdd`, `code-review`, `design`, `pre-commit-check`,
  `quiz-the-diff`, `update-dependencies` each list two or three synonyms for a single
  trigger branch ("build features, make changes or fix bugs"; "written, edited, or
  generated"; "review a branch, prepare a PR, check their changes") and/or a long quoted-
  phrase tail.
- **C — `address-copilot-comments/SKILL.md` sprawls (173 lines).** Past the ~150-line
  sprawl smell. It already has a `REFERENCE.md`; Step 7b in `SKILL.md` re-explains the
  criteria-distillation *technique* that `REFERENCE.md`'s "Distil review criteria (Step 7b)"
  section already covers in full.
- **D — step-heading style (2 skills).** `branch-hygiene/SKILL.md` uses `## Step N:`
  (colon); the more common house style across the newer skills is `## Step N —` (em-dash).
  `init-agent-docs/SKILL.md` has an out-of-sequence `6b` step (`1 2 3 4 5 6 6b 7 8 9 10`)
  mirrored through `init-agent-docs/REFERENCE.md`.

## Solution

One PR, one GitHub issue per skill touched (13 issues). Each issue is an independent
frontmatter or prose edit; no issue blocks another. No skill's steps, control flow, commands,
or behaviour change.

- **A** — rewrite the 6 descriptions to exactly two sentences, folding any body-restating
  middle sentence into an em-dash clause on sentence 1 or dropping it, and keeping sentence
  2 as a pure "Use when …" trigger list. Every genuine trigger the old description carried
  is preserved.
- **B** — collapse each synonym cluster to one phrasing per genuinely distinct branch and
  trim the quoted-phrase tail to at most two representative user utterances.
- **C** — replace `address-copilot-comments/SKILL.md` Step 7b's *technique* prose (the
  "Generalise", "Dedupe", "Write and commit" mechanics) with a one-line summary plus a
  pointer to the `REFERENCE.md` section that already holds it, keeping the step-flow parts
  (the **Guard** and **Collect** decisions, and the commit block) inline. If that alone does
  not clear ~150 lines, also tighten the Step 3 and Step 4b prose. The "Loop at a glance"
  map stays inline — every run of a 15-step loop benefits from it.
- **D** — `branch-hygiene`: `## Step N:` → `## Step N —` for all six headings. `init-agent-docs`:
  renumber `6b` → `7` and cascade old `7 8 9 10` → `8 9 10 11` across both `SKILL.md` and
  `REFERENCE.md`, updating every internal "skip to / continue to / go to Step N" jump and
  every "Steps N–M" range. Steps 1–6 are untouched.

## User Stories

1. As an agent scanning skill descriptions to pick one to load, I want every description to
   be two sentences — capability, then triggers — so I am not reading a paraphrase of the
   skill body in the selector.
2. As an agent matching a request against a description's "Use when" list, I want one
   trigger per genuinely distinct branch, so a three-way synonym does not read as three
   separate capabilities.
3. As an agent executing `address-copilot-comments`, I want `SKILL.md` under the sprawl
   threshold, with the criteria-distillation technique behind the pointer it already has, so
   the step flow stays legible.
4. As someone reading `branch-hygiene`, I want its step headings in the same style as the
   other workflow skills.
5. As an agent following `init-agent-docs`, I want its steps numbered `1..N` with no `6b`
   interruption, and every internal jump pointing at the right number.
6. As a maintainer, I want each skill's behaviour — steps, commands, control flow, output —
   byte-for-byte unchanged; this PR is descriptions and headings only.
7. As a maintainer running the `create-a-skill` Review Checklist over the repo afterwards, I
   want all 16 skills to pass the Pointer and "not sprawling" items.

## Implementation Decisions

- **Files touched**: the `description:` frontmatter line of
  `branch-hygiene`, `create-worktrees`, `grill`, `implement`, `init-agent-docs`,
  `write-spec`, `address-copilot-comments`, `bdd`, `code-review`, `design`,
  `pre-commit-check`, `quiz-the-diff`, `update-dependencies` `SKILL.md` (13 files);
  the `## Step` headings in `branch-hygiene/SKILL.md`; the step numbering in
  `init-agent-docs/SKILL.md` and `init-agent-docs/REFERENCE.md`; the Step 7b body plus
  prose density across the `gh` prereq line and Steps 1, 2b, 3, 4b, 4c, and 4d, and a
  compaction of the "Loop at a glance" Step 3 rows (all forks kept), in
  `address-copilot-comments/SKILL.md`. Plus this spec and its issue file.
- **Proposed descriptions** (final wording settled in review; intent fixed here):
  - `branch-hygiene`: *Validates the current git branch before work begins — autoSetupRemote,
    trunk-branch detection, prefix-vs-change-type, and name relevance. Use at the start of a
    work session, or from another skill passing a known change_type.*
  - `create-worktrees`: *Enters an isolated git worktree for the current task so work never
    touches the main checkout, creating one (and optionally bootstrapping its dependencies)
    or resuming an existing one. Use when starting implementation work that should be
    isolated, or as the first step of /implement.*
  - `grill`: *Entry point for the two-axis design session — runs the `design` skill. Use
    whenever a user wants to make any change to the repository: code, technical documents,
    skills, or configuration.*
  - `implement`: *Runs the full implementation workflow inline, from change request to
    merged PR: worktree, init-agent-docs, grill, branch, spec, issues, BDD per issue, code
    review, and merge confirmation. Use when the user wants to implement a feature, fix a
    bug, or make any repository change.*
  - `init-agent-docs`: *Bootstraps AI-agent documentation in the current repository —
    `.agent-docs/` layout, `agent.md`, `context.md`, `review.md`, ADR migration, and a
    `CLAUDE.md` reference — idempotently. Use at the start of an implementation workflow to
    ensure agent standards are in place before work begins.*
  - `write-spec`: *Synthesises the current conversation into a spec (PRD) at
    `.agent-docs/specs/<branch-name>.md` — no interview, synthesis only. Use after a /grill
    session when the design is agreed and ready to record.* (backticks not part of the
    shipped description — only here to satisfy the spec-file linter)
  - `address-copilot-comments`: *Automates the Copilot PR review loop — fetch comments, fix
    or push back, commit, push, re-trigger, repeat until no new actionable comments remain.
    Use when the user wants to address Copilot PR review feedback, or says "fix review
    comments" or "address Copilot".*
  - `bdd`: *Behaviour-driven development with a red-green-refactor loop and Given-When-Then
    scenarios. Use whenever a user is writing or changing code, mentions "red-green-refactor",
    or asks for test-first development or integration/acceptance tests.*
  - `code-review`: *Full code-review workflow — branch hygiene, pre-commit checks, iterative
    two-axis review (Standards + Spec) with fresh parallel sub-agents until clean, Copilot PR
    review, then pre-merge cleanup. Use when the user wants a branch or PR reviewed, or says
    "review my code" or "is this ready to merge".*
  - `design`: *Two-axis design session before any repository change — interviews from the
    business angle (what and why) then the engineering angle (how), updating CONTEXT.md and
    ADRs inline as decisions crystallise. Use whenever a user wants to change the codebase,
    technical documents, skills, or configuration.*
  - `pre-commit-check`: *Runs pre-commit hooks after code is written or changed. Use whenever
    code has just been written or edited, or the user asks to lint or format it.*
  - `quiz-the-diff`: *Teaches a pull request's diff, then quizzes the reader with
    multiple-choice questions — re-teaching and moving to a fresh question on every wrong
    answer until ten are answered correctly. Use when the user wants to be quizzed on a PR or
    diff, or says "quiz me on this PR" or "test my understanding of the diff".*
  - `update-dependencies`: *Syncs the current repo with main/master, then updates
    dependencies to their latest patch/minor versions across detected ecosystems (Python,
    .NET/C#, Node/TypeScript/React) and pre-commit hooks, committing the result locally. Use
    when the user asks to update dependencies or refresh pre-commit hooks.*
  All are third person, ≤ 1024 chars, exactly two sentences, front-loaded trigger word in
  sentence 2.
- **`grill` and `design` descriptions stay near-identical on purpose** — `grill` is the
  entry point that runs `design`; both should fire on "any repository change".
- **C mechanism**: `REFERENCE.md`'s "Distil review criteria (Step 7b)" already contains
  "What generalising looks like", "Dedupe", and "Writing the file". `SKILL.md` Step 7b keeps
  its **Guard** paragraph and **Collect** paragraph verbatim (they are step-flow gating, not
  technique), replaces the **Generalise** / **Dedupe** / **Write and commit** paragraphs with
  a two-line summary + "see the Distil Review Criteria section in REFERENCE.md", and keeps
  the `git add .agent-docs/review.md … commit … push` block. Net ≈ −16 lines. Target:
  `SKILL.md` ≤ 150. That alone landed at ~161, so the remaining ~11 came from merging
  wrapped paragraphs (no wording lost — the `gh` prereq line, Steps 1, 2b, 3, 4b, 4c, 4d)
  and compacting the "Loop at a glance" Step 3 block from six rows to four while keeping
  every fork (threads/suppressed → 4, clean → 7b, exhausted → one final check → 4 or 7b).
  No command, condition, threshold, guard, or mutation changed — the Step 3 / 4b / 7b prose
  below the map stays authoritative and its logic is untouched. Final: 149 lines.
- **D — `init-agent-docs` renumber**: apply high-to-low to avoid collisions —
  `Step 10→11`, `9→10`, `8→9`, `7→8`, `6b→7` — in `SKILL.md` (the `## Steps` list plus the
  jumps "skip to Step 10", "skip to Step 6b", "go to Step 6") and `REFERENCE.md` (the
  `## Step N` headings plus "skip to / continue to Step 6b|7|8|9|10" jumps and the
  "Steps 4–5" / "migrated by Step 7" phrases). Verify with
  `grep -nE "Step [0-9]+b?" init-agent-docs/` afterwards: no `6b`, sequence `1..11`.
- **No cross-skill or historical breakage**: no other `SKILL.md`/`WORKFLOW.md` references an
  `init-agent-docs` step by number (`implement/WORKFLOW.md` names the skill, not a step).
  `.agent-docs/specs/` and `issues/` files that mention "Step 6b" are history-of-record for
  merged work and are left untouched.
- **No ADR** — cosmetic / discoverability edits, fully reversible, no design trade-off.

## Testing Decisions

- No executable code — skill prose only. No test files; no shell/prose test harness in this
  repo. Consistent with `uv-support`, `sync-hook-interpreter-selection`,
  `create-worktrees-dependency-bootstrap`, `improve-create-a-skill`, and
  `skill-compliance-followups`.
- Verification:
  1. Each of the 13 descriptions: exactly two sentences (a `.` split yields 2), third
     person, ≤ 1024 chars, sentence 2 starts with "Use ", no clause that merely restates a
     body heading.
  2. `wc -l address-copilot-comments/SKILL.md` ≤ ~150; its Step 7b still states the Guard and
     Collect conditions and the commit command; `REFERENCE.md` unchanged.
  3. `grep -nE "Step [0-9]+b?" init-agent-docs/SKILL.md init-agent-docs/REFERENCE.md` shows a
     clean `1..11` sequence, no `6b`, and every "Step N" jump resolves to an existing
     heading.
  4. `branch-hygiene/SKILL.md` has six `## Step N —` headings, no `## Step N:`.
  5. `git diff` touches only frontmatter `description:` lines, `branch-hygiene` step
     headings, `init-agent-docs` step numbers, and `address-copilot-comments` Step 7b/3/4b
     prose — no step *logic*, command, or control-flow line changes.
  6. `pre-commit run --all-files` passes (markdownlint, markdown-link-check, codespell).
  7. `code-review` Standards + Spec axes.

## Out of Scope

- The deeper per-skill body audit — completion-criterion phrasing on every step, leading-word
  opportunities, steer-positive rewrites, examples coverage. Descriptions + sprawl only this
  round.
- `document-review/`, `plan-blog-post/`, `three-amigos/` — empty directories, not skills.
  Separate decision (delete or populate).
- Any change to a skill's steps, commands, control flow, arguments, or output.
- `update-dependencies` step-heading style (`## Step N:`) — not in scope; only
  `branch-hygiene` was called out, and cross-skill heading-style convergence is a bigger
  cleanup than this PR.

## Further Notes

- Full audit table: `scratchpad/skill-audit-2026-09.md` (session-local).
- After merge, re-running the `create-a-skill` Review Checklist over all 16 skills should
  show Pointer + "not sprawling" passing everywhere; the softer body-level items remain for a
  later pass.
