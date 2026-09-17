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
| Collaborators | `gh api repos/{owner}/{repo}/collaborators --jq 'map({login, role_name})'` | Always **context, not a Finding** — no fix-phase option. One entry per collaborator: login + highest permission, report each as its own line. `role_name` is GitHub's own precomputed highest-permission string (`admin`/`maintain`/`write`/`triage`/`read`) — use it directly rather than reducing the raw `permissions` object (`{admin, maintain, push, pull, triage}`, five separate booleans) yourself. Count collaborators — exactly one marks the repo **solo-maintained**, used to size the branch-protection fix in Step 2. (`map(...)` avoids a raw pipe character in this table cell — GFM table parsing splits a cell on any pipe even inside a code span, so an escaped one leaks a literal backslash into the command if copied verbatim, and an unescaped one breaks the table itself.) |
| Reachable self-hosted jobs | Read each workflow file; for a job that already has an `environment:` key, also `gh api repos/{owner}/{repo}/environments/<env-name> --jq '.protection_rules'` (see *Trigger crossing* rule 3) | See *Trigger crossing* below for the exact rule and its two worked fixtures. Each matching job is a **Finding**, one per job. |
| Dependabot config | 1. `gh api repos/{owner}/{repo}/contents/.github/dependabot.yml` 2. If that 404s, also try `gh api repos/{owner}/{repo}/contents/.github/dependabot.yaml` — GitHub accepts either extension | Always **context, not a Finding** — no fix-phase option either way. The Contents API returns the same 404 whether a file is genuinely absent or the token can't read repo contents (deliberately, to avoid leaking a private repo's existence) — there's no reliable way to tell those apart from this endpoint alone, so report both 404s as "no dependabot config found (or contents inaccessible to this token — GitHub returns an identical 404 for both)" rather than asserting a genuine absence. Either present → decode the base64 `content` field and report whether `updates[].target-branch` (or its default) names an in-repo branch matching a build-triggering pattern. This confirms the configured target, not the absence of a fork-based mirror/sync layered on top of it — no single API call verifies that, so report it as a known residual gap rather than implying it's covered. |
| Actions pinning | Read each workflow file; regex each `uses:` value | Skip entirely (not a Finding, out of scope for this check) any `./path/to/local-action` (an in-repo local action, already versioned with the workflow's own commit) and any `docker://...` value regardless of whether it has an `@` — a Docker action is pinned, if at all, by an image digest (`docker://image@sha256:<64-hex>`), a completely different mechanism from a git commit SHA, so it's never evaluated by this check either way (not flagged unpinned, not credited as pinned). For every remaining value, check the substring after its **last** `@`: 40 hex characters means pinned to a SHA — passes, and this correctly covers both a plain action ref (`owner/repo@<sha>`) and a reusable workflow ref with a path component (`owner/repo/.github/workflows/build.yml@<sha>`), since only the ref after the last `@` is checked, regardless of how many `/`-segments precede it. Anything else after that last `@` (`v4`, `main`, `latest`, a short SHA) is a **Finding**, one per occurrence, identified by file path + job name + the `uses:` value. |
| `sha_pinning_required` | 1. `gh api repos/{owner}/{repo}/actions/permissions --jq '{enabled, sha_pinning_required}'` (repo-level) 2. If `{owner}` is an organization (not a user account — `gh api users/{owner} --jq .type` returns `Organization`), also try `gh api orgs/{owner}/actions/permissions --jq .sha_pinning_required` | Report the repo-level `sha_pinning_required` boolean; `false` **and** `enabled: true` together are a **Finding** (its fix is "Enable SHA pinning" from the Fix commands table below, which is repo-level only) — this keeps it reachable through the same Finding-driven multi-select as every other check, including in an otherwise-clean repo where it's the only thing to offer. `sha_pinning_required: true` is a pass regardless of `enabled`. `enabled: false` (Actions genuinely disabled repo-wide) is reported as **context, not a Finding** — see the Fix commands row for why this fix never turns Actions on as a side effect. If the org-level call succeeds, report its value too as **context, not a Finding** — enabling it org-wide would affect every repo in the org at once, a larger blast radius than any other fix this skill offers, so there is no fix-phase option for it (an org-enforced `true` can still mask/override a repo-level `false`, which is exactly why it's worth showing even though it isn't actionable here). A `403` on the org-level call is "skipped — insufficient permission" like any other org-admin-only read, not a run-aborting failure. |
| Branch protection | `gh api repos/{owner}/{repo}/branches/{default_branch}/protection` | `404` with body `"message": "Branch not protected"` → report "not protected"; this is itself a **Finding** (missing protection entirely), fixed by the same payload below (expected result, not an error). `403` → report that check as "skipped — insufficient permission" (see *Permission handling*). `200` → report `required_status_checks`, `required_pull_request_reviews` (and its `required_approving_review_count`), `allow_force_pushes.enabled`, `allow_deletions.enabled`, `enforce_admins.enabled`, one line each; if any is missing or set to the unsafe value (force-push/deletion allowed, no status checks, no PR requirement, `enforce_admins.enabled: false`), that's one combined **Finding** for the branch as a whole — not one per sub-setting, since the Fix commands table's payload sets every sub-setting in a single atomic call. Keep this response around: *Applying the branch-protection fix* below reuses it rather than re-fetching. |
| Secrets exposure | Read each workflow file | A job whose `runs-on:` is self-hosted or a custom label (not one of GitHub's hosted labels: `ubuntu-*`, `windows-*`, `macos-*`) has secrets in scope if **any** of: a step referencing `${{ secrets.* }}`; job-level `secrets:` (including `secrets: inherit`); a workflow-level top-level `env:` block referencing `${{ secrets.* }}` (inherited by every job in the file, including this one, with no per-job `secrets:` key to signal it); or a job-level `environment:` key (GitHub Environment secrets are granted to the job automatically, with no `secrets:` key appearing anywhere in the job body) — including an `environment:` this skill's own "gate behind approval" fix added: a GitHub Environment can have secrets attached to it at any time after creation, so don't treat one as exempt just because this skill created it purely for approval-gating. Reported as **context, not a Finding** — one line per job, no fix-phase option, since removing a job's secrets access without knowing whether it legitimately needs them isn't a call this skill can safely make. |

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
     that includes a known bot prefix like `dependabot/**`) **and doesn't also negate every
     known bot prefix within that same list** (GitHub evaluates negation patterns like
     `!dependabot/**` within `branches:` itself, so
     `branches: ['**', '!dependabot/**', '!renovate/**']` is NOT reachable by those bots even
     though `'**'` is still literally present); or a `branches-ignore:` denylist that doesn't
     name every known bot prefix in play (cross-reference the repo's actual bot configs, e.g.
     `dependabot.yml`/`dependabot.yaml` — `branches-ignore: ['main']` alone still lets
     `dependabot/**`/`renovate/**` through). Either form of exclusion — a `branches-ignore:`
     denylist, or negation patterns inside a `branches:` allowlist — naming every bot prefix
     the repo actually uses clears the *bot* risk this check targets; neither can guarantee
     exclusion of an arbitrary human-created branch the way a plain `branches:` allowlist
     with no negations can — that residual is a non-admin-collaborator-push risk, not this
     check's concern. Check what's actually excluded, not whether `'**'` or the key itself is
     present.
2. For each `jobs.<name>`, read `runs-on:`. It's **self-hosted or custom-label** unless
   every value in it is one of GitHub's hosted labels (`ubuntu-latest`, `ubuntu-22.04`,
   `windows-latest`, `macos-latest`, etc. — the `<os>-<version>`/`<os>-latest` hosted
   families). `runs-on:` may be a single string or a YAML list (e.g.
   `runs-on: [self-hosted, gpu]`) — either shape crossing a reachable trigger counts.
