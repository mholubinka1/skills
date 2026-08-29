# `.agent-docs/review.md` — a per-repo review-criteria feedback loop

## Problem Statement

The `code-review` skill feeds its Standards sub-agent a single fixed file,
`code-review/REVIEW-CRITERIA.md`, shipped with the skill. Everything a repo learns from its
own Copilot review rounds — the recurring classes of mistake Copilot keeps catching — is
lost once the PR merges, unless a human notices the pattern and hand-edits
`REVIEW-CRITERIA.md` (as was just done for the `update-skills` PR after a manual
retrospective). There is no mechanism for a repo to accumulate its own review criteria, and
no automatic path from "Copilot found this and we fixed it" to "the next review checks for
this".

## Solution

A new per-repo file, `.agent-docs/review.md`, holding review criteria accumulated from that
repository's own Copilot reviews. Three skills cooperate:

1. **`init-agent-docs`** bootstraps `.agent-docs/review.md` from a template when it does not
   exist — the same verbatim-template pattern it uses for `agent.md`.
2. **`address-copilot-comments`**, once its Copilot loop is clean, distils every finding
   that resulted in a code change into a generalised one-line criterion and appends it to
   `.agent-docs/review.md`. Push-backs (findings replied to with "Ignored.") are never
   recorded — only things that changed the code.
3. **`code-review`** reads `.agent-docs/review.md` (when present in the target repo) and
   passes it to its Standards sub-agent alongside `REVIEW-CRITERIA.md`, treating its entries
   as documented repo standards.

The net effect: a class of mistake Copilot catches on one PR is on the review checklist for
the next PR in that repo, without a human retrospective in the loop.

## User Stories

1. As a maintainer running any implementation workflow, I want `init-agent-docs` to create
   `.agent-docs/review.md` if it is missing, so that the file the other two skills depend on
   exists without a manual step, and re-running the skill is a safe no-op when it is already
   present.
2. As an author finishing an `address-copilot-comments` loop, I want each Copilot finding I
   *fixed* (a real thread or a suppressed entry, across every round of that loop) turned
   into a generalised review criterion and appended to `.agent-docs/review.md`, so the repo
   accumulates its own review knowledge.
3. As that same author, I want findings I *pushed back on* ("Ignored.") to leave no trace in
   `.agent-docs/review.md`, so the file only ever contains criteria the team actually
   accepted by changing code.
4. As that author, I want a candidate criterion that merely restates something already in
   `.agent-docs/review.md` to be skipped, so the file does not fill with near-duplicates
   over many PRs.
5. As a reviewer running `/code-review` in a repo that has a `.agent-docs/review.md`, I want
   the Standards sub-agent to receive that file's criteria as documented standards (blocking
   when breached, same status as `REVIEW-CRITERIA.md`), so accumulated lessons are actually
   enforced on the next review.
6. As a reviewer running `/code-review` in a repo with no `.agent-docs/review.md`, I want the
   skill to behave exactly as before, so the feature is additive and safe for repos that
   have never run `init-agent-docs`.
7. As a maintainer of this skills repo, I want its own `.agent-docs/review.md` created from
   the template in this change, so the repo dogfoods the loop and `init-agent-docs`'s
   "already exists" path is exercised here.

## Implementation Decisions

### File: `.agent-docs/review.md`

- Format: a short explanatory header, then a single `## Criteria` section holding a flat
  markdown list. Empty state is an explicit `_None yet._` line.
- Each entry: a bold label + an imperative one-line rule in the same voice as
  `REVIEW-CRITERIA.md`'s bullets, ending with a `(PR #N)` source tag. Example:
  `- **Partial checks for compound state**: a readiness check that inspects one artefact when the state has several parts. (PR #58)`
- The header states what the file is, that `address-copilot-comments` maintains it (fixes
  only, no push-backs), that `code-review` consumes it as documented standards, and that
  entries can be pruned or promoted into the shared `REVIEW-CRITERIA.md` by hand.
- Lives at `.agent-docs/review.md`; it is agent-facing repo documentation, a sibling of
  `agent.md` / `context.md`, not an ADR or spec.

### `init-agent-docs`

- New template file `init-agent-docs/REVIEW-TEMPLATE.md`, alongside `AGENT-TEMPLATE.md`,
  holding the header + empty `## Criteria` section verbatim.
- New step **6b — Bootstrap `review.md`**, placed after Step 6 (context.md) and before Step
  7 (ADR migration). A lettered sub-step is used deliberately so Steps 7–10 and their
  cross-references are not renumbered.
  - If `.agent-docs/review.md` exists → report "`.agent-docs/review.md` already exists —
    skipping." and continue to Step 7.
  - Else → ensure `.agent-docs/` exists, write `REVIEW-TEMPLATE.md` verbatim to
    `.agent-docs/review.md`, report "Created `.agent-docs/review.md`." On write failure,
    report and continue to Step 7 (consistent with the context.md failure handling — a
    missing `review.md` is not fatal to the rest of the bootstrap).
  - Unlike `context.md`, there is no "search elsewhere and move" and no
    "review/improve existing" sub-path — the file is machine-maintained; if it exists,
    leave it untouched.
- Updated surfaces: the SKILL.md `## Steps` list (new item 6b), the SKILL.md frontmatter
  `description` (mention `.agent-docs/review.md`), the SKILL.md intro sentence, REFERENCE.md
  (new `## Step 6b` section; the Step 6 "continue to Step 7" hand-offs become "continue to
  Step 6b"), and all three Step 10 summary examples in REFERENCE.md (add a `review.md`
  line).

### `address-copilot-comments`

- New step **7b — Distil review criteria into `.agent-docs/review.md`**, between Step 7 and
  Step 8.
