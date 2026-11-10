---
name: implement
description: Carries a repository change from request to merged PR inline in the current conversation. Use when the user wants to make any change to a repository.
allowed-tools:
  - Skill
  - Read
  - Glob
  - ExitWorktree
  - Bash(git branch --show-current)
  - Bash(git add *)
  - Bash(git commit *)
  - Bash(gh pr view *)
  - Bash(git rev-parse --show-toplevel)
---

# Implement

Run the full implementation workflow inline in the current conversation, following [WORKFLOW.md](WORKFLOW.md) step by step.
