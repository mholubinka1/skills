---
name: init-agent-docs
description: Bootstraps AI agent documentation in the current repository — migrates any legacy agent-docs/ layout to .agent-docs/, creates .agent-docs/agent.md with default behavioural standards, bootstraps .agent-docs/context.md as a domain glossary, migrates existing ADR files from docs/ to .agent-docs/adr/, and ensures CLAUDE.md references .agent-docs/agent.md. Idempotent — reports what was created, migrated, or skipped on each run. Use at the start of any implementation workflow to ensure agent standards are in place before work begins.
---

# init-agent-docs

Bootstraps `.agent-docs/agent.md`, `.agent-docs/context.md`, and a `CLAUDE.md` reference in
the current repository. Safe to run more than once — skips any step where the output already
exists.

> **Assumption**: this skill must be invoked from the repository root. It writes paths
> relative to the current working directory.

## Steps

### Step 1 — Migrate existing agent-docs/ layout

Check whether the old `agent-docs/` directory (without the dot prefix) exists in the
current repository. If it does not exist at all, skip this step entirely and continue to
Step 2.

If `agent-docs/` exists, migrate its contents to `.agent-docs/` as follows.

First, create the `.agent-docs/` directory if it does not already exist.

Then handle each of the three items below in order:

**`agent-docs/agent.md`:**

- If `agent-docs/agent.md` exists and `.agent-docs/agent.md` does **not** exist:
  Move it: Read source → Write to `.agent-docs/agent.md`.
  - If the write fails, report the error clearly and skip to the next item. Do **not** delete the source file.
  Delete `agent-docs/agent.md` only after the write succeeds.
  - If the delete fails, report the error clearly and continue. The destination file has been written.
  Report: "Migrated `agent-docs/agent.md` to `.agent-docs/agent.md`."
- If both `agent-docs/agent.md` and `.agent-docs/agent.md` exist:
  Delete `agent-docs/agent.md` (the `.agent-docs/` version is preferred).
  Report: "Removed stale `agent-docs/agent.md` (`.agent-docs/agent.md` already present)."
- If only `.agent-docs/agent.md` exists, or neither exists: do nothing for this item.

**`agent-docs/context.md`:**

- If `agent-docs/context.md` exists and `.agent-docs/context.md` does **not** exist:
  Move it: Read source → Write to `.agent-docs/context.md`.
  - If the write fails, report the error clearly and skip to the next item. Do **not** delete the source file.
  Delete `agent-docs/context.md` only after the write succeeds.
  - If the delete fails, report the error clearly and continue. The destination file has been written.
  Report: "Migrated `agent-docs/context.md` to `.agent-docs/context.md`."
- If both `agent-docs/context.md` and `.agent-docs/context.md` exist:
  Delete `agent-docs/context.md`.
  Report: "Removed stale `agent-docs/context.md` (`.agent-docs/context.md` already present)."
- If only `.agent-docs/context.md` exists, or neither exists: do nothing for this item.

**`agent-docs/adr/` (directory):**

- If `agent-docs/adr/` exists and `.agent-docs/adr/` does **not** exist:
  Move the entire directory: create `.agent-docs/adr/`, then for each file in `agent-docs/adr/`:
  1. Read the source file.
  2. Write to `.agent-docs/adr/<filename>`. If the write fails, report the error clearly and skip this file. Do **not** delete the source file.
  3. Delete the source file only after the write succeeds. If the delete fails, report the error clearly and continue.
  After processing all files, if `agent-docs/adr/` is now empty, remove it.
  Report: "Migrated `agent-docs/adr/` to `.agent-docs/adr/`."
- If both `agent-docs/adr/` and `.agent-docs/adr/` exist:
  Delete all files in `agent-docs/adr/` and remove the directory.
  Report: "Removed stale `agent-docs/adr/` (`.agent-docs/adr/` already present)."
- If only `.agent-docs/adr/` exists, or neither exists: do nothing for this item.