- Guarded: run 7b only if `review_round` was set at Step 2b (an exempt PR never learned
  anything) **and** at least one Fix was applied at any Step 4 across the whole invocation.
  Otherwise skip straight to Step 8.
- Inputs: the set of findings across every round of this invocation whose Step 4 decision
  was **Fix** — both real threads (replied "Fixed.") and suppressed entries (recorded as
  "Fixed." in a Step 4d PR comment). Push-backs are excluded.
- For each fixed finding, write one generalised criterion: strip the specifics (file name,
  line number, the concrete identifier or value) down to the *class* of mistake, phrased as
  a reusable rule in `REVIEW-CRITERIA.md`'s bold-label + imperative voice, tagged
  `(PR #<this PR>)`. Multiple findings that generalise to the same rule collapse to one
  entry.
- Dedup: before appending, compare each candidate against the entries already in the target
  repo's `.agent-docs/review.md` (match on meaning, not text). Skip any candidate already
  covered. Dedup is only against `.agent-docs/review.md` — the skill does not read
  `code-review/REVIEW-CRITERIA.md` (it may not be present in the target repo, and mild
  overlap is acceptable).
- If `.agent-docs/review.md` does not exist, create it from the same header the
  `init-agent-docs` template uses, then append. Replace a lone `_None yet._` line rather
  than appending after it.
- Commit the file change to the PR branch on its own:
  `git add .agent-docs/review.md` → `git commit -m "docs: record N review criteria from Copilot review"` → push.
  This lands in the same PR whose review produced the criteria.
- REFERENCE.md gains a "Distil review criteria" section: how to generalise a finding, the
  dedup rule, the file header for first creation, and the commit message.
- The SKILL.md "Loop at a glance" diagram gains a `Step 7b` line; Step 8's wording is
  otherwise unchanged.

### `code-review`

- Step 4: "Read `REVIEW-CRITERIA.md` in full" becomes "Read `REVIEW-CRITERIA.md` in full,
  and `.agent-docs/review.md` from the target repo if it exists."
- Step 4 Standards sub-agent prompt: the "complete contents of REVIEW-CRITERIA.md" bullet
  gains "…and, if present, the contents of the target repo's `.agent-docs/review.md`
  (repo-specific criteria accumulated from past Copilot reviews — treat its entries as
  documented standards, same as REVIEW-CRITERIA.md)."
- No other `code-review` change. When `.agent-docs/review.md` is absent the prompt is
  byte-identical to today.

### This repo

- Create `.agent-docs/review.md` from the new template (starts at `_None yet._` — the seven
  criteria added for the `update-skills` retro already live in `REVIEW-CRITERIA.md` and are
  not duplicated here).
- Add a `review.md` term to `.agent-docs/context.md` under the Agent Docs section.
- No change to `.agent-docs/agent.md` (behavioural standards for doing work, not review
  context).

### No ADR

Three coordinated skill edits plus a new doc file; reverting is a contained diff and needs
no rationale record.

## Testing Decisions

- No code seam — three skills defined in markdown, one new markdown template, one new repo
  doc. Verification, consistent with prior skill changes in this repo
  (`chore/review-criteria-change-hygiene`, `chore/sed-rename-caution`):
  - **Review** each edited skill end-to-end against its own step logic: `init-agent-docs`
    Step 6b has the same shape as the `agent.md` steps (check → skip / write verbatim);
    `address-copilot-comments` Step 7b's guard, generalise, dedup, and commit are
    unambiguous and reference REFERENCE.md for detail; `code-review` Step 4 degrades to
    today's behaviour when the file is absent.
  - **Trace three scenarios** on paper against the new step text:
    1. `init-agent-docs` on a repo with no `.agent-docs/review.md` → file created from
       template; re-run → "already exists — skipping".
    2. `address-copilot-comments` finishing a loop where round 1 fixed two findings and
       round 2 pushed back on one → exactly the two fixed findings are generalised, deduped,
       and committed; the push-back leaves no entry; an exempt PR writes nothing.
    3. `code-review` Step 4 in a repo with a populated `.agent-docs/review.md` → its
       criteria appear in the Standards sub-agent prompt as documented standards; in a repo
       without the file → prompt unchanged.
  - **`pre-commit-check`**: markdownlint and the other hooks pass on every changed file.
  - **Cross-skill consistency check**: the file name, path, header wording, and "fixes only,
    no push-backs" rule are stated identically in `init-agent-docs`'s template,
    `address-copilot-comments`'s REFERENCE.md, and `code-review`'s Step 4 — apply the
    "restated-fact sweep" criterion to this very change.

## Out of Scope

- Auto-pruning, ranking, or promoting `.agent-docs/review.md` entries into
  `REVIEW-CRITERIA.md` — a human does that.
- Recording findings from `code-review`'s own Standards/Spec sub-agents — only Copilot
  findings, per the request.
- Per-round writes — one synthesis pass at the end of the `address-copilot-comments` loop.
- `address-copilot-comments` reading or reconciling against `code-review/REVIEW-CRITERIA.md`.
- Any change to `agent.md`, `pr-cleanup`, `bdd`, or the `implement` workflow.
- Back-filling `.agent-docs/review.md` in this repo with the `update-skills` retro criteria
  (already in `REVIEW-CRITERIA.md`).

## Further Notes

- `.agent-docs/review.md` is deliberately shaped like `REVIEW-CRITERIA.md`'s bullets so a
  maintainer can lift a stabilised entry straight into the shared file.
- `address-copilot-comments` Step 4b already runs `code-review` Steps 1–5 mid-loop; that
  path only *reads* `.agent-docs/review.md`, and Step 7b only *writes* it after the loop is
  clean, so there is no write-during-read hazard.
