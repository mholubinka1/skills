---
name: branch-hygiene
description: Validate the current git branch before starting work. Checks autoSetupRemote config, detects trunk branches, validates branch prefix against change type, and checks that the branch name is relevant to the current work. Accepts an optional change_type (feature, bugfix, hotfix, release, chore) — if not provided, infers it from the user's request. Use at the start of any work session, or invoke from other skills with a known change_type.
---

# Branch Hygiene

Validates that you are on the right branch before work begins. Can be run in two modes:

- **Fast mode** (no `change_type`): checks `autoSetupRemote` and warns if on a trunk branch. Infers change type from the user's request using heuristics.
- **Full mode** (`change_type` provided): performs all checks including prefix validation against the confirmed change type.

## Step 1: Check autoSetupRemote

Run:

```bash
git config push.autoSetupRemote
```

If the output is not `true`, warn the user:

> `push.autoSetupRemote` is not enabled. New branches won't be tracked upstream automatically when pushed. Run `git config --global push.autoSetupRemote true` to enable it, or branches will need `--set-upstream` on first push.

Ask if they want it set before continuing.

## Step 2: Detect current branch

Run:

```bash
git branch --show-current
```

Classify the branch:

| Branch | Classification |
|---|---|
| `main`, `master`, `develop` | Trunk — always flag |
| `feature/*` | Feature work |
| `bugfix/*` | Non-critical bug fix |
| `hotfix/*` | Urgent production fix |
| `release/*` | Release preparation |
| `chore/*` | Maintenance, refactor, tooling |
| `wip/*` | Temporary placeholder — must be renamed before code is written |
| Anything else | Unrecognised — flag and suggest |

## Step 3: Determine change type

If `change_type` was passed by the calling skill or context, use it directly.

Otherwise, infer from the user's request using these heuristics:

- **feature**: new capability or behaviour — "add X", "implement Y", "as a user I want"
- **bugfix**: restoring broken behaviour — "fix X", "broken", "not working", "wrong result"
- **hotfix**: urgent production fix — "prod is down", "critical", "blocking users"
- **release**: version bump, changelog, release preparation
- **chore**: refactor, tooling, dependency update, test-only change with no behaviour change

## Step 4: Validate branch prefix against change type

| Change type | Valid branch prefixes |
|---|---|
| feature | `feature/` |
| bugfix | `bugfix/`, `hotfix/` |
| hotfix | `hotfix/` |
| release | `release/` |
| chore | `chore/`, `feature/` |

A prefix mismatch occurs when:

- The current branch is a trunk branch (`main`, `master`, `develop`)
- The current branch is a `wip/` placeholder
- The branch prefix doesn't match the change type (e.g. a feature on `bugfix/`)
- The branch name is unrecognised (no valid prefix)

## Step 5: Validate branch name relevance

Extract the descriptive slug — everything after the `/` — and assess whether it relates to the current work description.

A name mismatch occurs when the slug clearly describes **different work** from what is being done now. Common signals:

- The slug references a feature or fix unrelated to the current task (e.g. `config-reload` when adding a CI pipeline)
- The slug is a placeholder (`tmp`, `test`, `wip`, `misc`, `changes`)
- The slug is so generic it provides no signal (`update`, `fix`, `patch`)

Do **not** flag a name mismatch when:

- The slug is a reasonable parent scope for the current work (e.g. `auth` when fixing a login bug)
- The work is a small follow-on to what the branch was originally named for

When in doubt, flag it — a stale branch name causes confusion in PRs and git history.

## Step 6: Resolve mismatch

On any mismatch (prefix or name), suggest a well-formed branch name derived from the work description:

> You're on `feature/config-reload` but this work is adding a CI pipeline. Suggested branch: `chore/add-ci-checks`. Create it and move your work there? (yes/no)

If the user confirms, first detect the default branch and fetch it:

```bash
git symbolic-ref refs/remotes/origin/HEAD --short
```

This returns something like `origin/main`. Strip the `origin/` prefix to get the default branch name.

If the command succeeds, fetch it:

```bash
git fetch origin <default-branch>
```

Then create the new branch from the fetched remote ref:

```bash
git checkout -b <suggested-branch> origin/<default-branch>
```

If `git symbolic-ref` fails (no remote, or `origin/HEAD` not set), warn the user:

> Could not detect default branch — no remote or `origin/HEAD` not set. Creating branch from local HEAD instead. Run `git remote set-head origin --auto` to fix this.

Then fall back to:

```bash
git checkout -b <suggested-branch>
```

Any uncommitted changes carry over automatically. **Do not push or commit to the new branch.**

If there is no mismatch, confirm the branch is appropriate and continue.
