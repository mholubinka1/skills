# update-dependencies audit follow-ups (UD-1 to UD-6)

## Problem Statement

The writing-for-agents skill audit (#143) left six findings against `update-dependencies`
open (GitHub issue #151). Two can destroy the user's work:

- **UD-1**: the skill restores its stash with a bare `git stash pop`. The stash stack is
  shared across worktrees and sessions, so the top entry may be someone else's.
- **UD-2**: the plain-pip flow ends with `pip freeze > requirements.txt`, which replaces the
  file with every package in the environment and drops its comments and markers.
- **UD-3**: the stash is restored before the updates run, so the user's in-progress edits
  sit in the working tree while the skill stages and commits.
- **UD-4**: the trunk and the new branch name are given as "e.g." examples
  (`main`/`master`, `chore/update-dependencies`), so the agent guesses, and a second run
  collides with the first run's branch.
- **UD-5**: files that `pre-commit run --all-files` rewrites are left in the working tree
  and never mentioned.
- **UD-6**: `yarn outdated` and `yarn upgrade` do not exist in Yarn 2 and later.

## Solution

Name the stash by SHA and restore it only after the commit. Edit `requirements.txt` pins in
place. Resolve the default branch from the remote and date the branch name. List hook
autofixes in the report. Choose the yarn commands by version.

## User Stories

1. As a user with another session's entry on top of the stash stack, I want the skill to
   restore its own stash by SHA, so that it never applies or removes someone else's work.
2. As a user with uncommitted edits, I want them restored only after the dependency commit,
   so that they cannot be staged into it.
3. As a user of a plain `requirements.txt`, I want only the bumped pins changed, so that
   the file keeps its comments, markers and scope.
4. As a user whose default branch is not `main`, I want the skill to resolve it from the
   remote, so that it syncs with the right branch.
5. As a user running the skill twice, I want a dated branch name, so that the second run
   does not fail on an existing branch.
6. As a user, I want files rewritten by `pre-commit run --all-files` listed in the report,
   so that I know they are sitting uncommitted in my working tree.
7. As a user of Yarn 3 or later, I want the skill to run commands that exist there, so that
   the Node update does not fail.

## Implementation Decisions

- **UD-1, UD-3 — SKILL Step 1 and Step 6**: Step 1 stashes with a timestamped message and
  reads the entry's SHA from `git stash list --format='%H %gs'`. The stash stays set aside
  through the update, hooks, validation and commit. Step 6 restores it with
  `git stash apply <sha>` after the commit, or straight away when nothing was committed.
  The entry is left on the stack and reported: `git stash drop` is not pre-approved (the
  frontmatter guard treats it as destructive), and a user who can see their work is back
  can drop it safely. Every early stop reports the SHA.
- **UD-4 — SKILL Step 1**: the default branch comes from
  `git symbolic-ref refs/remotes/origin/HEAD --short`; a failure stops the run with the fix
  (`git remote set-head origin --auto`). The new branch is
  `chore/update-dependencies-<YYYY-MM-DD>`, with a numeric suffix when taken.
- **UD-5 — SKILL Step 4 and Step 7**: `git status --porcelain` before and after
  `pre-commit run --all-files`; files listed only afterwards are the hook autofixes. They
  stay unstaged and are listed by path in the report. With the stash set aside, the tree
  before the hooks holds only this run's manifest changes.
- **UD-2 — REFERENCE, plain pip**: change each bumped package's `==` pin on its own line,
  then `pip install -r requirements.txt`. `pip freeze` is named as forbidden, with the
  reason.
- **UD-6 — REFERENCE, yarn**: `yarn --version` picks the flow. 1.x keeps
  `yarn outdated` / `yarn upgrade`. 3 and later runs `yarn up -R '**'`, which re-resolves
  within the declared ranges and leaves `package.json` alone; it has no non-interactive
  outdated listing, so majors are reported as not checked. 2.x is reported and skipped.
- **`allowed-tools`**: adds `Edit`, the `symbolic-ref` call, `git branch --show-current`,
  `date +%F*`, `git stash list *`, `git stash apply *`, `pip install -r requirements.txt`,
  `yarn --version` and `yarn up -R *`.
- The glossary entry for Dependency update says "the default branch" instead of
  `main`/`master`.

## Testing Decisions

- These are prose changes to a skill definition; there is no executable behaviour to test
  red-green.
- The frontmatter guard tests (`tests/test_skill_frontmatter.py`) cover the new
  `allowed-tools` entries.
- `yarn up -R '**'` is taken from Yarn's CLI documentation and was not run here.

## Out of Scope

- Other audit findings against this skill not listed in #151.
- Dropping the stash entry automatically.
- New ecosystems or changes to the other package managers' flows.

## Further Notes

Closes #151. This branch also ticks the acceptance criteria left unticked in the issues file
for `bugfix/address-copilot-push-resolve-poll`, whose PR (#162) merged before `pr-cleanup`
ran.
