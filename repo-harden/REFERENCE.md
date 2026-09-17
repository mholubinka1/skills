# repo-harden — Reference

Exact commands and fields for the workflow in [SKILL.md](SKILL.md): every read-only check,
the trigger-crossing rule, and every fix-phase command. `{owner}/{repo}` below is always
the current repo — resolve it once via the Visibility check's own call (which already
requests `owner,name,defaultBranchRef` alongside `visibility` — see the Checks table) and
reuse both `{owner}/{repo}` and `{default_branch}` throughout; never accept either as an
argument.

## Checks table

| Check | Command | What to report |
|---|---|---|
| Visibility | `gh repo view --json visibility,owner,name,defaultBranchRef` | Always **context, not a Finding** — no fix-phase option; report `.visibility` verbatim (`PUBLIC` / `PRIVATE` / `INTERNAL`). This is the one `gh repo view` call the whole skill makes — `{owner}` is `.owner.login` (a nested object, not a bare string), `{repo}` is `.name`, and `{default_branch}` is `.defaultBranchRef.name`; resolve all three here and reuse them for every other check and fix below — nothing else re-fetches them. |
| Collaborators | `gh api repos/{owner}/{repo}/collaborators --jq 'map({login, role_name})'` | Always **context, not a Finding** — no fix-phase option. One entry per collaborator: login + highest permission, report each as its own line. `role_name` is GitHub's own precomputed highest-permission string (`admin`/`maintain`/`write`/`triage`/`read` — verified live against a real repo) — use it directly rather than reducing the raw `permissions` object (`{admin, maintain, push, pull, triage}`, five separate booleans) yourself. Count collaborators — exactly one marks the repo **solo-maintained**, used to size the branch-protection fix in Step 2. (`map(...)` avoids a raw pipe character in this table cell — GFM table parsing splits a cell on any pipe even inside a code span, so an escaped one leaks a literal backslash into the command if copied verbatim, and an unescaped one breaks the table itself; verified both live.) |
| Reachable self-hosted jobs | Read each workflow file; no separate command | See *Trigger crossing* below for the exact rule and its two worked fixtures. Each matching job is a **Finding**, one per job. |
| Dependabot config | 1. `gh api repos/{owner}/{repo}/contents/.github/dependabot.yml` 2. If that 404s, also try `gh api repos/{owner}/{repo}/contents/.github/dependabot.yaml` — GitHub accepts either extension (verified against GitHub's own docs) | Always **context, not a Finding** — no fix-phase option either way. Both 404 → "no dependabot config found" (there's no config to inspect). Either present → decode the base64 `content` field and report whether `updates[].target-branch` (or its default) names an in-repo branch matching a build-triggering pattern. This confirms the configured target, not the absence of a fork-based mirror/sync layered on top of it — no single API call verifies that, so report it as a known residual gap rather than implying it's covered. |
| Actions pinning | Read each workflow file; regex each `uses:` value | A value shaped `owner/repo@<40-hex-char>` is pinned to a SHA — passes. Anything else (`@v4`, `@main`, `@latest`, a short SHA) is a **Finding**, one per occurrence, identified by file path + job name + the `uses:` value. |
| `sha_pinning_required` | 1. `gh api repos/{owner}/{repo}/actions/permissions --jq .sha_pinning_required` (repo-level) 2. If `{owner}` is an organization (not a user account — `gh api users/{owner} --jq .type` returns `Organization`), also try `gh api orgs/{owner}/actions/permissions --jq .sha_pinning_required` | Report the repo-level boolean; `false` is a **Finding** (its fix is "Enable SHA pinning" from the Fix commands table below, which is repo-level only) — this keeps it reachable through the same Finding-driven multi-select as every other check, including in an otherwise-clean repo where it's the only thing to offer. `true` is a pass. If the org-level call succeeds, report its value too as **context, not a Finding** — enabling it org-wide would affect every repo in the org at once, a larger blast radius than any other fix this skill offers, so there is no fix-phase option for it (an org-enforced `true` can still mask/override a repo-level `false`, which is exactly why it's worth showing even though it isn't actionable here). A `403` on the org-level call is "skipped — insufficient permission" like any other org-admin-only read, not a run-aborting failure. |
| Branch protection | `gh api repos/{owner}/{repo}/branches/{default_branch}/protection` | `404` with body `"message": "Branch not protected"` → report "not protected"; this is itself a **Finding** (missing protection entirely), fixed by the same payload below (expected result, not an error). `403` → report that check as "skipped — insufficient permission" (see *Permission handling*). `200` → report `required_status_checks`, `required_pull_request_reviews` (and its `required_approving_review_count`), `allow_force_pushes.enabled`, `allow_deletions.enabled`, `enforce_admins.enabled`, one line each; if any is missing or set to the unsafe value (force-push/deletion allowed, no status checks, no PR requirement, `enforce_admins.enabled: false`), that's one combined **Finding** for the branch as a whole — not one per sub-setting, since the Fix commands table's payload sets every sub-setting in a single atomic call. |
| Secrets exposure | Read each workflow file | A job whose `runs-on:` is self-hosted or a custom label (not one of GitHub's hosted labels: `ubuntu-*`, `windows-*`, `macos-*`) **and** whose body contains `secrets:` (job-level, including `secrets: inherit`) or a step referencing `${{ secrets.* }}` is reported as **context, not a Finding** — one line per job, no fix-phase option, since removing a job's secrets access without knowing whether it legitimately needs them isn't a call this skill can safely make. |

## Trigger crossing

For each `.github/workflows/*.yml`/`*.yaml` file, read it directly and reason per job —
there is no parsing script in this repo's skills, by convention.

1. Find the workflow's effective trigger(s) under top-level `on:`. A trigger is
   **bot/non-admin-reachable** when it includes any of:
   - `pull_request` (any `types:`)
   - `pull_request_target` (any `types:` — this trigger runs with the base branch's
     secrets and is the highest-risk case, since it executes attacker-controlled PR code
     with trusted context)
   - `push` with no `branches:`/`branches-ignore:` filter at all; a `branches:` allowlist
     that matches an arbitrary or bot-created branch pattern (e.g. `['**']`, `['*']`, or one
     that includes a known bot prefix like `dependabot/**`); or a `branches-ignore:` denylist
     that doesn't name every known bot prefix in play (cross-reference the repo's actual bot
     configs, e.g. `dependabot.yml`/`dependabot.yaml` — `branches-ignore: ['main']` alone
     still lets `dependabot/**`/`renovate/**` through). A `branches-ignore:` naming every bot prefix the
     repo actually uses clears the *bot* risk this check targets; it can never guarantee
     exclusion of an arbitrary human-created branch the way a `branches:` allowlist can —
     that residual is a non-admin-collaborator-push risk, not this check's concern. Check
     what the denylist actually excludes, not whether the key exists.
