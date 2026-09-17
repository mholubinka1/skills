# Issues: feature/repo-harden

## Add repo-harden skill (#107)

**Blocked by**: None

**User stories**: 1, 2, 3, 4, 5, 6, 7

### What to build

A new standalone skill, `repo-harden` (`repo-harden/SKILL.md` + `repo-harden/REFERENCE.md`),
authored by running the `create-a-skill` skill. It audits the current repo's CI/CD trust
boundary in a read-only pass, then applies only the fixes the user explicitly selects.

- **Scope**: always the current repo (`gh repo view`, no `-R`/owner-repo argument), mirroring
  `update-dependencies`' existing "whatever repo is currently open" convention.
- **Read-only phase** — every check below produces one line in a full report that always
  prints, pass or flagged, never a findings-only summary:
  - Repo visibility (`gh repo view --json visibility`) and collaborator list/permissions.
  - Every workflow's `on:` trigger crossed against each job's `runs-on:`, done by the agent
    reading each workflow file directly and reasoning per job (no `yq`/parsing script,
    matching this repo's pure-instructions convention) — flag any self-hosted or
    custom-label runner reachable by `pull_request`, `pull_request_target`, or an unscoped
    `push: branches: ['**']` as a **Reachable self-hosted job** finding.
  - `dependabot.yml`/equivalent bot configs: do the branches they open land in-repo (not a
    fork) and match a build-triggering pattern.
  - Actions pinning: any `uses:` on a mutable tag/branch instead of a full commit SHA is a
    **Finding**; also report whether `sha_pinning_required` is set org/repo-wide.
  - Branch protection on the default branch: required status checks, PR requirement,
    force-push/delete restrictions, admin enforcement.
  - Secrets exposure: jobs with runner-level or self-hosted access that also have secrets in
    scope.
  - Any check that fails from insufficient `gh` permission is reported
    "skipped — insufficient permission"; every other check still runs.
- **Fix phase** — an `AskUserQuestion` multi-select list, one line per individual finding
  (never bundled by category); only selected lines are applied:
  - Rewrite triggers to exclude bot branches from self-hosted jobs (`branches-ignore`), or
    gate with an `environment:` requiring manual approval. Gating actually requires
    configuring the environment's reviewers via the Environments API — referencing an
    `environment:` name alone doesn't gate anything, since GitHub auto-creates an undefined
    environment with no protection; a later audit also recognizes an already-gated job so it
    isn't re-flagged. See `REFERENCE.md`'s *Gating a trigger behind approval* section and the
    Trigger crossing rule for the full procedure.
  - Pin a selected third-party Action to its resolved commit SHA
    (`gh api repos/{action}/commits/{tag}`), keeping the original version as a trailing
    comment.
  - Enable `sha_pinning_required` via the Actions permissions API, if selected.
  - Apply branch protection sized to the actual team: skip requiring a second reviewer for a
    single-collaborator repo; still require status checks and block force-push/delete
    regardless of team size.
- **Output**: findings first, fixes second, in a short written summary; fixes are clearly
  marked as applied only where explicitly selected.
- **Out of scope**: rotating/auditing secret values, runner OS hardening, and any settings
  change the harness's own permission layer refuses — report it, don't route around it.
  zizmor is explicitly excluded (deferred to a separate future skill).
- **Glossary**: `.agent-docs/context.md` already has a "Repo Hardening" section with
  **Trust boundary**, **Reachable self-hosted job**, and **Finding** (repo-harden sense).

`SKILL.md` stays concise; the `gh`/`git` commands and exact API fields per check live in
`REFERENCE.md`. The skill's `description` frontmatter is tuned to fire on explicit intent
("harden this repo", "check security posture", self-hosted runner + public repo mentioned
together) and validated against the `create-a-skill` review checklist.

### Acceptance criteria

- [x] Given the current repo, when `/repo-harden` runs, then it reports repo visibility,
      collaborator list/permissions, dependabot config status, and default-branch protection
      settings — every check printed, pass or flagged. (Verified live against
      `mholubinka1/skills`: `gh repo view --json visibility` → `PUBLIC`; `gh api
      repos/.../collaborators` → one entry, `mholubinka1`, admin; dependabot content lookup →
      404 "no dependabot config found"; branch protection → 404 "Branch not protected". Every
      check produced its own line; none was silently skipped.)
- [x] Given a workflow job whose `runs-on:` names a self-hosted/custom-label runner and whose
      trigger is `pull_request`, `pull_request_target`, or unscoped `push: branches: ['**']`,
      when the audit runs, then that job is flagged as a Reachable self-hosted job finding.
      (This repo has no `.github/workflows/`, so verified against a scratch fixture built in
      the scratchpad, walked by hand against REFERENCE.md's Trigger crossing rule, then
      deleted — never committed.)
- [x] Given a workflow with a `uses:` pinned to a mutable tag/branch, when the audit runs,
      then that action is flagged as an unpinned-action finding, and the report separately
      states whether `sha_pinning_required` is set org/repo-wide. (Fixture walkthrough for the
      flagging; `sha_pinning_required` verified live via `gh api
      repos/mholubinka1/skills/actions/permissions` → `false`. Corrected on review: the first
      draft documented a `false` value as "a status line, not itself a fix-phase Finding,"
      which made its "Enable SHA pinning" fix unreachable — Step 2's multi-select only ever
      builds options from Findings and skips itself entirely at zero Findings, so a repo with
      no other findings could never be offered this fix. `false` is now itself a Finding, same
      as every other check, so it's always reachable.)
- [x] Given a job with both self-hosted/runner-level access and secrets in scope, when the
      audit runs, then that overlap is reported as context, not a fixable Finding — there's
      no safe automated fix. (Fixture's `deploy` job: `runs-on: [self-hosted, gpu]` +
      `secrets: inherit` + `${{ secrets.DEPLOY_TOKEN }}`, walked by hand against
      REFERENCE.md's Secrets exposure rule.)
- [x] Given a check that fails from insufficient `gh` permission, when the audit runs, then
      that check is reported "skipped — insufficient permission" and every other check still
      completes. (Verified by inspection: `SKILL.md` Step 1 and `REFERENCE.md`'s Permission
      handling section explicitly branch on 403 → skip-and-continue vs. the branch-protection
      endpoint's 404 → plain "not protected" result, never conflating the two. No live 403 was
      available to trigger against this repo's own admin-owned settings.)
- [x] Given a clean repo with no findings, when the audit completes, then the full report
      still prints every check as passed — no silent success. (This repo isn't fully clean —
      it has one live branch-protection finding, which doubles as the solo-maintainer example
      below — but every check that *is* clean here (visibility, dependabot, actions pinning,
      secrets exposure, no-workflows) printed its own explicit pass/N-A line rather than being
      omitted, live. Step 1's completion criterion in `SKILL.md` forces every check to report
      "whether or not any finding turned up," independent of how many findings exist.)
- [x] Given the audit has produced one or more findings, when the fix phase begins, then each
      finding is presented as its own selectable line in a multi-select `AskUserQuestion`, and
      only the selected lines are applied. (Verified by inspection of `SKILL.md` Step 2: one
      `AskUserQuestion` with `multiSelect: true`, one option per individual Finding, never
      grouped by category.)
- [x] Given a repo with a single collaborator/maintainer, when a branch-protection fix is
      offered, then it does not require a second reviewer, but still requires status checks
      and blocks force-push/delete. (This repo is itself the live solo-maintainer example —
      one collaborator, admin, confirmed via `gh api repos/.../collaborators`. Fix command
      construction verified by inspection only per the Testing Decisions section; never
      applied to this repo's real settings. Corrected on review: the first draft's payload set
      `required_pull_request_reviews=null`, which per the GitHub API disables "require a pull
      request before merging" entirely — allowing direct pushes — not just the second-reviewer
      count this criterion asked to skip. Changed to
      `required_pull_request_reviews[required_approving_review_count]=0`, a non-null object
      that keeps the PR requirement while requiring zero approvals.)
- [x] Given a selected "pin action" fix, when applied, then the action's `uses:` is rewritten
      to the resolved commit SHA with the original version kept as a trailing comment.
      (Command construction verified live: `gh api repos/actions/checkout/commits/v4 --jq
      .sha` returned `11d5960a326750d5838078e36cf38b85af677262`, confirming the resolved
      rewrite `uses: actions/checkout@11d5960a...# v4` is correct — never written to any real
      workflow file.)
- [x] Given a selected "restrict trigger" fix, when applied, then the job's trigger is
      rewritten with `branches-ignore` for bot branches, or gated behind an `environment:`
      requiring manual approval. (Verified by inspection/construction against the fixture's
      `pull_request_target`-triggered job — REFERENCE.md's Fix commands table maps it to the
      `environment:` gate — and by reasoning through the `branches-ignore` case for an
      unscoped-`push`-only trigger.)
- [x] Given no findings are selected, when the fix phase ends, then nothing in the repo is
      changed. (Verified by inspection: `SKILL.md` Step 2 explicitly handles the zero-selected
      case — "report 'no fixes selected — nothing changed' and stop" — distinct from the
      zero-findings case above it.)
- [x] Given a settings change the harness's own permission layer refuses, when the fix phase
      attempts it, then the skill reports the refusal and does not attempt to route around it.
      (Verified by inspection: `SKILL.md` Step 2 and `REFERENCE.md`'s Permission handling
      section both state the refusal is reported on that finding's line and the run moves to
      the next selected fix, with no retry, fallback credential, or alternate API path.)
- [x] `repo-harden/SKILL.md` and `REFERENCE.md` exist, `SKILL.md`'s `description` includes
      explicit "Use when..." triggers, and detailed commands live in `REFERENCE.md`.
- [x] `pre-commit` passes on all changed files. (Ran `pre-commit run --files
      repo-harden/SKILL.md repo-harden/REFERENCE.md` — all applicable hooks passed.)

---
