# Issues: feature/init-agent-docs

## Create init-agent-docs skill (AGENT-TEMPLATE.md + SKILL.md)

**Blocked by**: None

**User stories**: 1, 2, 3, 4, 5, 6

### What to build

Create the `init-agent-docs` skill in the skills repo under `init-agent-docs/`. The skill
bootstraps AI agent documentation in any target repository when invoked from its root.

Two files to create:

- `init-agent-docs/AGENT-TEMPLATE.md` — the full content of `agent.md`, containing all
  six sections of the "Expectations of a Software Developer" document translated into
  second-person imperative instructions for an AI agent. Kept separate from SKILL.md so
  the template can be edited independently.
- `init-agent-docs/SKILL.md` — step-by-step instructions for the agent:
  1. Check if `agent-docs/agent.md` already exists; if so skip writing it.
  2. Create `agent-docs/` if it does not exist.
  3. Copy the content of `AGENT-TEMPLATE.md` into `agent-docs/agent.md`.
  4. If writing fails, surface the error and stop — do not proceed to CLAUDE.md.
  5. Check if `CLAUDE.md` already contains the string `agent-docs/agent.md`; if so skip.
  6. If `CLAUDE.md` does not exist, create it. If it exists, append to it.
  7. Append the Agent Standards reference block.
  8. Report each action taken and each step skipped with a reason.

The CLAUDE.md reference block format:

```markdown
## Agent Standards

See [agent-docs/agent.md](agent-docs/agent.md) for behavioural standards that apply to
all AI agent work in this repository.
```

The skill description frontmatter:

```text
Bootstraps AI agent documentation in the current repository — creates agent-docs/agent.md
with default behavioural standards and ensures CLAUDE.md references it. Idempotent and
silent on success. Use at the start of any implementation workflow to ensure agent
standards are in place before work begins.
```

The skill assumes it is always invoked from the repo root (document this in SKILL.md).

### Acceptance criteria

- [ ] `init-agent-docs/AGENT-TEMPLATE.md` exists and covers all six sections (Ownership &
      Independence, Production Code Quality, Testing Discipline, Source Control & Git
      Practice, Engineering Lifecycle (SDLC), Communication & Feedback) in second-person
      imperative language.
- [ ] `init-agent-docs/SKILL.md` exists with a valid frontmatter description and
      step-by-step instructions.
- [ ] Running the skill in a repo with no `agent-docs/` creates `agent-docs/agent.md`
      with the template content.
- [ ] Running the skill when `agent-docs/agent.md` already exists leaves it untouched.
- [ ] Running the skill when `CLAUDE.md` does not exist creates one containing the
      Agent Standards reference block.
- [ ] Running the skill when `CLAUDE.md` exists but does not reference
      `agent-docs/agent.md` appends the reference block at the end.
- [ ] Running the skill when `CLAUDE.md` already references `agent-docs/agent.md` makes
      no changes.
- [ ] The skill reports a summary of actions taken and steps skipped with reasons.
- [ ] Live verification: skill is invoked against a scratch location confirming Scenario A
      (fresh repo) produces the correct output.

---

## Wire init-agent-docs into /implement

**Blocked by**: #1 (Create init-agent-docs skill)

**User stories**: 7

### What to build (issue 2)

Update `implement/SKILL.md` to invoke the `init-agent-docs` skill as Step 0, before the
existing Step 1 (`/grill`). The step should be labelled clearly and noted as a bootstrap
step that runs silently when nothing needs doing.

### Acceptance criteria (issue 2)

- [ ] `implement/SKILL.md` contains a Step 0 that invokes the `init-agent-docs` skill
      before `/grill`.
- [ ] The step is clearly described as a bootstrap step.
- [ ] The existing step numbering is updated consistently (Step 1 becomes Step 1 or
      renumbered as appropriate).

---
