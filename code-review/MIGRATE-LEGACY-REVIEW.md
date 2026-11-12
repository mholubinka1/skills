# Migrate a legacy review.md

Read this only when the target repo has `.agent-docs/review.md` — a leftover from before
criteria moved to the shared [Criteria gist](CRITERIA-GIST.md). Run it once, before
`code-review` Step 4 dispatches the reviewers:

- **Validate the whole file, not just the entries.** The only accepted content under
  `## Criteria` is one of: the literal placeholder line `_None yet._` on its own, or zero or
  more entries each matching `- **Label**: text (PR #<number>)` exactly — including that
  trailing `(PR #<number>)` suffix; an entry missing it doesn't parse either, since there'd be
  nothing to retag and it would end up appended with no provenance. Content above the heading
  is free-form explanatory prose and isn't validated. If the file has no `## Criteria`
  heading, has **any** content under that heading that isn't the placeholder or a
  correctly-tagged entry (a stray note after the list is exactly as unaccounted-for as a
  malformed entry), or **any** single entry fails to parse, **stop here** for the whole file:
  report that it couldn't be parsed and leave it in place untouched. Never delete a file whose
  content you couldn't fully account for, and never salvage only the parts that happened to
  parse.
- Rewrite each entry to the [Criteria style](CRITERIA-STYLE.md) rules — an entry covering
  two defects becomes two — and retag its `(PR #<number>)` as `(repo#PR)` on every entry it
  produces, using the target repo's name and the existing PR number. Get the repo name via `gh repo view --json name -q .name`, run in the
  target repo. **If that lookup fails** (no network, `gh` not authenticated) — stop here:
  there is no valid tag to retag with, so don't append untagged entries and don't delete the
  file. Leave `.agent-docs/review.md` in place, skip migration for this run, and continue
  straight to **Dispatch the reviewers** in `code-review` Step 4 as if the migration check had
  found nothing to do.
- Start this skill's own [CRITERIA-GIST.md](CRITERIA-GIST.md)'s "Appending an entry"
  procedure now, but stop after its fetch step (step 1) — that gist content is what you
  dedupe the retagged entries against, matching on meaning. **If that fetch fails** — no
  network, `gh` not authenticated, the gist unreachable — treat it exactly like a failed
  write below: report the failure, leave `.agent-docs/review.md` in place, do not delete it.
  There is no confirmed successful outcome (a write, or a verified-empty dedupe) without a
  successful fetch to base it on. Otherwise, carry that same fetched content forward into the
  rest of the procedure rather than fetching it again.
- **If there are any retagged entries left after dedupe**: continue the "Appending an entry"
  procedure from step 2 with the survivors, and **confirm the write succeeded** (the
  `gh gist edit` call exits zero) before proceeding.
  - If the write failed for any reason — no network, `gh` not authenticated, the gist
    unreachable — report the failure and leave `.agent-docs/review.md` in place; do **not**
    delete it. A migrated-and-deleted file with a failed write would lose those criteria
    permanently, since nothing else retains them.
- **If the file parsed cleanly but had nothing to append** (an empty list, only the
  `_None yet._` placeholder, or every entry already covered by the gist): there is no write
  to confirm — treat this as a successful no-op and proceed directly to deletion below.
- Once the write (or no-op) is confirmed successful: delete `.agent-docs/review.md` from the
  target repo. If it was tracked by git (`git ls-files --error-unmatch .agent-docs/review.md`
  exits zero before the delete), stage the deletion (`git add .agent-docs/review.md`) so it
  isn't lost to an incidental `git checkout`/`git restore`; if it was never tracked (e.g. an
  old, uncommitted bootstrap that never got added), there's nothing to stage — the file being
  gone from disk is already the complete outcome, and `git add` on an untracked deletion would
  just fail with a pathspec error. Either way, leave the deletion uncommitted: the next
  commit made after this review picks up the staged deletion.

This is idempotent: once `.agent-docs/review.md` is gone, later runs against the same repo
skip straight past this check. A failed migration simply leaves the file in place for the
next run to retry.
