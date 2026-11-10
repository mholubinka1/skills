# create-a-skill — Reference

The writing levers, the description rules, and the Review Checklist. The process and structure are in [SKILL.md](SKILL.md). The levers are adapted from Matt Pocock's `writing-for-agents` skill.

## Description requirements

The `description` is the agent's main signal when choosing which skill to load — the skill's top-level **context pointer**. It must let the agent know *what capability this is* and *when to trigger it*. These rules govern a **model-invoked** skill's description; a user-invoked skill drops the trigger list and keeps a human-facing one-liner (see *Model- vs user-invoked*).

- Third person; max 1024 chars.
- Exactly two sentences — first: what the skill does; second: "Use when [triggers]".
- Front-load the trigger word — the pointer does its work at the start.
- One trigger per branch. Synonyms that rename a single branch ("create, write, or build a skill") are one branch written three times; keep only genuinely distinct cases.
- Cut identity the body already carries — every word costs on every turn.

Good: `Extracts text and tables from PDF files, fills forms, merges documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.`

Bad: `Helps with documents.` — nothing distinguishes it from other document skills.

## Writing levers

Each lever ends on a check the draft has to pass.

**Context pointer.** A reference that names out-of-context material plus the branches that trigger reaching it; its wording, not its target, sets how reliably it fires.

*Check: from the pointer alone, can a reader name the exact cases that should load the material?*

**The two loads.** A pointer or always-loaded line spends *context load* (tokens every turn); a doc that no pointer names spends *cognitive load* (the human remembering it exists).

*Check: does each line earn the load it spends?*

**Information hierarchy.** Rank material by how soon the agent needs it: in-file step, then in-file reference, then disclosed reference behind a pointer.

*Check: is anything a run always needs behind a pointer it might skip, or any branch-only detail bloating the top?*

**Progressive disclosure.** Move branch-only material out of `SKILL.md` behind a pointer; keep what every branch needs inline — the **branch test**.

*Check: for each disclosed section, do only some branches reach it?*

**Co-location.** A concept's definition, rules, and caveats sit under one heading; a meaning fragmented across headings (scattering) is the failure.

*Check: does reading one part of a concept bring its caveats with it?*

**Completion criteria.** Every step ends on a condition that is *checkable* (done vs not-done) and *exhaustive* ("every X accounted for", not "produce a list"). A fuzzy bound invites premature completion — the step stops early as attention slips to *being done*; sharpen the bound before hiding later steps, and hiding works only across a real context boundary (a hand-off or subagent, not an inline call).

*Check: can the agent tell done from not-done, and does the bound force the whole job?*

**When to split.** Split by sequence — the **sequence test** — when later steps tempt a rush of the current one; split by invocation when a distinct leading word should trigger a part on its own, or another skill must reach it. Past ~150 lines `SKILL.md` is a **sprawl smell** — attention thins across the excess — so look for one of those cuts, or disclose branch-only sections; the line count only says to look.

*Check: does the cut buy more legwork or independent reach than the load it spends?*

**Leading words.** A compact concept already in the model's pretraining (`tracer bullet`, `red`, `fog of war`), repeated as a token and never spelled out; prefer an existing word — a coined one costs the definition tokens a pretrained word gives free.

*Check: is any triad or gesturing sentence begging to collapse into one word — "fast, deterministic, low-overhead" → *tight*?*

**Steer positive.** State the target behaviour (negation steering is the failure); a prohibition drags the banned thing into context and makes it *more* available. Reserve "don't" for a hard guardrail, paired with the positive target.

*Check: does every instruction name what to do rather than what to avoid?*

**Pruning.** One source of truth per meaning — changing behaviour is a one-place edit; a meaning in two places (duplication) or a line the model already obeys by default (a no-op) is the failure; delete the line or use a stronger leading word. The environment (`package.json` scripts, config, `--help`) is a source of truth too: restate it only when the lookup is expensive.

*Check: run the document — did any line change behaviour versus the model's default? Would changing any rule take more than a one-place edit?*

## Model- vs user-invoked