2. For each `jobs.<name>`, read `runs-on:`. It's **self-hosted or custom-label** unless
   every value in it is one of GitHub's hosted labels (`ubuntu-latest`, `ubuntu-22.04`,
   `windows-latest`, `macos-latest`, etc. — the `<os>-<version>`/`<os>-latest` hosted
   families). `runs-on:` may be a single string or a YAML list (e.g.
   `runs-on: [self-hosted, gpu]`) — either shape crossing a reachable trigger counts.
3. A job matching both 1 and 2 is a **Reachable self-hosted job** finding.

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
    runs-on: [self-hosted, gpu]    # Reachable self-hosted job AND secrets-exposure context
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
workflow's `pull_request_target`/unscoped `push`) — and since the reachable trigger includes
`pull_request_target`, its fix-phase option is "gate behind approval," not
"branches-ignore," per the Fix commands table. `deploy` is flagged as Reachable (a Finding)
and separately reported for secrets exposure (context only, self-hosted labels +
`secrets: inherit` + `${{ secrets.* }}` — no fix-phase option for that half). `lint` is not
Reachable (hosted runner) but its `checkout@v4` is still an unpinned-action Finding. All
three `checkout@v4` lines are separate pinning Findings — three fix-phase options, not one,
since each rewrites a different file/line.

### Second worked fixture — `push`-only, exercising the `branches:` rewrite

The fixture above always routes to "gate behind approval" because `pull_request_target` is
present workflow-wide, so it never exercises the `branches:`-allowlist rewrite case. A
separate, `push`-only workflow does:

```yaml
on:
  push:
    branches: ['**']

jobs:
  release:
    runs-on: self-hosted  # Reachable self-hosted job (push, unscoped branches allowlist)
    steps:
      - uses: actions/checkout@v4  # Finding — mutable tag
```

