---
name: branch-hygiene
description: Validate the current git branch before starting work. Checks autoSetupRemote config, detects trunk branches, validates branch prefix against change type, and checks that the branch name is relevant to the current work. Accepts an optional change_type (feature, bugfix, hotfix, release, chore) — if not provided, infers it from the user's request. Use at the start of any work session, or invoke from other skills with a known change_type.
---

# Branch Hygiene

Validates that you are on the right branch before work begins. Can be run in two modes:

- **Fast mode** (no `change_type`): checks `autoSetupRemote` and warns if on a trunk branch. Infers change type from the user's request using heuristics.
- **Full mode** (`change_type` provided): performs all checks including prefix validation against the confirmed change type.

See [REFERENCE.md](REFERENCE.md) for classification tables, inference heuristics, and the full mismatch resolution procedure.

## Step 1: Check autoSetupRemote

Run `git config push.autoSetupRemote`. If the output is not `true`, warn the user and ask if they want it set before continuing.

## Step 2: Detect current branch

Run `git branch --show-current`. Classify the branch using the table in [REFERENCE.md](REFERENCE.md#branch-classification-table-step-2). Flag trunk branches (`main`, `master`, `develop`) and unrecognised prefixes.

## Step 3: Determine change type

If called from within `/implement`, derive the change type and branch slug from the grill session output already in context. If `change_type` was passed explicitly, use it. Otherwise infer from the user's request — see [REFERENCE.md](REFERENCE.md#change-type-inference-heuristics-step-3).

## Step 4: Validate branch prefix against change type

Check the branch prefix against the valid prefixes for the change type — see [REFERENCE.md](REFERENCE.md#branch-prefix-validation-table-step-4). Flag trunk branches, `wip/` placeholders, prefix mismatches, and unrecognised prefixes.

## Step 5: Validate branch name relevance

Extract the descriptive slug and assess whether it relates to the current work. Flag when the slug clearly describes different work — see [REFERENCE.md](REFERENCE.md#branch-name-relevance-rules-step-5) for signal criteria.

## Step 6: Resolve mismatch

On any mismatch, suggest a well-formed branch name and offer to create it from the remote default branch. See [REFERENCE.md](REFERENCE.md#mismatch-resolution-step-6) for the full procedure. **Do not push or commit to the new branch.**

If there is no mismatch, confirm the branch is appropriate and continue.