- **Model-invoked** — keeps a `description`, so the agent can fire it autonomously and other skills can reach it. Permanent context load for discoverability. Omit `disable-model-invocation`; write the description to the rules above.
- **User-invoked** — set `disable-model-invocation: true`. Only the human typing its name invokes it; no other skill can. Zero context load, but it spends cognitive load — the human is the index. The `description` becomes a human-facing one-liner with the trigger list stripped.

Pick model-invocation only when the agent or another skill must reach the skill on its own. When user-invoked skills multiply past what the human can remember, add a **router skill** — one user-invoked skill that names the others and when to reach for each.

## When to add scripts

Add a utility script when the operation is deterministic (validation, formatting), the same code would be generated repeatedly, or errors need explicit handling. Scripts save tokens and improve reliability over generated code.

## allowed-tools

Every skill declares `allowed-tools` in its frontmatter as a YAML block list, one entry per line, after `description:`.

- **Pre-approves, never restricts.** The list lets the skill's turn run those tools without a permission prompt; every other tool stays available and prompts as usual.
- **Least privilege.** List exactly the tools the skill's own steps run, plus the commands only its sub-agents run. Every entry traces to a step or a sub-agent handover.
- **Scope Bash.** Write `Bash(<cmd> *)` (which also matches the bare `<cmd>`) or an exact `Bash(<cmd>)`. Every part of a compound command (`a && b`, `$(...)`, pipes) must match an entry, or the call prompts.
- **Never pre-approved.** Unscoped `Bash`, `Bash(*)`, `Bash(git *)`, `git push` with arguments (bare `Bash(git push)` is fine), force pushes, `reset --hard`, `branch -D`, `rm`, `git clean`, `stash pop` and `stash drop`, `>`/`>>` redirects, package installs outside a project virtualenv (`pip install …`), and the project's test command.
- **Path wildcards also match later flags.** `Bash(gh api repos/*)` matches `gh api repos/o/r -X DELETE`; only a call that puts `--method` before the path stays outside it. Likewise `Bash(gh api graphql *)` matches any mutation, not just the skill's own queries. Use a path wildcard only where the skill's own writes are flag-first or acceptable to pre-approve.
- **Path-scoped `Edit(...)` / `Write(...)`** are fine where a skill writes under one tree. If the harness ignores the path scope, the call prompts, which fails safe.

`tests/test_skill_frontmatter.py` enforces a subset: it fails when a skill lacks `allowed-tools`, pre-approves a shell, interpreter, or VCS or package-manager CLI (the test's `UNSCOPED_BASH` list) with a bare `*`, or pre-approves `git push` with arguments, `--force`, `reset --hard`, `branch -D`, `rm`, `git clean`, `stash pop` or `stash drop`. The rest of the never-pre-approved list is checked in review.

## Review Checklist

Every item is pass/fail. A skill that fails one is not done.

### Pointer

- [ ] Description passes every rule in *Description requirements* (third person; ≤ 1024 chars; two sentences; front-loaded trigger word; one trigger per branch; no identity the body carries).

### Hierarchy & disclosure

- [ ] Each step's actions are in `SKILL.md`; the rules and reference a step consults may sit behind a pointer the step names; branch-only material is disclosed, not inline. References are one level deep.
- [ ] `SKILL.md` is not sprawling — see the *When to split* lever.
- [ ] Each concept's definition, rules, and caveats sit under one heading (co-location).

### Completion criteria

- [ ] Every step ends on a criterion that is checkable and exhaustive.

### Leading words & positivity

- [ ] Reaches for a leading word where a triad or phrase repeats.
- [ ] Each meaning has one source of truth (pruning): no line restates another or the environment, and none is a no-op.
- [ ] Steers positive — a "don't …" appears only as a guardrail paired with the positive target.

### General

- [ ] `name:` matches the directory name.
- [ ] Invocation is chosen deliberately: model-invoked only when the agent or another skill must reach it; otherwise `disable-model-invocation: true`.
- [ ] `allowed-tools` lists the least-privilege set — every entry traces to a step or sub-agent; Bash is scoped; nothing destructive.
- [ ] No time-sensitive info; consistent terminology throughout.
- [ ] Concrete examples included.
