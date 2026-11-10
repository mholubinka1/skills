# Copilot review effort is chosen per PR: None, Lite or Balanced

Balanced Copilot reviews (about $1.50 each, the GitHub default since 2026-09-28) were spent on every review-required PR, because ADR 0004's Amendment assumed GitHub had no per-request effort parameter. It has one: the GraphQL mutation `requestCopilotCodeReview` takes `reviewEffort`. So `address-copilot-comments` Step 2b now picks a **Review level** (`.agent-docs/context.md`) for each PR and requests the review at that effort. The level depends on how bad a missed defect would be and how hard it would be to spot from the diff alone. Each file gets a level, and the PR takes the highest.

This replaces ADR 0004's Amendment sentence about effort. The rest of ADR 0004 still holds: Copilot is triggered explicitly, judged by diff content rather than file extension, and requested at most once per invocation.

## Decisions

- **Explicit effort only.** The skill always passes `LITE` or `BALANCED`. The `gh pr edit --add-reviewer` fallback was dropped, because it has no effort parameter and would quietly run at the repo default. `MAX` is never used (about $10 a review). `AUTO` is never used either: its cost is unpredictable, and the skill couldn't report which level it got.
- **Dependencies.** A patch or minor bump that only changes a lockfile or version pin is None. A major bump is Lite. Adding a new dependency is Balanced, because it is a supply-chain risk.
- **Size rule.** Balanced above about 300 changed logic lines, or for logic changes across 5 or more modules. Smaller behaviour changes that hit no other Balanced rule are Lite. This replaces the old review-required threshold of 30 lines or 3 files, which was only a choice between a review and none.
- **Optional repo path list.** A repo can list paths in a `## Review levels` section of its `.agent-docs/agent.md`. A file under a listed path is Balanced. The list can only raise a file's level, never lower it.
- **Tests never lower the level.** A PR that adds tests alongside a risky change keeps the level of that change.
- **Doubt.** When unsure between None and a review, review. Doubt about a security-boundary or data-integrity rule means Balanced. Any other doubt between Lite and Balanced means Lite.
- **Failed request.** `REQUEST_CONFLICT` means a review is already pending, so the skill carries on to polling. Any other failure is reported, and the skill skips to its final report without calling the PR ready to merge.

## Considered Options

- **Keep Balanced for every review and set the repo default to Lite by hand.** Rejected: the repo default only applies to reviews requested from the UI, and the skill would still have no way to send a risky PR to Balanced.
- **Lite for everything.** Rejected: Lite reads only the changed lines, so it misses defects that need reasoning across files, such as concurrency, contracts and data integrity, which are the costliest ones to miss.
