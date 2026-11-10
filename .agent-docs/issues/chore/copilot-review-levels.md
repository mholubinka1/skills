# Issues: chore/copilot-review-levels

## Request the Copilot review at an explicit effort

**GitHub issue**: #158

**Blocked by**: None

**User stories**: 8, 9, 11

### What to build

Replace `address-copilot-comments`' "Trigger Copilot Review" with one request: fetch the PR node ID, then call the GraphQL mutation `requestCopilotCodeReview`, passing `pullRequestId` and an explicit `reviewEffort` (`LITE` or `BALANCED`) as variables. Read back `success` and `failureReason`. Remove the `gh pr edit --add-reviewer` option, the `requestReviews` fallback, the PowerShell `@copilot` note, and the `Bash(gh pr edit *)` grant. Failure handling: `REQUEST_CONFLICT` → Step 3. Any other failure → report it and go to Step 7, which then leaves out "ready to merge". Record the decision in ADR 0007, and point ADR 0004's Amendment effort sentence to it.

### Acceptance criteria

- [ ] Given a review-required PR, when Step 2b requests the review, then it calls `requestCopilotCodeReview` with an explicit `LITE` or `BALANCED`: never `MAX` or `AUTO`, and never without an effort.
- [ ] Given the request returns `failureReason: REQUEST_CONFLICT`, then the skill continues to Step 3.
- [ ] Given any other `failureReason`, `success: false` with no reason, or a `gh`/GraphQL error, then the skill reports it and goes to Step 7, which leaves out "ready to merge".
- [ ] No `gh pr edit`, `--add-reviewer` or `requestReviews` remains in the skill, and the unittest suite passes.

---

## Pick a None / Lite / Balanced review level per PR

**GitHub issue**: #159

**Blocked by**: #158

**User stories**: 1, 2, 3, 4, 5, 6, 7, 10, 11

### What to build

Replace Step 2b's Classification rule with the three-level **Review level** rubric: the principle, seven Balanced rules, Lite, and the exhaustive None list, each with *Skills:* examples, then the doubt and edge-case rules. Before classifying, read the target repo's `## Review levels` section in `.agent-docs/agent.md` if it has one. Replace the worked examples with a Change → Level table: general code cases first, then skill cases, each Balanced row citing its rule number. In the skill, Step 2b becomes a three-way decision, the "Loop at a glance" diagram matches it, and Step 7 reports the level and the rule that decided it. Add the **Review level** term to `context.md`, and update **Single review** and **Review-required diff**.

### Acceptance criteria

- [ ] Given each row of the worked-examples table, when it is classified under the rubric as written, then it resolves to the stated level.
- [ ] Given a repo whose `.agent-docs/agent.md` lists a path under `## Review levels`, then a file under that path is Balanced, and the list never lowers a file's level.
- [ ] Given a PR classified None, then no review is requested, and Step 7 reports None and the rule that decided it.
- [ ] Given a PR classified Lite or Balanced, then the review is requested at that effort, and Step 7 reports the level and the deciding rule.
- [ ] The doubt rules, the tests-never-lower rule and the binary-file → Lite-at-least rule are stated in the rubric.
- [ ] Given `gh pr diff` exits non-zero, then the PR is never classified None from empty output. The skill classifies from the file list (Lite at least), or, if that fetch fails too, reports and goes to Step 7 without "ready to merge".

---
