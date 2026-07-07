<!-- markdownlint-disable MD024 MD025 -->

# Extend init-agent-docs to bootstrap context.md

## Problem Statement

When an AI agent runs `/implement` in a fresh repository, the `design` skill expects an `.agent-docs/context.md` domain glossary to be present so it can maintain consistent terminology throughout a design session. Currently, `init-agent-docs` only creates `.agent-docs/agent.md` and wires `CLAUDE.md` — it does not bootstrap `context.md`. This means the first design session in any new repo either finds no glossary (so the `design` skill has nothing to update inline) or the user must manually create one, knowing the correct format. This friction defeats the purpose of having a bootstrapping skill.

## Solution

Extend `init-agent-docs` to also bootstrap `.agent-docs/context.md` as part of its standard run. The skill applies a three-strategy ordered approach: skip if the file already exists, move an existing `context.md` found elsewhere in the repo to the canonical location, or create a fresh one from a bundled template. The skill remains fully idempotent — every strategy either no-ops or resolves correctly on repeated runs.

## User Stories

1. As an agent running `init-agent-docs` in a repo that already has `.agent-docs/context.md`, I want the skill to detect it and skip without touching it, so that an existing domain glossary is never overwritten.
2. As an agent running `init-agent-docs` in a repo that has a `context.md` at the root or in `docs/`, I want it moved to `.agent-docs/context.md`, so that the glossary lands in the canonical location without me having to do it manually.
3. As an agent running `init-agent-docs` in a repo with no `context.md` anywhere, I want a well-formed empty glossary created at `.agent-docs/context.md` from the bundled template, so that the `design` skill has a file to update from the first session onward.
4. As an agent running `init-agent-docs` in a repo that has multiple `context.md` files in the search scope, I want the skill to report the ambiguity and ask me to resolve it, rather than silently picking the wrong one.
5. As an agent running `init-agent-docs` when a move operation fails, I want the error reported clearly so I can diagnose it, while the rest of the skill (CLAUDE.md wiring) completes normally.

## Implementation Decisions

- `init-agent-docs/SKILL.md` gains three new steps (Steps 3, 4, 5 in the renumbered sequence) between the existing `agent.md` steps and the `CLAUDE.md` steps.
- A new `init-agent-docs/CONTEXT-TEMPLATE.md` is added alongside `SKILL.md` and `AGENT-TEMPLATE.md`. It contains a `# Project Context` heading, a one-sentence placeholder description, a `## Language` subheading, and one placeholder term entry following the format in `design/CONTEXT-FORMAT.md`.
- **Step 3 — Check for existing context.md**: if `.agent-docs/context.md` exists, report and skip to the CLAUDE.md steps.
- **Step 4 — Search and move**: search root and `docs/` (non-recursively) for any `context.md` file. If exactly one found, move it: Read source → Write to `.agent-docs/context.md` → delete source. If multiple found, report ambiguity with file list, skip this step, and continue. If move fails, report error, skip, and continue.
- **Step 5 — Create from template**: if no `context.md` was found or moved, read `CONTEXT-TEMPLATE.md` from the skill directory and write its contents verbatim to `.agent-docs/context.md`.
- Step numbering in `SKILL.md` shifts: old Steps 3–5 become Steps 6–8. The summary step (last) is updated to include `context.md` outcomes.
- No changes to `CLAUDE.md` wiring logic — `context.md` does not get a `CLAUDE.md` reference.

## Testing Decisions

- The skill is a Markdown instruction file, not executable code. There is no automated test harness.
- BDD scenarios act as the acceptance spec. Each scenario maps to one user story and is verified manually by running the skill in a scratch repository configured to match the scenario's preconditions.
- Four scenarios to cover: (1) `.agent-docs/context.md` exists — skip; (2) `context.md` found at root or `docs/` — moved; (3) multiple `context.md` files found — ambiguity reported; (4) no `context.md` anywhere — created from template.
- The move failure path (story 5) is exercised by making the destination directory read-only in the scratch repo.
- Prior art: the existing `agent.md` creation steps in `SKILL.md` establish the pattern (Read template → Write to target → report).

## Out of Scope

- Recursive search of the full repo for `context.md` — only root and `docs/` are searched.
- Validation of the contents of an existing `.agent-docs/context.md`.
- Adding a `context.md` reference to `CLAUDE.md`.
- Supporting `CONTEXT-MAP.md` multi-context repos in the bootstrap — the template creates a single root glossary only.
- Automated test runner or CI for skill files.

## Further Notes

- The `design` skill finds `.agent-docs/context.md` by convention, not via `CLAUDE.md`. The bootstrapped file gives the `design` skill something to update from the first session; a brand-new repo with only the template in place is a valid starting state.
- The template follows `design/CONTEXT-FORMAT.md` exactly. If that format ever changes, `CONTEXT-TEMPLATE.md` should be updated to match.
- The "search and move" strategy is a convenience for projects that already have a freestanding `context.md` not yet in the canonical location. It is not expected to be the common path.

