# Worktree creation precedes grill, using a wip/ placeholder branch

`/implement` now creates its isolation worktree as its very first action, before `init-agent-docs` or `grill` run — both of those steps can write files to the repo (`agent.md`, `CONTEXT.md`, ADRs), so isolation has to start before any file writes happen, not after. At that point the real branch name isn't known yet — `branch-hygiene` only infers it from grill output once it runs — so the worktree is created on a `wip/<slug>` placeholder branch, a category `branch-hygiene` already classifies as "must be renamed before code is written." Its existing mismatch-resolution step then renames the placeholder once the true name is confirmed, so no new renaming logic was needed.

## Considered Options

- **Create the worktree after `init-agent-docs`, before grill.** Rejected: `init-agent-docs` can still write to the main checkout (bootstrapping `.agent-docs/agent.md`, updating `CLAUDE.md`), which is exactly the kind of write isolation is meant to prevent.
- **Reorder the workflow so branch-hygiene's naming runs first**, in the main checkout, using just the raw trigger message, then create the worktree with the real name directly. Rejected: naming decisions would happen outside the isolation boundary the worktree is meant to provide, and it fragments `branch-hygiene`'s job (name inference) away from where it currently lives (after grill, using grill's richer output).
