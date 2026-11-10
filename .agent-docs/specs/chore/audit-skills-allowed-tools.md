# Audit skills against writing-for-agents; add least-privilege allowed-tools

## Problem Statement

The 16 skills in this repo drifted from the writing levers in Matt Pocock's `writing-for-agents` skill,
which this repo adapts in `create-a-skill`. An audit of every skill found descriptions that restate
their bodies and compete for the same trigger (`design` vs `implement`), step sequences reachable only
through weak pointers, cross-skill copies that have drifted, negation steering, and steps with no
checkable completion criterion. Each of these adds run-to-run variance.

Only one skill (`pre-commit-check`) declares `allowed-tools`, and that one pre-approves every Bash
command. A skill's `allowed-tools` pre-approves tools for the turn that invokes it. It never restricts
other tools. So the user either gets permission prompts for routine, safe commands or grants
blanket Bash approval. Nothing in `create-a-skill` tells a new skill to declare the field.

## Solution

Every skill gets a least-privilege `allowed-tools` list: the tools its own steps and its sub-agents
run, with Bash scoped to command patterns and nothing destructive pre-approved. Every writing-lever
(W) finding from the audit is fixed in place, with no change to what any skill does. `create-a-skill`
makes `allowed-tools` a standing rule, and a unittest guard stops the convention regressing. The audit
also found behaviour bugs (B) and large restructures (R). These are filed as follow-up GitHub issues,
not fixed here.

## User Stories

1. As a skill user, I want each skill to run its routine, non-destructive commands without a
   permission prompt, so that workflows like `/implement` don't stall on approvals I'd always grant.
2. As a skill user, I want destructive commands (`git push --force`, `reset --hard`, `branch -D`,
   `rm`, `stash pop`) and arbitrary project test commands to keep prompting, so that pre-approval
   never widens into blanket shell access.
3. As a skill user, I want `pre-commit-check` to stop pre-approving every Bash command, so that its
   grant covers only the pre-commit runners and git lookups it uses.
4. As a skill author, I want `create-a-skill`'s template, reference and Review Checklist to require a
   least-privilege `allowed-tools`, so that new and reworked skills keep the convention.
5. As a maintainer, I want a test that fails when a skill lacks `allowed-tools`, has an unscoped
   `Bash`, or pre-approves a destructive pattern, so that the convention can't silently regress.
6. As the agent, I want skill descriptions that front-load their leading word and name each trigger
   branch once, so that I pick the right skill. In particular, a repository change goes to
   `/implement`, not `/design`.
7. As the agent, I want each step to end on a checkable, exhaustive completion criterion, so that I
   don't stop a step early.
8. As the agent, I want each rule stated in one place, positively, so that I don't follow a stale or
   contradictory copy or get pulled toward a banned pattern.
9. As a maintainer, I want every B and R finding tracked as a GitHub issue, so that the deferred work
   isn't lost.

## Implementation Decisions

### allowed-tools convention

- **Form**: a YAML block list under `allowed-tools:` in each `SKILL.md` frontmatter, one entry per
  line. Entries with spaces stay readable.
- **Least privilege**: list exactly the tools the skill's own steps run, **plus** commands only its
  sub-agents run (decision from the design session). The Claude Code docs don't say whether the grant
  reaches sub-agents. Including them bets on inheritance.
- **Bash** is always scoped: `Bash(<cmd> *)` (which also matches the bare `<cmd>`) or an exact
  `Bash(<cmd>)`. Every part of a compound command must match, or the call prompts.
- **Never pre-approved**: unscoped `Bash`, `Bash(*)`, `Bash(git *)`, `git push *` (bare `git push`
  only), force pushes, `reset --hard`, `branch -D`, `rm`, `git clean`, `stash pop`/`drop`, `>`/`>>`
  redirects, package installs outside a project virtualenv (`pip install …`), and the project's test
  command (it varies per repo and runs arbitrary code). A script runner is pinned to its quoted skill
  path, never a free leading wildcard.
- **Path-scoped** `Edit(...)`/`Write(...)` are used where a skill only writes under one tree. If the
  harness ignores them in `allowed-tools`, the call just prompts. That fails safe.
- **Forked skills** (`context: fork`) get the field too. Undocumented whether it applies there; it
  fails safe.
