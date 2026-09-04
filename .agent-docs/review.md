# Review Criteria (repo-specific)

Review criteria this repository has accumulated from its own Copilot review rounds.

- The `address-copilot-comments` skill appends a generalised, one-line criterion here for
  every Copilot finding on a PR that resulted in a code change. Findings that were pushed
  back on ("Ignored.") are never recorded — this file only holds criteria the team accepted
  by changing code.
- The `code-review` skill feeds this file to its Standards sub-agent alongside the skill's
  own `REVIEW-CRITERIA.md`, and treats the entries here as documented repo standards (a
  breach may be blocking).
- Prune stale entries, and promote durable ones into a shared criteria file, by hand.

Each entry is a bold label plus a one-line imperative rule, tagged with the PR it came
from — for example:
`- **Partial checks for compound state**: flag a readiness check that inspects one artefact when the state it gates has several parts. (PR #58)`

## Criteria

- **Incomplete cross-reference**: when a change adds a fresh statement of a fact that is
  defined canonically elsewhere (a rule, a constraint, an enumeration), it must carry the
  same qualifiers as the canonical version — a summary that silently drops a caveat reads as
  a contradiction between the two places. (PR #64)
- **Executable placeholder in an instruction file**: flag a command in a step-logic file
  (`SKILL.md`/`REFERENCE.md`/`WORKFLOW.md`) that carries a literal example value or a
  placeholder token the step never derives — an agent runs these verbatim. Prefer a command
  form that needs no substitution. (PR #70)
- **Edit outside a declared no-change boundary**: when the issue or spec fences an existing
  section as "kept verbatim / additive clarification only", flag any reword of that
  section's existing sentences — even an accuracy fix belongs in the added material, not the
  frozen text. (PR #72)
- **Ambiguous cadence in an instruction step**: flag a directive to act "after every X" or
  "once Y" that does not say whether it runs each iteration or a single time at the end — an
  agent following it can pick the wrong cadence. (PR #72)
- **Prose copies drift from shipped behaviour**: after a design detail changes mid-review (a
  prompt mechanism, a default, a flag, a command), every prose statement of it — spec, issue,
  glossary, ADR bullets, acceptance criteria, not just the primary skill file — must be
  swept and reconciled with what the code/skill now does; a copy left at the pre-change
  wording reads as a contradiction. Also verify any claim that characterises a referenced
  document ("X only documents the upgrade flow", "Y has none of these") against that
  document. (PR #78)
- **Doc fails its own standard**: when a file defines a checklist or rule set, flag any part
  of that same file that breaks one of its own rules — a `description` that isn't third
  person, a section longer than the length limit the file itself sets. (PR #80)
- **Vague pointer where a precise anchor exists**: flag a cross-reference that names only the
  target file when it could name the specific section or heading the reader needs — most of
  all when the spec asks for the precise form. (PR #80)
- **Inconsistent element across a parallel series**: flag a sequence of parallel items
  (steps, sections, list entries) where one omits a structural element its siblings all
  carry — a completion criterion, a "Done when", a heading. (PR #80)
- **Rule looser than the check that enforces it**: flag a blanket rule with an unlisted
  special case that breaks it, or a rule whose wording is vaguer than the checklist item
  that tests it (prose says "first sentence … second sentence"; checklist says "exactly
  two"); both places must state the same constraint. (PR #80)
- **Coined word spellcheck will flag**: flag an invented compound or coinage in prose that
  codespell or similar tooling is likely to trip on; prefer plain phrasing unless the term
  is a deliberately pinned leading word. (PR #80)
- **Unqualified criterion that known-excluded files break**: flag an acceptance criterion or
  rule stated as an absolute ("no file references X", "every Y is Z") when files the same
  change deliberately leaves alone — history-of-record specs/issues, generated output,
  vendored code — already violate it. Scope it to the class actually in play ("no skill or
  workflow doc", not "no file"). (PR #97)
- **Tightening prose drops something load-bearing**: when shortening a description, rule, or
  comment, flag the loss of a qualifier that changes scope ("pre-commit hook versions" →
  "pre-commit hooks", "patch/minor" → "latest") or of a clause naming a genuinely distinct
  case (a trigger branch that is not a synonym of a kept one). Keep it unless it is provably
  redundant. (PR #97)
- **Verification step that doesn't verify**: flag a test-plan or acceptance step whose
  stated method gives wrong answers on the actual inputs — a `.`-split sentence count on
  text full of `.md`/`.NET`, a `grep` that also matches comments, a line count that
  includes generated output. State a method that survives the real data. (PR #97)
