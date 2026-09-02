# create-a-skill — Reference

The writing levers, the description rules, and the review checklist. The process and structure are in [SKILL.md](SKILL.md). The levers are adapted from Matt Pocock's `writing-for-agents` skill.

## Description requirements

The `description` is the only thing the agent sees when choosing which skill to load — it is the skill's top-level **context pointer**. Give the agent enough to know *what capability this is* and *when to trigger it*.

- Third person; max 1024 chars.
- First sentence: what the skill does. Second sentence: "Use when [triggers]".
- **Front-load the trigger word** — the pointer does its work at the start.
- **One trigger per branch.** Synonyms that rename a single branch ("create, write, or build a skill") are one branch written three times — collapse them; keep only genuinely distinct cases.
- **Cut identity the body already carries** — every word costs on every turn.

Good: `Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.`

Bad: `Helps with documents.` — nothing distinguishes it from other document skills.

## Writing levers

**Context pointer.** A reference plus the branches that should trigger reaching it. The wording, not the target, decides how reliably it fires — sharpen a weak pointer before you inline the material it guards.

**The two loads.** Every document or pointer spends one of two budgets: *context load* (always-loaded tokens on the agent's window) or *cognitive load* (the human having to remember the skill exists). Disclosure trades the first for the second.

**Information hierarchy.** Rank material by how immediately the agent needs it: (1) in-file step, (2) in-file reference — a flat peer-set of rules is fine here, (3) disclosed reference behind a pointer. Push too little down and the top bloats; push too much and you hide what the agent needs.

**Progressive disclosure.** The move down the ladder — out of `SKILL.md`, behind a pointer. Branch test: inline what every branch needs, disclose what only some reach.

**Co-location.** Keep a concept's definition, rules, and caveats under one heading, so reading one part brings its neighbours. Scattering fragments one meaning across headings; duplication repeats one meaning in two places — co-location is the fix for scattering.

**Completion criteria.** Every step ends on one. Make it *checkable* (the agent can tell done from not-done) and *exhaustive* ("every model accounted for", not "produce a list"). A fuzzy bound invites premature completion — the step stops early because the visible later steps pull attention to *being done*. Sharpen the bound first; only if it stays fuzzy and you see the rush, hide the later steps by splitting the sequence across a real context boundary (a hand-off or subagent — an inline call clears nothing).

**When to split.** *By sequence* — when later steps tempt the agent to rush the one in front. *By invocation* — when a distinct leading word should trigger part of it on its own, or another skill must reach it. Each split spends a load, so it has to earn it.

**Leading words.** A compact concept already in the model's pretraining (`tracer bullet`, `red`, `fog of war`), repeated as a token and never spelled out as a sentence, anchors a region of behaviour in the fewest tokens. Prefer an existing word — coining your own works only if you define it, and you pay in definition tokens what a pretrained word gives free. Hunt for triads and gesturing sentences that collapse into one: "fast, deterministic, low-overhead" → *tight*.

**Steer positive.** State the target behaviour. A "don't X" drags X into context and makes it *more* available — reserve prohibition for a hard guardrail, and pair it with the positive target so attention lands on what to do.

**Pruning.** One source of truth per meaning — changing behaviour should be a one-place edit. The environment (`package.json` scripts, config, `--help`) is a source of truth too: restate it only when the lookup is expensive — cache the unwritten convention or the reason behind a choice, not the one-command lookup. Check every line for relevance. Hunt no-ops: a line the model already obeys by default; test it by running the document, and delete the whole sentence when it fails. A leading word too weak to beat the default is a no-op too — reach for a stronger word.

## Model- vs user-invoked

- **Model-invoked** — keeps a `description`, so the agent can fire it autonomously and other skills can reach it. Permanent context load in exchange for discoverability. Omit `disable-model-invocation`; write the description to the pointer rules above.
- **User-invoked** — set `disable-model-invocation: true`. Only the human typing its name invokes it; no other skill can. Zero context load, but it spends cognitive load — the human is the index. The `description` becomes a human-facing one-liner with the trigger list stripped.

Pick model-invocation only when the agent or another skill must reach the skill on its own. When user-invoked skills multiply past what the human can remember, add a **router skill** — one user-invoked skill that names the others and when to reach for each.

## When to add scripts

Add a utility script when the operation is deterministic (validation, formatting), the same code would be generated repeatedly, or errors need explicit handling. Scripts save tokens and improve reliability over generated code.

## When to split files

Split `SKILL.md` when a section is reached by only some branches (disclose it), or when a run of steps tempts a rush (split the sequence). Past ~150 lines is a **sprawl smell** — attention thins across the excess — so look for one of those cuts. The branch and sequence tests drive the split; the line count only tells you to look.

## Common failure modes

- **Sprawl** — too long even when every line is live. → Disclose reference behind pointers; split by branch or sequence.
- **Negation steering** — a "don't X" makes X more available. → Prompt the positive target.
- **Duplication** — one meaning in two places; a two-place edit to change behaviour. → Single source of truth.
- **Scattering** — one meaning fragmented across headings. → Co-locate under one heading.
- **No-op** — a line the model already obeys by default. → Delete the sentence, or use a stronger leading word.
- **Premature completion** — a step stops before it is done. → Sharpen the criterion; then split the sequence if the rush persists.

## Review checklist

### Pointer

- [ ] Description is third person, ≤ 1024 chars; first sentence says what it does, second is "Use when …".
- [ ] The trigger word is front-loaded; one trigger per branch (no synonym-branches); no identity the body already carries.

### Hierarchy & disclosure

- [ ] Every-branch material is in `SKILL.md`; branch-only sections are disclosed behind a pointer.
- [ ] `SKILL.md` is not sprawling (~150 lines); references are one level deep.

### Completion criteria

- [ ] Every step ends on a criterion that is both checkable and exhaustive.

### Leading words & positivity

- [ ] Reaches for a leading word where a triad or phrase repeats.
- [ ] Steers positive — a "don't …" appears only as a guardrail paired with the positive target.

### General

- [ ] `name:` matches the directory name.
- [ ] No time-sensitive info; consistent terminology throughout.
- [ ] Concrete examples included.