- Lists match each skill's **current** commands. A deferred B fix that changes a command updates its
  list in that follow-up.

| Skill | allowed-tools |
|---|---|
| address-copilot-comments | Read, Grep, Edit, Write, Agent, Skill, `gh --version`, `git branch --show-current`, `gh pr list *`, `gh repo view *`, `gh pr create *`, `gh pr diff *`, `gh pr edit *`, `gh pr view *`, `gh api repos/*`, `gh api graphql *`, `gh gist view *`, `gh gist edit *`, `mktemp *`, `git diff *`, `git add *`, `git commit *`, `git log *`, `git push`, the check-review-status.sh runner, `sleep 60` |
| pr-cleanup | Read, Edit, `git branch --show-current`, `gh pr view *`, `git add .agent-docs/issues/*`, `git commit *`, `git push`, `gh issue close *` |
| pre-commit-check | Read, Glob, `git diff *`, `git ls-files *`, `git symbolic-ref *`, `pre-commit *` and its `.venv/bin`, `.venv/Scripts`, `poetry run`, `uv run` forms, `.githooks/pre-commit *`, `.git/hooks/pre-commit *` (replaces the unscoped `Bash, Read`) |
| branch-hygiene | Read, `git config push.autoSetupRemote`, `git branch --show-current`, `git symbolic-ref *` |
| code-review | Skill, Agent, AskUserQuestion, Read, Grep, Glob, Edit, Write, `git diff *`, `git status *`, `git log *`, `git rev-parse *`, `git symbolic-ref *`, `git merge-base *`, `git branch --show-current`, `git ls-files *`, `gh repo view *`, `gh issue view *`, `gh gist view *`, `gh gist edit *`, `mktemp *` |
| bdd | Skill, Agent, AskUserQuestion, Read, Grep, Glob, Edit, Write, `git diff *`, `git branch --show-current` |
| repo-harden | Read, Glob, Grep, Edit, AskUserQuestion, `gh repo view *`, `gh api repos/*`, `gh api --paginate repos/*`, `gh api users/*`, `gh api orgs/*` (settings writes start `gh api --method …`, so they stay prompted) |
| quiz-the-diff | Read, Grep, Glob, AskUserQuestion, TodoWrite, `gh pr diff *`, `gh pr view *`, `git symbolic-ref *`, `git remote show *`, `git fetch *`, `git diff *` |
| init-agent-docs | Read, Write, Edit, Glob, Grep, `git log -1 *` |
| update-dependencies | Read, Glob, Grep, `git status *`, `git fetch *`, `git pull *`, `git checkout -b *`, `git merge *`, `git diff *`, `git stash push *`, `git add *`, `git commit *`, `git rev-parse *`, `command -v *`, plus each ecosystem's outdated/update/validate commands from its REFERENCE flows, and `pre-commit autoupdate *`/`pre-commit run *` |
| create-worktrees | Read, Glob, Grep, Skill, AskUserQuestion, EnterWorktree, Agent, `git rev-parse --git-dir`, `git worktree list *`, `grep -qxE *`, `echo present`, `echo missing`, `git branch --show-current`, `git add .gitignore`, `git commit -m *`, plus each first-class ecosystem's install command from REFERENCE.md (installer sub-agent) |
| implement | Skill, Read, Glob, ExitWorktree, `git branch --show-current`, `git add *`, `git commit *`, `gh pr view *`, `git rev-parse --show-toplevel` |
| design | AskUserQuestion, Read, Grep, Glob, `Edit(.agent-docs/**)`, `Write(.agent-docs/**)`, `Edit(CONTEXT.md)`, `Write(CONTEXT.md)` (the CONTEXT.md entries go when DES-1 is fixed) |
| write-spec | Read, Grep, Glob, `Write(.agent-docs/specs/**)`, `git branch --show-current` |
| create-issues | Read, Grep, Glob, `Write(.agent-docs/issues/**)`, `Edit(.agent-docs/issues/**)`, Agent, `git branch --show-current`, `gh --version`, `gh issue create *` |
| create-a-skill | Read, Grep, Glob, Write, Edit |

