---
name: pre-commit-check
description: Runs pre-commit hooks after code is written or changed. Use whenever code has just been written or edited, or the user asks to lint or format it.
allowed-tools: Bash, Read, Write, Edit
context: fork
agent: general-purpose
model: haiku
effort: low
background: false
argument-hint: "[changed files…]"
---

# Pre-Commit Hook Runner

Run the repo's pre-commit hooks in two passes — changed files, then the full repo — and fix
what they report.

Input: `$ARGUMENTS` — the changed files, if the caller named them. Otherwise collect them
yourself: `git diff --name-only HEAD` plus `git ls-files --others --exclude-standard`.

If `pre-commit` is not installed or `.pre-commit-config.yaml` is missing, stop and say which
in the report. If the project uses `poetry`, run every command below through `poetry run`.

## Pass 1 — Changed files

```bash
pre-commit run --files <changed files>
```

## Pass 2 — Full repo

Once pass 1 is clean, always run:

```bash
pre-commit run --all-files
```

This catches drift in files the current change did not touch; fixes here are in scope even
for those files. The passes are sequential: pass 2 never sends you back to pass 1.

## Fixing failures (both passes)

- A hook that auto-fixes in place (`black`, `isort`, `prettier`, …): re-run the same pass to
  confirm it now passes.
- Otherwise: read the error, fix the code, re-run.
- Repeat until the pass is clean. Every hook runs; leave `--no-verify` and skipping hooks to
  an explicit user request.
- A failure you cannot fix without changing behaviour or making a design choice: leave it
  and report it — the caller fixes it.

## Report

Done when both passes are clean or every remaining failure is reported. Reply with:

```text
Pre-commit results:

Changed files:
  - ruff ............. Passed
  - black ............ Fixed → Passed

Full repo:
  - ruff ............. Passed
  - isort ............ Fixed → Passed

Unfixed: <hook — file:line — error> per line, or "none"
Missing hooks worth adding: <one line, or "none">
Skipped / risk: <one line>
```
