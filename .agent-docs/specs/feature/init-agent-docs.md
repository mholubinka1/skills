# init-agent-docs Skill

## Problem Statement

When an AI agent begins work in a repository, there is no guarantee that any behavioural
standards document exists. Each repository starts blank, meaning the agent has no
documented rules about code quality, testing discipline, git practice, or communication
norms to follow. Standards must be bootstrapped into every new repository before work
begins — currently there is no automated way to do this.

Additionally, even when a standards document exists, `CLAUDE.md` may not reference it,
meaning the agent running in that repository may never load the standards.

## Solution

A new skill, `init-agent-docs`, bootstraps AI agent documentation in any target
repository. It creates `.agent-docs/agent.md` with second-person imperative behavioural
standards (translated from the "Expectations of a Software Developer" source document)
and ensures `CLAUDE.md` references it. The skill is idempotent — it reports what was created or skipped on each run — making it
safe to run as the first step of any implementation workflow.

The `/implement` skill is updated to invoke `init-agent-docs` as its first step, before
`/grill`, so every implementation cycle in every repository begins with standards in
place.

## User Stories

1. As an AI agent beginning work in a fresh repository, I want `.agent-docs/agent.md` to
   exist with behavioural standards, so that I know the rules I am expected to follow
   throughout the work.

2. As a developer, I want `CLAUDE.md` to reference `.agent-docs/agent.md`, so that any
   AI agent loaded in this repository automatically has access to the standards document.

3. As a developer running the skill in a repository that already has `.agent-docs/agent.md`,
   I want the skill to leave it untouched, so that my customised standards are not
   overwritten.

4. As a developer running the skill when `CLAUDE.md` already references
   `.agent-docs/agent.md`, I want no change to be made to `CLAUDE.md`, so that the skill
   is safe to run repeatedly without accumulating duplicate entries.

5. As a developer running the skill when `CLAUDE.md` exists but does not reference
   `.agent-docs/agent.md`, I want the reference appended at the end, so that my existing
   `CLAUDE.md` content is preserved and the standards reference is added cleanly.

6. As a developer, I want the skill to report what it did (or skipped and why), so that I
   can confirm the correct actions were taken each time it runs.

7. As a developer invoking the `/implement` workflow, I want `init-agent-docs` to run
   automatically as the first step, so that standards are always bootstrapped before any
   design or implementation work begins.

## Implementation Decisions

- Two files are created in the skills repo under `init-.agent-docs/`:
  - `SKILL.md` — step-by-step instructions for the agent
  - `AGENT-TEMPLATE.md` — the full content of `agent.md`, kept separate so the template
    can be edited independently of the skill instructions
- `AGENT-TEMPLATE.md` contains all six sections of the "Expectations of a Software
  Developer" document, translated into second-person imperative instructions for an AI
  agent. Nothing is dropped; translation handles the human-to-agent mapping.
- The skill assumes it is invoked from the root of the target repository (documented in
  `SKILL.md`).
- Idempotency rules:
  - If `.agent-docs/agent.md` already exists, skip writing it.
  - If `CLAUDE.md` already contains the string `.agent-docs/agent.md` anywhere, skip
    appending.
- CLAUDE.md reference format when appended:

  ```markdown
  ## Agent Standards

  See [.agent-docs/agent.md](.agent-docs/agent.md) for behavioural standards that apply to
  all AI agent work in this repository.
  ```

- Failure behaviour: if writing `.agent-docs/agent.md` fails, stop and surface the error —
  do not attempt to update `CLAUDE.md`.
- The `/implement` skill (`implement/SKILL.md`) is updated to add `init-agent-docs` as
  Step 0, before the existing Step 1 (`/grill`).

## Testing Decisions

- The single test seam is filesystem output. After the skill runs, inspect that:
  - `.agent-docs/agent.md` exists and contains second-person imperative content covering
    all six sections
  - `CLAUDE.md` contains a reference to `.agent-docs/agent.md`
- BDD scenarios (manual/live verification):
  - **Scenario A**: fresh repo with no `.agent-docs/` — both files created correctly
  - **Scenario B**: repo with existing `.agent-docs/agent.md` — file unchanged, CLAUDE.md
    still updated if needed
  - **Scenario C**: repo where `CLAUDE.md` already references `.agent-docs/agent.md` —
    no changes made
- A live verification step is included in the implementation: run the skill against a
  scratch location (temp directory with a bare git repo) and confirm Scenario A passes
  before the PR is raised.
- No automated test harness required — the skill is a markdown instruction file, not
  executable code.

## Out of Scope

- Updating or merging existing `.agent-docs/agent.md` content — the skill bootstraps only.
- Placing the CLAUDE.md reference at a specific position other than the end of the file.
- Running the skill from a subdirectory (only repo root is supported).
- Any validation or linting of existing `.agent-docs/agent.md` content.
- Adding `init-agent-docs` to any other orchestrator skill beyond `/implement`.

## Further Notes

- The source document ("Expectations of a Software Developer") covers: Ownership &
  Independence, Production Code Quality, Testing Discipline, Source Control & Git
  Practice, Engineering Lifecycle (SDLC), and Communication & Feedback. All six sections
  are translated into AI-agent equivalents in `AGENT-TEMPLATE.md`.
- The skill description frontmatter reflects that it is called from within `/implement`
  rather than invoked manually: "Bootstraps AI agent documentation in the current
  repository — creates .agent-docs/agent.md with default behavioural standards and ensures
  CLAUDE.md references it. Idempotent — reports what was created or skipped on each run.
  Use at the start of any implementation workflow to ensure agent standards are in place
  before work begins."
