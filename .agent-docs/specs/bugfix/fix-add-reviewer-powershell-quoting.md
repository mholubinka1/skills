# Fix --add-reviewer PowerShell quoting in address-copilot-comments

## Problem Statement

When a user runs the Step 6 Option A command from `address-copilot-comments/REFERENCE.md` in
PowerShell, the command silently drops the `--add-reviewer` argument because PowerShell parses
bare `@copilot` as a splat operator. This causes `gh` to error with
`flag needs an argument: --add-reviewer`. Without the `@` prefix, `copilot` fails with a
GraphQL login resolution error. Neither form works in PowerShell as currently documented.

Additionally, Option B is labelled "if Option A fails", which implies it is a generic fallback
for any failure mode. In practice Option B is needed only when `gh pr edit` itself is
unavailable due to plan or org restrictions — not as a workaround for the quoting bug.

## Solution

Quote `@copilot` in single quotes in the Option A command block so it works in both PowerShell
and Bash. Add a brief note explaining the PowerShell splat-operator behaviour. Relabel Option B
to make clear it is a fallback for when `gh pr edit` is unavailable, not a shell-specific
workaround.

## User Stories

1. As an agent running on PowerShell, I want the Step 6 Option A command to use
   `'@copilot'` so that `gh pr edit` does not error with `flag needs an argument`.
2. As a developer reading REFERENCE.md, I want the Option B heading to explain when to
   use it, so that I do not reach for GraphQL when the quoted Option A would have worked.
3. As a Bash user, I want the single-quoted form to remain valid in my shell, so that the
   fix does not break existing workflows.

## Implementation Decisions

- Edit `address-copilot-comments/REFERENCE.md`, Step 6 section only.
- Change `@copilot` to `'@copilot'` in the Option A code block.
- Add a blockquote note immediately below the Option A code block explaining that
  single-quoting is required in PowerShell because bare `@copilot` is parsed as a splat
  operator and silently drops the argument.
- Change the Option B heading from `(if Option A fails)` to
  `(fallback if gh pr edit is unavailable)`.
- No other files or steps are modified.

## Testing Decisions

- This is a documentation-only change. Correctness is verified by reading the updated file
  and confirming the three edits are applied accurately.
- No automated tests exist or are warranted for REFERENCE.md content.

## Out of Scope

- Changes to any other step in REFERENCE.md.
- Changes to SKILL.md or any other skill file.
- Fixing any other shell-compatibility issues.

## Further Notes

Single quotes are valid in both PowerShell (literal string, no interpolation) and Bash, so
`'@copilot'` is the correct cross-shell form. The GraphQL mutation in Option B works on any
shell; the heading change clarifies its trigger condition (plan/org availability) rather than
implying a shell restriction.
