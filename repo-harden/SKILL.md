---
name: repo-harden
description: Audits the current repo's CI/CD trust boundary — visibility, collaborators, dependabot config, actions pinning, branch protection, and self-hosted-runner exposure — then applies only the fixes the user explicitly selects. Use when the user asks to harden a repo, asks to check its security posture, or mentions a self-hosted runner and a public repo together.
---

# Repo Harden

Audits the repo the session is already in (no owner/repo argument, matching
`update-dependencies`) for gaps in its **trust boundary** — the paths by which an
untrusted PR or bot could reach a self-hosted runner or secrets — then offers fixes for
only the findings the user picks. See the *Checks table* and *Fix commands* sections in
[REFERENCE.md](REFERENCE.md) for every check's exact command and every fix's exact payload.

## At a glance

```text
1 Read-only audit   run every check in REFERENCE.md's Checks table; print at least one
                    report line per check — pass, flagged (a Finding, one line per item
                    when a check flags several), or skipped — never omit a check
2 Fix phase         findings only → one or more AskUserQuestion calls, multiSelect, one
                    option per individual Finding; apply only what's picked
3 Summary           findings first, then which fixes were applied, refused, or unselected
```

## Step 1 — Run the read-only audit

Run every check below against the current repo. A check that fails from insufficient `gh`
permission (typically HTTP 403) is reported as **"skipped — insufficient permission"**; move
on to the next check rather than aborting the run. A 404 from the branch-protection endpoint
is not a permission failure — it means the branch has no protection configured, which is
itself a plain "not protected" result to report.

- **Visibility & collaborators** — one `gh repo view` call (see *Checks table* in
  REFERENCE.md for its exact fields — it also resolves `{owner}`, `{repo}`, and
  `{default_branch}` for every other check below) and `gh api
  repos/{owner}/{repo}/collaborators`. Reported as **context, not a fixable Finding** — no
  fix-phase option, since changing a repo's visibility or a collaborator's access isn't a
  call this skill makes on the user's behalf. Report visibility plainly, and each
  collaborator with their permission level. A single collaborator marks this repo
  **solo-maintained** — remember this for Step 2's branch-protection fix sizing.
- **Reachable self-hosted jobs** — read every file under `.github/workflows/` with `Read`
  and reason per job (no YAML-parsing script): cross each job's `runs-on:` against the
  workflow's effective trigger. A self-hosted/custom-label runner reachable by
  `pull_request`, `pull_request_target`, or an under-filtered `push` is a **Reachable
  self-hosted job** finding — one per job. "Under-filtered" covers an arbitrary-matching
  `branches:` allowlist (e.g. `['**']`) as well as a `branches-ignore:` that exists but
  doesn't name every bot prefix actually in play (e.g. only `['main']`, still letting
  `dependabot/**` through) — presence of the key proves nothing on its own. See *Trigger
  crossing* in REFERENCE.md for the exact rule and its two worked fixtures.
- **Dependabot config** — reported as **context, not a fixable Finding** (no fix-phase
  option, same treatment as secrets exposure): does `.github/dependabot.yml` (or
  equivalent) exist, and do the PRs it opens land in-repo on a branch pattern that would
  trigger a build.
- **Actions pinning** — every `uses:` pinned to a tag or branch instead of a full commit SHA
  is a **Finding**, one per occurrence (same action pinned in two places is two findings,
  since each is rewritten at its own file/line). Separately check `sha_pinning_required`:
  the repo-level value's `false` is itself a **Finding**, but only when Actions is actually
  enabled for the repo (`enabled: true`) — fixing it would otherwise silently turn Actions on
  repo-wide as a side effect, a far bigger change than "enable SHA pinning" implies, so a
  disabled repo gets this reported as context instead. When `enabled` is `true`, it's always
  offerable in Step 2 even in a repo with no other findings. When `{owner}` is an
  organization, also report the org-level value as context — it isn't itself a fixable
  Finding, since enabling it would change every repo in the org at once, a larger blast
  radius than any other fix this skill offers. See *Checks table* in REFERENCE.md for both
  commands.
- **Branch protection** — the default branch's protection settings (see *Checks table* in
  REFERENCE.md for the exact command): required status checks, PR requirement, force-push/
  delete restriction, admin enforcement. Report each sub-setting on its own line; if any is
  missing or unsafe, that's one combined **Finding** for the branch as a whole (not one per
  sub-setting) — its single fix-phase option applies every missing setting in one atomic
  payload, matching the one combined command in the Fix commands table.
