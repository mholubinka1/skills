# Issues: chore/bdd-clean-context-impl

> Work complete — PR ready to merge.

## Split BDD workflow into test-authoring phase + clean-context implementation subagent

**GitHub**: #71

**Blocked by**: None

**User stories**: 1, 2, 3, 4, 5, 6, 7

### What to build

Restructure the `behaviour-driven-development` skill so its implementation loop runs in a
fresh `general-purpose` subagent, started after the test-authoring phase has agreed the
scenario list and written a single failing tracer bullet test. The agreed scenarios and
interface changes are passed inline in the subagent prompt (no new on-disk artifact). The
subagent runs the red-green-refactor loop vertically and reports back; the main context
verifies against the per-cycle checklist. The "Anti-Pattern: Horizontal Slices" section is
kept intact with only an additive clarification and a diagram tweak. Only `SKILL.md` and
`WORKFLOW.md` in the skill change.

### Acceptance criteria

- [x] `SKILL.md` "Anti-Pattern: Horizontal Slices" prohibition text is unchanged; one added
      paragraph states the handoff crosses the boundary with exactly one failing test (the
      tracer bullet), the subagent writes every remaining test one at a time, and batching
      all tests upfront stays forbidden in both contexts.
- [x] `SKILL.md` `WRONG`/`RIGHT` diagram gains a context-boundary line: the boundary sits
      between the tracer test and the loop; the loop stays `test1→impl1, test2→impl2, …`
      inside the subagent.
- [x] `SKILL.md` closing "See WORKFLOW.md" pointer line names the phase split.
- [x] `WORKFLOW.md` Step 3 is the tracer bullet test only (RED): confirm it fails for the
      right reason (not an import/collection error); no production code written.
- [x] `WORKFLOW.md` Step 4 dispatches one `Agent` call (`type: general-purpose`) whose
      prompt carries inline: the user stories, the full Given-When-Then scenario list, the
      confirmed interface changes, path(s) to the failing tracer test file(s), the core
      loop rules (red-green vertical, one scenario at a time, minimal code to pass, never
      refactor while red, test observable behaviour only, refactor once green), pointers to
      `tests.md` / `mocking.md` / `refactoring.md`, and an explicit "do not re-invoke the
      `bdd` skill" instruction. The subagent returns per-scenario status (green / not
      satisfied + why), refactors applied, and the final test-run output.
- [x] `WORKFLOW.md` Step 5 has the main context verify the returned result against the
      per-cycle checklist, confirm every scenario is covered and green, and review the
      subagent's refactors. `pre-commit-check` and commit remain the caller's
      responsibility. A scenario the subagent cannot satisfy: it stops and reports; the
      main context decides (fix inline or re-dispatch a narrower subagent); no automatic
      retry loop in the skill.
- [x] Behaviour is identical whether `bdd` is invoked standalone or as `/implement` Step 6.
- [x] Only `behaviour-driven-development/SKILL.md` and
      `behaviour-driven-development/WORKFLOW.md` are modified in the skill.
- [x] `pre-commit-check` passes on all changed files.

---
