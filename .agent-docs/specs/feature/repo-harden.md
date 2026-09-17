# repo-harden

## Problem Statement

A repo that is both public and wired to a self-hosted runner has a trust boundary problem:
anyone who can open a pull request — including automated bots like Dependabot and Renovate —
can potentially get a workflow to execute on that runner. If the runner has any network reach
into internal systems or long-lived credentials, that's a supply-chain or lateral-movement risk,
not just a CI nuisance. Today, catching this requires someone to manually read every workflow's
`on:`/`runs-on:` combination, check whether third-party actions are pinned to a mutable ref,
and check branch protection settings — a multi-step, easy-to-skip audit with no tooling support
in this skills repo.

## Solution

A new `repo-harden` skill audits the current repo's CI/CD trust boundary in a read-only pass,
reports every check's result (pass or flagged, never silent), then — only for named findings the
user explicitly selects — applies the corresponding fix. Nothing is ever changed without being
named and picked first.

The skill always operates on the repo the session is already in, matching `update-dependencies`'
existing convention — no cross-repo targeting.

## User Stories

1. As a maintainer of a public repo with a self-hosted runner, I want a single command that
   tells me exactly which workflow jobs a bot or non-admin PR could trigger on that runner, so
   that I know my actual exposure without reading every workflow file by hand.
2. As a maintainer, I want to see which third-party Actions are pinned to a mutable tag/branch
   instead of a commit SHA, so that I know where a supply-chain compromise of an upstream Action
   could reach my runner or secrets.
3. As a maintainer, I want to see my default branch's protection settings (required checks, PR
   requirement, force-push/delete restrictions, admin enforcement) reported plainly, so that I
   know whether they match what I intend.
4. As a maintainer, I want the full report even when nothing is wrong, so that a clean result is
   something I can point to with confidence rather than silence I have to trust.
5. As a maintainer, I want a check that can't run because `gh` lacks the required permission
   (e.g. no admin scope for branch protection or Actions settings) to say so and be skipped,
   without aborting every other check in the run.
6. As a maintainer, I want every fix presented as its own named, individually selectable item —
   one unpinned action, one over-broad trigger, one branch-protection gap — so I can accept some
   and decline others in a single pass, and never have anything applied that I didn't pick.
7. As a maintainer of a solo-maintained repo, I want branch protection fixes sized to my actual
   team — not forced into requiring a second reviewer I don't have — so the suggested fix is one
   I'd actually want to apply.

## Implementation Decisions

- **New skill directory** `repo-harden/` with `SKILL.md` (step overview) and `REFERENCE.md`
  (the `gh`/`git` commands and exact fields to inspect per check), following this repo's
  existing convention: every skill here is pure markdown instructions the agent executes ad hoc
  via `gh`/`git`/`bash` — no bundled parsing script. In particular, the trigger-vs-`runs-on:`
  crossing (the check with the most structure to reason about) is done by the agent reading each
  workflow file directly with `Read` and reasoning per job, not a `yq`/Python parsing pipeline.
- **Scope**: always the current repo (`gh repo view` with no `-R` flag) — no owner/repo argument.
- **Read-only phase — checks, each producing one line of the full report:**
  - Repo visibility (`gh repo view --json visibility`) and collaborator list/permissions
    (`gh api repos/{owner}/{repo}/collaborators`).
  - Every workflow file's `on:` trigger crossed against each job's `runs-on:`: flag any job
    naming a self-hosted or custom-label runner whose trigger is `pull_request`,
    `pull_request_target`, or an unscoped `push: branches: ['**']` — anything a bot (Dependabot,
    Renovate) or a non-admin contributor could hit. This becomes a **Reachable self-hosted job**
    finding per job.
  - `dependabot.yml`/equivalent bot configs: whether the branches they open land in-repo (not a
    fork) and match a pattern that would trigger a build.
  - Actions pinning: every `uses:` pinned to a mutable tag/branch instead of a full commit SHA
    is a **Finding**; also check whether `sha_pinning_required` is set at the org/repo level via
    the Actions permissions API.
  - Branch protection on the default branch: required status checks, PR requirement,
    force-push/delete restrictions, admin enforcement (`gh api repos/{owner}/{repo}/branches/{branch}/protection`).
  - Secrets exposure: cross-reference which jobs with runner-level or self-hosted access also
    have `secrets:`/`${{ secrets.* }}` in scope.
  - Each check that fails to run from insufficient `gh` permission is reported as
    "skipped — insufficient permission" and every other check still runs; the audit never
    aborts on one permission gap (mirrors the repo's existing convention of reporting a
    permission refusal rather than routing around it).
  - The full report always prints every check's result, pass or flagged — never a
    findings-only report — so a clean repo gets an explicit, confidence-giving "all clear."
