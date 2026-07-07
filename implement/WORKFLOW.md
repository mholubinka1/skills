# Implementation Workflow

This is the full workflow embedded in the sub-agent prompt by [SKILL.md](SKILL.md) Step 2.

---

You have been spawned by `/implement` to carry out a full implementation cycle. The trigger context above tells you what to build. Work through the steps below in order.

> **Prerequisite skills**: all skills referenced in this workflow live in this same skills
> repo and are installed automatically via the post-commit sync hook:
> `init-agent-docs`, `grill`, `write-spec`, `create-issues`, `branch-hygiene`,
> `bdd`, `pre-commit-check`, `code-review`,
> `address-copilot-comments`, `pr-cleanup`.

## Step 0 — Bootstrap agent docs

Run the `init-agent-docs` skill. This bootstraps `.agent-docs/agent.md` and ensures
`CLAUDE.md` references it. The skill is idempotent — it reports what was created or
skipped on each run. If it surfaces an error, stop and resolve it before continuing.

## State detection — resume from where work left off

After Step 0, check what already exists for the current branch:

```bash
git branch --show-current
```

| State | Action |
|---|---|
| `.agent-docs/issues/<branch-name>.md` exists | Resume at the BDD loop (Step 5) for any unchecked issues |
| `.agent-docs/specs/<branch-name>.md` exists only | Resume at `/create-issues` (Step 4) |
| Neither exists | Continue to Step 1 below |

## Step 1 — Grill

Run the `grill` skill. Use the trigger context as the starting point — you already know what to build, so the grilling session sharpens and validates it rather than starting from scratch.

## Step 2 — Branch hygiene

Run the `branch-hygiene` skill. Derive the change type and branch slug from the grill output in context. If the current branch is wrong, suggest and create the correct one.

## Step 3 — Write spec

Run the `write-spec` skill. It will synthesise the grill output into `.agent-docs/specs/<branch-name>.md`.

## Step 4 — Create issues

Run the `create-issues` skill. It will break the spec into vertical slices, quiz you on the breakdown, write `.agent-docs/issues/<branch-name>.md`, and push to GitHub.

## Step 5 — BDD loop (per issue, in dependency order)

For each unchecked issue in `.agent-docs/issues/<branch-name>.md`, in dependency order (no blockers first):

1. Run the `bdd` skill for this issue.
2. Run the `pre-commit-check` skill on all changed files.
3. Commit with a single pithy line:

   ```bash
   git add <changed files>
   git commit -m "<one-line summary>"
   ```

## Step 6 — Code review

Run the `code-review` skill.

## Step 7 — Merge confirmation loop

After `/address-copilot-comments` shares the PR link, enter this loop:

Prompt the user:

> The PR is at {url}. Please confirm when it has been merged.

- If the response is not a clear confirmation, press the user again.
- Once confirmation is given, verify:

  ```bash
  gh pr view <number> --json state --jq '.state'
  ```

  Use `gh pr view <number>` with the actual PR number — the `--head` flag is not supported by this version of `gh`.

- If the state is not `MERGED`, tell the user and press them again.
- Once verified as `MERGED`, continue.

## Step 8 — PR cleanup

Run the `pr-cleanup` skill.