**After handling all three items:**

Scan the `agent-docs/` directory for any remaining files or subdirectories that were not
covered by the three items above (i.e. anything other than `agent.md`, `context.md`, and
`adr/`). Common examples include `specs/`, `issues/`, or other subdirectories from an
older skill layout.

If any such files or directories remain:

- Report each one:
  > Warning: `agent-docs/<name>` was not migrated — please move it to `.agent-docs/<name>`
  > manually and re-run this skill.
- Do **not** delete the `agent-docs/` directory (it is not empty and contains unmigrated
  content). Do **not** attempt automatic migration of unknown items.
- Continue to Step 2.

If no unexpected files or directories remain and `agent-docs/` is now empty, delete it.

Continue to Step 2.

### Step 2 — Check for existing agent.md

Check whether `.agent-docs/agent.md` already exists in the current repository.

If it exists:

- Report: "`.agent-docs/agent.md` already exists — skipping."
- Skip to Step 4.

If it does not exist, continue to Step 3.

### Step 3 — Create .agent-docs/ and write agent.md

Create the `.agent-docs/` directory if it does not already exist.

Read the full contents of this skill's `AGENT-TEMPLATE.md` file (located in the same
directory as this `SKILL.md`).

Write those contents verbatim to `.agent-docs/agent.md` in the current repository.

If writing fails for any reason (permissions, disk space, etc.):

- Report the error clearly.
- Stop. Do not proceed to any further steps.

If writing succeeds:

- Report: "Created `.agent-docs/agent.md`."

### Step 4 — Check for existing context.md

Check whether `.agent-docs/context.md` already exists in the current repository.

If it exists:

- Report: "`.agent-docs/context.md` already exists — skipping."
- Skip to Step 7 (ADR migration still runs).

If it does not exist, continue to Step 5.

### Step 5 — Search for context.md to move

Search the following locations (non-recursively) for a file named `context.md`:

- Repository root (`./context.md`)
- `docs/context.md`

Collect all matches found.

**If multiple files are found:**

- Report the ambiguity, listing each file actually found:

  > Multiple `context.md` files found — unable to determine which to use:
  > - `<path to first match>`
  > - `<path to second match>`
  > - (etc.)
  >
  > Please resolve manually by moving the correct file to `.agent-docs/context.md`, then
  > re-run this skill.

- Skip to Step 7.

**If exactly one file is found**, move it to `.agent-docs/context.md`:

1. Read the contents of the source file.
2. Write those contents verbatim to `.agent-docs/context.md`.
   - If the write fails, report the error clearly and skip to Step 7. Do **not** delete the source file.
3. Delete the source file only after the write succeeds.
   - If the delete fails, report the error clearly and skip to Step 7. The destination file has already been written.

If both steps succeed:

- Report: "Moved `<source path>` to `.agent-docs/context.md`."
- Skip to Step 7.

**If no files are found**, continue to Step 6.

### Step 6 — Create context.md from template

Read the full contents of this skill's `CONTEXT-TEMPLATE.md` file (located in the same
directory as this `SKILL.md`).

Write those contents verbatim to `.agent-docs/context.md` in the current repository.

If writing fails for any reason (permissions, disk space, etc.):

- Report the error clearly.
- Skip to Step 7.

If writing succeeds:

- Report: "Created `.agent-docs/context.md` from template."

### Step 7 — Migrate ADR files

Search the following locations for files matching the ADR naming convention (`[0-9]*-*.md`):

- `docs/` (non-recursively — files directly inside `docs/` only, not subdirectories)
- `docs/adr/` (all `.md` files matching the pattern)

Collect all matches found across both locations.

**If no matching files are found:**

- Record "no ADRs found — skipped" for the summary.
- Continue to Step 8.

**If matching files are found:**