Back-ticked entries are `Bash(...)` patterns. Each skill's final list is checked against the commands
its files actually contain at implementation time. A command found in the skill but missing above is
added if it is non-destructive. An entry above with no matching command is dropped.

### create-a-skill

- The SKILL.md template gains an `allowed-tools:` block.
- REFERENCE.md gains an *allowed-tools* section holding the convention rules above.
- The Review Checklist gains a pass/fail item: "`allowed-tools` lists the least-privilege set: every
  entry traces to a step or sub-agent; Bash is scoped; nothing destructive."

### Writing-lever (W) fixes

Wording and structure only. No skill's commands, step order or outputs change. The IDs refer to the
audit findings. Each fix is as described in the audit.

- **address-copilot-comments**: ACC-3 single routing source (drop line 8 and REFERENCE "Loop
  termination conditions"; "Loop at a glance" one line per step); ACC-4 strip routing/decide text
  from REFERENCE Step 3/4 sections and drop the handover override lines; ACC-5 small-change threshold →
  pointer to code-review Step 5; ACC-6 description rewrite; ACC-7 shrink Step 6 to a pointer and drop
  the stale `<N>` line; ACC-8 **Single review** as the leading word, said once; ACC-9 one positive
  Step 4b trigger line; ACC-10 cut the gh install recipe, the exposition and the maintainer aside.
- **pr-cleanup**: PRC-2 Step 2 done-bound plus a missing-file branch; PRC-3 description trim.
- **pre-commit-check**: PCC-2 scoped allowed-tools; PCC-3 description rewrite.
- **branch-hygiene**: BH-1 two-sentence description; BH-2 define `change_type: unknown` and how
  Step 4 then judges; BH-3 mismatch list in REFERENCE only; BH-4 positive phrasing of "never push or
  commit".
- **code-review**: CR-3 replace the false "never commits" rationale; CR-4 "strictly in sequence"
  once, positive; CR-6 description rewrite; CR-7 delete line 8; CR-8 issue refs via `gh issue view`;
  CR-9 bdd/design hand-off resume rule; CR-11 REVIEW-CRITERIA stale "passed verbatim" plus the duplicated
  skip rule; CR-13 delete CRITERIA-GIST's consumer list.
- **bdd**: BDD-2 positive tracer-bullet framing replaces the banned-pattern block; BDD-3 good/bad
  test prose → pointer to tests.md; BDD-4 narrow description; BDD-5 Three Amigos single home in bdd;
  BDD-7 change_type definitions → pointer to branch-hygiene; BDD-8 one positive commit-ownership
  line; BDD-10 "dispatched as in Step 4"; BDD-11 replace "TDD cycle".
- **repo-harden**: RH-1 co-locate the Visibility-403 exception; RH-4 and RH-5 Step 1 and fix bullets
  → one line plus pointer; RH-6 "go to Step 3"; RH-7 cut author narrative; RH-8 description trim;
  RH-9 "five settings"; RH-10 out-of-scope list in REFERENCE only; RH-11 drop the aside; RH-12
  hosted-runner labels defined once.
- **quiz-the-diff**: QD-1 description; QD-2 fallback → pointer; QD-3 and QD-5 single copies; QD-4
  Teach done-condition; QD-6 and QD-7 TodoWrite item created and carrying examined hunks; QD-8
  delete the pedagogy restatements.
- **init-agent-docs**: IAD-3 **safe move** leading word and a Step 1 table; IAD-5 delete the
  multi-context section and both prohibitions; IAD-6 bounded term-discovery criterion; IAD-7
  exhaustive positive bar; IAD-8 fold the gate-only steps; IAD-9 one summary example; IAD-10
  AGENT-TEMPLATE bans rewritten as positive targets.
- **update-dependencies**: UD-7 description using *dependency update*; UD-8 single source for
  scope, managers and pre-commit commands; UD-9 *best-effort* leading word, "never pushes" once.
- **create-worktrees**: CW-1 resume question via AskUserQuestion with a *Start new* default; CW-4
  one pointer with a real path; CW-5 disclose the install handover and the uncovered-ecosystem flow
  into REFERENCE; CW-6 courtesy-install channel; CW-7 non-interactive default once; CW-8 cut
  branch-hygiene exposition; CW-9 description; CW-10 cut the no-op and the stale hook reference.
- **implement**: IMP-3 description; IMP-4 resumed-worktree cleanup as actions only; IMP-5 delete
  the no-op preamble.
- **design**: DES-2 trigger no longer collides with implement; DES-3 final step hands back to
  /implement or offers it; DES-4 phase completion criteria; DES-5 gate once per phase; DES-6 ADR
  criteria in SKILL only; DES-7 "one at a time" once.
- **write-spec**: WS-1 state the one seam question; WS-2 Step 4 done-condition; WS-3 bounded
  exploration; WS-4 positive phrasing; WS-5 delete the no-op.
- **create-issues**: CI-1 replace the copied Three Amigos block with per-slice GWT criteria drawn
  from the spec; CI-3 Step 3 done-condition; CI-4 description.
- **create-a-skill**: CAS-1 review/rework branch; CAS-2 conditional pointer in the template; CAS-3
  Pruning/co-location/invocation checklist items; CAS-4 merge the duplicate split sections and the
  failure-modes list; CAS-5 the allowed-tools convention above.

Descriptions keep the repo's two-sentence form: what it does, then "Use when …".

## Testing Decisions

- One seam: a new stdlib `unittest` module, `tests/test_skill_frontmatter.py`, alongside
  `tests/test_sync_claude_skills.py` (prior art for style). It discovers every top-level
  `*/SKILL.md`, parses the frontmatter's `allowed-tools` (block list or inline string), and asserts
  behaviour per skill, with the skill named in each failure:
  - `allowed-tools` is present and non-empty;
  - no entry is unscoped `Bash`, `Bash(*)` or `Bash(git *)`;
  - no entry pre-approves a destructive pattern: `git push` followed by anything, `--force`,
    `reset --hard`, `branch -D`, `rm`, `git clean`, `stash pop`, `stash drop`.
- The W prose fixes have no executable seam. They are verified by code-review's Spec axis against the
  list above, plus pre-commit (markdownlint, markdown-link-check, codespell).

## Out of Scope

Filed as follow-up GitHub issues, not changed here:

- **B (behaviour bugs)**: ACC-1 push before `gh pr create`; ACC-2 resolve only Copilot threadIds;
  PRC-1 `**GitHub issue**` field so pr-cleanup closes only slice issues; PRC-4 `$BRANCH` across Bash
  calls; PCC-1 hash-based autofix detection; CR-1 committed-branch "no changes" stop; CR-5
  stop-after-Step-5 branch; CR-10 conditional coverage criterion; CR-12 FIXER rollback snapshot;
  BDD-9 standalone bdd runs pre-commit; RH-2 shell variables across Bash calls; RH-3 conditional
  CONTEXTS fetch; IAD-2 repo-root check; IAD-4 delete failure skips review; UD-1 stash by SHA; UD-2
  no `pip freeze`; UD-3 restore the stash after commit; UD-4 trunk/branch resolution; UD-5 report
  autofixes; UD-6 Yarn 2+; CW-2 `git check-ignore`; CW-3 newline-safe append; IMP-1 tick issues per
  slice; DES-1 glossary path; CI-2 GWT issue template.
- **R (restructures)**: CR-2 disclose the legacy review.md migration; BDD-1 inline bdd's steps; BDD-6
  delete deep-modules.md/interface-design.md in favour of `codebase-design`; IAD-1 inline
  init-agent-docs' steps; IMP-2 inline implement's steps.
- Restricting tools (`disallowed-tools` or custom `agent:` tool sets). `allowed-tools` only
  pre-approves.

## Further Notes

- Source standard: `mattpocock-skills:writing-for-agents` (SKILL.md and SKILL-MECHANICS.md) and
  `create-a-skill/REFERENCE.md`.
- `allowed-tools` semantics come from code.claude.com/docs/en/skills and /permissions: it pre-approves
  for the invoking turn only; `Bash(x *)` matches the bare `x`; every part of a compound command must
  match. Undocumented: inheritance into sub-agents and nested skills, the effect under `context: fork`,
  and path-scoped rules inside `allowed-tools`. Each fails safe.
- During this session `init-agent-docs` rewrote eight glossary entries unprompted. They were reverted
  as out of scope (relates to IAD-6).
