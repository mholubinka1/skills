# Claude Code Skills

A repository of self-contained agent skills installed to `~/.claude/skills/`. Each skill defines a named workflow that the Claude Code harness invokes when the user types `/<skill-name>`.

## Language

### Skill System

**Skill**:
A named, self-contained unit of agent instructions stored as a directory under `~/.claude/skills/<skill-name>/`. Invoked by the harness when the user types `/<skill-name>`.
_Avoid_: command, tool, plugin, script

**SKILL.md**:
The required entrypoint file for a skill. Contains the skill's frontmatter (`name`, `description`) and step-by-step instructions. The agent reads this file at invocation.
_Avoid_: skill file, main file, entrypoint file

**REFERENCE.md**:
A supplementary file co-located with `SKILL.md`, holding detailed commands, queries, and platform-specific syntax extracted to keep `SKILL.md` concise.
_Avoid_: detail file, command reference, documentation file

**WORKFLOW.md**:
A file used by orchestrating skills (e.g. `implement`) to define a multi-step workflow executed inline in the current conversation rather than delegated to a sub-agent.
_Avoid_: process file, workflow definition

### Workflow Execution

**Step**:
A numbered phase within a skill's workflow, executed in order unless the skill explicitly branches or terminates early.
_Avoid_: phase, stage, action

**Loop** (workflow context):
A defined iteration cycle within a skill's steps, with an explicit termination condition (e.g. "max 10 attempts", "until clean").
_Avoid_: iteration, cycle, repeat

### PR Review Loop

**Review round**:
In `address-copilot-comments`, a counter tracking how many times Copilot has been requested to review a PR. Capped at 2; incrementing past the cap skips re-triggering.
_Avoid_: review iteration, Copilot attempt, pass

**Unresolved thread**:
A PR review comment thread that has not yet been marked resolved via GitHub's `resolveReviewThread` GraphQL mutation.
_Avoid_: open comment, pending thread, active comment

**Push back**:
A decision in the `address-copilot-comments` skill to reject a Copilot comment: reply "Ignored." and resolve the thread without applying a code change.
_Avoid_: reject, dismiss, decline comment

### Agent Docs

**Agent docs**:
The `.agent-docs/` directory containing agent-facing documentation for a repository: `agent.md`, `context.md`, `specs/`, `issues/`, and `adr/`.
_Avoid_: agent documentation, agent directory, .agent-docs folder

**Context** (agent-docs sense):
The domain glossary file (`context.md`) that defines bounded language for a project. Agents read it to use correct terminology.
_Avoid_: glossary, dictionary, vocabulary file

**Spec**:
A PRD-style document written to `.agent-docs/specs/<branch-name>.md` after a grill session, capturing what to build and why before any code is written.
_Avoid_: PRD, requirements document, design document

**Issue** (agent-docs sense):
A vertical-slice work item in `.agent-docs/issues/<branch-name>.md`, derived from a spec and mirrored to GitHub Issues. Tracked with a checklist across the BDD loop.
_Avoid_: task, ticket, story (except in the GitHub Issues sense)

**ADR** (Architecture Decision Record):
A record in `.agent-docs/adr/` documenting a significant design choice and its rationale. Named with a zero-padded numeric prefix (e.g. `0001-decision-name.md`).
_Avoid_: decision log, design decision

### Design and Implementation Process

**Grill**:
A two-axis design session (business angle then engineering angle) that sharpens scope and surfaces constraints before implementation. Produces material for a spec.
_Avoid_: design session, planning session, interview

**Vertical slice**:
A unit of work that delivers end-to-end value, used by `create-issues` to break a spec into independent, shippable issues.
_Avoid_: story, task, feature slice

**BDD loop**:
The red-green-refactor cycle used in the `behaviour-driven-development` skill: write a failing Given-When-Then scenario, implement to pass it, then refactor.
_Avoid_: TDD cycle, test loop, test-first loop

**Pre-commit check**:
Validation run against changed files before a git commit, driven by `.pre-commit-config.yaml` or `.githooks/pre-commit`. Run by the `pre-commit-check` skill after every code change.
_Avoid_: lint check, pre-commit hook run, validation step

**Branch hygiene**:
Validation that the current git branch follows naming conventions (correct type prefix, not a trunk branch, name relevant to the work). Run by the `branch-hygiene` skill.
_Avoid_: branch naming check, branch validation
