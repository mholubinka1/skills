---
name: create-a-skill
description: Create, revise, or review a Claude Code agent skill. Use when the user wants to write a new skill, rework an existing one, or review a skill against the writing levers.
---

# Writing Skills

A skill is predictable when the agent takes the same *process* every run — not when it produces the same output. The **writing levers** that buy that, the description rules, the model/user-invocation choice, and the Review Checklist are all in [REFERENCE.md](REFERENCE.md).

## Process

1. **Gather requirements** — get an answer to each of: the task or domain and its concrete use cases; a utility script or instructions only; reference material to bundle or point at; model-invoked or user-invoked (REFERENCE.md). Drafting starts once every one is answered.

2. **Place each piece of content on the information hierarchy** (REFERENCE.md) — in-file step, in-file reference, or disclosed reference — by the branch test. Done when every piece has a place.

3. **Draft** `SKILL.md`, plus `REFERENCE.md` / `EXAMPLES.md` / `scripts/` for whatever step 2 put there, applying every writing lever from REFERENCE.md as you write. Done when every lever holds.

4. **Review with the user** — walk the use cases from step 1; done when each is covered and the user has nothing to add.

5. **Verify against the Review Checklist** (REFERENCE.md) — every item is pass/fail; a skill that fails one is not done.

## Skill structure

```text
skill-name/
├── SKILL.md           # required — the process, placed on the information hierarchy
├── REFERENCE.md       # disclosed reference (branch-only content, or sprawl)
├── EXAMPLES.md        # worked examples (same test)
└── scripts/           # utility scripts (deterministic operations)
    └── helper.py
```

`name:` matches the directory.

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