---

# Add ADR migration step to init-agent-docs

## Problem Statement

The `design` skill records architectural decisions as ADR files under `.agent-docs/adr/`, but `init-agent-docs` has no step to migrate existing ADR files from their old conventional locations (`docs/` or `docs/adr/`) into the canonical `.agent-docs/adr/` directory. Teams that already have ADRs in `docs/adr/` must move them manually before the `design` skill can find and number them correctly. Additionally, `design/ADR-FORMAT.md` currently specifies `.agent-docs/docs/adr/` as the canonical path, which contradicts how the skill actually behaves — this creates confusion for anyone reading the format spec.

## Solution

Add a new step to `init-agent-docs/SKILL.md` that searches `docs/` (root, non-recursively) and `docs/adr/` for files matching the ADR naming convention (`[0-9]*-*.md`) and migrates them to `.agent-docs/adr/`. The step uses git commit date (filesystem mtime fallback) for conflict resolution. After migration, `docs/adr/` is removed if empty. The step is idempotent — on a second run, no source files remain and the step reports "no ADRs found — skipped". Alongside this, `design/ADR-FORMAT.md` is corrected to reference `.agent-docs/adr/` as the canonical path, and an ADR is recorded in the skills repo documenting this path decision.

## User Stories

1. As an agent running `init-agent-docs` in a repo that has ADR files in `docs/adr/`, I want them moved to `.agent-docs/adr/` automatically, so that the `design` skill can find and number them correctly without manual intervention.
2. As an agent running `init-agent-docs` in a repo that has ADR-named files directly in `docs/`, I want them moved to `.agent-docs/adr/` automatically.
3. As an agent running `init-agent-docs` when an ADR already exists at the destination, I want the newer file kept and the older one discarded, so that no work is lost.
4. As an agent running `init-agent-docs` in a repo with no ADR files, I want the step to report "no ADRs found — skipped" and continue, so that the summary is always complete.
5. As a developer reading `design/ADR-FORMAT.md`, I want the canonical ADR path to match reality (`.agent-docs/adr/`), so that I am not confused by the discrepancy with `.agent-docs/docs/adr/`.

## Implementation Decisions

- A new **Step 6** is inserted in `init-agent-docs/SKILL.md` after the context.md steps (Steps 3–5) and before the CLAUDE.md steps (old Steps 6–7).
- Step 6 logic:
  1. Search `docs/` (non-recursively) and `docs/adr/` for files matching `[0-9]*-*.md`.
  2. If none found, report "no ADRs found — skipped" and continue to Step 7.
  3. If any found, create `.agent-docs/adr/` lazily (only now).
  4. For each file: if no conflict, move it (Read → Write to `.agent-docs/adr/<filename>` → delete source). If conflict exists, compare git commit date (fallback to filesystem mtime) — overwrite if source is newer, skip and report if destination is newer.
  5. After all moves, remove `docs/adr/` if it is now empty. Leave `docs/` alone.
- Old Steps 6–8 renumber to Steps 7–9. Summary step renumbers to Step 10.
- `design/ADR-FORMAT.md` is updated: replace `.agent-docs/docs/adr/` with `.agent-docs/adr/` in all three occurrences.
- An ADR (`.agent-docs/adr/0001-adr-canonical-location.md`) is created in the skills repo documenting that `.agent-docs/adr/` is the canonical path (not `.agent-docs/docs/adr/`).

## Testing Decisions

- The skill is a Markdown instruction file with no automated test harness. BDD scenarios are the acceptance spec, verified by running the skill in scratch repos.
- Scenarios to cover: (1) ADRs in `docs/adr/` — moved, `docs/adr/` removed; (2) ADRs in `docs/` root — moved; (3) conflict where destination is newer — source skipped, reported; (4) conflict where source is newer — destination overwritten; (5) no ADRs found — "no ADRs found — skipped" reported.
- Prior art: the context.md move step (Steps 4–5) establishes the Read → Write → delete source pattern.

## Out of Scope

- Recursive search of the full repo for ADR files — only `docs/` and `docs/adr/` are searched.
- Validation of ADR file contents.
- Renumbering ADRs after migration.
- Automated test runner or CI for skill files.

## Further Notes

- The `design` skill creates `.agent-docs/adr/` lazily when it writes the first ADR. The `init-agent-docs` migration step follows the same lazy-creation pattern.
- Git commit date is preferred over filesystem mtime because mtime is reset on clone/checkout and is therefore unreliable for determining which version of a file is "newer" in a meaningful sense.

---

# Rename .agent-docs/ to ..agent-docs/ across all skills

## Problem Statement

