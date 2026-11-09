# init-agent-docs — Step Reference

Full detail for each step. The skill overview is in [SKILL.md](SKILL.md).

**Safe move** — every move below follows this one rule: read the source, write the destination, and delete the source only after the write succeeds. If the write fails, report the error and skip that item, keeping the source. If the delete fails, report the error and continue; the destination is already written.

## Step 1 — Migrate existing agent-docs/ layout

Check whether the old `agent-docs/` directory (without the dot prefix) exists. If it does not, skip this step and continue to Step 2.

Otherwise create `.agent-docs/` if it does not exist, then handle each item with a safe move:

| Item | `.agent-docs/` copy absent | `.agent-docs/` copy present |
|---|---|---|
| `agent-docs/agent.md` | Safe-move it to `.agent-docs/agent.md`. Report: "Migrated `agent-docs/agent.md` to `.agent-docs/agent.md`." | Delete `agent-docs/agent.md`. Report: "Removed stale `agent-docs/agent.md` (`.agent-docs/agent.md` already present)." |
| `agent-docs/context.md` | Safe-move it to `.agent-docs/context.md`. Report: "Migrated `agent-docs/context.md` to `.agent-docs/context.md`." | Delete `agent-docs/context.md`. Report: "Removed stale `agent-docs/context.md` (`.agent-docs/context.md` already present)." |
| `agent-docs/adr/` | Create `.agent-docs/adr/`, safe-move each file into it, then remove `agent-docs/adr/` if empty. Report: "Migrated `agent-docs/adr/` to `.agent-docs/adr/`." | Delete all files in `agent-docs/adr/` and remove the directory. Report: "Removed stale `agent-docs/adr/` (`.agent-docs/adr/` already present)." |

An item that is missing from `agent-docs/` needs no action.

Then scan `agent-docs/` for anything other than `agent.md`, `context.md`, `adr/`, and `docs/` (`docs/` holds ADR files that Step 4 migrates). Typical leftovers are `specs/` or `issues/` from an older skill layout. For each leftover, report:

> Warning: `agent-docs/<name>` was not migrated — please move it to `.agent-docs/<name>`
> manually and re-run this skill.

Leave `agent-docs/` in place while anything remains in it. When it is empty, delete it. Continue to Step 2.

## Step 2 — Create agent.md

If `.agent-docs/agent.md` exists, report "`.agent-docs/agent.md` already exists — skipping." and go to Step 3.

Otherwise create `.agent-docs/` if needed, read this skill's `AGENT-TEMPLATE.md` (next to `SKILL.md`), and write it verbatim to `.agent-docs/agent.md`. If the write fails, report the error and stop. Otherwise report "Created `.agent-docs/agent.md`."

## Step 3 — Bootstrap or review context.md

**Find the file.**

1. If `.agent-docs/context.md` exists, report "`.agent-docs/context.md` found — proceeding to review." and take the review sub-path.
2. Otherwise look (non-recursively) for `./context.md` and `docs/context.md`.
   - **Several found**: report the ambiguity, listing each file found, then go to Step 4:

     > Multiple `context.md` files found — unable to determine which to use:
     > - `<path to first match>`
     > - `<path to second match>`
     > - (etc.)
     >
     > Please resolve manually by moving the correct file to `.agent-docs/context.md`, then
     > re-run this skill.

   - **Exactly one found**: safe-move it to `.agent-docs/context.md`; here a failed write **or** a failed delete overrides the safe-move rule: report it and go to Step 4. Report "Moved `<source path>` to `.agent-docs/context.md`." and take the review sub-path.
   - **None found**: take the generate sub-path.

**Generate sub-path.**

