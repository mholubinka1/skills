# pr-cleanup closes only its own issues; create-issues writes Given-When-Then criteria

## Problem Statement

Three audit findings (#143) across two skills that share one file, the local issues file
(GitHub issues #145 and #155):

- **PRC-1**: `pr-cleanup` extracts "all GitHub issue numbers referenced in the file" and
  closes each. A slice's **Blocked by** line names another branch's issue, so that issue is
  closed too, before its work is done.
- **PRC-4**: `pr-cleanup` Step 1 sets `$BRANCH` and Step 2 reads it. Shell variables do not
  persist between Bash calls, so Step 2 reads an empty path.
- **CI-2**: the `create-issues` templates show acceptance criteria as "Criterion 1 /
  Criterion 2". `create-issues` Step 4 asks for Given-When-Then scenarios and `bdd` skips
  its planning step only when it finds them, so criteria written to the template's shape
  force the planning to be redone.

## Solution

Give each slice in the issues file a `**GitHub issue**` field holding its own issue number,
and have `pr-cleanup` close only those. Have `pr-cleanup` note the branch name instead of
relying on a variable. Make both `create-issues` templates Given-When-Then.

## User Stories

1. As a user whose slice is blocked by another branch's issue, I want `pr-cleanup` to leave
   that issue open, so that unfinished work is not marked done.
2. As a user, I want `pr-cleanup` to close every issue the branch implements, so that the
   tracker matches the merged work.
3. As an agent running `pr-cleanup`, I want the branch name carried as a noted value, so
   that the issues file path resolves in a later Bash call.
4. As an agent running `bdd` on a slice, I want its acceptance criteria already in
   Given-When-Then form, so that I can confirm them and skip planning.

## Implementation Decisions

- **`create-issues` REFERENCE, local issues file template**: each slice gains
  `**GitHub issue**: not yet published` above `**Blocked by**`. After publishing, the
  slice's own number replaces the placeholder. A short note under the template states what
  each of the two fields means.
- **`create-issues` REFERENCE, both templates**: criteria are
  `Given <starting state>, when <action or event>, then <observable outcome>.` The GitHub
  issue body carries the slice's criteria word for word.
- **`create-issues` SKILL**: Step 5 says each criterion is an approved Step 4 scenario,
  unchanged; the Step 6 handover names both fields to write numbers into.
- **`pr-cleanup` SKILL, Step 2 and Step 4 (PRC-1)**: issue numbers come only from
  `**GitHub issue**: #<n>` lines. The older spelling `**GitHub**: #<n>`, used by 22 existing
  slices in this repo, is accepted too. When no number is collected — neither field is
  present, or every field still reads `not yet published` — nothing is closed and the
  report says so.
- **`pr-cleanup` SKILL, Step 1 (PRC-4)**: `git branch --show-current` runs on its own and
  the agent notes its output as `<branch-name>`; `$BRANCH` is gone.
- **`allowed-tools`**: neither skill runs a new command, so neither list changes.

## Testing Decisions

- Prose changes to skill definitions; there is no executable behaviour to test red-green.
- The existing `unittest` suite must still pass.
- This branch's own issues file uses the new field and criteria shape, and its cleanup is
  done by the new rule.

## Out of Scope

- When `pr-cleanup` closes issues (it still closes them before the merge).
- Rewriting existing issues files to the new field name.
- Other audit findings against these two skills.

## Further Notes

Closes #145 and #155. This branch also ticks the acceptance criteria in the issues file for
`bugfix/update-dependencies-audit-followups`, whose PR (#163) merged before cleanup ran.
