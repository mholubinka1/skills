# Improve and fix create-a-skill

## Problem Statement

`create-a-skill` is the skill that tells an agent how to write a new skill, yet it is thin
and partly self-contradictory:

- **It contradicts itself on when to split `SKILL.md`.** `SKILL.md` step 2 says add
  reference files "if content exceeds 500 lines"; `REFERENCE.md`'s "When to Split Files" and
  the Review Checklist both say 100. An author following it can't tell which number to obey.
- **It teaches structure, not the levers that make a skill reliable.** It has a 4-step
  process, a structure diagram, a `SKILL.md` template, and a 6-item checklist — but nothing
  about how a `description` actually triggers, where content should sit relative to how
  urgently the agent needs it, what makes a step's stopping condition sound, or how word
  choice steers behaviour. Skills written against it come out structurally plausible and
  behaviourally vague.
- **The concepts that would fix this already exist**, well-developed, in Matt Pocock's
  `writing-for-agents` skill (installed as the `mattpocock-skills:writing-for-agents`
  plugin) — but nothing in this repo points an author at them.

## Solution

Rewrite `create-a-skill/SKILL.md` and `create-a-skill/REFERENCE.md` so the skill produces a
skill against a named set of **writing levers**, adapted from `writing-for-agents` into this
repo's voice and kept as terse, testable rules rather than essay prose. `create-a-skill`
becomes self-contained (no runtime dependency on the plugin) and passes its own revised
checklist. The 100/500 contradiction is replaced by a single rule: ~150 lines in `SKILL.md`
is a *sprawl smell* prompting a look for reference to disclose or a sequence to split — the
branch test, not the line count, is the real driver.

## User Stories

1. As an agent asked to create a skill, I want `create-a-skill` to tell me how to write the
   `description` as a context pointer — front-load the trigger word, one trigger per branch,
   cut identity the body already carries — so the skill actually fires when it should.
2. As an agent drafting a skill's body, I want a rule for where each piece of content sits
   (in-file step / in-file reference / disclosed reference) and a branch test for what to
   push behind a pointer, so `SKILL.md` stays legible without hiding material the agent
   needs.
3. As an agent writing a skill's steps, I want each step to end on a stopping condition that
   is both checkable (done vs not-done) and exhaustive ("every X accounted for"), so the
   skill doesn't stop a step early.
4. As a skill author, I want a single answer to "how long can `SKILL.md` be?" instead of
   three different numbers.
5. As a skill author, I want to reach for pretrained **leading words** where a triad or
   phrase repeats, and to state behaviour **positively** rather than by prohibition.
6. As a skill author, I want to choose **model- vs user-invocation** deliberately, and to
   know when a **router skill** is the answer to too many user-invoked skills.
