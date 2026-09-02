# Issues: chore/skill-description-compliance

One issue per skill. All independent — no blockers. Behaviour (steps, commands, control
flow, output) is unchanged in every case. Final description wording is in
`.agent-docs/specs/chore/skill-description-compliance.md` → Implementation Decisions.

---

## branch-hygiene: two-sentence description + em-dash step headings  (#84)

**Blocked by**: None
**User stories**: 1, 4, 6, 7

### What to build

Rewrite the `description` (currently 4 sentences) to exactly two: capability, then "Use
when …", per the spec's proposed wording. Change the six `## Step N:` headings to
`## Step N —`.

### Acceptance criteria

- [ ] `description` is exactly two sentences, third person, ≤ 1024 chars; sentence 2 starts
      "Use "; no sentence restates a body section ("Checks autoSetupRemote …", "Accepts an
      optional change_type …" are gone).
- [ ] Every genuine trigger from the old description is still present (start of a work
      session; invoked from another skill with a known change_type).
- [ ] All six step headings read `## Step N — <title>`; no `## Step N:` remains.
- [ ] `branch-hygiene/REFERENCE.md` and step *bodies* are unchanged.
- [ ] `pre-commit run --all-files` passes.

---

## create-worktrees: two-sentence description  (#85)

**Blocked by**: None
**User stories**: 1, 6, 7

### What to build

Rewrite the `description` (currently 3 sentences — the middle one spells out the whole
no-op/resume/create/bootstrap algorithm) to exactly two, per the spec's proposed wording.

### Acceptance criteria

- [ ] `description` is exactly two sentences, third person, ≤ 1024 chars; sentence 2 starts
      "Use "; the algorithm-restating middle sentence is gone but "creating one / resuming an
      existing one / optional dependency bootstrap" survives as a compact clause.
- [ ] Triggers preserved: starting isolated implementation work; first step of /implement.
- [ ] SKILL.md body and REFERENCE.md unchanged.
- [ ] `pre-commit run --all-files` passes.

---

## grill: two-sentence description  (#86)

**Blocked by**: None
**User stories**: 1, 6, 7

### What to build

Fold the trailing "Triggers the design skill." into sentence 1 as an em-dash clause so the
`description` is exactly two sentences, per the spec's proposed wording.

### Acceptance criteria

- [ ] `description` is exactly two sentences, third person; sentence 2 starts "Use ".
- [ ] It still says grill runs/triggers the `design` skill.
- [ ] It still fires on "any change to the repository — code, technical documents, skills,
      or configuration".
- [ ] SKILL.md body unchanged.
- [ ] `pre-commit run --all-files` passes.

---

## implement: two-sentence description  (#87)

**Blocked by**: None
**User stories**: 1, 6, 7

### What to build

Rewrite the `description` (currently 4 sentences) to exactly two, keeping the pipeline
overview in sentence 1 and dropping the redundant "Always starts by entering an isolated git
worktree" sentence, per the spec's proposed wording.

### Acceptance criteria

- [ ] `description` is exactly two sentences, third person, ≤ 1024 chars; sentence 2 starts
      "Use ".
- [ ] Sentence 1 still lists the workflow stages (worktree … code review … merge).
- [ ] Triggers preserved: implement a feature, fix a bug, or make any repository change.
- [ ] SKILL.md body and `implement/WORKFLOW.md` unchanged.
- [ ] `pre-commit run --all-files` passes.

---

## write-spec: two-sentence description  (#88)

**Blocked by**: None
**User stories**: 1, 6, 7

### What to build

Fold "No interview — synthesis only." into sentence 1 as an em-dash clause so the
`description` is exactly two sentences, per the spec's proposed wording.

### Acceptance criteria

- [ ] `description` is exactly two sentences, third person; sentence 2 starts "Use ".
- [ ] It still says "no interview / synthesis only" and names the output path
      `.agent-docs/specs/<branch-name>.md`.
- [ ] Trigger preserved: after a /grill session when the design is agreed.
- [ ] SKILL.md body unchanged; `attribution:` frontmatter key untouched.
- [ ] `pre-commit run --all-files` passes.

---

## init-agent-docs: two-sentence description + renumber the 6b step  (#89)

**Blocked by**: None
**User stories**: 1, 5, 6, 7

### What to build

Rewrite the `description` (currently 3 sentences — a six-action enumeration, then
"Idempotent — reports …", then "Use …") to exactly two, per the spec's proposed wording.
Renumber the out-of-sequence `6b` step: `6b → 7` and cascade old `7 8 9 10 → 8 9 10 11`
across `SKILL.md` (the `## Steps` list and its "skip to Step N" jumps) and `REFERENCE.md`
(the `## Step N` headings and every "skip to / continue to Step N" jump and "Steps N–M"
range). Apply high-to-low. Steps 1–6 untouched.

### Acceptance criteria

- [ ] `description` is exactly two sentences, third person, ≤ 1024 chars; sentence 2 starts
      "Use "; "idempotent" survives as a clause, the standalone enumeration sentence and the
      "Idempotent — reports …" sentence are gone.
- [ ] `grep -nE "Step [0-9]+b?" init-agent-docs/SKILL.md init-agent-docs/REFERENCE.md`: no
      `6b`; heading sequence is `1..11`; every "Step N" jump resolves to an existing heading.
- [ ] The *content* of every step is unchanged — only its number and inbound jump references.
- [ ] No file outside `init-agent-docs/` references an `init-agent-docs` step by number
      (verified — `implement/WORKFLOW.md` names the skill only).
- [ ] `pre-commit run --all-files` passes.

---

## address-copilot-comments: one-trigger-per-branch description + de-sprawl SKILL.md  (#90)

**Blocked by**: None
**User stories**: 2, 3, 6, 7

### What to build

Collapse the `description`'s three-way synonym ("address Copilot PR review comments / respond
to Copilot feedback / iterate on a pull request review") and trim the quoted-phrase tail to
two, per the spec's proposed wording. Bring `SKILL.md` under the ~150-line sprawl smell
(currently 173) by replacing Step 7b's *technique* paragraphs (Generalise / Dedupe / Write
and commit) with a one-to-two-line summary plus a pointer to the "Distil Review Criteria"
section already in `REFERENCE.md`; keep Step 7b's **Guard** and **Collect** paragraphs and
the commit-command block inline. If still over ~150, also tighten the Step 3 and Step 4b
prose. Keep the "Loop at a glance" map.

