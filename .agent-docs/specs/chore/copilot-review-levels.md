# Choose a Copilot review level (None / Lite / Balanced) per PR

## Problem Statement

`address-copilot-comments` Step 2b only decides between a review and no review. Every review it
requests runs at the repository default effort, which has been Balanced since 2026-09-28 and costs
about $1.50 per review on average. Lite costs about $0.25 and catches the obvious bugs and
vulnerabilities in the changed lines, which is all that most review-worthy PRs need. So most of the
review spend buys reasoning that the change didn't need. These skills run mainly in *other* repos,
so the rules for deciding have to cover general code changes first and skill (`SKILL.md` /
`REFERENCE.md`) changes second.

## Solution

Step 2b picks a **Review level** for each PR: None, Lite or Balanced. It judges each changed file by
how bad a missed defect would be and how hard it would be to spot from the diff alone. The PR takes
the highest level of any file. The skill then requests the one Copilot review (the **Single review**)
at exactly that effort, through the GraphQL mutation `requestCopilotCodeReview` with an explicit
`reviewEffort`. It never falls back to a path that would quietly run at the repo default. A repo can
send extra paths to Balanced through an optional `## Review levels` section in its
`.agent-docs/agent.md`. The final report states the level chosen and the rule that decided it.

## User Stories

1. As a developer using the skill in any repo, I want a PR whose behaviour changes stay local,
   recoverable and visible in the diff to be reviewed at Lite, so that I pay about $0.25 instead of
   about $1.50 for it.
2. As a developer, I want a PR that touches a security boundary, data integrity or an irreversible
   action, concurrency or state, a contract, deploy or runtime config (including a new dependency),
   or a large scope to be reviewed at Balanced, so that the defects that are costly or need
   cross-file reasoning still get a deep review.
3. As a developer, I want a PR that changes no behaviour to get no review, so that docs, test-only,
   rename, generated-file, patch or minor lockfile bump and tiny no-risk edits cost nothing.
4. As a developer, I want doubt to resolve upward: unsure between None and a review means review,
   and doubt about the security or data-integrity rules means Balanced. That way a risky diff is
   never under-reviewed by mistake.
5. As a developer, I want tests in a PR never to lower its level, and a binary file to mean Lite at
   least, so that changes Copilot can't judge from the diff aren't waved through.
6. As a repo maintainer, I want to list paths in a `## Review levels` section of my repo's
   `.agent-docs/agent.md` that always get Balanced, so that risk only my repo knows about is
   honoured. The list must never lower a file's level.
7. As a skill author, I want skill-specific examples in the rubric (`allowed-tools`, new `gh api`
   writes, guard changes, reworded prose), so that changes to `SKILL.md` and `REFERENCE.md` are
   judged the same way as code.
8. As a developer, I want the review to be requested at exactly the chosen effort, with no fallback
   that would run at the repo default, so that the level I'm told about is the level I paid for.
9. As a developer, I want a request that fails because a review is already pending
   (`REQUEST_CONFLICT`) to carry on to polling. I want any other failure, including a `gh` or
   GraphQL error or `success: false` with no reason, to be reported, with the PR not called ready
   to merge, so that a missing review is never hidden.
10. As a developer, I want the final report to state the level chosen and the rule that decided it,
    so that I can check the decision.
11. As a maintainer of this skills repo, I want `context.md` and the ADRs to record the review-level
    decisions and replace ADR 0004's claim that effort can't be chosen, so that the next person
    doesn't reintroduce the Balanced-only behaviour.

## Implementation Decisions

- **`address-copilot-comments` reference (Step 2b).** The Classification rule becomes the
  three-level rubric: the principle, seven Balanced rules (security boundary, data integrity or
  irreversible actions, concurrency and state, contract, deploy and runtime, large scope above about
  300 logic lines or across 5+ modules, repo-listed path), then Lite, then the exhaustive None list.
  Each rule with a skill-specific case has a *Skills:* example. The doubt and edge-case rules follow. Before classifying, the
  agent reads the target repo's `## Review levels` section in `.agent-docs/agent.md` if it has one.
  The worked examples are replaced by a Change → Level table: general code cases first, then
  skill cases, each Balanced row citing its rule number.
- **Trigger.** "Trigger Copilot Review" becomes a single request: fetch the PR node ID, then call
  `requestCopilotCodeReview` with `pullRequestId` and `reviewEffort` passed as GraphQL variables,
  read back `success` and `failureReason`. The `gh pr edit --add-reviewer` option, the old
  `requestReviews` fallback and the PowerShell quoting note for `@copilot` are removed. `MAX` and
  `AUTO` are never sent. Failure handling: `REQUEST_CONFLICT` → Step 3. Any other `failureReason`,
  `success: false` with no reason, or a non-zero `gh` exit → report it and go to Step 7.
- **`address-copilot-comments` skill.** Step 2b becomes a three-way decision (None → Step 7;
  Lite or Balanced → request at that effort → Step 3). The "Loop at a glance" diagram is updated to
  match. Step 7 states the level and deciding rule, and leaves out "ready to merge" after a failed
  request, as it already does after a poll `ERROR`. `allowed-tools` drops `Bash(gh pr edit *)`.
  `Bash(gh api graphql *)` and `Bash(gh api repos/*)` already cover the new calls.
- **Domain docs.** `context.md` gains **Review level**, and updates **Single review** (the request
  always names its level) and **Review-required diff** (a diff at Lite or Balanced). ADR 0007
  records the decisions, and ADR 0004's Amendment sentence on effort is replaced with a pointer
  to ADR 0007.
- **Other skills and README.** A grep found no other mention of Balanced or of the old
  review-required wording. `code-review` Step 6 already says "only when the diff warrants one" and
  stays as it is.

## Testing Decisions

- The change is Markdown-only, with no executable logic. The existing pytest suite (notably
  `test_skill_frontmatter.py`, which validates every skill's `allowed-tools`) must stay green
  after `Bash(gh pr edit *)` is removed.
- Acceptance is a manual read-through: each worked-examples row resolves to its stated level under
  the rubric as written, and no path in the skill requests a review without an explicit effort.

## Out of Scope

- Setting each repo's default Copilot review effort to Lite by hand (Settings → Copilot → Code
  review). That default only affects reviews requested from the UI.
- Having `init-agent-docs` seed a `## Review levels` section in new repos (deferred).
- Any use of `MAX` or `AUTO` effort.

## Further Notes

API facts were verified against GitHub's live GraphQL schema on 2026-11-10: `reviewEffort` is the
enum `CopilotCodeReviewEffort` (`LITE | BALANCED | MAX | AUTO`), and `failureReason` is the enum
`CopilotCodeReviewRequestReason` (`REQUEST_CONFLICT`, `ACTOR_INELIGIBLE`, `REPOSITORY_INELIGIBLE`,
`APP_NOT_INSTALLED`, `NO_QUOTA_REMAINING`, `LICENSED_ORGANIZATION_UNAVAILABLE`).