7. As a reviewer, I want a revised checklist that tests the levers (not just "has a
   description"), so a non-compliant skill fails the gate.
8. As a maintainer, I want `create-a-skill` to pass its own revised checklist, so the skill
   that defines the standard also meets it.

## Implementation Decisions

- Files touched: `create-a-skill/SKILL.md`, `create-a-skill/REFERENCE.md`,
  `.agent-docs/context.md` (4 glossary terms — done inline during the grill).
- **Self-contained absorption.** The levers are folded into `create-a-skill/REFERENCE.md` in
  this repo's voice, credited in one line as adapted from `writing-for-agents`. No pointer to
  the plugin as a required read; `create-a-skill` must stand alone if the plugin is absent.
- **`create-a-skill/SKILL.md`** (~90 lines, hard ceiling ~150):
  - Frontmatter `description` rewritten to obey the new pointer rules: front-loaded trigger
    word, three genuinely distinct branches — create a new skill / revise an existing one /
    review a skill against the levers — with the synonym-branch "create, write, or build"
    collapsed.
  - Short intro + one pointer to `REFERENCE.md` for the levers and the checklist.
  - `## Process` rewritten to numbered steps: (1) gather requirements — task/domain, use
    cases, scripts-or-not, reference materials, **and model- vs user-invoked**; (2) place
    each piece of content on the information hierarchy, disclosing what only some branches
    reach; (3) draft `SKILL.md` (+ `REFERENCE.md`/`EXAMPLES.md` when branch-only content or
    sprawl warrants) writing the description as a context pointer, giving each step a
    checkable + exhaustive completion criterion, reaching for leading words, steering
    positive; (4) review with the user; (5) verify against the Review Checklist in
    `REFERENCE.md`.
  - Keep the skill-structure diagram and the `SKILL.md` template unchanged in substance; the
    template gains a one-line sample completion criterion in its `## Workflows` slot.
- **`create-a-skill/REFERENCE.md`** (target ~130 lines; must not itself sprawl):
  - `## Description requirements` — kept, folded with the pointer-writing rules (front-load
    the trigger word; one trigger per branch, no synonym-branches; cut identity the body
    carries; third person; <=1024 chars; first sentence = what it does, second = "Use
    when …").
  - `## Writing levers` — each a terse imperative rule ending on a check:
    **context pointer** (wording not target decides reliability; the pointer-writing rules);
    **the two loads** (context load vs cognitive load; disclosure trades one for the other);
    **information hierarchy** (in-file step > in-file reference > disclosed reference; inline
    what every branch needs, disclose what only some reach); **progressive disclosure** (the
    move down the ladder; branch test); **co-location** (a concept's definition, rules,
    caveats under one heading; distinct from duplication and scattering); **completion
    criteria** (every step ends on one — checkable and exhaustive; a fuzzy bound invites
    premature completion; sharpen the bound first, split the sequence only if the rush
    persists and only across a real context boundary); **when to split** (by sequence — later
    steps tempt a rush; by invocation — a distinct leading word triggers it, or another
    skill must reach it); **leading words** (a compact pretrained concept repeated as a
    token, never a sentence; prefer an existing word — coining costs definition tokens);
    **steer positive** (state the target behaviour; a prohibition drags the banned behaviour
    into context — reserve it for a hard guardrail paired with the positive); **pruning**
    (one source of truth per meaning; the environment is a source of truth too — cache only
    the lookup the agent cannot do by looking; check every line for relevance; hunt no-ops —
    an instruction the model already obeys by default, tested by running the document).
  - `## Model- vs user-invoked` — model-invoked keeps a `description` (agent and other skills
    can fire it; permanent context load); user-invoked sets `disable-model-invocation: true`
    (human-only, zero context load, spends cognitive load; `description` becomes a
    human-facing one-liner with the trigger list stripped). A **router skill** is one
    user-invoked skill that names the others and when to reach for each, when they multiply
    past what the human can remember.
  - `## When to add scripts` — kept.
  - `## When to split files` — reconciled: past ~150 lines `SKILL.md` is a sprawl smell —
    look for reference to disclose or a sequence to split; the branch test is the real
    driver, not the line count.
  - `## Common failure modes` — a named one-line-each list: **Sprawl** (too long even when
    every line is live -> disclose reference, split by branch/sequence); **Negation
    steering** (a "don't X" makes X more available -> prompt the positive); **Duplication**
    (one meaning in two places -> single source of truth); **Scattering** (one meaning
    fragmented across headings -> co-locate); **No-op** (a line the model already obeys ->
    delete the sentence, or use a stronger leading word); **Premature completion** (a step
    stops before it is done -> sharpen the criterion, then split the sequence).
  - `## Review checklist` — revised, ~10 grouped pass/fail items:
    - Pointer: description front-loads the trigger word; one trigger per branch; no identity
      the body repeats; third person; <=1024 chars; second sentence is "Use when …".
    - Hierarchy: branch-only sections are disclosed behind a pointer; every-branch material
      is in-file; `SKILL.md` is not sprawling (~150); references are one level deep.
    - Completion criteria: every step ends on a checkable and exhaustive criterion.
    - Leading words / positivity: reaches for >=1 leading word where a triad or phrase
      repeats; steers positive (a "don't …" appears only as a guardrail paired with the
      positive target).
    - General: `name:` matches the directory; no time-sensitive info; consistent
      terminology; concrete examples included.
- **`create-a-skill` passes its own revised checklist** — this is an explicit acceptance
  criterion and a code-review Spec-axis check, not just an aspiration.

## Testing Decisions

- No executable code — skill prose only. No test files; no shell/prose test harness in this
  repo. Consistent with the `uv-support`, `sync-hook-interpreter-selection`, and
  `create-worktrees-dependency-bootstrap` slices this session.
- Verification:
  1. **Self-apply**: run the revised Review Checklist against `create-a-skill`'s own
     `SKILL.md` and `REFERENCE.md`; every item passes.
  2. **Read-through**: each lever line is imperative and ends on a check; checklist items are
     pass/fail; each lever's rule is stated once (in `## Writing levers`) and referenced —
     not restated — by `SKILL.md` and the checklist; repo-specific process is visually
     separate from the universal levers.
  3. **Line count**: `SKILL.md` <= ~150 (target ~90); `REFERENCE.md` legible, no sprawl.
  4. `pre-commit run --all-files` passes (markdownlint, markdown-link-check, codespell).
  5. `code-review` Standards + Spec axes.

## Out of Scope

- The other audit findings: `behaviour-driven-development`'s `name: bdd` vs its directory,
  `pr-cleanup`'s missing "Use when" trigger, `address-copilot-comments`'s `SKILL.md` length,
  and any other skill's compliance. Separate follow-ups; this branch is `create-a-skill/`
  (plus the `context.md` glossary) only.
- Reproducing `writing-for-agents` in full — the levers become terse rules, not paragraphs
  of exposition.
- A runtime dependency on `mattpocock-skills:writing-for-agents` being installed.
- Changing `create-a-skill`'s own invocation model or `name` (stays model-invoked,
  `name: create-a-skill`).
- New executable scripts — `create-a-skill` stays instructions-only.
- An ADR — improving a skill's guidance is reversible, unsurprising, and the one real
  trade-off (self-contained vs point-at-plugin) is small and decided.

## Further Notes

- Reframing the split rule to "~150 = sprawl smell, branch test drives it" softens the
  earlier compliance audit: `code-review/SKILL.md` at 106 lines is fine under the new rule;
  `address-copilot-comments/SKILL.md` at 173 becomes "look for reference to disclose" rather
  than a hard fail. Those remain separate follow-ups.
- Source: `mattpocock-skills:writing-for-agents` v1.2.3 — `SKILL.md` and `SKILL-MECHANICS.md`
  (read during the grill; copies stashed in the session scratchpad).
