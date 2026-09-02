# init-agent-docs — Step Reference

Full detail for each step. The skill overview is in [SKILL.md](SKILL.md).

## Step 1 — Migrate existing agent-docs/ layout

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
covered by the three items above (i.e. anything other than `agent.md`, `context.md`, `adr/`,
and `docs/`). Do **not** warn about `docs/` — any ADR files inside `agent-docs/docs/adr/`
will be migrated by Step 8. Common examples of items that do warrant a warning include
`specs/`, `issues/`, or other subdirectories from an older skill layout.

If any such files or directories remain:

- Report each one:
  > Warning: `agent-docs/<name>` was not migrated — please move it to `.agent-docs/<name>`
  > manually and re-run this skill.
- Do **not** delete the `agent-docs/` directory (it is not empty and contains unmigrated
  content). Do **not** attempt automatic migration of unknown items.
- Continue to Step 2.

If no unexpected files or directories remain and `agent-docs/` is now empty, delete it.

Continue to Step 2.

## Step 2 — Check for existing agent.md

Check whether `.agent-docs/agent.md` already exists in the current repository.

If it exists:

- Report: "`.agent-docs/agent.md` already exists — skipping."
- Skip to Step 4.

If it does not exist, continue to Step 3.

## Step 3 — Create .agent-docs/ and write agent.md

Create the `.agent-docs/` directory if it does not already exist.

Read the full contents of this skill's `AGENT-TEMPLATE.md` file (located in the same
directory as this `SKILL.md`).

Write those contents verbatim to `.agent-docs/agent.md` in the current repository.

If writing fails for any reason (permissions, disk space, etc.):

- Report the error clearly.
- Stop. Do not proceed to any further steps.

If writing succeeds:

- Report: "Created `.agent-docs/agent.md`."

## Step 4 — Check for existing context.md

Check whether `.agent-docs/context.md` already exists in the current repository.

If it exists:

- Report: "`.agent-docs/context.md` found — proceeding to review."
- Continue to Step 6 (review sub-path).

If it does not exist, continue to Step 5.

## Step 5 — Search for context.md to move

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
- Continue to Step 6 (review sub-path).

**If no files are found**, continue to Step 6.

## Step 6 — Bootstrap or review context.md

This step has two sub-paths depending on whether a `context.md` was found in Steps 4–5.

### Generate sub-path (no context.md found after Steps 4–5)

1. Read the **Structure** and **Rules** sections of `CONTEXT-FORMAT.md` from this skill's
   directory (alongside this `REFERENCE.md`). Do not apply the "Single vs multi-context
   repos" section — this skill always bootstraps a single-context `.agent-docs/context.md`.
2. Read the codebase to identify domain-specific concepts — the terminology, workflow names,
   file conventions, and concepts unique to this repository. Focus on terms that a new
   contributor would need to understand to work in this codebase, not general programming
   concepts.
3. Write a full `context.md` to `.agent-docs/context.md` following the format defined in
   `CONTEXT-FORMAT.md`:
   - A `# {Context Name}` heading using the repository name or domain name.
   - A one- or two-sentence description of what the context is and why it exists.
   - A `## Language` section listing all domain-specific terms found, each with a tight
     one- or two-sentence definition and an `_Avoid_` line listing synonyms to reject.
   - Subheadings grouping terms when natural clusters emerge.

   If writing fails for any reason, report the error clearly and skip to Step 7.

4. Report: "Created `.agent-docs/context.md` from codebase analysis."

### Review and improve sub-path (context.md exists or was just moved)

1. Read `CONTEXT-FORMAT.md` from this skill's directory.
2. Read the existing `.agent-docs/context.md`.
3. Audit the file against the **Structure** and **Rules** sections of `CONTEXT-FORMAT.md`
   (the single-context format). Apply each rule in turn and identify any shortcomings — do
   not rely on memory; read the rules from the file. Do not apply the "Single vs multi-context
   repos" section — this skill always bootstraps a single-context `context.md`.
4. If shortcomings are found:
   - Write the improved file to `.agent-docs/context.md`.
     If writing fails, report the error clearly and skip to Step 7.
   - Report: "Improved `.agent-docs/context.md` — `<brief summary of changes>`."
5. If no shortcomings are found:
   - Report: "`.agent-docs/context.md` reviewed — no improvements needed."
   - Continue to Step 7 without writing.

## Step 7 — Bootstrap review.md

`.agent-docs/review.md` holds review criteria this repository has accumulated from its own
Copilot review rounds. It is written to by the `address-copilot-comments` skill (one
generalised criterion per Copilot finding that resulted in a code change; push-backs are
never recorded) and read by the `code-review` skill's Standards sub-agent as documented repo
standards. This step only ensures the file exists — it never edits an existing one.

Check whether `.agent-docs/review.md` already exists in the current repository.

If it exists:

- Report: "`.agent-docs/review.md` already exists — skipping."
- Continue to Step 8.

If it does not exist:

1. Create the `.agent-docs/` directory if it does not already exist.
2. Read the full contents of this skill's `REVIEW-TEMPLATE.md` file (located in the same
   directory as this `REFERENCE.md`).
3. Write those contents verbatim to `.agent-docs/review.md`.
   - If the write fails, report the error clearly and continue to Step 8 — a missing
     `review.md` does not block the rest of the bootstrap.
4. Report: "Created `.agent-docs/review.md`."

Unlike `context.md`, there is no search-for-a-file-to-move sub-path and no
review-and-improve sub-path: the file is machine-maintained, so an existing one is left
exactly as found.

## Step 8 — Migrate ADR files

Search the following locations for files matching the ADR naming convention (`[0-9]*-*.md`):

- `docs/` (non-recursively — files directly inside `docs/` only, not subdirectories)
- `docs/adr/` (all `.md` files matching the pattern)
- `agent-docs/docs/adr/` (all `.md` files matching the pattern — legacy path from older convention)
- `.agent-docs/docs/adr/` (all `.md` files matching the pattern — dotted legacy path that may exist after Step 1 migration)

Collect all matches found across all four locations.

**If no matching files are found:**

- Record "no ADRs found — skipped" for the summary.
- Continue to Step 9.

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
     1. Determine the effective date of the source file: run `git log -1 --format="%ai" -- <source path>`. If the command exits non-zero or the output is empty (file is untracked or unknown to git), use the filesystem modification time instead.
     2. Determine the effective date of the destination file: run `git log -1 --format="%ai" -- .agent-docs/adr/<filename>`. If the command exits non-zero or the output is empty, use the filesystem modification time instead.
     3. Compare the two dates:
        - **Source is newer**: overwrite the destination. Read source → Write to `.agent-docs/adr/<filename>` → delete source. Report: "Overwrote `.agent-docs/adr/<filename>` with newer `<source path>`."
        - **Destination is newer or same age**: skip the source file. Report: "Skipped `<source path>` — `.agent-docs/adr/<filename>` is already newer."
3. After processing all files, clean up each legacy source directory if it is now empty:
   - If `docs/adr/` exists and is empty, delete it. Do **not** delete or modify `docs/` itself.
   - If `agent-docs/docs/adr/` exists and is empty, delete it. If `agent-docs/docs/` is then empty, delete it too. If `agent-docs/` is then empty, delete it too.
   - If `.agent-docs/docs/adr/` exists and is empty, delete it. If `.agent-docs/docs/` is then empty, delete it too.

Continue to Step 9.

## Step 9 — Check CLAUDE.md

Check whether `CLAUDE.md` exists in the current repository root.

Check the content of `CLAUDE.md` (if it exists) for the following strings, in this order:

1. **If `CLAUDE.md` contains `.agent-docs/agent.md`** (new path, with dot):
   - Report: "`CLAUDE.md` already references `.agent-docs/agent.md` — skipping."
   - Continue to Step 11.

2. **If `CLAUDE.md` contains `agent-docs/agent.md`** (old path, without dot):
   - Replace the old path string `agent-docs/agent.md` with `.agent-docs/agent.md` everywhere
     it appears in `CLAUDE.md`. This includes both the link text and the link target.
   - Report: "Migrated `CLAUDE.md` reference from `agent-docs/agent.md` to `.agent-docs/agent.md`."
   - Continue to Step 11.

3. **If `CLAUDE.md` does not exist, or exists but contains neither path**:
   - Continue to Step 10.

## Step 10 — Create or append CLAUDE.md

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

## Step 11 — Summary

Report a brief summary of every action taken and every step skipped with a reason.
Example (fresh repo with no prior agent docs):

```text
init-agent-docs complete:
  - no agent-docs/ layout to migrate — skipped
  - Created `.agent-docs/agent.md`.
  - Created `.agent-docs/context.md` from codebase analysis.
  - Created `.agent-docs/review.md`.
  - no ADRs found — skipped
  - Created `CLAUDE.md` with Agent Standards reference.
```

Example (existing repo where context.md needed improvement):

```text
init-agent-docs complete:
  - no agent-docs/ layout to migrate — skipped
  - `.agent-docs/agent.md` already exists — skipping.
  - `.agent-docs/context.md` found — proceeding to review.
  - Improved `.agent-docs/context.md` — tightened 2 definitions, added avoid-lists for 3 terms.
  - Created `.agent-docs/review.md`.
  - no ADRs found — skipped
  - `CLAUDE.md` already references `.agent-docs/agent.md` — skipping.
```

Or if nothing needed doing:

```text
init-agent-docs complete (nothing to do):
  - no agent-docs/ layout to migrate — skipped
  - `.agent-docs/agent.md` already exists — skipping.
  - `.agent-docs/context.md` reviewed — no improvements needed.
  - `.agent-docs/review.md` already exists — skipping.
  - no ADRs found — skipped
  - `CLAUDE.md` already references `.agent-docs/agent.md` — skipping.
```