### Acceptance criteria

- [ ] `description` is exactly two sentences, third person, ≤ 1024 chars; one phrasing per
      branch; at most two quoted user utterances.
- [ ] `wc -l address-copilot-comments/SKILL.md` ≤ ~150.
- [ ] Step 7b still states its run-guard (review_round set AND ≥ 1 Fix) and what to collect
      (every Fix; exclude push-backs), and still shows the `git add .agent-docs/review.md …
      commit … push` block.
- [ ] `address-copilot-comments/REFERENCE.md` is unchanged; no step logic, command, or
      branching line in `SKILL.md` changed — only prose density and the Step 7b technique
      text.
- [ ] `pre-commit run --all-files` passes.

---

## bdd: one-trigger-per-branch description  (#91)

**Blocked by**: None
**User stories**: 2, 6, 7

### What to build

Collapse "build features, make changes or fix bugs" and "test-first or behaviour-first
development" to one phrasing per branch, per the spec's proposed wording.

### Acceptance criteria

- [ ] `description` is exactly two sentences, third person; one phrasing per branch.
- [ ] Triggers preserved: writing/changing code; says "red-green-refactor"; asks for
      test-first development or integration/acceptance tests.
- [ ] SKILL.md body and the sibling `.md` files unchanged.
- [ ] `pre-commit run --all-files` passes.

---

## code-review: one-trigger-per-branch description  (#92)

**Blocked by**: None
**User stories**: 2, 6, 7

### What to build

Collapse "review a branch, prepare a PR, check their changes" to one phrasing and trim the
quoted tail to two, per the spec's proposed wording.

### Acceptance criteria

- [ ] `description` is exactly two sentences, third person, ≤ 1024 chars; one phrasing per
      branch; at most two quoted utterances.
- [ ] Sentence 1 still lists the workflow stages (branch hygiene … Copilot review …
      cleanup).
- [ ] SKILL.md body and `REVIEW-CRITERIA.md` unchanged.
- [ ] `pre-commit run --all-files` passes.

---

## design: one-trigger-per-branch description  (#93)

**Blocked by**: None
**User stories**: 2, 6, 7

### What to build

Drop the trailing example list ("implement a feature, fix a bug, update a runbook, modify a
skill") that restates "any change", per the spec's proposed wording. Keep it near-identical
to `grill`'s description on purpose.

### Acceptance criteria

- [ ] `description` is exactly two sentences, third person, ≤ 1024 chars; sentence 2 starts
      "Use ".
- [ ] It still fires on "change the codebase, technical documents, skills, or
      configuration".
- [ ] SKILL.md body, `ADR-FORMAT.md`, `CONTEXT-FORMAT.md`, and the `attribution:` key
      unchanged.
- [ ] `pre-commit run --all-files` passes.

---

## pre-commit-check: one-trigger-per-branch description  (#94)

**Blocked by**: None
**User stories**: 2, 6, 7

### What to build

Collapse "written, edited, or generated" and "lint, format, or validate code quality" to one
phrasing each, per the spec's proposed wording.

### Acceptance criteria

- [ ] `description` is exactly two sentences, third person; one phrasing per branch.
- [ ] Triggers preserved: code just written or edited; user asks to lint or format.
- [ ] SKILL.md body and the `allowed-tools:` frontmatter key unchanged.
- [ ] `pre-commit run --all-files` passes.

---

## quiz-the-diff: one-trigger-per-branch description  (#95)

**Blocked by**: None
**User stories**: 2, 6, 7

### What to build

Collapse "quizzed or tested" and "check or prove their understanding" and trim the quoted
tail to two, per the spec's proposed wording.

### Acceptance criteria

- [ ] `description` is exactly two sentences, third person, ≤ 1024 chars; one phrasing per
      branch; at most two quoted utterances.
- [ ] Sentence 1 still describes the teach-then-quiz loop and the "ten correct" bound.
- [ ] SKILL.md body and `REFERENCE.md` unchanged.
- [ ] `pre-commit run --all-files` passes.

---

## update-dependencies: one-trigger-per-branch description  (#96)

**Blocked by**: None
**User stories**: 2, 6, 7

### What to build

Collapse "update dependencies, bump packages, run a dependency upgrade" to one phrasing;
keep "refresh pre-commit hooks" as the distinct second trigger, per the spec's proposed
wording.

### Acceptance criteria

- [ ] `description` is exactly two sentences, third person, ≤ 1024 chars; one phrasing per
      branch.
- [ ] Sentence 1 still names the ecosystems (Python, .NET/C#, Node/TypeScript/React), the
      pre-commit-hook bump, the main/master sync, and "commits locally".
- [ ] SKILL.md body and `REFERENCE.md` unchanged.
- [ ] `pre-commit run --all-files` passes.

---
