# repo-harden — Reference

Exact commands and fields for the workflow in [SKILL.md](SKILL.md): every read-only check,
the trigger-crossing rule, and every fix-phase command. `{owner}/{repo}` below is always
the current repo — resolve it once with `gh repo view --json owner,name` and reuse it,
never accept it as an argument.

## Checks table

| Check | Command | What to report |
|---|---|---|
| Visibility | `gh repo view --json visibility` | `PUBLIC` / `PRIVATE` / `INTERNAL`, verbatim |
| Collaborators | `gh api repos/{owner}/{repo}/collaborators --jq '.[] \| {login, permissions}'` | One line per collaborator: login + highest permission (`admin`/`maintain`/`push`/`triage`/`pull`). Count them — exactly one collaborator marks the repo **solo-maintained**, used to size the branch-protection fix in Step 2. |
| Reachable self-hosted jobs | Read each workflow file; no separate command | See *Trigger crossing* below for the exact rule and a worked fixture. Each matching job is a **Finding**, one per job. |
| Dependabot config | `gh api repos/{owner}/{repo}/contents/.github/dependabot.yml` | 404 → "no dependabot config found" (a plain report line, not a finding by itself unless combined with an in-repo build-triggering branch pattern found in the file's `updates[].target-branch` / default). Present → decode the base64 `content` field and report whether opened PRs land on an in-repo branch matching a build-triggering pattern, and whether `updates[].target-branch` (or its default) names a branch in this repo rather than a fork — Dependabot/Renovate PRs always land in-repo by how the integration works, so this second half of the check is really confirming no fork-based mirror/sync config has been layered on top that would redirect them. |
| Actions pinning | Read each workflow file; regex each `uses:` value | A value shaped `owner/repo@<40-hex-char>` is pinned to a SHA — passes. Anything else (`@v4`, `@main`, `@latest`, a short SHA) is a **Finding**, one per occurrence, identified by file path + job name + the `uses:` value. |
| `sha_pinning_required` | `gh api repos/{owner}/{repo}/actions/permissions --jq .sha_pinning_required` | Report the literal boolean. `false` is a **Finding** (its fix is "Enable SHA pinning" from the Fix commands table below) — this keeps it reachable through the same Finding-driven multi-select as every other check, including in an otherwise-clean repo where it's the only thing to offer. `true` is a pass, nothing to report beyond the boolean. |
| Branch protection | `gh api repos/{owner}/{repo}/branches/{default_branch}/protection` | `404` with body `"message": "Branch not protected"` → report "not protected" (expected, not an error). `403` → report that check as "skipped — insufficient permission" (see *Permission handling*). `200` → report `required_status_checks`, `required_pull_request_reviews` (and its `required_approving_review_count`), `allow_force_pushes.enabled`, `allow_deletions.enabled`, `enforce_admins.enabled`, one line each, flagging any that's missing or set to the unsafe value (force-push/deletion allowed, no status checks, no PR requirement). |
| Secrets exposure | Read each workflow file | A job whose `runs-on:` is self-hosted or a custom label (not one of GitHub's hosted labels: `ubuntu-*`, `windows-*`, `macos-*`) **and** whose body contains `secrets:` (job-level, including `secrets: inherit`) or a step referencing `${{ secrets.* }}` is a **Finding**, one per job. |

Resolve `{default_branch}` from the visibility check's `gh repo view` call
(`--json defaultBranchRef` gives `.defaultBranchRef.name`) rather than assuming `main`.

## Trigger crossing

For each `.github/workflows/*.yml`/`*.yaml` file, read it directly and reason per job —
there is no parsing script in this repo's skills, by convention.

1. Find the workflow's effective trigger(s) under top-level `on:`. A trigger is
   **bot/non-admin-reachable** when it includes any of:
   - `pull_request` (any `types:`)
   - `pull_request_target` (any `types:` — this trigger runs with the base branch's
     secrets and is the highest-risk case, since it executes attacker-controlled PR code
     with trusted context)
   - `push` with no `branches:`/`branches-ignore:` filter, or a `branches:` pattern that
     matches an arbitrary/bot-created branch (e.g. `['**']`, `['*']`)
2. For each `jobs.<name>`, read `runs-on:`. It's **self-hosted or custom-label** unless
   every value in it is one of GitHub's hosted labels (`ubuntu-latest`, `ubuntu-22.04`,
   `windows-latest`, `macos-latest`, etc. — the `<os>-<version>`/`<os>-latest` hosted
   families). `runs-on:` may be a single string or a YAML list (e.g.
   `runs-on: [self-hosted, gpu]`) — either shape crossing a reachable trigger counts.
3. A job matching both 1 and 2 is a **Reachable self-hosted job** finding. A job-level
   `on:` override (rare) takes precedence over the workflow-level trigger for that job only.

### Worked fixture

```yaml
on:
  pull_request_target:
  push:
    branches: ['**']

jobs:
  build-self-hosted:
    runs-on: self-hosted          # Reachable self-hosted job (pull_request_target + push **)
    steps:
      - uses: actions/checkout@v4  # Finding — mutable tag

  deploy:
    runs-on: [self-hosted, gpu]    # Reachable self-hosted job AND secrets-exposure Finding
    secrets: inherit
    steps:
      - uses: actions/checkout@v4  # Finding — mutable tag (separate occurrence)
      - run: ./deploy.sh
        env:
          TOKEN: ${{ secrets.DEPLOY_TOKEN }}

  lint:
    runs-on: ubuntu-latest         # hosted runner — no reachable-job finding
    steps:
      - uses: actions/checkout@v4  # Finding — mutable tag (third occurrence)
```

Walking this by hand: `build-self-hosted` is flagged as Reachable (self-hosted + the
workflow's `pull_request_target`/unscoped `push`); `deploy` is flagged both as Reachable
and for secrets exposure (self-hosted labels + `secrets: inherit` + `${{ secrets.* }}`);
`lint` is not Reachable (hosted runner) but its `checkout@v4` is still an unpinned-action
Finding. All three `checkout@v4` lines are separate pinning Findings — three fix-phase
options, not one, since each rewrites a different file/line.

## Permission handling

A check's command returning `403` (or `gh`'s `HTTP 403`/"Resource not accessible") means
the audit's own read lacks scope — report that single check as
**"skipped — insufficient permission"** and continue to the next check. This is different
from a `404` on the branch-protection endpoint, which is GitHub's normal signal for
"no protection configured" and gets reported as a plain (not skipped, not erroring) result.

A fix-phase write refused by the harness's own tool-permission layer (the user or their
settings decline the underlying `gh`/`Write` call) is reported on that finding's line as
**"refused by permission settings — not applied"**; move to the next selected fix. Never
retry the same call, fall back to an unscoped credential, or otherwise route around either
kind of refusal — both the audit-read case and the fix-write case are reported, not worked
around.

