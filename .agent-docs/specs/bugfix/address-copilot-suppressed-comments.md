# Detect and address Copilot's suppressed comments

## Problem Statement

`address-copilot-comments` drives a loop that fetches Copilot's PR review findings, fixes or pushes back on each one, and declares the PR clean once no unresolved threads remain. GitHub's Copilot reviewer, however, sometimes folds findings into a collapsible `### Suppressed comments (N)` block inside the review body's markdown text instead of posting them as real review threads. Suppressed comments have no `databaseId`/thread ID — they are not real PR review comments, just text inside the review summary — so both the skill's thread-count check (Step 3) and its unresolved-thread fetch (Step 4) are structurally blind to them. A review can report "Comments generated: 0 new" while its body still lists several actionable findings above that line. The skill currently declares the PR clean and merge-ready in this situation, and the PR gets merged with real Copilot findings never seen or addressed.

Confirmed in production: `octopus-monitoring` PR #465, Copilot reviews `4856012639` (round 1 — 1 suppressed comment) and `4856300640` (round 2 — 3 suppressed comments, including one about an issue recurring from round 1). Both rounds the skill reported 0 unresolved threads and declared the PR clean; the PR merged with the suppressed findings unaddressed.

## Solution

Extend the skill's polling and addressing steps to also see and act on suppressed comments, using the same fix-or-push-back decision process as real threads, with an acknowledgment mechanism suited to their lack of an ID:

- The poll (Step 3, and its Step 7 re-poll) checks the latest Copilot review body for a non-zero `### Suppressed comments (N)` block in addition to the existing thread-count check. Either being non-zero routes to Step 4 instead of declaring the PR clean.
- Step 4 treats each suppressed-comment entry (identified by its bold `**path:line**` header and following bullet text) as its own finding to Fix or Push back on, same as a thread — but skips the reply/resolve mechanism, since there is no thread or comment ID to target.
- A new Step 4d posts a single PR-level comment (`gh pr comment`) summarizing the fix/ignore outcome for every suppressed comment seen that round. It fires whenever suppressed comments existed that round, regardless of whether the round's decisions were all push-backs or included fixes — this is the only place a suppressed comment's outcome is ever recorded, so it must not be skipped just because no code changed.

## User Stories

1. As a developer running `address-copilot-comments`, I want the skill to notice suppressed Copilot findings even when there are zero unresolved threads, so that the PR is never declared clean while Copilot findings sit unaddressed.
2. As a developer, I want each suppressed finding fixed or explicitly pushed back on, so that suppressed findings get the same scrutiny as normal review comments.
3. As a reviewer reading the PR afterward, I want a visible record of what happened to each suppressed finding, so that push-backs on suppressed items are not silently invisible (unlike normal threads, which already carry an inline reply).
4. As a developer, I want the skill's max-2-review-round cap and all-push-back short-circuit to keep working unchanged when suppressed comments are involved, so that this fix doesn't introduce a new way for the loop to run long or loop indefinitely.

## Implementation Decisions

- **Files changed**: `address-copilot-comments/SKILL.md`, `address-copilot-comments/REFERENCE.md`. No application code — these are the Markdown instructions the skill's own agent loop follows.
- **Step 3 / Step 7 (poll)**: add a second, deterministic check run alongside the existing thread-count check — fetch the latest Copilot review body (same API call already used to capture the baseline review ID) and grep for `Suppressed comments (N)`, extracting `N`. `N > 0` is treated identically to `thread_count > 0`: exit the poll to Step 4. This applies to both the main poll loop and the final pass performed after poll exhaustion.
- **REFERENCE.md Step 3 detail**: add a "Step A2 — Suppressed comments check" alongside the existing Step A (thread count) and Step B (new-review-detected) so the reference stays consistent with the poll's actual branching.
- **Step 4 (address)**: suppressed-comment entries are parsed by the agent reading the review body's markdown directly — instructional prose describing the entry shape (bold `**path:line**` header line, one or more bullet lines of finding text, optional fenced code quoting the affected file content), not a rigid extraction script. This matches how the skill already hands full comment bodies to the agent for real threads, and avoids a brittle parser breaking silently if Copilot's markdown format drifts.
- **Decision process**: identical Fix/Push-back decision rule as Step 4 already applies to threads (including the existing push-back-on-`.agent-docs/`-files rule). Suppressed entries and thread entries are decided together in the same Step 4 pass.
- **No reply/resolve for suppressed entries**: Step 4c's per-thread reply + `resolveReviewThread` mutation only applies to real threads (they have the IDs it needs). Suppressed entries are excluded from that step.
- **Step 4b validation**: unchanged — still runs once per round if at least one fix (thread or suppressed) was applied, covering all of that round's code changes together.
- **New Step 4d — acknowledge suppressed comments**: after Step 4c, if any suppressed comments existed this round, post one `gh pr comment {number} --body "..."` summarizing the fix/ignore outcome for each. Fires whenever suppressed comments existed that round, independent of the fix/push-back mix — including rounds where every decision (thread and suppressed) was a push-back, which otherwise skip Steps 5–7 entirely. Skipped only when there were zero suppressed comments that round.
- **Loop termination conditions** (REFERENCE.md): update condition 1 ("all push-backs, no code changes") to note threads are resolved via Step 4c and suppressed comments are acknowledged via Step 4d, regardless of the skip.
- **"Loop at a glance" diagram** (SKILL.md): update to show the suppressed-comments branch in Step 3/7 and the new Step 4d.
- **Round cap unchanged**: the existing `review_round >= 2` cap in Step 6 is untouched — suppressed comments are re-evaluated each round from whatever the latest review body contains (no persistent tracking needed, since there's no ID to track against), same as threads.

## Testing Decisions

This is an instruction-only change for an LLM-driven skill — there is no application code, so no unit or integration tests apply. Verification instead:

- **Dry-run the new Step A2 extraction** against the real sample review body from the bug report (the `octopus-monitoring` PR #465 example) to confirm the grep/extraction pipeline correctly reads the suppressed count out of realistic Copilot markdown, including the `<details>`-wrapped, multi-entry case.
- **Consistency read-through** of the edited `SKILL.md` and `REFERENCE.md`: step numbering stays coherent (4a/4b/4c/4d), the "Loop at a glance" diagram matches the prose steps, and every cross-reference between the two files still resolves.

## Out of Scope

- Changing how real (thread-based) Copilot comments are detected, fetched, replied to, or resolved — that path is unaffected.
- Building a general-purpose Markdown parser for Copilot review bodies; parsing stays scoped to the one known block shape.
- Deduplicating suppressed comments across review rounds (e.g. recognizing "this is the same finding as round 1") — each round is evaluated independently against whatever the latest review body contains, same as the existing thread flow, bounded by the existing 2-round cap.
- Any change to `pr-cleanup`, `code-review`, or other skills downstream of `address-copilot-comments`.

## Further Notes

Real suppressed-comment markdown example (from `gh api repos/{owner}/{repo}/pulls/{number}/reviews --jq '.[] | select(.user.login | test("copilot";"i")) | .body'`), used as the dry-run fixture:

```markdown
### 🟡 Not ready to approve
...
<details>
<summary>Review details</summary>

### Suppressed comments (3)

**grafana/mariadb/queries.md:158**
* The Agile Prices threshold description uses pound symbols... mixes currencies...
<quoted file context>

**grafana/dashboard.json:1021**
* Panel id 13 omits the `title` field entirely...
<quoted file context>

Comments generated: 0 new
Review effort level: Lite
</details>
```