1. Create the `.agent-docs/adr/` directory if it does not already exist.
2. For each matched file, in the order found:
   - **If no file with the same name exists at `.agent-docs/adr/<filename>`:**
     1. Read the source file contents.
     2. Write those contents verbatim to `.agent-docs/adr/<filename>`.
        - If the write fails, report the error clearly and skip this file. Continue with the next file.
     3. Delete the source file only after the write succeeds.
        - If the delete fails, report the error clearly and continue. The destination file has been written.
     4. Report: "Moved `<source path>` to `.agent-docs/adr/<filename>`."
   - **If a file with the same name already exists at `.agent-docs/adr/<filename>`** (conflict):
     1. Determine the effective date of the source file: run `git log -1 --format="%ai" -- <source path>`. If the output is empty (file is untracked), use the filesystem modification time instead.
     2. Determine the effective date of the destination file: run `git log -1 --format="%ai" -- .agent-docs/adr/<filename>`. If the output is empty, use the filesystem modification time.
     3. Compare the two dates:
        - **Source is newer**: overwrite the destination. Read source → Write to `.agent-docs/adr/<filename>` → delete source. Report: "Overwrote `.agent-docs/adr/<filename>` with newer `<source path>`."
        - **Destination is newer or same age**: skip the source file. Report: "Skipped `<source path>` — `.agent-docs/adr/<filename>` is already newer."
3. After processing all files, check whether the `docs/adr/` directory exists and is now empty. If it is empty, delete the `docs/adr/` directory. Do **not** delete or modify `docs/` itself.

Continue to Step 8.

### Step 8 — Check CLAUDE.md

Check whether `CLAUDE.md` exists in the current repository root.

Check the content of `CLAUDE.md` (if it exists) for the following strings, in this order:

1. **If `CLAUDE.md` contains `.agent-docs/agent.md`** (new path, with dot):
   - Report: "`CLAUDE.md` already references `.agent-docs/agent.md` — skipping."
   - Continue to Step 10.

2. **If `CLAUDE.md` contains `agent-docs/agent.md`** (old path, without dot):
   - Replace the old path string `agent-docs/agent.md` with `.agent-docs/agent.md` everywhere
     it appears in `CLAUDE.md`. This includes both the link text and the link target.
   - Report: "Migrated `CLAUDE.md` reference from `agent-docs/agent.md` to `.agent-docs/agent.md`."
   - Continue to Step 10.

3. **If `CLAUDE.md` does not exist, or exists but contains neither path**:
   - Continue to Step 9.

### Step 9 — Create or append CLAUDE.md

Append the following content to `CLAUDE.md` (create the file first if it does not exist).
Write only the Markdown content below — do not include the code fence markers. When
appending to an existing file, ensure there is a blank line between the existing content
and the block (add one if the file does not already end with a newline):

```markdown
## Agent Standards

See [.agent-docs/agent.md](.agent-docs/agent.md) for behavioural standards that apply to all AI agent work in this repository.
```

If `CLAUDE.md` did not exist:

- Report: "Created `CLAUDE.md` with Agent Standards reference."

If `CLAUDE.md` existed and was appended to:

- Report: "Appended Agent Standards reference to existing `CLAUDE.md`."

### Step 10 — Summary

Report a brief summary of every action taken and every step skipped with a reason.
Example (fresh repo with a legacy agent-docs/ layout to migrate):

```text
init-agent-docs complete:
  - Migrated agent-docs/agent.md to .agent-docs/agent.md
  - Migrated agent-docs/context.md to .agent-docs/context.md
  - .agent-docs/agent.md already exists — skipped
  - .agent-docs/context.md already exists — skipped
  - no ADRs found — skipped
  - Migrated CLAUDE.md reference from agent-docs/agent.md to .agent-docs/agent.md
```

Or if nothing needed doing:

```text
init-agent-docs complete (nothing to do):
  - no agent-docs/ layout to migrate — skipped
  - .agent-docs/agent.md already exists — skipped
  - .agent-docs/context.md already exists — skipped
  - no ADRs found — skipped
  - CLAUDE.md already references .agent-docs/agent.md — skipped
```