`release` is Reachable via `push` alone (no `pull_request_target` in this file), and its
trigger already has a `branches:` allowlist rather than no filter or an existing
`branches-ignore:`. Per the Fix commands table, the correct fix rewrites that allowlist in
place — `branches: ['**', '!dependabot/**', '!renovate/**']` — never adds a `branches-ignore:`
alongside it, since GitHub rejects a workflow declaring both for the same event.

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
| Restrict trigger — exclude bot branches | Depends on the `push:` block's current filter (`branches:` and `branches-ignore:` can never coexist on the same event — GitHub rejects the workflow if both are present): **no filter at all** → add a fresh `branches-ignore:` list naming the bot's branch prefix(es) (e.g. `['dependabot/**', 'renovate/**']`). **Existing `branches-ignore:`** that just doesn't cover every bot prefix → append the missing prefix(es) to that same list; never add a second `branches-ignore:` key. **Existing `branches:` allowlist** (e.g. `['**']`) → do not add `branches-ignore:` alongside it; instead rewrite the existing `branches:` list in place to add negation patterns excluding the bot prefixes (e.g. `branches: ['**', '!dependabot/**', '!renovate/**']`) — GitHub's own documented way to combine include/exclude on one event. | **`push` only.** `pull_request`/`pull_request_target`'s own `branches`/`branches-ignore` filters match the PR's *base* branch, not the bot's head branch, so this fix excludes nothing there — per the Trigger crossing rule, those two triggers stay Reachable regardless of branch filtering. Use only when the reachable trigger is `push` from a known bot. |
| Restrict trigger — gate behind approval | 1. Check whether `<name>` already requires manual approval specifically: `gh api repos/{owner}/{repo}/environments/<name> --jq '.protection_rules'` — look for an entry whose `type` is `required_reviewers` (verified live by creating a real test environment with a configured reviewer: `protection_rules[].type` is exactly `"required_reviewers"`, distinct from `wait_timer` or `branch_policy`, neither of which involves a human). If one is already present, leave it alone. A 404, an empty array, or an array with only `wait_timer`/`branch_policy` entries all mean it isn't gated behind approval yet. 2. Check the admin-collaborator list isn't empty first: `gh api repos/{owner}/{repo}/collaborators --jq '(map(if .role_name == "admin" then {type:"User", id} else empty end))[0]'` — if this is `null` (no admin collaborators, a theoretical edge case), stop and report "can't gate `<name>` — no eligible reviewer found"; do **not** proceed to step 3, since an empty `reviewers` array creates zero protection rules (verified live) — the exact no-op this whole fix exists to avoid. 3. Otherwise build the request body into a variable, capped at GitHub's 6-reviewer limit (verified against GitHub's REST docs) and with `prevent_self_review` set based on whether there's a *second* admin collaborator — `true` if so (without it, the PR author could rubber-stamp their own gated run if they're in the reviewer list, verified live that the field takes effect); `false` for exactly one admin (solo-maintained — same reasoning as the solo-maintained branch-protection row two below: the sole admin must be able to approve their own run, or the gate deadlocks every run it protects, forever, with no one able to unblock it): `BODY=$(gh api repos/{owner}/{repo}/collaborators --jq '{reviewers: (map(if .role_name == "admin" then {type:"User", id} else empty end))[0:6], prevent_self_review: ((map(if .role_name == "admin" then {type:"User", id} else empty end))[1] != null)}')`. 4. Send it as the real request body: `gh api --method PUT repos/{owner}/{repo}/environments/<name> --input - <<< "$BODY"` — `--input` is used here rather than `-f`/`-F` because `reviewers` is an array of objects, a shape `-f`/`-F`'s bracket syntax has no verified construction for (the same reason `checks` was left as future work below); `--input` sends the JSON body directly, so there's nothing to get wrong. 5. Only then add `environment: <name>` to the reachable job in the workflow file. | The only trigger-restricting fix for `pull_request`/`pull_request_target` — branch filtering can't exclude a bot there (see the row above). A reachable `push` is always handled by the row above instead, whichever of its three cases applies. **Step 5 alone is not the fix.** Referencing an environment name with no protection rules doesn't gate anything — GitHub auto-creates it with none (verified live against a real repo, and against GitHub's docs) and the job runs exactly as if `environment:` were never added. Steps 1–4 are what actually restrict the trigger; step 5 only wires the job to them. |
| Enable SHA pinning | `gh api --method PUT repos/{owner}/{repo}/actions/permissions -F enabled=true -F sha_pinning_required=true` | Repo-level; requires admin. `enabled` is a **required** body parameter on this endpoint (verified against GitHub's REST docs) — omitting it is rejected, not defaulted; set to `true` since the repo already has Actions enabled (this check only ever ran because workflows exist to audit). Both fields are boolean, so both need `-F` (magic type conversion), not `-f` (which would send the string `"true"` against a field typed boolean). `allowed_actions` is optional and safely left out — omitting it preserves the repo's current value rather than resetting it. |
| Branch protection — solo-maintained (1 collaborator) | `gh api --method PUT repos/{owner}/{repo}/branches/{default_branch}/protection -F 'required_status_checks[strict]=true' -f 'required_status_checks[contexts][]=<context>' -F enforce_admins=true -F 'required_pull_request_reviews[required_approving_review_count]=0' -F restrictions=null -F allow_force_pushes=false -F allow_deletions=false` | `gh api`'s bracket syntax (`key[subkey]=value`, `key[]=value` for arrays) — not dotted keys — is what nests JSON in this CLI. Every bracket-bearing argument must be single-quoted, including `required_status_checks[strict]=true` — zsh (macOS's default shell) treats an unquoted `[strict]` as a glob character class and aborts with "no matches found" before `gh` even runs (verified live); bash happens to pass it through unquoted, but don't rely on that. `required_pull_request_reviews` must stay a **non-null object** — setting it to JSON `null` disables "require a pull request before merging" entirely, allowing direct pushes, which is not what "skip requiring a second reviewer" asked for. `required_approving_review_count=0` keeps the PR requirement while requiring zero approvals. Repeat the `contexts[]` flag once per required check name (see below); `-F x=null` sends a real JSON `null`, where `-f` would send the four-character string `"null"` — used here only for `restrictions`, which is meant to be genuinely absent. |
| Branch protection — multi-maintainer (2+ collaborators) | Same as above, but `-F 'required_pull_request_reviews[required_approving_review_count]=1'` instead of `=0` | Everything else identical to the solo-maintained payload. Always a flat `1` — this fix never scales the count with collaborator count (the spec's "sized to the actual team" only distinguishes solo from non-solo). `required_approving_review_count`'s valid range is 0–6 either way (verified against GitHub's REST docs); not relevant here since the value used is always `1`. |

**Populating `contexts`**: read existing check-run names from
`gh api repos/{owner}/{repo}/commits/{default_branch}/check-runs --jq '.check_runs[].name'`
and pass each as its own `-f 'required_status_checks[contexts][]=<context>'`. If no check runs
exist yet (no CI configured), pass `-f 'required_status_checks[contexts][]'` (no `=value`)
for an empty array and note in the report that status-check enforcement is a no-op until a
CI workflow exists to name.

`contexts` (a plain string array) is what's used above rather than GitHub's newer `checks`
field (an array of `{context, app_id}` objects that GitHub's docs say will eventually
replace it) — `contexts` is still live and functional today, and `checks`' array-of-objects
shape has no verified `gh api` bracket-flag construction (untested here, since applying it
would mean a live mutating call against real branch-protection settings, which this skill's
own testing rules exclude). Revisit if GitHub actually removes `contexts` support.

Most fix-phase commands above were not executed against a real repo's live settings during
this skill's own build or testing — deliberately, since a branch-protection or
Actions-permissions change is real and partially hard to reverse. The pin-action command was
checked the most directly of those: `gh api repos/actions/checkout/commits/v4` was actually
run and returned a real 40-char SHA. The branch-protection payloads' nested bracket syntax
(`key[subkey]=value`, `key[]=value`) was checked against `gh api --help`'s documented nesting
rules, not run — verified by construction, not execution. One exception: the "gate behind
approval" environment-creation step (`--input -` with a `reviewers` JSON body) was actually
executed once, against a real disposable test environment, with explicit confirmation — it
succeeded, and the resulting `protection_rules[].type` value (`"required_reviewers"`) that
step 1 of that fix checks for was read from that real response, not guessed. The test
environment was deleted immediately after and confirmed gone (404).

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