1. Read the **Structure** and **Rules** sections of `CONTEXT-FORMAT.md` (alongside this `REFERENCE.md`).
2. Collect candidate terms from `README.md`, `CLAUDE.md`, and the names of top-level files and directories only. Keep a term that appears in at least two of those sources or names a workflow or file convention unique to this repository. A term a new contributor would need to work here qualifies; a general programming concept does not.
3. Write `.agent-docs/context.md` in the `CONTEXT-FORMAT.md` format: a `# {Context Name}` heading using the repository or domain name, a one- or two-sentence description, a `## Language` section giving each term a tight one- or two-sentence definition and an `_Avoid_` line of synonyms to reject, and subheadings where natural clusters emerge. If the write fails, report the error and go to Step 4.
4. Report: "Created `.agent-docs/context.md` from codebase analysis."

**Review sub-path.**

1. Read `CONTEXT-FORMAT.md`, then `.agent-docs/context.md`.
2. Audit the file against the **Structure** and **Rules** sections, applying each rule in turn; read the rules from the file rather than from memory.
3. The file is compliant when it satisfies every rule. A rule it violates is a shortcoming: write the improved file (on a write failure, report the error and go to Step 4) and report "Improved `.agent-docs/context.md` — `<brief summary of changes>`." A compliant file is left as is: report "`.agent-docs/context.md` reviewed — no improvements needed."

Continue to Step 4.

## Step 4 — Migrate ADR files

Search these locations for files matching `[0-9]*-*.md`:

- `docs/` (files directly inside only, not subdirectories)
- `docs/adr/`
- `agent-docs/docs/adr/` (legacy path from an older convention)
- `.agent-docs/docs/adr/` (dotted legacy path that may exist after Step 1)

If none are found, record "no ADRs found — skipped" and continue to Step 5.

Otherwise create `.agent-docs/adr/` if needed and process each match in the order found:

- **No file of that name in `.agent-docs/adr/`**: safe-move it (on a write failure, skip this file and continue with the next). Report: "Moved `<source path>` to `.agent-docs/adr/<filename>`."
- **A file of that name already exists** (conflict): get each file's effective date from `git log -1 --format="%ai" -- <path>`, using the filesystem modification time when the command exits non-zero or prints nothing. Then:
  - Source newer: overwrite the destination with a safe move. Report: "Overwrote `.agent-docs/adr/<filename>` with newer `<source path>`."
  - Destination newer or same age: skip the source. Report: "Skipped `<source path>` — `.agent-docs/adr/<filename>` is already newer."

Afterwards clean up each legacy source directory that is now empty:

- `docs/adr/`: delete it; leave `docs/` itself untouched.
- `agent-docs/docs/adr/`: delete it, then `agent-docs/docs/` and `agent-docs/` if each becomes empty.
- `.agent-docs/docs/adr/`: delete it, then `.agent-docs/docs/` if empty.

Continue to Step 5.

## Step 5 — Create or append CLAUDE.md

Check `CLAUDE.md` in the repository root, in this order:

1. Contains `.agent-docs/agent.md`: report "`CLAUDE.md` already references `.agent-docs/agent.md` — skipping." and go to Step 6.
2. Contains the old path `agent-docs/agent.md`: replace it with `.agent-docs/agent.md` everywhere (link text and target). Report "Migrated `CLAUDE.md` reference from `agent-docs/agent.md` to `.agent-docs/agent.md`." and go to Step 6.
3. Missing, or contains neither path: append the block below, creating the file first if needed. Write only the Markdown content, not the fence markers, with a blank line between existing content and the block.

```markdown
## Agent Standards

See [.agent-docs/agent.md](.agent-docs/agent.md) for behavioural standards that apply to all AI agent work in this repository.
```

Report "Created `CLAUDE.md` with Agent Standards reference." for a new file, or "Appended Agent Standards reference to existing `CLAUDE.md`." otherwise.

## Step 6 — Summary

Report every action taken and every step skipped with a reason, ending with the `Skipped / risk:` line. Example:

```text
init-agent-docs complete:
  - no agent-docs/ layout to migrate — skipped
  - `.agent-docs/agent.md` already exists — skipping.
  - `.agent-docs/context.md` reviewed — no improvements needed.
  - no ADRs found — skipped
  - `CLAUDE.md` already references `.agent-docs/agent.md` — skipping.
Skipped / risk: none
```
