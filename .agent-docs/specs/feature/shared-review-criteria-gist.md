# Shared review criteria staged in a cross-machine gist

## Problem Statement

Today, when `address-copilot-comments` generalises a Copilot finding into a review
criterion, it appends that criterion to the *target repo's own* `.agent-docs/review.md`.
That means a criterion discovered while reviewing one repo is invisible to every other
repo's `/code-review` runs — including repos on a different machine — until someone
manually notices it, copies it by hand into this skills repo's `code-review/REVIEW-CRITERIA.md`,
and pushes that change. In practice this promotion rarely happens promptly, so most repos'
`review.md` files just grow in isolation and the value of a hard-won finding stays trapped
in the repo where it was found.

## Solution

New criteria are written to and read from a single shared **Criteria gist** — a secret
GitHub gist, read and written live via the `gh` CLI — instead of a per-repo file. Because the
gist is a live network call rather than a local file, a criterion discovered while reviewing
any repo on any machine is available to every other repo's very next `/code-review` run,
immediately, with no promotion step required for that first level of sharing. A human still
periodically collates durable entries out of the gist into `code-review/REVIEW-CRITERIA.md`
(the permanent baseline) via a normal PR to this skills repo, deleting each entry from the
gist as it's copied over — the same manual judgement call that exists today, just applied to
one shared pool instead of scattered per-repo files.

Repos that already accumulated their own `.agent-docs/review.md` under the old scheme are
migrated automatically: the next time `/code-review` runs against such a repo, it moves that
file's entries into the gist and deletes the file, so the repo never needs special handling
again.

## User Stories

1. As someone running `/code-review` on repo A, I want a criterion discovered while reviewing
   repo B (on this machine or another) to already be part of my Standards review, so that I
   benefit from lessons learned anywhere without waiting for manual promotion.
2. As someone running `address-copilot-comments` on a repo, I want the generalised criterion
   from a Copilot finding I acted on to be written somewhere every other repo can see, not
   locked into this one repo's local file.
3. As someone maintaining `code-review/REVIEW-CRITERIA.md`, I want to periodically skim one
   shared list of not-yet-collated criteria (tagged by repo and PR) and copy the durable ones
   in, deleting them from the shared list once copied, so the list only ever shows what's
   still pending review.
4. As someone running `/code-review` on a repo that still has an old `.agent-docs/review.md`
   from before this change, I want that file's entries folded into the shared gist and the
   file removed automatically, so I don't have to do anything special to catch that repo up.
5. As someone running `/code-review` when the gist is unreachable (offline, `gh` not
   authenticated, gist deleted), I want the review to continue using
   `REVIEW-CRITERIA.md` alone with a clear warning, so a network hiccup never blocks a review.

## Implementation Decisions

- **Create the gist.** A new secret gist, containing one file (e.g. `CRITERIA.md`) that holds
  staged criteria in the same bold-label-plus-one-line-rule style as
  `code-review/REVIEW-CRITERIA.md`'s existing entries, each tagged `(repo#PR)` instead of the
  old bare `(PR #64)` — e.g. `- **Mysterious log key**: ... (acme-api#64)`. Start it with a
  short header explaining its purpose and the collation/deletion convention, mirroring the
  explanatory header `REVIEW-CRITERIA.md`/the old `review.md` template already carry.
- **Record the gist ID.** Create `code-review/CRITERIA-GIST.md` in this skills repo containing
  the gist's ID/URL and a one-line explanation of what it is, so both skills below can find it
  without per-machine configuration. This file is the only new git-tracked artifact.
- **`address-copilot-comments` (SKILL.md/REFERENCE.md)**: replace every instruction that
  appends a generalised criterion to the target repo's `.agent-docs/review.md` with an
  instruction to append it to the Criteria gist instead, via `gh gist edit` — read the gist's
  current content first, append the new entry, write the full content back (gists don't
  support partial-append). Read the gist ID from `code-review/CRITERIA-GIST.md`. Drop any
  language describing `review.md` as something this skill maintains.
