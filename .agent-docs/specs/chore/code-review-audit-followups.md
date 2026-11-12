# Code-review audit follow-ups (CR-1, CR-2, CR-5, CR-10, CR-12)

## Problem Statement

The writing-for-agents skill audit (#143) left five findings against `code-review` open
(GitHub issue #147):

- **CR-1**: Step 2 decides "no changes" from `git diff HEAD` and `git diff --cached`. Both
  are empty on a branch whose work is fully committed, so the review stops before it starts.
- **CR-2**: around 50 lines of legacy `review.md` migration sit inline in Step 4, on the
  path of every review although almost no repo still has that file.
- **CR-5**: `address-copilot-comments` Step 4b runs "`code-review` Steps 1–5 only", but
  `code-review` has no branch that stops after Step 5, so it can run on into Step 6 and
  re-invoke its caller.
- **CR-10**: the review criteria state "an 80% code coverage requirement enforced at the
  pipeline level" as fact for every repo, including repos with no coverage gate.
- **CR-12**: the fixer's per-finding snapshot is `git diff` only. It does not record
  untracked files, so a blocked finding's new test file cannot be told apart from files
  that were already untracked, and the rollback cannot be checked.

## Solution

Fix each finding in the `code-review` skill's own files, and bring its `allowed-tools` in
line with the commands the skill now runs.

## User Stories

1. As a user reviewing a fully committed branch, I want `code-review` to see the committed
   diff against the default branch, so that the review runs instead of stopping at "no
   changes".
2. As a user with nothing committed and nothing in the working tree, I want `code-review`
   to still stop and say so, so that reviewers are not dispatched on an empty diff.
3. As an agent running `code-review`, I want the legacy `review.md` migration disclosed in
   its own file, so that I read it only when `.agent-docs/review.md` exists.
4. As an agent running `address-copilot-comments` Step 4b, I want `code-review` to stop
   after Step 5 when asked for Steps 1–5 only, so that Copilot review and PR cleanup are not
   re-entered.
5. As a reviewer sub-agent in a repo with no coverage gate, I want the coverage criterion
   to depend on what the repo's CI enforces, so that I do not cite a requirement that does
   not exist.
6. As a fixer sub-agent rolling back a blocked finding, I want the snapshot to include the
   working-tree status, so that I can remove exactly the files that finding created.

## Implementation Decisions

- **CR-1 — `code-review` SKILL, Step 2**: resolve the default branch here (the same
  `git symbolic-ref` line Step 3 uses today) and check `git diff origin/$BASE...HEAD --stat`
  and `git status --porcelain`. Stop only when the commands succeed and both are empty; a
  failing command is reported as an error. Step 3 reuses `$BASE` rather
  than resolving it again. A user-supplied fixed point replaces `origin/$BASE` in the
  Step 2 check too.
- **CR-2 — new `MIGRATE-LEGACY-REVIEW.md`** in the `code-review` skill: the migration
  procedure moves there unchanged in behaviour. Step 4 keeps only the trigger (the file
  exists) and a link. Links inside the moved text keep resolving, as it stays in the same
  directory.
- **CR-5 — `code-review` SKILL, Step 5 exit and "Loop at a glance"**: when the caller asked
  for Steps 1–5 only, stop once the exit rule is met and return to the caller; do not run
  Steps 6 or 7. The caller is named generically, with `address-copilot-comments` Step 4b as
  the example. `address-copilot-comments` itself is not edited (#144 covers that skill).
- **CR-10 — `REVIEW-CRITERIA`, Testing → Coverage target**: flag new code paths lacking
  tests in every repo; cite a coverage threshold only when the repo's CI or test
  configuration enforces one, and then cite that repo's figure.
- **CR-12 — `FIXER`, "Snapshot first" and "Blocked"**: the snapshot saves
  `git status --porcelain --untracked-files=all` next to `git diff`, so files inside an
  already-untracked directory are listed individually. Rollback deletes files that are untracked
  now and were absent from the snapshot's status, and is checked by comparing status and
  diff against the snapshot.
- **`allowed-tools`**: the skill's frontmatter already scopes `git diff *` and
  `git status *`; add or remove entries only where the edits above change the commands the
  main context runs. The fixer is a sub-agent and does not inherit this list.

## Testing Decisions

- These are prose changes to skill definition files; there is no executable behaviour to
  test red-green.
- The existing `unittest` suite's frontmatter checks (`tests/test_skill_frontmatter.py`)
  must still pass: they guard `allowed-tools` scoping.
- Verification is otherwise a read-through against each finding, plus `code-review`.

## Out of Scope

- The other `code-review` audit findings not listed in #147.
- Any change to `address-copilot-comments` (#144, #132) or the other audited skills.
- Changing the migration's behaviour; CR-2 is a move.

## Further Notes

Closes #147. Agent standards §3 still asks for 80% coverage in this repo's own standards
file; CR-10 only stops the shared review criteria asserting it for every repo.
