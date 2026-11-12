# create-worktrees checks and writes the .claude ignore rule correctly

## Problem Statement

Two audit findings (#143; GitHub issue #152) in `create-worktrees` Step 3, which makes sure
`.claude` is gitignored before a worktree is created under it:

- **CW-2**: the check is `grep -qxE '\.claude/?' .gitignore`. It matches only the two
  spellings `.claude` and `.claude/` in the root `.gitignore`. A repo that ignores it as
  `/.claude`, in `.git/info/exclude`, or through a global excludes file is reported as
  missing, and the skill commits a redundant entry.
- **CW-3**: the entry is added with `echo '.claude' >> .gitignore`. When the file's last
  line has no trailing newline, `.claude` is glued onto that line, which breaks the
  existing rule and adds no working new one.

## Solution

Ask git whether the path is ignored, and append the entry with a leading newline.

## User Stories

1. As a user whose repo already ignores `.claude` by any rule git honours, I want Step 3
   to see that, so that no redundant commit is made.
2. As a user whose `.gitignore` has no trailing newline, I want the new entry on its own
   line, so that the existing last rule keeps working and the new one takes effect.
3. As a user, I want the skill to confirm the rule works after adding it, so that the
   worktree is never created under an unignored directory.

## Implementation Decisions

- **`create-worktrees` SKILL, Step 3, check (CW-2)**:
  `git check-ignore -v .claude/worktrees`. Exit 0 means ignored and prints the rule's
  source; exit 1 means not ignored; any other exit is an error to stop on. The probe path
  is the directory the worktree will be created in, so a directory-only rule (`.claude/`)
  matches even before `.claude` exists.
- **Step 3, write (CW-3)**: `printf '\n.claude\n' >> .gitignore`, then the same check again;
  the step continues only on exit 0. A file that already ends in a newline gains one blank
  line, which is harmless.
- **`allowed-tools`**: `grep -qxE *`, `echo present` and `echo missing` are removed. The
  exact `git check-ignore` call and the exact `printf` append are added.

## Testing Decisions

- Prose change to a skill definition; there is no executable behaviour to test red-green.
- The frontmatter guard tests cover the `allowed-tools` change.
- Both commands were run in a throwaway repo: `git check-ignore` exits 0 for `.claude`,
  `.claude/`, `/.claude`, `/.claude/` and `**/.claude`, and 1 for an unrelated rule or no
  `.gitignore`; the `printf` append onto a file ending `foo` with no newline leaves `foo`
  and `.claude` on separate lines, and the check then exits 0.

## Out of Scope

- The other steps of `create-worktrees`, and other audit findings against it.

## Further Notes

Closes #152.