- **`code-review/SKILL.md` Step 4**: before reading criteria, add a migration check against
  the target repo: if `.agent-docs/review.md` exists, read its entries, append them (in the
  `(repo#PR)` form, inferring the repo name) to the gist via the same read-append-write as
  above, confirm that write succeeded, and only then delete `.agent-docs/review.md` from the
  target repo — a failed write must leave the file in place rather than lose those criteria
  permanently. Then read criteria from
  three sources instead of two: `code-review/REVIEW-CRITERIA.md` (unchanged), the target
  repo's `.agent-docs/review.md` (now only ever hit on the migration path, immediately before
  it's deleted), and the Criteria gist (fetched live via `gh gist view`). If the gist is
  unreachable for any reason, warn once ("shared criteria gist unavailable — continuing with
  REVIEW-CRITERIA.md only") and proceed without it — never block the review.
- **`init-agent-docs`**: Step 7 currently bootstraps `.agent-docs/review.md` from
  `REVIEW-TEMPLATE.md` when missing. Since target repos should no longer have a local
  `review.md` at all going forward, remove this bootstrap step entirely (renumber subsequent
  steps) rather than leaving a template that immediately becomes stale.
- **`code-review/REVIEW-CRITERIA.md`**: update its explanatory header — "promote durable ones
  into a shared criteria file, by hand" becomes a pointer at the Criteria gist by name/location
  (`code-review/CRITERIA-GIST.md`), and the collation convention (copy in, then delete from the
  gist) is spelled out there since that's now the only place criteria get promoted from.
- **This skills repo's own `.agent-docs/review.md`**: goes through the exact same migration
  path as any other repo — do not hand-collate its entries directly into `REVIEW-CRITERIA.md`
  as a special case; running the updated `/code-review` Step 4 against this repo migrates them
  into the gist and deletes the file, proving the migration path works on real data as part of
  this change's own review cycle.
- **Attribution and format**: entries written by `address-copilot-comments` need the target
  repo's name, derivable the same way `gh` commands already target a repo (`gh repo view
  --json nameWithOwner` or equivalent), combined with the PR number already in scope.

## Testing Decisions

- The only executable seam is the gist itself: create the real secret gist, then verify a
  full round trip — write a criterion via `gh gist edit`, read it back via `gh gist view
  --raw`, confirm the content matches — before either skill is pointed at it.
- The `.agent-docs/review.md`-migration path is verified by dry-running it against a real
  case with actual data: this skills repo's own `.agent-docs/review.md` (13 entries,
  PRs #64–#97). After Step 4's migration logic runs against it, confirm all 13 entries appear
  in the gist tagged with this repo's name and the file is gone.
- The instruction-file changes (SKILL.md/REFERENCE.md wording) have no executable form to
  test; verify them by walking each rewritten step against two concrete scenarios — a repo
  with an existing `review.md` (migration path) and a repo with none (steady-state path) —
  and confirming the described flow is unambiguous and idempotent (running it twice does
  nothing extra the second time).

## Out of Scope

- Automating the collation step itself (drafting the `REVIEW-CRITERIA.md` diff, or the gist
  deletion, from the gist's current content) — collation stays a manual, on-demand,
  human-driven action.
- Any protection against two machines' near-simultaneous writes clobbering each other in the
  gist (last-write-wins is accepted as a low-stakes race for a single-user tool).
- Restructuring `REVIEW-CRITERIA.md`'s own format or content beyond the header pointer update.

## Further Notes

- ADR-0006 (`.agent-docs/adr/0006-shared-review-criteria-staged-in-a-github-gist.md`) records
  why a gist was chosen over a git-tracked staging file (this repo's post-commit
  `sync_claude_skills.py` hook would clobber runtime writes to a file also present in the git
  tree), a runtime-only local file (doesn't cross machines), a dedicated GitHub repo, and a
  cloud-synced folder.
- `context.md` already reflects the new **Criteria gist** term (replacing **Review
  criteria**), and the **Agent docs** term no longer lists `review.md` among its files.
