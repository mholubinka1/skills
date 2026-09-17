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
1 Read-only audit   run every check in REFERENCE.md's Checks table; print one report line
                    per check — pass, flagged (a Finding), or skipped — never omit a line
2 Fix phase         findings only → one AskUserQuestion, multiSelect, one option per
                    individual Finding; apply only what's picked
3 Summary           findings first, then which fixes were applied/declined/refused
```

## Step 1 — Run the read-only audit

Run every check below against the current repo. A check that fails from insufficient `gh`
permission (typically HTTP 403) is reported as **"skipped — insufficient permission"**; move
on to the next check rather than aborting the run. A 404 from the branch-protection endpoint
is not a permission failure — it means the branch has no protection configured, which is
itself a plain "not protected" result to report.

- **Visibility & collaborators** — `gh repo view --json visibility` and
  `gh api repos/{owner}/{repo}/collaborators`. Report visibility plainly, and each
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
  crossing* in REFERENCE.md for the exact rule and worked fixture.
- **Actions pinning** — every `uses:` pinned to a tag or branch instead of a full commit SHA
  is a **Finding**, one per occurrence (same action pinned in two places is two findings,
  since each is rewritten at its own file/line). Separately check `sha_pinning_required`:
  the repo-level value's `false` is itself a **Finding** (fixed by enabling it), so it's
  always offerable in Step 2 even in a repo with no other findings. When `{owner}` is an
  organization, also report the org-level value as context — it isn't itself a fixable
  Finding, since enabling it would change every repo in the org at once, a larger blast
  radius than any other fix this skill offers. See *Checks table* in REFERENCE.md for both
  commands.
- **Dependabot config** — does `.github/dependabot.yml` (or equivalent) exist, and do the
  PRs it opens land in-repo on a branch pattern that would trigger a build.
- **Branch protection** — `gh api repos/{owner}/{repo}/branches/{branch}/protection` on the
  default branch: required status checks, PR requirement, force-push/delete restriction,
  admin enforcement. Report each sub-setting.
- **Secrets exposure** — a job with self-hosted/runner-level access that also has
  `secrets:` or `${{ secrets.* }}` in scope is reported as **context, not a fixable
  Finding** — there's no safe automated fix (removing a job's secrets access requires
  knowing whether it legitimately needs them, a call this skill can't make, and rotating or
  auditing the secret values themselves is out of scope). This check does not itself
  re-check trigger reachability — worth reporting even behind an admin-only trigger like
  `workflow_dispatch`, since a later trigger change would otherwise reopen an unreviewed
  exposure with no record it was ever flagged; reachability is what the separate Reachable
  self-hosted job finding is for.

**Done** when every check above has printed exactly one report line — pass, flagged, or
skipped — with no check silently omitted, whether or not any finding turned up.

## Step 2 — Run the fix phase

Skip this step entirely if Step 1 found zero Findings — say so and stop; nothing changes.

Otherwise, issue one `AskUserQuestion` with `multiSelect: true` and one option per
individual Finding from Step 1 (never grouped by category — one unpinned action is one
option, one over-broad trigger is another). If the answer selects none of them, report
"no fixes selected — nothing changed" and stop; the repo is left exactly as audited. For
each option the user did select, apply its fix from the Fix commands table in
REFERENCE.md:

- **Pin action** → resolve the tag to a commit SHA (`gh api repos/{action}/commits/{tag}`)
  and rewrite that `uses:` line to the SHA, keeping the original version as a trailing
  comment (`uses: actions/checkout@<sha> # v4`).
- **Restrict trigger** → for `pull_request`/`pull_request_target`, `branches-ignore:`
  doesn't work (it filters the PR's base branch, not the bot's head branch), so gate the job
  behind an `environment:` requiring manual approval instead — the only trigger-restricting
  option for those two events. For a reachable `push`: if it has no branch filter yet, add a
  fresh `branches-ignore:` naming the bot's prefix; if it already has one, append the missing
  prefix to it; if it has a `branches:` allowlist instead (`branches:` and `branches-ignore:`
  can never coexist on one event), rewrite that allowlist in place with negation patterns
  (`!dependabot/**`) rather than adding a second key. See *Fix commands* in REFERENCE.md for
  all three cases.
- **Enable SHA pinning** → the Actions permissions API.
- **Branch protection** → size the payload to the collaborator count from Step 1: a
  solo-maintained repo skips requiring any approving review — the sole collaborator can't
  approve their own PR, so requiring even one would make every PR unmergeable — but still
  requires status checks and blocks force-push/delete, same as a multi-maintainer repo.

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
