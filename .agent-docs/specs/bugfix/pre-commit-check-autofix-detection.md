# pre-commit-check detects autofixes by content hash

## Problem Statement

Audit finding PCC-1 (#143; GitHub issue #146): `pre-commit-check` finds the files its hooks
autofixed by recording `git diff --name-only` before and after each pass and taking the
names that appear only afterwards. A file that was already modified before the pass is in
both lists, so when a hook rewrites it the autofix goes undetected. The file is then
missing from "Files autofixed", and the caller is never told to stage it, or that it holds
drift fixes.

## Solution

Snapshot each dirty file's content hash before and after a pass. A file is autofixed when
it is new to the after-snapshot or its hash changed.

## User Stories

1. As a caller that has edited a file, I want a hook's autofix to that same file reported,
   so that I stage the fixed version with my commit.
2. As a caller, I want a clean file that a hook rewrites still reported as autofixed, so
   that the existing behaviour is kept.

## Implementation Decisions

- **`pre-commit-check` SKILL, "Handling failures"**: the snapshot is
  `git ls-files --modified --others --exclude-standard`, minus the paths
  `git ls-files --deleted` prints, each with its `git hash-object` hash. It is taken before
  and after each pass, including the confirming re-run.
- **Autofixed set**: a file in the after-snapshot that was missing from the
  before-snapshot, or is in both with a different hash.
- Only files that differ from the index or are untracked are hashed. A clean file a hook
  rewrites becomes modified, so it is new to the after-snapshot; hashing the whole tree is
  not needed.
- Deleted files are left out because `git hash-object` fails on a missing path.
- **`allowed-tools`** gains `Bash(git hash-object *)`. `git ls-files *` is already scoped.
  `git diff *` stays: it still collects the changed set.

## Testing Decisions

- Prose change to a skill definition; there is no executable behaviour to test red-green.
- The frontmatter guard tests cover the new `allowed-tools` entry.
- The snapshot commands were run by hand in this repo against an already-modified file to
  confirm the hash changes when its content does.

## Out of Scope

- The rest of the skill's flow, the report shape, and the `next:` rules.
- Detecting files a hook deletes.

## Further Notes

Closes #146.