- **Fix phase:**
  - Presented as an `AskUserQuestion` multi-select list, **one line per individual finding**
    (not bundled by category) — e.g. each unpinned action gets its own line, each over-broad
    trigger gets its own line. Only the selected lines are applied.
  - Rewrite triggers to exclude bot branches from self-hosted jobs (`branches-ignore`), or gate
    with an `environment:` requiring manual approval. Gating actually requires configuring the
    environment's reviewers via the Environments API — referencing an `environment:` name alone
    doesn't gate anything, since GitHub auto-creates an undefined environment with no
    protection; a later audit also recognizes an already-gated job so it isn't re-flagged. See
    `REFERENCE.md`'s *Gating a trigger behind approval* section and the Trigger crossing rule
    for the full procedure.
  - Pin a selected third-party Action to its resolved commit SHA via
    `gh api repos/{action}/commits/{tag}`, keeping the original version as a trailing comment.
  - Enable `sha_pinning_required` via the Actions permissions API, if selected.
  - Apply branch protection sized to the actual team: skip requiring a second reviewer for a
    repo with a single collaborator/maintainer; still require status checks and block
    force-push/delete, regardless of team size.
- **Output**: a short written summary — findings first, fixes second — with fixes clearly
  marked as applied only where explicitly selected.
- **Out of scope for this skill** (do not implement, and do not attempt to route around a
  refusal): rotating or auditing secret values themselves, runner OS hardening, and any settings
  change the harness's own permission layer refuses — report it, don't work around it.
- **zizmor** (an existing OSS static analyzer for GitHub Actions security) was considered and
  explicitly excluded from this skill during design. It's being generalized into a separate,
  later piece of work (a cross-repo pre-commit-config gist skill) rather than folded into
  `repo-harden` directly.
- **`context.md`**: already updated with three new terms under a "Repo Hardening" section —
  **Trust boundary**, **Reachable self-hosted job**, **Finding** (repo-harden sense).

## Testing Decisions

- This skills repo itself (`mholubinka1/skills`, public, no `.github/workflows/`) is the real
  test target for the checks that don't depend on workflow files: repo visibility, branch
  protection, dependabot config, and org/repo Actions permissions. Run the read-only phase
  against it and confirm the report matches its actual current settings.
- The workflow-trigger-crossing and actions-pinning checks have no real workflow file to
  exercise here, so they're verified against a scratch fixture workflow file (written to the
  worktree only, never committed) containing one job with a known self-hosted runner reachable
  by `pull_request_target` and one `uses:` pinned to a mutable tag. Confirm both are flagged as
  findings, then delete the fixture.
- The fix phase's write operations (trigger rewrites, SHA pinning, Actions API calls, branch
  protection changes) are not exercised against this repo live in testing — they're real,
  externally-visible, and partially hard-to-reverse actions. Verify their command construction
  by inspection (does the `gh api` call target the right endpoint with the right payload for a
  given finding) rather than by actually applying them during the BDD loop.
- The instruction-file changes (`SKILL.md`/`REFERENCE.md` wording) have no executable form
  beyond the above; verify by walking each step against a few concrete scenarios (clean repo,
  repo with reachable self-hosted jobs, repo with unpinned actions, permission-denied check) and
  confirming the described flow is unambiguous.

## Out of Scope

- Cross-repo targeting (an owner/repo argument) — always the current repo.
- Any zizmor integration, live or as a fix-phase item — deferred to a separate future skill.
- Rotating or auditing secret values themselves.
- Runner OS hardening.
- Routing around any settings change the harness's own permission layer refuses.
- Automating collation of findings into any shared/cross-repo store (unlike the Criteria gist
  pattern used elsewhere in this repo) — each run's findings are local to that run's report.

## Further Notes

- Follows the same "operates on whatever repo is currently open" convention as
  `update-dependencies`, and the same "report a permission refusal, don't route around it"
  convention already documented for skills in this repo.
- The zizmor discussion during design surfaced a larger, separate idea — a shared, cross-repo
  pre-commit-config gist skill, modeled on the existing Criteria gist pattern
  (`code-review/CRITERIA-GIST.md`) — to be scoped and implemented after this skill ships.
