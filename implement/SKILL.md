---
name: implement
description: Full implementation workflow — from change request to merged PR. Spawns a fresh sub-agent briefed with the trigger context to run the complete cycle: init-agent-docs → grill → branch → spec → issues → BDD per issue → code review → PR merge confirmation → cleanup. Use when the user wants to implement a feature, fix a bug, or make any change to the repository.
---

# Implement

Capture the trigger context from the current conversation and spawn a fresh sub-agent to run the full implementation cycle.

## Step 1 — Capture trigger context

Before spawning, summarise from the current conversation:

- What the user wants to change or build (one short paragraph)
- Any constraints, preferences, or prior decisions already stated
- The current branch (if the user mentioned it or it is evident from context)

Keep the summary tight — enough to brief a fresh agent, not a transcript.

## Step 2 — Spawn the implementation sub-agent

Spawn a `claude` sub-agent with a self-contained prompt that includes:

1. The trigger context summary from Step 1
2. The full workflow from [WORKFLOW.md](WORKFLOW.md) (copy verbatim into the prompt)

## Step 3 — Monitor

The sub-agent runs the full workflow. You (the parent) have nothing further to do — the sub-agent will report when complete.
