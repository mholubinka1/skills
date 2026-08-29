# Generalise `update-skills` Review Lessons into `code-review` Criteria

## Problem Statement

The `update-skills` PR (#58) went through nine Copilot review rounds and fifteen
findings. A retrospective (`copilot-fixes.md`, kept in scratch) showed the findings
clustered into a handful of *general* review lessons — none of which
`code-review/REVIEW-CRITERIA.md` currently states, so the `code-review` skill's Standards
sub-agent would not have caught them on that PR and will not catch the same class of issue
on the next one. The lessons are not shell- or `update-skills`-specific; they apply to any
change that edits files it doesn't own, shells out to external tools, or restates a value in
prose.

## Solution

Add the generalised lessons to `code-review/REVIEW-CRITERIA.md` as new review points, folded
into the existing sections and phrased in the file's existing terse, imperative house style
(the whole file is passed verbatim to the Standards sub-agent). One existing bullet is
broadened rather than duplicated. No new section; the Fowler smell baseline is untouched.

## User Stories

1. As a reviewer running `/code-review`, I want the Standards sub-agent told to flag
   best-effort edits to files the change does not own (shell rc files, another team's
   config or schema, a user's document), so that a diff which can silently truncate or
   corrupt such a file is caught as a blocking finding rather than read as "looks
   reasonable".
2. As a reviewer, I want the sub-agent told to flag an unsafe fallback — code that, when its
   preferred resource is missing, does something materially riskier (global/system install,
   unpinned version, world-writable path) instead of failing with a clear message.
3. As a reviewer, I want the sub-agent told to flag a "spot check" that inspects one
   artefact when the thing being verified needs several (one of N hooks, one of N config
   keys, one of N migrations).
4. As a reviewer, I want the sub-agent told to flag code that shells out to
   `git`/`pip`/network/`venv` (etc.) without guarding foreseeable failures or attaching an
   actionable cause, and to flag error text that asserts a single cause when several are
   possible.
5. As a reviewer, I want the sub-agent told to flag predictable temp paths (`$f.$$`, fixed
   `/tmp` names, PID suffixes) that should be `mktemp`, and temp files not cleaned up on
   failure.
6. As a reviewer, I want the sub-agent told to flag a comment or doc that claims a stronger
   guarantee than the code delivers ("exactly one", "in place", "atomic", "idempotent") —
   either the code tightens or the claim is corrected.
7. As a reviewer, I want the existing "stale rationale sweep" broadened so it also covers a
   diff that changes a value, order, or enumeration which is *restated in prose* elsewhere
   (README, config comment, spec, another doc) — every restatement must move in the same
   change.

## Implementation Decisions

- Single file changed: `code-review/REVIEW-CRITERIA.md`. It is the sole source read by
  `code-review/SKILL.md` Step 4 and passed verbatim to the Standards sub-agent — no mirror
  to keep in sync.
- Placement (folded into existing sections, no new section):
  - **Code Correctness** — three new bullets: destructive edits to non-owned files (story
    1); spot-check vs multi-part requirement (story 3); unguarded external-command failure
    and single-cause error text (story 4).
  - **Code Quality** — one new bullet: comment/doc guarantee stronger than the code delivers
    (story 6).
  - **Security and Performance** — two new bullets: unsafe fallback to a riskier action
    (story 2); predictable temp paths / missing temp cleanup (story 5).
  - **Documentation** — the existing "Stale rationale sweep" bullet is rewritten to cover
    both design-rationale/invariant comments *and* restated values/orders/enumerations
    (story 7). Not a second bullet.
- Each new bullet follows the file's established form: a bold lead-in label, then an
  imperative "flag …" / "check for …" instruction, one concrete example, kept to one or two
  sentences. Consistent with the other bullets in each target section (which are prose
  instructions, not the "→ fix" form used only in the Fowler list).
- The two rule bindings at the top of the file ("The repo overrides", "Always a judgement
  call", "Documented-standard breaches may be blocking; smells are always advisory") already
  govern the new bullets — they are documented standards once added, so the sub-agent may
  mark them blocking. No change to that preamble.
- No ADR: this is additive review guidance in one markdown file; reverting is a one-file
  diff and needs no context to understand.
- Out of the diff: `.agent-docs/agent.md` (behavioural standards for *doing* work, a
  separate concern from *reviewing* it) and `check-review-status.sh` (the review-body-prose
  gap is its own follow-up).

## Testing Decisions

- No code seam — this is a guidance document. Consistent with prior doc-only changes in
  this repo (e.g. `chore/sed-rename-caution`, `chore/stale-rationale-review-check`),
  verification is:
  - **Review**: each new bullet reads as a general heuristic (no `update-skills`/shell
    specifics leaking in); it sits in the right section; it matches the surrounding bullets'
    length and voice; the rewritten Documentation bullet still covers everything the
    original did.
  - **`pre-commit-check`**: markdownlint (and the repo's other hooks) pass on the file.
- A light cross-check: map each of findings 1–15 in `copilot-fixes.md` to at least one
  bullet (existing or new) that would now flag it, to confirm coverage and no gaps.

## Out of Scope

- Any change to `code-review/SKILL.md` itself (the workflow is unchanged; only the criteria
  it feeds the sub-agent grow).
- `.agent-docs/agent.md` and other skills.
- The `check-review-status.sh` review-body-prose gap (follow-up issue, tracked separately).
- Re-running the `update-skills` review against the new criteria.
- Any new tooling or automated lint for these criteria — they are sub-agent guidance, human/
  model judgement as with every other bullet in the file.

## Further Notes

Source material is `copilot-fixes.md` (session scratch, not committed): a per-round log of
all fifteen findings plus an "Insights" section. Candidate criteria were labelled A–G during
the grill; the mapping is A→story 1, B→2, C→3, D→4, E→5, F→6, G→7.
