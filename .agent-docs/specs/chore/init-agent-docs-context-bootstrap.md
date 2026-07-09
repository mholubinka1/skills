# init-agent-docs Context Bootstrap

## Problem Statement

When `init-agent-docs` runs and no existing `context.md` is found, Step 6 instructs the
agent to write `CONTEXT-TEMPLATE.md` verbatim to `.agent-docs/context.md`. That template
file does not exist — the reference is broken. More importantly, even if it did exist, a
verbatim copy would produce a generic placeholder rather than a domain glossary grounded
in the actual codebase.

Additionally, when a `context.md` already exists, Step 4 short-circuits the entire flow and
skips to Step 7. This means an existing glossary is never reviewed for quality or compliance
with the format rules in `CONTEXT-FORMAT.md` — gaps, weak definitions, and missing avoid-lists
accumulate silently.

## Solution

Fix Step 4 and Step 6 in both `SKILL.md` and `REFERENCE.md`:

- **Step 4**: when `context.md` already exists (or is moved into place by Step 5), route to
  Step 6 for review rather than skipping to Step 7.
- **Step 6**: two sub-paths replace the broken template-copy instruction:
  - **Generate** (no `context.md` found): read the codebase to understand the domain, then
    write a full, comprehensive `context.md` following the structure and rules in
    `CONTEXT-FORMAT.md`.
  - **Review and improve** (file exists or was just moved): read `CONTEXT-FORMAT.md`, audit
    the existing file against its rules, write improvements if shortcomings are found, and
    report "no improvements needed" if the file is already fully compliant.

## User Stories

1. As a developer bootstrapping a new repo, I want `init-agent-docs` to produce a real domain
   glossary from my codebase, so that I get a useful `context.md` rather than a generic
   placeholder.
2. As a developer re-running `init-agent-docs` on a repo with an existing `context.md`, I want
   the skill to review and improve it, so that the glossary stays aligned with the
   `CONTEXT-FORMAT.md` quality rules over time.
3. As a developer with a high-quality `context.md`, I want `init-agent-docs` to leave it alone
   if it is already compliant, so that I do not get spurious rewrites.
4. As a skill maintainer, I want Steps 4 and 5 to route to Step 6 in all paths, so that every
   run of the skill produces or validates a domain glossary.

## Implementation Decisions

Two files change — `init-agent-docs/SKILL.md` and `init-agent-docs/REFERENCE.md`:

**Step 4 change (both files):**

- Remove the "skip to Step 7" branch.
- When `context.md` exists: report "`.agent-docs/context.md` found — proceeding to review."
  and continue to Step 6 (review sub-path).
- When `context.md` does not exist: continue to Step 5 as before.

**Step 5 change (REFERENCE.md only — the skip target):**

- When a file is found and moved: instead of "skip to Step 7", continue to Step 6
  (review sub-path) so the newly moved file is immediately reviewed.
- The "multiple files found" and "no files found" branches are unchanged.

**Step 6 change (both files):**
Replace the single "write CONTEXT-TEMPLATE.md verbatim" instruction with two sub-paths:

- **Generate sub-path** (no `context.md` found after Steps 4–5):
  1. Read `CONTEXT-FORMAT.md` from this skill's directory to understand the required
     structure and rules.
  2. Read the codebase to identify domain-specific concepts: skill names, workflow concepts,
     file conventions, and terminology unique to this repo.
  3. Write a full `context.md` to `.agent-docs/context.md` following the format — with a
     title, description, `## Language` section, and all relevant domain terms with tight
     definitions and avoid-lists.
  4. Report: "Created `.agent-docs/context.md` from codebase analysis."

- **Review and improve sub-path** (file exists):
  1. Read `CONTEXT-FORMAT.md` from this skill's directory.
  2. Read the existing `.agent-docs/context.md`.
  3. Audit against the rules: missing terms, weak definitions (more than two sentences),
     missing avoid-lists, general programming concepts that do not belong, ungrouped clusters.
  4. If shortcomings are found: write the improved file and report: "Improved
     `.agent-docs/context.md` — {brief summary of changes}."
  5. If no shortcomings are found: report "`.agent-docs/context.md` reviewed — no
     improvements needed." and continue to Step 7 without writing.

`CONTEXT-FORMAT.md` already lives in `init-agent-docs/` alongside `SKILL.md` and
`REFERENCE.md` — no new files are needed.

## Testing Decisions

No executable code changes. Verification is by inspection of the updated skill files:

- **Step 4 routing**: read `SKILL.md` and `REFERENCE.md` — the "skip to Step 7" branch for
  an existing `context.md` must be absent; the route to Step 6 must be present.
- **Step 5 routing**: read `REFERENCE.md` — the "skip to Step 7" branch after a successful
  move must be absent; the continue-to-Step-6 instruction must be present.
- **Step 6 generate sub-path**: read `REFERENCE.md` — must reference `CONTEXT-FORMAT.md`,
  must instruct codebase reading, must not reference `CONTEXT-TEMPLATE.md`.
- **Step 6 review sub-path**: read `REFERENCE.md` — must include audit criteria from
  `CONTEXT-FORMAT.md` rules, must include both "improved" and "no improvements needed"
  report variants.
- **`CONTEXT-TEMPLATE.md` reference absent**: grep both files — must produce zero hits.

## Out of Scope

- Changes to any other step (Steps 1–3, 7–10)
- Changes to `CONTEXT-FORMAT.md` itself
- Changes to other skills
- Generating or modifying an actual `context.md` for this skills repo (that is a runtime
  output of the skill, not part of the skill definition)

## Further Notes

`CONTEXT-FORMAT.md` already exists in `init-agent-docs/` as of the trigger for this work.
The `CONTEXT-TEMPLATE.md` reference in the current files is simply wrong — there is no such
file and there never will be. The fix replaces the broken reference entirely rather than
creating a template file to satisfy it.

The SKILL.md overview only needs to update the Step 4 and Step 6 summary lines — the detail
lives in REFERENCE.md. Both files must be updated in sync.