## Fix commands

| Fix | Command | Notes |
|---|---|---|
| Pin action to SHA | 1. `gh api repos/{action_owner}/{action_repo}/commits/{tag} --jq .sha` 2. Rewrite the finding's `uses:` line to `uses: {action_owner}/{action_repo}@{sha} # {tag}` | `{action_owner}/{action_repo}` and `{tag}` come from the Finding's original `uses:` value (e.g. `actions/checkout@v4` → owner `actions`, repo `checkout`, tag `v4`). The trailing comment preserves the human-readable version. |
| Restrict trigger — exclude bot branches | Add `branches-ignore:` to the job's (or workflow's) `push:`/`pull_request:` block naming the bot's branch prefix (e.g. `dependabot/**`, `renovate/**`) | Use when the reachable trigger is `push` or `pull_request` from a known bot. |
| Restrict trigger — gate behind approval | Add `environment: <name>` to the reachable job, where `<name>` is an existing or newly-described protected environment requiring manual reviewer approval | Use for `pull_request_target` or when no branch-prefix filter cleanly excludes the risk. |
| Enable SHA pinning | `gh api --method PUT repos/{owner}/{repo}/actions/permissions -f sha_pinning_required=true` | Repo-level; requires admin. |
| Branch protection — solo-maintained (1 collaborator) | `gh api --method PUT repos/{owner}/{repo}/branches/{default_branch}/protection -F required_status_checks[strict]=true -f 'required_status_checks[contexts][]=<context>' -F enforce_admins=true -F 'required_pull_request_reviews[required_approving_review_count]=0' -F restrictions=null -F allow_force_pushes=false -F allow_deletions=false` | `gh api`'s bracket syntax (`key[subkey]=value`, `key[]=value` for arrays) — not dotted keys — is what nests JSON in this CLI. `required_pull_request_reviews` must stay a **non-null object** — setting it to JSON `null` disables "require a pull request before merging" entirely, allowing direct pushes, which is not what "skip requiring a second reviewer" asked for. `required_approving_review_count=0` keeps the PR requirement while requiring zero approvals. Repeat the `contexts[]` flag once per required check name (see below); `-F x=null` sends a real JSON `null`, where `-f` would send the four-character string `"null"` — used here only for `restrictions`, which is meant to be genuinely absent. |
| Branch protection — multi-maintainer (2+ collaborators) | Same as above, but `-F 'required_pull_request_reviews[required_approving_review_count]=1'` (or higher, per team size) instead of `=0` | Everything else identical to the solo-maintained payload. |

**Populating `contexts`**: read existing check-run names from
`gh api repos/{owner}/{repo}/commits/{default_branch}/check-runs --jq '.check_runs[].name'`
and pass each as its own `-f 'required_status_checks[contexts][]=<name>'`. If no check runs
exist yet (no CI configured), pass `-f 'required_status_checks[contexts][]'` (no `=value`)
for an empty array and note in the report that status-check enforcement is a no-op until a
CI workflow exists to name.

None of the fix-phase commands above were executed against a real repo's live settings
during this skill's own build or testing — deliberately, since a branch-protection or
Actions-permissions change is real and partially hard to reverse. The pin-action command was
checked the most directly: `gh api repos/actions/checkout/commits/v4` was actually run and
returned a real 40-char SHA. The branch-protection payloads' nested bracket syntax
(`key[subkey]=value`, `key[]=value`) was checked against `gh api --help`'s documented nesting
rules, not run — verified by construction, not execution.

## Out of scope

- Rotating or auditing secret values themselves.
- Runner OS hardening (patching, image hygiene).
- **zizmor** (a GitHub Actions static analyzer) — considered and explicitly deferred to a
  separate future skill; not integrated here even as an optional pass.
- Cross-repo targeting — this skill only ever reads/writes the repo the session is in.
- Collating findings into any shared/cross-repo store — each run's report is local to that
  run.
- Routing around a harness permission refusal by any means (retry, alternate credential,
  alternate API path).
