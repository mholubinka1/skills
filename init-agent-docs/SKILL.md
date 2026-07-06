---
name: init-agent-docs
description: Bootstraps AI agent documentation in the current repository — creates agent-docs/agent.md with default behavioural standards and ensures CLAUDE.md references it. Idempotent — reports what was created or skipped on each run. Use at the start of any implementation workflow to ensure agent standards are in place before work begins.
---

# init-agent-docs

Bootstraps `agent-docs/agent.md` and a `CLAUDE.md` reference in the current repository.
Safe to run more than once — skips any step where the output already exists.

> **Assumption**: this skill must be invoked from the repository root. It writes paths
> relative to the current working directory.

## Steps

### Step 1 — Check for existing agent.md

Check whether `agent-docs/agent.md` already exists in the current repository.

If it exists:

- Report: "`agent-docs/agent.md` already exists — skipping."
- Skip to Step 3.

If it does not exist, continue to Step 2.

### Step 2 — Create agent-docs/ and write agent.md

Create the `agent-docs/` directory if it does not already exist.

Read the full contents of this skill's `AGENT-TEMPLATE.md` file (located in the same
directory as this `SKILL.md`).

Write those contents verbatim to `agent-docs/agent.md` in the current repository.

If writing fails for any reason (permissions, disk space, etc.):

- Report the error clearly.
- Stop. Do not proceed to Step 3 or Step 4.

If writing succeeds:

- Report: "Created `agent-docs/agent.md`."

### Step 3 — Check CLAUDE.md

Check whether `CLAUDE.md` exists in the current repository root.

Then check whether `CLAUDE.md` (if it exists) contains the string `agent-docs/agent.md`
anywhere in its content.

If `CLAUDE.md` already contains `agent-docs/agent.md`:

- Report: "`CLAUDE.md` already references `agent-docs/agent.md` — skipping."
- Continue to Step 5.

If `CLAUDE.md` does not exist, or exists but does not contain `agent-docs/agent.md`,
continue to Step 4.

### Step 4 — Create or append CLAUDE.md

Append the following content to `CLAUDE.md` (create the file first if it does not exist).
Write only the Markdown content below — do not include the code fence markers:

```markdown

## Agent Standards

See [agent-docs/agent.md](agent-docs/agent.md) for behavioural standards that apply to all AI agent work in this repository.
```

If `CLAUDE.md` did not exist:

- Report: "Created `CLAUDE.md` with Agent Standards reference."

If `CLAUDE.md` existed and was appended to:

- Report: "Appended Agent Standards reference to existing `CLAUDE.md`."

### Step 5 — Summary

Report a brief summary of every action taken and every step skipped with a reason.
Example:

```text
init-agent-docs complete:
  - Created agent-docs/agent.md
  - Created CLAUDE.md with Agent Standards reference
```

Or if nothing needed doing:

```text
init-agent-docs complete (nothing to do):
  - agent-docs/agent.md already exists — skipped
  - CLAUDE.md already references agent-docs/agent.md — skipped
```
