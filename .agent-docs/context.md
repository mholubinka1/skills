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

### Skill Distribution

**`sync_claude_skills.py`**:
The standard-library script that walks this repo and copies every directory containing a `SKILL.md` into `~/.claude/skills/`. Invoked by the `sync-claude-skills` hook and by `update-skills`.
_Avoid_: sync script, copier

**`sync-claude-skills` hook**:
The `post-commit` pre-commit hook that runs `sync_claude_skills.py` after every commit in this repo. Fires only on the machine that commits — `update-skills` covers the pull-and-sync path for machines that only consume skills.
_Avoid_: sync hook, post-commit hook

**`update-skills`**:
A command placed on the user's `PATH` by `install.sh` that fast-forwards the local clone to `origin/main`, bootstraps `.venv` and the pre-commit hooks on first run, then runs `sync_claude_skills.py`. Refuses to run on a dirty working tree; never forces or resets. For machines that consume skills rather than develop them.
_Avoid_: updater, refresh script, sync command

**`install.sh`**:
The one-time setup script at the repo root. Adds the repo's `bin/` directory to `PATH` via a marker-delimited block in the user's shell rc file (`~/.zshrc` for zsh, else `~/.bashrc`). Idempotent — re-running drops any existing block(s) and re-appends a single current one.
_Avoid_: installer, bootstrap script

### Workflow Execution

**Step**:
A numbered phase within a skill's workflow, executed in order unless the skill explicitly branches or terminates early.
_Avoid_: phase, stage, action

**Loop** (workflow context):
A defined iteration cycle within a skill's steps, with an explicit termination condition (e.g. "max 10 attempts", "until clean").
_Avoid_: iteration, cycle, repeat

### Isolation

**Worktree session**:
The isolated git worktree (created via the harness's `EnterWorktree` tool under `.claude/worktrees/`) that `/implement` and `/create-worktrees` run inside for the duration of a task, keeping the main checkout untouched.
_Avoid_: sandbox, isolated checkout, workspace

**Placeholder branch**:
A `wip/<slug>` branch created when a worktree session is first entered, before the real branch name is known. Once `branch-hygiene`'s existing mismatch resolution switches to the real branch (confirmed from grill output), `/implement` deletes the now-empty placeholder.
_Avoid_: temp branch, scratch branch

### PR Review Loop

**Review round**:
In `address-copilot-comments`, a counter tracking how many times Copilot has been requested to review a PR. Capped at 2; incrementing past the cap skips re-triggering.
_Avoid_: review iteration, Copilot attempt, pass

**Review-required diff**:
The judgment `address-copilot-comments` Step 2b makes about whether a PR's diff needs an initial Copilot review — based on diff content, not file extension. Functional code changes and skill step-logic edits (commands, decisioning, mutations in `SKILL.md`/`REFERENCE.md`/`WORKFLOW.md`) require review; prose-only documentation, no-logic config, and formatting-only diffs are exempt.
_Avoid_: complex change, non-trivial diff, code change

**Unresolved thread**:
A PR review comment thread that has not yet been marked resolved via GitHub's `resolveReviewThread` GraphQL mutation.
_Avoid_: open comment, pending thread, active comment

**Push back**:
A decision in the `address-copilot-comments` skill to reject a Copilot comment: reply "Ignored." and resolve the thread without applying a code change.
_Avoid_: reject, dismiss, decline comment

**Suppressed comment**:
A Copilot finding folded into the review body's collapsible `### Suppressed comments (N)` markdown block instead of posted as a real Unresolved thread. Has no `databaseId`/thread ID, so it is invisible to thread-count checks and can't be replied-to or resolved individually — `address-copilot-comments` acknowledges these instead with a single PR-level comment.
_Avoid_: hidden comment, collapsed comment, filtered finding

### Agent Docs

**Agent docs**:
The `.agent-docs/` directory containing agent-facing documentation for a repository: `agent.md`, `context.md`, `review.md`, `specs/`, `issues/`, and `adr/`.
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

**Review criteria** (`review.md`):
The `.agent-docs/review.md` file holding review criteria a repository has accumulated from its own Copilot review rounds. `init-agent-docs` bootstraps it from a template; `address-copilot-comments` appends a generalised criterion for each Copilot finding that resulted in a code change (push-backs are never recorded); `code-review` feeds it to its Standards sub-agent as documented repo standards.
_Avoid_: review notes, lessons file, review log

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
Validation driven by `.pre-commit-config.yaml` or `.githooks/pre-commit`, run by the `pre-commit-check` skill after every code change. Runs in two sequential passes: changed files first, then a full-repo pass (`--all-files`) that fixes any drift found repo-wide, even in untouched files.
_Avoid_: lint check, pre-commit hook run, validation step

**Branch hygiene**:
Validation that the current git branch follows naming conventions (correct type prefix, not a trunk branch, name relevant to the work). Run by the `branch-hygiene` skill.
_Avoid_: branch naming check, branch validation

**Dependency update**:
The process of syncing a target repo with `main`/`master` (to absorb changes Dependabot already merged), then bumping patch/minor package versions per detected ecosystem (Python, .NET, Node/TypeScript) and updating pre-commit hook versions, committed locally without pushing. Run by the `update-dependencies` skill against whatever repo is currently open — not specific to this skills repo.
_Avoid_: dependency bump, package update, dependency refresh

**Ecosystem** (dependency update sense):
A language/package-manager combination detected in a target repo via marker files (e.g. `pyproject.toml` → Poetry, `package.json` + lockfile → npm/yarn/pnpm, `*.csproj`/`*.sln` → dotnet/NuGet). A single repo may have more than one.
_Avoid_: stack, toolchain, language target

### Diff Examination

**In-scope diff**:
The portion of a PR's diff the `quiz-the-diff` skill draws questions from — everything left after removing documentation, classified by the purpose of each change rather than by file extension. Out: content that explains the project to a human (`README*`, `CHANGELOG*`, `docs/**`, `.agent-docs/**`, `LICENSE`, `*.rst`, `*.txt`, narrative `.md`) and comment/docstring/prose-only hunks. In: code, config, CI, build scripts, tests, lockfiles, schema, and step-logic edits to agent-instruction files (`SKILL.md`, `REFERENCE.md`, `WORKFLOW.md`, `AGENTS.md`, `CLAUDE.md`, prompt templates). Shares the content-not-extension principle with **Review-required diff**.
_Avoid_: quizzable diff, non-doc diff, testable changes

**Exam loop**:
The `quiz-the-diff` cycle of asking one multiple-choice question, grading it, and — on a wrong answer — re-teaching the missed concept before asking about a different part of the diff. Runs until the reader has ten correct answers, with no attempt cap.
_Avoid_: quiz loop, question loop, test cycle