- **Secrets exposure** — a job with self-hosted/runner-level access that also has
  `secrets:` or `${{ secrets.* }}` in scope is reported as **context, not a fixable
  Finding** — there's no safe automated fix (removing a job's secrets access requires
  knowing whether it legitimately needs them, a call this skill can't make, and rotating or
  auditing the secret values themselves is out of scope). This check does not itself
  re-check trigger reachability — worth reporting even behind an admin-only trigger like
  `workflow_dispatch`, since a later trigger change would otherwise reopen an unreviewed
  exposure with no record it was ever flagged; reachability is what the separate Reachable
  self-hosted job finding is for.

**Done** when every check above has printed at least one report line — pass, flagged, or
skipped — with no check silently omitted, whether or not any finding turned up. A check that
flags more than one item (a collaborator per line, a Reachable self-hosted job per job, an
unpinned action per occurrence) prints one line per item, not a single combined line —
"at least one," not "exactly one," is what every check owes the report.

## Step 2 — Run the fix phase

Skip this step entirely if Step 1 found zero Findings — say so and stop; nothing changes.

Otherwise, present one option per individual Finding from Step 1 (never grouped by
category — one unpinned action is one option, one over-broad trigger is another) via
`AskUserQuestion`, every question `multiSelect: true`. `AskUserQuestion` requires 2 to 4
options per question and allows up to 4 questions per call: 2 to 4 Findings fit in one
question; more than 4 need multiple questions (up to 4 per question, up to 16 Findings in one
call); more than 16 need further calls, until every Finding has been offered exactly once. If
a question would otherwise carry only **one** Finding-option — the whole audit found exactly
one Finding, or a final batch has exactly one left over — add a second, non-Finding option to
that question ("Skip — apply nothing") so it always has at least 2 real options; that option
is never itself an outcome to apply, it only satisfies the tool's own minimum. Combine the
selections from every question and call into a single set before applying anything. If that
combined set is empty, report "no fixes selected — nothing changed" and stop; the repo is
left exactly as audited. For each Finding the user did select, apply its fix from the Fix
commands table in REFERENCE.md:

- **Pin action** → resolve the tag to a commit SHA (see *Fix commands* in REFERENCE.md for
  the exact command) and rewrite that `uses:` line to the SHA, keeping the original version
  as a trailing comment (`uses: actions/checkout@{sha} # v4`).
- **Restrict trigger** → for `pull_request`/`pull_request_target`, branch filtering can't
  exclude a bot (it matches the PR's *base* branch, not the bot's head branch), so gate the
  job behind a genuinely protected `environment:` requiring manual approval instead — the
  only trigger-restricting option for those two events, and adding the `environment:` line
  alone is not enough on its own. See *Fix commands* in REFERENCE.md for the full
  check-then-configure-then-wire sequence. For a reachable `push`, the rewrite depends on its
  current filter (no filter, an existing `branches-ignore:`, or a `branches:` allowlist) —
  see *Fix commands* in REFERENCE.md for all three cases.
- **Enable SHA pinning** → the Actions permissions API; see *Fix commands* in REFERENCE.md
  for the exact command.
- **Branch protection** → size the payload to the collaborator count from Step 1: a
  solo-maintained repo skips requiring any approving review — the sole collaborator can't
  approve their own PR, so requiring even one would make every PR unmergeable — but still
  requires status checks and blocks force-push/delete, same as a multi-maintainer repo. See
  *Fix commands* in REFERENCE.md for the exact payloads.

If the harness's own permission layer refuses a settings change (e.g. a tool-use denial),
report the refusal on that finding's line and move to the next selected fix — never retry
around it or attempt an alternate path to the same change.

**Done** when every selected option has an applied/refused result and every unselected
option is confirmed untouched.

## Step 3 — Report

A short written summary: **Findings** first (every flagged check from Step 1, plain
language), then **Fixes** (which selected fixes were applied, which were refused by the
harness and why, and a one-line reminder that unselected findings were left as-is). Skipped
checks and passing checks are already covered in Step 1's report and don't need repeating
here beyond a one-line "N checks passed, M skipped" roll-up.

**Done** when the summary names every Step 1 finding and every Step 2 fix decision, in
that order.

## Out of scope

Rotating or auditing secret values, runner OS hardening, and zizmor — never attempted here.
See *Out of scope* in REFERENCE.md for the full list and rationale.
