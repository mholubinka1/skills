# init-agent-docs audit follow-ups (IAD-1, IAD-2, IAD-4)

## Problem Statement

Three audit findings (#143) against `init-agent-docs` (GitHub issue #150):

- **IAD-1**: `SKILL.md` lists six one-line step summaries and says "See REFERENCE.md for
  the full per-step detail". The real procedure, with its safe-move rule and failure
  handling, is only in `REFERENCE.md`. The skill runs on Haiku at low effort, which can act
  on the summaries alone.
- **IAD-2**: the skill states "must be invoked from the repository root" as an assumption
  and never checks it. Run from a subdirectory, it creates a second `.agent-docs/` there.
- **IAD-4**: in Step 3, when the single `context.md` found is moved into place, a failed
  write and a failed delete are handled the same way: skip to Step 4. After a failed
  delete the destination is already written, yet it is never reviewed.

## Solution

Put the full procedure in `SKILL.md` and delete `REFERENCE.md`. Add a Step 0 that confirms
the current directory is the repository root. Split the Step 3 failure handling so a failed
delete still leads to the review.

## User Stories

1. As a caller running the skill on a small model, I want every step's full instructions
   in `SKILL.md`, so that the safe-move rule and failure handling cannot be skipped.
2. As a user who invoked the skill from a subdirectory, I want it to stop and say so, so
   that no stray `.agent-docs/` is created.
3. As a user whose old `context.md` could not be deleted after the move, I want the new
   `.agent-docs/context.md` still reviewed, and the leftover file named in the report.

## Implementation Decisions

- **IAD-1 — `init-agent-docs` SKILL**: the safe-move rule and Steps 1 to 6 move from
  `REFERENCE.md` into `SKILL.md` with their wording unchanged, replacing the six summaries.
  `REFERENCE.md` is deleted. Step numbers are unchanged.
- **IAD-2 — new Step 0**: `git rev-parse --show-prefix`. No output means the repository
  root; a printed path means a subdirectory, and the skill stops; a failure means no git
  repository, and the skill stops. `--show-prefix` is used rather than comparing
  `--show-toplevel` with the working directory because that comparison is unreliable when
  the two are printed in different path forms (`C:/…` and `/c/…` on Windows). The
  "Assumption" note is removed.
- **IAD-4 — Step 3, "Exactly one found"**: three outcomes. Write failed: report, go to
  Step 4. Write succeeded but delete failed: report, name the leftover source on the
  `Skipped / risk:` line, and take the review sub-path. Both succeeded: report the move and
  take the review sub-path.
- **`allowed-tools`** gains `Bash(git rev-parse --show-prefix)`.
- The pointer inside the generate sub-path now says the format file sits next to
  `SKILL.md`.

## Testing Decisions

- Prose changes to a skill definition; there is no executable behaviour to test red-green.
- The frontmatter guard tests cover the new `allowed-tools` entry, and the Markdown link
  check covers the removed file.
- `git rev-parse --show-prefix` was run at this repo's root and printed nothing.

## Out of Scope

- `AGENT-TEMPLATE.md` and `CONTEXT-FORMAT.md`.
- Other audit findings against this skill.
- Supporting repositories that are not git repositories.

## Further Notes

Closes #150.
