---
name: init-agent-docs
description: Bootstraps AI agent documentation in the current repository — creates agent-docs/agent.md with default behavioural standards, bootstraps agent-docs/context.md as a domain glossary, and ensures CLAUDE.md references agent.md. Idempotent — reports what was created or skipped on each run. Use at the start of any implementation workflow to ensure agent standards are in place before work begins.
---

# init-agent-docs

Bootstraps `agent-docs/agent.md`, `agent-docs/context.md`, and a `CLAUDE.md` reference in
the current repository. Safe to run more than once — skips any step where the output already
exists.

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
- Stop. Do not proceed to Step 3, Step 4, or Step 5.

If writing succeeds:

- Report: "Created `agent-docs/agent.md`."

### Step 3 — Check for existing context.md

Check whether `agent-docs/context.md` already exists in the current repository.

If it exists:

- Report: "`agent-docs/context.md` already exists — skipping."
- Skip to Step 6.

If it does not exist, continue to Step 4.

### Step 4 — Search for context.md to move

Search the following locations (non-recursively) for a file named `context.md`:

- Repository root (`./context.md`)
- `docs/context.md`
- `agent-docs/context.md` (already checked above — will not be present at this point)

Collect all matches found.

**If multiple files are found:**

- Report the ambiguity:

  > Multiple `context.md` files found — unable to determine which to use:
  > - `./context.md`
  > - `docs/context.md`
  >
  > Please resolve manually by moving the correct file to `agent-docs/context.md`, then
  > re-run this skill.

- Skip to Step 6.

**If exactly one file is found**, move it to `agent-docs/context.md`:

1. Read the contents of the source file.
2. Write those contents verbatim to `agent-docs/context.md`.
3. Delete the source file.

If the write or delete fails for any reason:

- Report the error clearly.
- Skip to Step 6.

If the move succeeds:

- Report: "Moved `<source path>` to `agent-docs/context.md`."
- Skip to Step 6.

**If no files are found**, continue to Step 5.

### Step 5 — Create context.md from template

Read the full contents of this skill's `CONTEXT-TEMPLATE.md` file (located in the same
directory as this `SKILL.md`).

Write those contents verbatim to `agent-docs/context.md` in the current repository.

If writing fails for any reason (permissions, disk space, etc.):

- Report the error clearly.
- Skip to Step 6.

If writing succeeds:

- Report: "Created `agent-docs/context.md` from template."

### Step 6 — Check CLAUDE.md

Check whether `CLAUDE.md` exists in the current repository root.

Then check whether `CLAUDE.md` (if it exists) contains the string `agent-docs/agent.md`
anywhere in its content.

If `CLAUDE.md` already contains `agent-docs/agent.md`:

- Report: "`CLAUDE.md` already references `agent-docs/agent.md` — skipping."
- Continue to Step 8.

If `CLAUDE.md` does not exist, or exists but does not contain `agent-docs/agent.md`,
continue to Step 7.

### Step 7 — Create or append CLAUDE.md

Append the following content to `CLAUDE.md` (create the file first if it does not exist).
Write only the Markdown content below — do not include the code fence markers. When
appending to an existing file, ensure there is a blank line between the existing content
and the block (add one if the file does not already end with a newline):

```markdown
## Agent Standards

See [agent-docs/agent.md](agent-docs/agent.md) for behavioural standards that apply to all AI agent work in this repository.
```

If `CLAUDE.md` did not exist:

- Report: "Created `CLAUDE.md` with Agent Standards reference."

If `CLAUDE.md` existed and was appended to:

- Report: "Appended Agent Standards reference to existing `CLAUDE.md`."

### Step 8 — Summary

Report a brief summary of every action taken and every step skipped with a reason.
Example:

```text
init-agent-docs complete:
  - Created agent-docs/agent.md
  - Created agent-docs/context.md from template
  - Created CLAUDE.md with Agent Standards reference
```

Or if nothing needed doing:

```text
init-agent-docs complete (nothing to do):
  - agent-docs/agent.md already exists — skipped
  - agent-docs/context.md already exists — skipped
  - CLAUDE.md already references agent-docs/agent.md — skipped
```
