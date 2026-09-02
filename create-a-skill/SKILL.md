---
name: create-a-skill
description: Create, revise, or review a Claude Code agent skill — structured on the information hierarchy, with a description that triggers reliably and steps that stop on a real criterion. Use when the user wants to write a new skill, rework an existing one, or check a skill against the writing levers.
---

# Writing Skills

A skill is predictable when the agent takes the same *process* every run — not when it produces the same output. The levers that buy that, the description rules, and the review checklist are in [REFERENCE.md](REFERENCE.md).

## Process

1. **Gather requirements** — get an answer to each before drafting:
   - What task or domain does the skill cover? Which use cases, concretely?
   - A utility script (a deterministic operation), or instructions only?
   - Reference material to bundle or point at?
   - **Model-invoked or user-invoked?** The agent (or another skill) must reach it on its own → model-invoked. It only ever fires by hand → user-invoked. See the Model- vs user-invoked section in REFERENCE.md.
   Continue once every question has an answer.

2. **Place each piece of content on the information hierarchy** — an in-file step (an ordered action), in-file reference (consulted on demand), or disclosed reference (pushed into a pointer-reached file). Branch test: inline what every run needs, disclose what only some branches reach. Stop when every piece has a place.

3. **Draft** — `SKILL.md`, plus `REFERENCE.md` / `EXAMPLES.md` / `scripts/` when step 2 or sprawl calls for them:
   - Write the `description` as a **context pointer** — front-load the trigger word, one trigger per branch, cut identity the body already carries.
   - End every step on a **completion criterion** that is checkable (done vs not-done) *and* exhaustive ("every X accounted for", not "produce a list").
   - Reach for a **leading word** where a triad or phrase repeats. State behaviour **positively** — a "don't …" only as a hard guardrail paired with the positive target.
   - Keep each meaning in one place; leave one-file, one-command lookups to the environment.
   The draft is done when all four rules hold for every step and pointer.

4. **Review with the user** — does it cover the use cases? Anything missing, or over-detailed? Continue once the user confirms coverage.

5. **Verify against the Review Checklist in REFERENCE.md** — every item is pass/fail. A skill that fails one is not done.

## Skill structure

```text
skill-name/
├── SKILL.md           # required — the process, placed on the information hierarchy
├── REFERENCE.md       # disclosed reference (when branch-only content or sprawl warrants)
├── EXAMPLES.md        # worked examples (same test)
└── scripts/           # utility scripts (deterministic operations)
    └── helper.py
```

`name:` matches the directory. `SKILL.md` past ~150 lines is a sprawl smell — look for reference to disclose or a sequence to split.

## SKILL.md template

```md
---
name: skill-name
description: <what it does>. Use when <one trigger per branch>.
---

# Skill Name

## Quick start

<minimal working example>

## Workflows

<steps, each ending on a completion criterion — e.g. "every changed file has a
test and the full suite is green">

## Advanced

See [REFERENCE.md](REFERENCE.md).
```
