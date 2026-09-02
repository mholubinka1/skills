# Skill compliance follow-ups: bdd directory rename + pr-cleanup trigger

## Problem Statement

The `create-a-skill` compliance audit (see the out-of-scope list in
`.agent-docs/specs/chore/improve-create-a-skill.md`) left two skills failing
`create-a-skill`'s own Review Checklist:

- **`behaviour-driven-development/` fails "`name:` matches the directory name".** The skill's
  frontmatter is `name: bdd`, its `WORKFLOW.md` tells the implementation subagent "do not
  re-invoke the `bdd` skill", and `implement/WORKFLOW.md` and `code-review/SKILL.md` both
  call it "the `bdd` skill" — but the directory on disk is `behaviour-driven-development/`.
  The name the rest of the repo uses and the name the sync hook installs it under
  (`sync_claude_skills.py` keys off the directory basename, ignoring `name:`) disagree.
- **`pr-cleanup` fails the description rule "second sentence is 'Use when [triggers]'".** Its
  `description` second sentence is "Invoked automatically by /code-review after the Copilot
  review loop" — a provenance note, not a trigger. An agent scanning descriptions to decide
  which skill to load gets no "use when" signal for it.

## Solution

Two edits, no behaviour change to either skill's steps:

- `git mv behaviour-driven-development bdd` so the directory matches `name: bdd`, and update
  the repo's **live** references to the old path. History-of-record files
  (`.agent-docs/specs/` and `issues/` for already-merged work) keep the old string — they are
  point-in-time records, and rewriting them would falsify history and breach the repo's own
  "Edit outside a declared no-change boundary" review criterion.
- Rewrite `pr-cleanup`'s `description` second sentence as a "Use when" trigger, keeping the
  `/code-review` context.

## User Stories

1. As an agent following `implement/WORKFLOW.md`, I want the `bdd` skill to live in a
   directory called `bdd/`, so the name the workflow invokes and the name the sync hook
   installs resolve to the same skill.
2. As a maintainer running the `create-a-skill` Review Checklist over every skill, I want
   `behaviour-driven-development` — now `bdd` — to pass the "`name:` matches the directory"
   item.
3. As someone reading the glossary, I want `.agent-docs/context.md`'s "red-green-refactor"
   and "implementation subagent" entries to name the `bdd` skill consistently, not mix the
   old directory name with the new skill name in one sentence.
4. As an agent choosing which skill to load, I want `pr-cleanup`'s `description` to tell me
   *when* to reach for it, not just that `/code-review` calls it.
5. As a maintainer, I want the already-merged `bdd-clean-context-impl` and
   `fix-skill-checklist-compliance` spec/issue files left exactly as written, so the record
   of what was done then stays accurate.

## Implementation Decisions

- **Files touched**:
  - `behaviour-driven-development/` → `bdd/` (directory rename via `git mv`; all seven files
    move — `SKILL.md`, `WORKFLOW.md`, `deep-modules.md`, `interface-design.md`,
    `mocking.md`, `refactoring.md`, `tests.md` — contents unchanged).
  - `.agent-docs/context.md` — two glossary entries (the "red-green-refactor" definition and
    the "implementation subagent" definition) change the phrase "the
    `behaviour-driven-development` skill" to "the `bdd` skill".
  - `pr-cleanup/SKILL.md` — frontmatter `description` only.
- **`pr-cleanup` description** — new text:
  `Pre-merge cleanup — check off acceptance criteria in .agent-docs/issues/<branch-name>.md,
  commit to the PR branch, close GitHub issues, and share the PR link for merging. Use when a
  branch has passed review and its PR is ready to merge, or as the final step of /code-review
  after the Copilot review loop.`
  Two sentences; the second starts "Use when" and still records the `/code-review` call site.
- **No `git mv` of the skill's own body needed** — nothing inside `behaviour-driven-development/`
  refers to its own directory path (its self-reference already says "the `bdd` skill").
- **Left unchanged, deliberately**: `.agent-docs/specs/chore/bdd-clean-context-impl.md`,
  `.agent-docs/issues/chore/bdd-clean-context-impl.md`,
  `.agent-docs/specs/chore/fix-skill-checklist-compliance.md`,
  `.agent-docs/issues/chore/fix-skill-checklist-compliance.md`, and the out-of-scope bullet
  in `.agent-docs/specs/chore/improve-create-a-skill.md` — all history-of-record for merged
  PRs.
- **`.claude/settings.local.json`** carries a stale `Read(...behaviour-driven-development/**)`
  permission glob, but that file is untracked (not in git) and local to this machine — out
  of scope for the PR. Updated locally as a courtesy, not committed.
- **No ADR** — a directory rename is reversible, unsurprising, and carries no trade-off with
  live alternatives.
- **Sync hook** — `sync_claude_skills.py` iterates skill directories by basename, so after
  the rename it installs `~/.claude/skills/bdd/`. The old
  `~/.claude/skills/behaviour-driven-development/` copy on a developer's machine is left
  behind by the sync (it only copies, never prunes); harmless, and removable by hand.

## Testing Decisions

- No executable code — a directory rename plus prose edits. No test files; no shell/prose
  test harness in this repo. Consistent with the `uv-support`,
  `sync-hook-interpreter-selection`, `create-worktrees-dependency-bootstrap`, and
  `improve-create-a-skill` slices this session.
- Verification:
  1. `git mv` preserves history — `git log --follow bdd/SKILL.md` shows the pre-rename
     commits.
  2. `grep -rn "behaviour-driven-development"` over the repo returns only the deliberately
     preserved history-of-record files listed above (and nothing under `bdd/`,
     `implement/`, `code-review/`, or the rest of `.agent-docs/context.md`).
  3. `bdd/SKILL.md` frontmatter `name: bdd` now equals the directory basename.
  4. `pr-cleanup/SKILL.md` description is two sentences, second begins "Use when".
  5. `pre-commit run --all-files` passes (markdownlint, markdown-link-check, codespell).
  6. `code-review` Standards + Spec axes.

## Out of Scope

- Any change to the `bdd` or `pr-cleanup` skill *steps* / workflow logic.
- Rewriting merged-work spec/issue files to erase the old directory name.
- The remaining audit items: `address-copilot-comments/SKILL.md` length, and the three empty
  local directories (`document-review/`, `plan-blog-post/`, `three-amigos/`). Separate
  follow-ups.
- Committing a fix to `.claude/settings.local.json` (untracked).

## Further Notes

- Source of the two findings: the compliance audit performed before
  `.agent-docs/specs/chore/improve-create-a-skill.md`, whose "Out of Scope" section names
  both explicitly.
