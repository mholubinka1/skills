# Branch Hygiene — Reference

Validation tables and the create command. The step overview is in [SKILL.md](SKILL.md).

## Branch classification table (Step 2)

| Branch | Classification |
|---|---|
| `main`, `master`, `develop` | Trunk — always flag |
| `feature/*` | Feature work |
| `bugfix/*` | Non-critical bug fix |
| `hotfix/*` | Urgent production fix |
| `release/*` | Release preparation |
| `chore/*` | Maintenance, refactor, tooling |
| `wip/*` | Temporary placeholder — must be renamed before code is written |
| `worktree-wip+*` | Temporary placeholder — must be renamed before code is written (the form `EnterWorktree(name: "wip/<slug>")` creates; any other `worktree-*` is Unrecognised) |
| Anything else | Unrecognised — flag and suggest |

## Change type inference heuristics (Step 3)

If `change_type` was not given, infer it from the work summary:

- **feature**: new capability or behaviour — "add X", "implement Y", "as a user I want"
- **bugfix**: restoring broken behaviour — "fix X", "broken", "not working", "wrong result"
- **hotfix**: urgent production fix — "prod is down", "critical", "blocking users"
- **release**: version bump, changelog, release preparation
- **chore**: refactor, tooling, dependency update, test-only change with no behaviour change

## Branch prefix validation table (Step 4)

| Change type | Valid branch prefixes |
|---|---|
| feature | `feature/` |
| bugfix | `bugfix/`, `hotfix/` |
| hotfix | `hotfix/` |
| release | `release/` |
| chore | `chore/`, `feature/` |

A prefix mismatch occurs when:

- The current branch is a trunk branch (`main`, `master`, `develop`)
- The current branch is a `wip/` or `worktree-wip+` placeholder
- The branch prefix doesn't match the change type (e.g. a feature on `bugfix/`)
- The branch name is unrecognised (no valid prefix)

## Branch name relevance rules (Step 5)

A name mismatch occurs when the slug clearly describes **different work** from what is being done now. Common signals:

- The slug references a feature or fix unrelated to the current task (e.g. `config-reload` when adding a CI pipeline)
- The slug is a placeholder (`tmp`, `test`, `wip`, `misc`, `changes`)
- The slug is so generic it provides no signal (`update`, `fix`, `patch`)

Do **not** flag a name mismatch when:

- The slug is a reasonable parent scope for the current work (e.g. `auth` when fixing a login bug)
- The work is a small follow-on to what the branch was originally named for

When in doubt, flag it — a stale branch name causes confusion in PRs and git history.

## Create command (Step 6)

Detect the default branch (read-only):

```bash
git symbolic-ref refs/remotes/origin/HEAD --short
```

This returns something like `origin/main`; strip `origin/` to get `<default-branch>`. The
create command for the report is then:

```bash
git fetch origin <default-branch> && git checkout -b <suggested-branch> origin/<default-branch>
```

If `git symbolic-ref` fails (no remote, or `origin/HEAD` not set), the create command is
`git checkout -b <suggested-branch>` (from local HEAD), and the report's `Skipped / risk`
line says: "Could not detect the default branch; run `git remote set-head origin --auto` to
fix." Uncommitted changes carry over to the new branch either way.