3. A job matching both 1 and 2 is a **Reachable self-hosted job** finding — unless it already
   has an `environment:` key naming an environment with a `required_reviewers` protection
   rule (`gh api repos/{owner}/{repo}/environments/<env-name> --jq '.protection_rules'`, same
   check the "gate behind approval" fix itself uses): that job is already gated, so don't
   flag it again. Checking whatever environment the job's own `environment:` key currently
   names — rather than a name this skill would guess — is exactly why that fix always reuses
   an existing `environment:` value when one is present, and only invents a fresh
   `<name>-manual-approval` name (`<name>` being the same `jobs.<name>` from rule 2 above)
   when the job has no `environment:` key yet: without this, a fully-applied fix would still
   show up as an unresolved Finding on every subsequent run.

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
| Pin action to SHA | 1. Split the Finding's `uses:` value at its **last** `@`: everything before is `{ref_prefix}` (e.g. `actions/checkout`, or `org/repo/.github/workflows/build.yml` for a reusable workflow), everything after is `{tag}`. Take `{action_owner}/{action_repo}` as `{ref_prefix}`'s first two `/`-segments — the commits API below is repo-scoped, so any further path segments (a reusable workflow's `.github/workflows/*.yml`) don't apply to it. 2. `gh api repos/{action_owner}/{action_repo}/commits/{tag} --jq .sha` 3. Rewrite the finding's `uses:` line to `uses: {ref_prefix}@{sha} # {tag}` | `{ref_prefix}` is the *whole* original left-hand side, path component included — only the ref after the last `@` is ever replaced, so a reusable workflow's path is preserved rather than collapsed to a bare `owner/repo`. The trailing comment preserves the human-readable version. |
| Restrict trigger — gate behind approval | See *Gating a trigger behind approval* below | The only trigger-restricting fix for `pull_request`/`pull_request_target`; a reachable `push` always uses the row below instead. |
| Restrict trigger — exclude bot branches | Depends on the `push:` block's current filter (`branches:` and `branches-ignore:` can never coexist on the same event — GitHub rejects the workflow if both are present): **no filter at all** → add a fresh `branches-ignore:` list naming the bot's branch prefix(es) (e.g. `['dependabot/**', 'renovate/**']`). **Existing `branches-ignore:`** that just doesn't cover every bot prefix → append the missing prefix(es) to that same list; never add a second `branches-ignore:` key. **Existing `branches:` allowlist** (e.g. `['**']`) → do not add `branches-ignore:` alongside it; instead rewrite the existing `branches:` list in place, adding only the negation patterns not already present (e.g. `branches: ['**', '!dependabot/**', '!renovate/**']`) — GitHub's own documented way to combine include/exclude on one event, and per the Trigger crossing rule above, this is also what clears the Finding on the next audit, so check for existing `!dependabot/**`-style entries first rather than blindly appending (which would otherwise duplicate them on a second run). | **`push` only.** `pull_request`/`pull_request_target`'s own `branches`/`branches-ignore` filters match the PR's *base* branch, not the bot's head branch, so this fix excludes nothing there — per the Trigger crossing rule, those two triggers stay Reachable regardless of branch filtering (see the row above). Use only when the reachable trigger is `push` from a known bot. |
| Enable SHA pinning | Only offered when the Checks table's `enabled` was already `true` (see that row) — this Finding never fires on `enabled: false` in the first place, so there's nothing to check before applying: `gh api --method PUT repos/{owner}/{repo}/actions/permissions -F enabled=true -F sha_pinning_required=true` | Repo-level; requires admin. `enabled` is a **required** body parameter on this endpoint — omitting it is rejected, not defaulted. It's always sent as `true` here, but that's a no-op re-assertion of the repo's already-`true` current value, not a state change — this Finding is never offered for a repo with Actions actually disabled (a `sha_pinning_required` check makes no sense to fix there, and forcing `enabled=true` would silently turn Actions on repo-wide as a side effect of what looks like a narrow fix, a far bigger change than asked for). Both fields are boolean, so both need `-F` (magic type conversion), not `-f` (which would send the string `"true"` against a field typed boolean). `allowed_actions` is optional and safely left out — omitting it preserves the repo's current value rather than resetting it. |
| Branch protection — solo-maintained (1 collaborator) | See *Applying the branch-protection fix* below — `required_approving_review_count=0` | Keeps the PR requirement while requiring zero approvals — the sole collaborator can't approve their own PR. |
| Branch protection — multi-maintainer (2+ collaborators) | See *Applying the branch-protection fix* below — `required_approving_review_count=1` | Always a flat `1` regardless of collaborator count above one; this fix distinguishes only solo from non-solo. `required_approving_review_count`'s valid range is 0–6 either way; not relevant here since the value used is always `1`. |

### Gating a trigger behind approval

Applies only to a reachable `pull_request`/`pull_request_target` job — branch filtering
can't exclude a bot there (see *Restrict trigger — exclude bot branches* above, `push`
only). Referencing an `environment:` name with no protection rules doesn't gate anything:
GitHub auto-creates it with none, and the job runs exactly as if `environment:` were never
added. Steps 1–4 below are what actually restrict the trigger; step 5 only wires the job to
them.

0. **Derive `<env-name>`** (not the same placeholder as `jobs.<name>` in *Trigger crossing*
   above — this one names the GitHub Environment, a separate resource, and a job can only
   ever reference one, as a plain string or a `{name, url}` object, never a list, which is
   exactly why this step and step 5 go to this trouble).
   - If the reachable job **already has an `environment:` key**, take its `name` as
     `<env-name>` — whether the key's value is a bare string or a `{name: ..., url: ...}`
     object; the object form's `url` never belongs in the API URL, only `name` does. Check
     whether any *other* job — in this workflow file or any other under
     `.github/workflows/` — also references that same environment name (read the files
     directly and reason; no parsing script). If so, it's a **shared environment**: don't
     reuse it, since configuring `required_reviewers` on it would silently gate every other
     job that references it too. Report "can't gate `<env-name>` — already shared with
     another job; add a dedicated `environment:` to this job manually" and stop.
   - If no other job references it, reuse that exact `<env-name>` — protect the environment
     this job already references instead of inventing a second one, so step 5 never needs to
     add or replace a key. If the job's `environment:` was the object form, leave the key
     exactly as it already is in step 5 (nothing to wire — the object, `url` included, is
     untouched); the object-vs-string distinction only matters for deriving `<env-name>`
     here, never for what step 5 writes back.
   - Only if the job has no `environment:` key yet, derive one deterministically from the
     job's own name (`<name>` from `jobs.<name>`), so a repeat run recognizes the same
     environment instead of creating a new one each time: `<env-name>` is
     `<name>-manual-approval` — a job named `deploy` gets `deploy-manual-approval`. Step 5
     writes this as the bare-string form (`environment: <env-name>`), since there's no
     existing `url` to preserve.
1. **Check whether it's already gated**: `gh api repos/{owner}/{repo}/environments/<env-name>
   --jq '.protection_rules'` — look for an entry whose `type` is `required_reviewers`,
   distinct from `wait_timer`/`branch_policy`, neither of which involves a human. If present,
   leave it alone. A 404, an empty array, or only `wait_timer`/`branch_policy` entries all
   mean it isn't gated yet — proceeding is safe either way, since this endpoint merges rather
   than replaces: a step-4 `PUT` that only sends `reviewers`/`prevent_self_review` leaves a
   pre-existing `wait_timer` or `deployment_branch_policy` untouched.
2. **Fetch eligible reviewers once**, capped at GitHub's 6-reviewer limit, and reuse for step
   3 too — never re-fetch: `ADMINS=$(gh api repos/{owner}/{repo}/collaborators --jq
   '(map(if .role_name == "admin" then {type:"User", id} else empty end))[0:6]')`. If
   `$ADMINS` is `[]`, stop and report "can't gate `<env-name>` — no eligible reviewer found":
   an empty `reviewers` array creates zero protection rules, the exact no-op this fix exists
   to avoid.
3. **Build the request body** from `$ADMINS`, with `prevent_self_review` set based on whether
   there's a *second* admin collaborator — `true` if so (without it, the PR author could
   rubber-stamp their own gated run if they're in the reviewer list); `false` for exactly one
   admin, the same deadlock-avoidance reasoning as the solo-maintained branch-protection row
   above (the sole eligible reviewer must be able to approve their own run, or the gate
   deadlocks every run it protects, with no one able to unblock it). Note this "one admin"
   count is a different population from the Collaborators check's "solo-maintained" (which
   counts *every* collaborator, any role) — a repo with one admin plus non-admin
   collaborators still hits the `false` branch, since only admins can be environment
   reviewers here: `BODY=$(jq -n --argjson reviewers "$ADMINS" '{reviewers: $reviewers,
   prevent_self_review: ($reviewers[1] != null)}')`.
4. **Send it**: `gh api --method PUT repos/{owner}/{repo}/environments/<env-name> --input -
   <<< "$BODY"` — `--input` is used because `reviewers` is an array of objects, a shape
   `-f`/`-F`'s bracket syntax has no verified construction for; it sends the JSON body
   directly, so there's nothing to get wrong.
5. **Wire the job to it**: add `environment: <env-name>` to the reachable job — but only if
   it didn't already have an `environment:` key in step 0 (in which case `<env-name>` came
   from that existing key, and it's already there). A second `environment:` key would be
   invalid YAML either way, but this makes it structurally impossible rather than something
   to remember to check for.

### Applying the branch-protection fix

The branch-protection endpoint's `PUT` fully replaces the protection object — any field this
fix's payload doesn't send is reset to its default, not left alone. Hand-assembling `-F`/`-f`
flags for only the settings this fix cares about is exactly what makes that dangerous: it's
easy to miss a field GitHub supports (`required_linear_history`, `required_conversation_
resolution`, `lock_branch`, `allow_fork_syncing`, `block_creations`, `require_last_push_
approval`, `bypass_pull_request_allowances`, alongside `restrictions` and the dismissal
settings), silently resetting it while fixing something unrelated. Building the payload by
merging into the actual current state, rather than enumerating fields by hand, is what
guarantees nothing this fix doesn't intend to change gets touched — enumeration can go stale
as GitHub adds fields; merging from the live response can't.

1. **Fetch the current state** — reuse the branch-protection response the Checks table's
   audit already fetched, or re-fetch via the same command if unavailable:
   `CURRENT=$(gh api repos/{owner}/{repo}/branches/{default_branch}/protection)`. A 404 here
   means "not protected at all" (the Checks table's own Finding condition) — treat it as
   `CURRENT='{}'`, since there's nothing existing to preserve.
2. **Determine `required_status_checks`**: existing check-run names (see the literal command
   in step 3) become `{strict: true, contexts: <that array>}` if any exist. If none exist (no
   CI configured yet), there is nothing to name — `required_status_checks` becomes `null`
   instead (status checks genuinely aren't required, an honest reflection of there being no
   CI to check yet), and report "status checks not enabled — no CI workflow exists yet to
   name; add one and re-run this fix," while still applying every other part of this fix
   below. Either way this produces one JSON value, never two conflicting assignments to the
   same key.
3. **Merge and send** — build the full PUT body from `$CURRENT`, overriding only the four
   settings this fix's Finding actually covers (`required_status_checks` from step 2,
   `enforce_admins`, `required_pull_request_reviews.required_approving_review_count`,
   `allow_force_pushes`, `allow_deletions`), reshaping every GET-response field this fix
   doesn't touch into the PUT body's shape (GitHub's GET wraps most booleans as
   `{enabled: bool}` and restriction/dismissal actors as `{login: ...}`/`{slug: ...}` objects;
   the PUT body wants bare booleans and bare login/slug strings) rather than sending them back
   unreshaped, which the endpoint would reject:

   ```bash
   CONTEXTS=$(gh api repos/{owner}/{repo}/commits/{default_branch}/check-runs --jq '[.check_runs[].name] | unique')
   RSC=$(echo "$CONTEXTS" | jq 'if length == 0 then null else {strict: true, contexts: .} end')
   BODY=$(echo "$CURRENT" | jq --argjson rsc "$RSC" --argjson rc <0 or 1> '{
     required_status_checks: $rsc,
     enforce_admins: true,
     required_pull_request_reviews: {
       dismiss_stale_reviews: (.required_pull_request_reviews.dismiss_stale_reviews // false),
       require_code_owner_reviews: (.required_pull_request_reviews.require_code_owner_reviews // false),
       require_last_push_approval: (.required_pull_request_reviews.require_last_push_approval // false),
       dismissal_restrictions: {
         users: [(.required_pull_request_reviews.dismissal_restrictions.users // [])[].login],
         teams: [(.required_pull_request_reviews.dismissal_restrictions.teams // [])[].slug]
       },
       bypass_pull_request_allowances: {
         users: [(.required_pull_request_reviews.bypass_pull_request_allowances.users // [])[].login],
         teams: [(.required_pull_request_reviews.bypass_pull_request_allowances.teams // [])[].slug],
         apps: [(.required_pull_request_reviews.bypass_pull_request_allowances.apps // [])[].slug]
       },
       required_approving_review_count: $rc
     },
     restrictions: (if .restrictions == null then null else {
       users: [(.restrictions.users // [])[].login],
       teams: [(.restrictions.teams // [])[].slug],
       apps: [(.restrictions.apps // [])[].slug]
     } end),
     allow_force_pushes: false,
     allow_deletions: false,
     required_linear_history: (.required_linear_history.enabled // false),
     required_conversation_resolution: (.required_conversation_resolution.enabled // false),
     lock_branch: (.lock_branch.enabled // false),
     allow_fork_syncing: (.allow_fork_syncing.enabled // false),
     block_creations: (.block_creations.enabled // false)
   }')
   gh api --method PUT repos/{owner}/{repo}/branches/{default_branch}/protection --input - <<< "$BODY"
   ```

   `required_pull_request_reviews` must stay a **non-null object** — sending JSON `null` there
   disables "require a pull request before merging" entirely, allowing direct pushes, which is
   not what "skip requiring a second reviewer" (the solo-maintained case, `$rc=0`) asked for.
   `$rc` is `0` for solo-maintained, `1` for multi-maintainer — the only value this fix ever
   varies by team size.

`contexts` (a plain string array) is what's used above rather than GitHub's newer `checks`
field (an array of `{context, app_id}` objects that GitHub's docs say will eventually
replace it) — `contexts` is still live and functional today, and `checks`' array-of-objects
shape has no verified construction. Revisit if GitHub actually removes `contexts` support.

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
