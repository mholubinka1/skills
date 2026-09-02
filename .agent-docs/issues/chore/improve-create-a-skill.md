# Issues: chore/improve-create-a-skill

## Rewrite create-a-skill around the writing levers (#79)

**Blocked by**: None

**User stories**: 1, 2, 3, 4, 5, 6, 7, 8

### What to build

Rewrite `create-a-skill/SKILL.md` and `create-a-skill/REFERENCE.md` so the skill produces a
skill against a named set of **writing levers** (adapted from Matt Pocock's
`writing-for-agents`, credited in one line, absorbed self-contained — no runtime dependency
on the plugin). Fix the 100-vs-500 `SKILL.md` split contradiction with a single rule.

- **`create-a-skill/SKILL.md`** (~90 lines; hard ceiling ~150):
  - Frontmatter `description` rewritten as a context pointer: front-loaded trigger word;
    three genuinely distinct branches — create a new skill / revise an existing one / review
    a skill against the levers — with "create, write, or build" (synonym-branches)
    collapsed.
  - Short intro + one pointer to `REFERENCE.md` for the levers and the checklist.
  - `## Process` rewritten: (1) gather — task/domain, use cases, scripts-or-not, reference
    materials, **model- vs user-invoked**; (2) place each piece of content on the
    information hierarchy, disclosing what only some branches reach; (3) draft — description
    as a context pointer, each step on a checkable + exhaustive completion criterion, reach
    for leading words, steer positive; (4) review with the user; (5) verify against the
    Review Checklist in `REFERENCE.md`.
  - Keep the skill-structure diagram and the `SKILL.md` template; the template gains a
    one-line sample completion criterion.
- **`create-a-skill/REFERENCE.md`** (target ~130 lines; must not itself sprawl):
  - `## Description requirements` — kept, folded with the pointer-writing rules.
  - `## Writing levers` — terse imperative rules, each ending on a check: context pointer,
    the two loads, information hierarchy, progressive disclosure, co-location, completion
    criteria, when to split, leading words, steer positive, pruning.
  - `## Model- vs user-invoked` — `description` vs `disable-model-invocation: true`; router
    skills.
  - `## When to add scripts` — kept.
  - `## When to split files` — reconciled: past ~150 lines `SKILL.md` is a sprawl smell;
    the branch test is the real driver, not the line count.
  - `## Common failure modes` — named one-line list: Sprawl / Negation steering /
    Duplication / Scattering / No-op / Premature completion, each with its fix.
  - `## Review checklist` — revised, ~10 grouped pass/fail items (Pointer / Hierarchy /
    Completion criteria / Leading words & positivity / General).
- **`.agent-docs/context.md`** — "Skill Authoring" cluster with Context pointer, Information
  hierarchy, Progressive disclosure, Leading word (done inline during the grill; this issue
  carries it through).
- Each lever's rule is stated once (in `## Writing levers`) and referenced — not restated —
  by `SKILL.md` and the checklist.

No change to any other skill, or to `create-a-skill`'s `name` / invocation model.

### Acceptance criteria

- [ ] `create-a-skill/SKILL.md` `## Process` has five steps (gather incl. model/user-invoked
      -> place on the information hierarchy -> draft applying every lever -> review against
      the step-1 use cases -> verify against the Review Checklist); each step ends on a
      completion criterion and **points at `REFERENCE.md` for the rules rather than restating
      them**; structure diagram + `SKILL.md` template retained; template shows a sample
      completion criterion.
- [ ] `create-a-skill/SKILL.md` is <= ~150 lines (target ~55); one markdown pointer target
      (`REFERENCE.md`), references one level deep.
- [ ] `create-a-skill/REFERENCE.md` has `## Writing levers` covering context pointer, the
      two loads, information hierarchy, progressive disclosure, co-location, completion
      criteria, when to split, leading words, steer positive, pruning — each a terse rule of
      one to three sentences ending on an explicit `*Check:*` line.
- [ ] `create-a-skill/REFERENCE.md` has `## Model- vs user-invoked` (`disable-model-invocation`,
      router skills) and `## Common failure modes` (Sprawl / Negation steering / Duplication /
      Scattering / No-op / Premature completion, each with its fix).
- [ ] `## Description requirements` is kept and folded with the pointer-writing rules
      (front-load the trigger word; one trigger per branch; cut identity the body carries;
      third person; <=1024 chars; first sentence what it does, second "Use when ...").
- [ ] The 100-vs-500 contradiction is gone: `SKILL.md`, `REFERENCE.md` "When to split
      files", and the checklist all say the same thing — ~150 = sprawl smell, branch test
      drives it.
- [ ] `## Review Checklist` is revised to grouped pass/fail items (Pointer, Hierarchy &
      disclosure, Completion criteria, Leading words & positivity, General) that **reference
      the rules rather than re-spell enumerations** — the `~150` number and the "every X /
      not a list" phrasing each live once in their own section.
- [ ] Each lever's rule appears once in `## Writing levers`; `SKILL.md` and the checklist
      reference it, not restate it — SKILL.md steps name the `REFERENCE.md` section, the
      checklist points at *Description requirements* / *When to split files*.
- [ ] `create-a-skill` passes its own revised checklist: description front-loads the trigger
      word with three distinct branches and no body-restating clause; one pointer target,
      one level deep; every step ends on a checkable + exhaustive criterion; positive
      phrasing (a "don't ..." only as a paired guardrail); reaches for leading words where a
      triad repeats.
- [ ] Content is credited in one line as adapted from `writing-for-agents`.
- [ ] `.agent-docs/context.md` has the "Skill Authoring" glossary cluster.
- [ ] `pre-commit run --all-files` passes.
- [ ] No other skill's files are changed.

---