The `.agent-docs/` directory created by `init-agent-docs` appears prominently in file browsers and `ls` output, adding visual noise alongside source code directories. Teams using the skills workflow find that `.agent-docs/` looks like a first-class source directory rather than tooling scaffolding. A hidden directory (prefixed with `.`) keeps AI agent documentation accessible to tools but out of casual sight — consistent with the convention used by `.github/`, `.husky/`, and similar tooling directories.

## Solution

Rename `.agent-docs/` to `..agent-docs/` everywhere: physically in the skills repo (via `git mv`), in every skill file that references the path, and in the `init-agent-docs` skill's runtime behaviour. The `init-agent-docs` skill gains a new Step 1 that detects and migrates existing `.agent-docs/` content in target repos to `..agent-docs/`, making the transition safe for repos already using the old layout. The `CLAUDE.md` migration step is updated to replace `.agent-docs/agent.md` references in-place rather than appending a duplicate block.

## User Stories

1. As a developer browsing a repo that uses the skills workflow, I want the AI agent documentation directory to be hidden (`..agent-docs/`), so that it does not clutter my file browser alongside source code.
2. As an agent running `init-agent-docs` in a repo that already has `.agent-docs/` content from a previous run, I want the skill to migrate it to `..agent-docs/` automatically, so that I do not need to intervene manually.
3. As an agent running `init-agent-docs` in a repo where both `.agent-docs/` and `..agent-docs/` exist, I want the skill to prefer `..agent-docs/` and remove the old `.agent-docs/` copies, so that there is only one canonical location.
4. As an agent running `init-agent-docs` in a repo whose `CLAUDE.md` references the old `.agent-docs/agent.md` path, I want the reference updated in-place to `..agent-docs/agent.md`, so that no duplicate block is appended.
5. As a skill author reading any skill file in the skills repo, I want all paths to use `..agent-docs/` consistently, so that there is no confusion about which path convention is current.

## Implementation Decisions

- **Skills repo**: `git mv agent-docs .agent-docs` to rename the directory with git history preserved. Followed by a bulk find-and-replace of `.agent-docs/` → `..agent-docs/` across all `.md` files in the repo.
- **`init-agent-docs/SKILL.md` — new Step 1 (Migration)**:
  - Run before all other steps.
  - For each of `.agent-docs/agent.md`, `.agent-docs/context.md`, `.agent-docs/adr/`:
    - If old path exists and new path (`..agent-docs/...`) does not: move to new path, report.
    - If both exist: prefer `..agent-docs/`, delete old `.agent-docs/` copy, report.
    - If only new path exists (already migrated): do nothing.
  - After migrating files, if `.agent-docs/` directory is empty, remove it.
- **`init-agent-docs/SKILL.md` — CLAUDE.md idempotency check** (Step 8 after renumbering):
  - Check for both `.agent-docs/agent.md` and `..agent-docs/agent.md` in `CLAUDE.md`.
  - If `..agent-docs/agent.md` already present: skip (already up to date).
  - If `.agent-docs/agent.md` present but not `..agent-docs/agent.md`: replace the old string in-place, report "Migrated `CLAUDE.md` reference from `.agent-docs/agent.md` to `..agent-docs/agent.md`."
  - If neither present: append the new block (`..agent-docs/agent.md`), report as before.
- All existing step numbers in `init-agent-docs/SKILL.md` shift up by 1 (old Step 1 → new Step 2, etc.).
- An ADR is recorded in the skills repo documenting the `.agent-docs/` → `..agent-docs/` rename decision (hidden directory convention, hard to reverse, genuine alternative of keeping it visible was rejected).

## Testing Decisions

- BDD scenarios verified by running the skill in scratch repos.
- Scenarios: (1) fresh repo — `..agent-docs/` created correctly; (2) repo with existing `.agent-docs/` — migrated to `..agent-docs/`, old directory removed; (3) repo with both `.agent-docs/` and `..agent-docs/` — old copies removed, new kept; (4) repo whose `CLAUDE.md` has old `.agent-docs/agent.md` reference — replaced in-place, no duplicate block.
- Bulk find-and-replace verified by grepping the skills repo for any remaining `.agent-docs/` references after the change (expect zero).

## Out of Scope

- Migration of any files other than `.agent-docs/agent.md`, `.agent-docs/context.md`, and `.agent-docs/adr/`.
- Updating `CLAUDE.md` files in repos other than the one the skill is currently running in.
- Automated propagation to repos that have already used the old skill and are not re-running `init-agent-docs`.

## Further Notes

- The `..agent-docs/` naming follows the established convention of `.github/`, `.husky/`, `.vscode/` — tooling config hidden from casual browsing but accessible to tools that know to look for it.
- The post-commit sync hook in the skills repo propagates all skill file changes to `~/.claude/skills/` automatically — no manual copy step needed after committing the rename.
- `address-copilot-comments/SKILL.md` already contained one reference to `.agent-docs` (anticipating this rename) — the bulk replace will make all other references in that file consistent.
