---
name: branch-hygiene
description: Validates the current git branch before work begins — autoSetupRemote, trunk-branch detection, prefix-vs-change-type, and name relevance. Takes a one-line summary of the work, optionally preceded by a change_type. Use at the start of a work session, or from another skill passing a known change_type.
context: fork
agent: general-purpose
model: haiku
effort: low
background: false
argument-hint: "[change_type] <one-line summary of the work>"
---

# Branch Hygiene

A read-only check: report whether the current branch fits the work, and what the caller
should do about it. Change nothing — no config, no branches, no commits.

Input: `$ARGUMENTS`, an optional `change_type` then a quoted one-line summary of the work,
e.g. `feature "add CSV export"` or `"add CSV export"`. A first word counts as the confirmed
`change_type` only when it is unquoted, is one of `feature`, `bugfix`, `hotfix`, `release`,
`chore`, and a quoted summary follows it; otherwise the whole input is the summary (so
`"feature flag cleanup"` is a summary). A summary is required: on empty input, run
nothing and reply `verdict: unknown — no summary given` and
`next: rerun branch-hygiene with a one-line summary of the work`.

Tables and rules for each step are in [REFERENCE.md](REFERENCE.md).

## Step 1 — autoSetupRemote

Run `git config push.autoSetupRemote`. Record whether it is `true`.

## Step 2 — Current branch

Run `git branch --show-current`. Classify it with the Branch Classification Table.

## Step 3 — Change type

Use the given `change_type`; otherwise infer one from the summary with the Change Type
Inference Heuristics, and mark it `inferred`.

## Step 4 — Prefix

Check the branch prefix against the Branch Prefix Validation Table. A trunk branch, a `wip/`
placeholder, a prefix that doesn't match, or an unrecognised prefix is a mismatch.

## Step 5 — Name relevance

Judge the branch slug against the summary with the Branch Name Relevance Rules.

## Step 6 — Suggestion

On any mismatch, build a suggested name `<change_type>/<slug-from-summary>` and the
command that creates it, using the Create Command section of REFERENCE.md.

## Report

Done when every step above has a line. Reply with exactly this block:

```text
autoSetupRemote: true | false
branch: <name> (<classification>)
change_type: <type> (given | inferred | unknown)
verdict: ok | mismatch — <reason>
suggested: <branch>                        (mismatch only)
next: <see below>
Skipped / risk: <one line>
```

`next:` tells the caller what to do, one clause per problem found:

- autoSetupRemote not `true` → `ask the user "Set push.autoSetupRemote to true?"; on yes run: git config push.autoSetupRemote true`
- mismatch → `ask the user "You're on <branch> but this work is <summary>. Create <suggested> and move the work there?"; on yes run: <create command>. Never push or commit to the new branch.`
- neither → `none — the branch fits.`
