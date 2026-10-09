---
name: pre-commit-check
description: Runs pre-commit hooks after code is written or changed. Use whenever code has just been written or edited, or the user asks to lint or format it.
allowed-tools: Bash, Read
context: fork
agent: general-purpose
model: haiku
effort: low
background: false
argument-hint: "[changed files…]"
---

# Pre-Commit Hook Runner

Run the repo's pre-commit hooks in two passes — changed files, then the full repo — keep the
hooks' own autofixes, and report everything else to the caller.

Input: `$ARGUMENTS` — the changed files, if the caller named them. Otherwise collect them
yourself: `git diff --name-only HEAD` plus `git ls-files --others --exclude-standard`; if that
is empty (the work is already committed), use `git diff --name-only <base>...HEAD`, where
`<base>` is the output of `git symbolic-ref refs/remotes/origin/HEAD --short`. If that lookup
fails, skip pass 1, say "changed set unknown" on the Skipped / risk line, and list every
pass 2 failure under `Unclassified:` instead of the two failure lines.

Find the runner, first match wins: `pre-commit` on `PATH`; the repo's virtualenv
(`.venv/bin/pre-commit`, or `.venv/Scripts/pre-commit` on Windows); `poetry run pre-commit`
when the project uses Poetry; `uv run pre-commit` when it uses uv. Use that runner for every
command below. With no `.pre-commit-config.yaml`, run the repo's hook script instead
(`.githooks/pre-commit`, else `.git/hooks/pre-commit`) once, apply the same autofix rule
below, and list every remaining failure under `Unclassified:`. If there is neither, or no runner works, stop and say which in the report.

## Pass 1 — Changed files

```bash
pre-commit run --files <changed files>
```

## Pass 2 — Full repo

Always run it after pass 1, whatever pass 1 left unfixed:

```bash
pre-commit run --all-files
```

This catches drift in files the current change did not touch. The passes are sequential:
pass 2 never sends you back to pass 1.

## Handling failures (both passes)

Before each pass, record `git diff --name-only`; after it, diff again. Files that appear only
afterwards were autofixed by the hooks — that difference is the autofixed set.

- A hook that autofixes in place (`black`, `isort`, `prettier`, end-of-file, …): keep the
  fix, in any file, and re-run the same pass once to confirm it now passes. A hook still
  changing files on that re-run is a failure: list it like any other failure below. These autofixes are
  the only edits you make.
- Any other failure (type errors, lint findings, failing checks): leave the code as it is
  and list it — under **changed** when the file is in the changed set, otherwise under
  **pre-existing**.
- A hook already listed from pass 1 is not listed again from pass 2.
- Every hook runs; leave `--no-verify` and skipping hooks to an explicit user request.

## Report

Done when both passes have run and every failure is listed. Reply with:

```text
Pre-commit results:

Changed files:
  - ruff ............. Passed
  - black ............ Fixed → Passed

Full repo:
  - ruff ............. Passed
  - isort ............ Fixed → Passed

Files autofixed (changed set): <paths>, or "none"
Files autofixed (outside the change): <paths>, or "none"
Unfixed (changed files): <hook — file:line — error> per line, or "none"
Pre-existing (untouched files): <hook — file:line — error> per line, or "none"
Unclassified: <hook — file:line — error> per line (changed set unknown, or hook script only)
Missing hooks worth adding: <one line, or "none">
next: <see below>
Skipped / risk: <one line>
```

`next:` tells the caller what to do, one clause per non-empty line above:

- Files autofixed (changed set) → `stage these with your commit: <paths>`
- Files autofixed (outside the change) → `leave these unstaged and tell the user they hold repo-wide drift fixes for a separate commit: <paths>`
- Unfixed (changed files) → `fix each changed-file item and run pre-commit-check again; if this was already your third run, stop and show the items to the user`
- Pre-existing → `show the pre-existing failures to the user; leave those files alone`
- Unclassified → `show these failures to the user; the changed set could not be worked out`
- every line `none` → `none — ready to commit.`
