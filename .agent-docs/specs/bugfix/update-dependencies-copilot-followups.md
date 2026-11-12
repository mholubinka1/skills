# update-dependencies: Copilot review follow-ups from PR #163

## Problem Statement

PR #163 (the UD-1 to UD-6 audit follow-ups) merged before its Copilot review landed. The
review left three findings against `update-dependencies`, each with a concrete failing case:

- **Stash lookup collision**: the stash message carries a timestamp with one-second
  precision. Two sessions stashing in the same second produce the same message, so the
  lookup by message can pick the other session's SHA.
- **Stale hashes on a bumped pin**: the plain-pip flow changes `==<old>` to `==<new>` and
  leaves the line's `--hash` options alone. Those hashes belong to the old release, so the
  install fails pip's hash check and the commit holds an uninstallable file.
- **Hook rewrite of an already-modified file**: Step 4 compares the paths
  `git status --porcelain` lists before and after the hooks. A manifest this run already
  changed reads `M` both times, so a hook's rewrite of it is neither reported nor kept out
  of the commit.

## Solution

Add sub-second precision to the stash message and stop when the message still matches more
than one entry. Skip hash-checked pins and report them. Stage the run's changes before the
hooks, so a diff against the index shows every file a hook rewrote.

## User Stories

1. As a user running two sessions at once, I want the skill to stop when it cannot tell its
   stash from another's, so that it never applies someone else's work.
2. As a user of a hash-checked `requirements.txt`, I want hashed pins left alone and
   reported, so that the file stays installable.
3. As a user whose hooks reformat a manifest, I want that rewrite listed in the report, so
   that I know the commit holds more than the version bump.

## Implementation Decisions

- **SKILL Step 1**: the timestamp is `date +%F-%H%M%S-%N`. Where `date` has no `%N`, the
  message falls back to one-second precision, so the lookup also requires exactly one
  matching line. More than one stops the run, with every stash left in place and each
  matching SHA reported. `date +%F*` in `allowed-tools` already covers the new format.
- **REFERENCE, plain pip**: a pin with `--hash` options, on its line or on continuation
  lines, is left unchanged and reported as skipped. Regenerating hashes needs a tool this
  flow does not have.
- **SKILL Step 4**: after `pre-commit autoupdate`, the run stages its manifests, lockfiles
  and `.pre-commit-config.yaml` by path, then notes what `git diff --name-only` still lists:
  tracked files Step 3 changed that are not staged, such as a regenerated `.pnp.cjs`. After
  the hooks, a file `git diff --name-only` lists that was not noted was rewritten by a hook,
  and new untracked entries in `git status --porcelain` are files a hook created. A hook
  rewrite of a file already noted is not detected.
- **Hook rewrite of a staged file**: the file is staged again and the autofix is reported as
  committed. Committing the pre-hook version instead would make the commit fail the repo's
  own hooks wherever pre-commit is installed as a git hook. Autofixes to any other file stay
  unstaged, as before.
- **SKILL Step 7**: each autofix is reported as committed or uncommitted.

## Testing Decisions

- These are prose changes to a skill definition; there is no executable behaviour to test
  red-green.
- `allowed-tools` is unchanged, and the frontmatter guard tests
  (`tests/test_skill_frontmatter.py`) still pass.

## Out of Scope

- Regenerating `--hash` values for plain-pip requirements.
- Handling a commit that a hook rejects for a reason other than an autofix.

## Further Notes

Follow-up to PR #163; no GitHub issue. This branch also ticks the acceptance criteria left
unticked in the issues file for `bugfix/update-dependencies-audit-followups`, whose PR
merged before `pr-cleanup` ran.
