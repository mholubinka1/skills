---
name: repo-harden
description: Audits the current repo's CI/CD trust boundary, then applies only the fixes the user explicitly selects. Use when the user asks to harden a repo or check its security posture, or mentions a self-hosted runner and a public repo together.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Edit
  - AskUserQuestion
  - Bash(gh repo view *)
  - Bash(gh api repos/*)
  - Bash(gh api --paginate repos/*)
  - Bash(gh api users/*)
  - Bash(gh api orgs/*)
---

# Repo Harden

Audits the repo the session is already in (no owner/repo argument) for gaps in its **trust boundary** — the paths by which an
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
on to the next check. Two exceptions: a 403 on the Visibility check aborts the whole run,
reported as "can't run — no read access to this repo", because every later check needs the
`{owner}`/`{repo}`/`{default_branch}` it resolves; and a 404 from the branch-protection
endpoint is not a permission failure — it is a plain "not protected" result.

Each bullet gives the check's report rule; REFERENCE.md's *Checks table* holds its exact
command and fields.

- **Visibility & collaborators** — **context, not a fixable Finding**. Report visibility
  plainly, and each collaborator with their permission level. A single collaborator marks the
  repo **solo-maintained**, which sizes Step 2's branch-protection fix.
- **Reachable self-hosted jobs** — read every file under `.github/workflows/` with `Read` and
  reason per job: cross each job's `runs-on:` against the workflow's effective trigger. A
  self-hosted/custom-label runner reachable by `pull_request`, `pull_request_target`, or an
  under-filtered `push` is a **Reachable self-hosted job** Finding, one per job. See *Trigger
  crossing* in REFERENCE.md for the exact rule, including what "under-filtered" means.
- **Dependabot config** — **context, not a fixable Finding**: does `.github/dependabot.yml`
  (or equivalent) exist, and do the PRs it opens land in-repo on a branch pattern that would
  trigger a build.
- **Actions pinning** — every `uses:` pinned to a tag or branch instead of a full commit SHA
  is a **Finding**, one per occurrence. Separately, a repo-level `sha_pinning_required` of
  `false` is a **Finding** only when Actions is enabled for the repo (`enabled: true`);
  otherwise report it as context. When `{owner}` is an organization, also report the org-level
  value as context, not a Finding.
- **Branch protection** — report each sub-setting on its own line: required status checks, PR
  requirement, force-push/delete restriction, admin enforcement. If any is missing or unsafe,
  that is one combined **Finding** for the branch as a whole, fixed by one atomic payload.
- **Secrets exposure** — **context, not a fixable Finding**: a job with self-hosted/runner-level
  access that also has `secrets:` or `${{ secrets.* }}` in scope. Report it whatever the
  job's trigger, since a later trigger change would otherwise reopen an unflagged exposure;
  reachability is the separate Reachable self-hosted job check.

**Done** when every check above has printed at least one report line — pass, flagged, or
skipped — with no check silently omitted, whether or not any finding turned up. The one
exception is a Visibility 403, which ends the audit at that check. A check that
flags more than one item (a collaborator per line, a Reachable self-hosted job per job, an
unpinned action per occurrence) prints one line per item, not a single combined line —
"at least one," not "exactly one," is what every check owes the report.

## Step 2 — Run the fix phase

If Step 1 found zero Findings, say so (nothing changes) and go to Step 3.

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
combined set is empty, report "no fixes selected — nothing changed" and go to Step 3; the
repo is left exactly as audited. For each Finding the user did select, apply its fix from the Fix
commands table in REFERENCE.md:

- **Pin action** → rewrite that `uses:` line to the commit SHA, keeping the original version
  as a trailing comment (`uses: actions/checkout@{sha} # v4`). The *Fix commands* table in
  REFERENCE.md has the SHA lookup.
- **Restrict trigger** → for `pull_request`/`pull_request_target`, gate the job behind a
  protected `environment:`; for a reachable `push`, rewrite its branch filter. See *Fix
  commands* in REFERENCE.md for the full sequence and all three `push` cases.
- **Enable SHA pinning** → the Actions permissions API; exact command in *Fix commands*.
- **Branch protection** → size the payload to the collaborator count from Step 1 (a
  solo-maintained repo requires zero approving reviews, since the sole collaborator can't
  approve their own PR); exact payloads in *Fix commands*.

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

See *Out of scope* in REFERENCE.md.
