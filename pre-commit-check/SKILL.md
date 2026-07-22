---
name: pre-commit-check
description: Run pre-commit hooks after writing or modifying any code. Use whenever code has been written, edited, or generated, or when the user asks to lint, format, or validate code quality.
allowed-tools: Bash, Read, Write
---

# Pre-Commit Hook Runner

After writing or modifying any code files, automatically run pre-commit hooks
and fix any issues found.

## Workflow

1. **Identify changed files** — Determine which files were just created or modified.
2. **Run pre-commit on those files**:

   ```bash
   pre-commit run --files <changed_files>
   ```

   If no specific files are known, run against all staged files:

   ```bash
   pre-commit run --all-files
   ```

3. **Parse the output** — Check each hook's result for PASSED, FAILED, or
   SKIPPED.
4. **If any hooks fail**:
   - Read the failing file(s) to see what changed (some hooks like `black`,
     `isort`, or `prettier` auto-fix in place).
   - If auto-fixed: re-run `pre-commit run --files <fixed_files>` to confirm
     they now pass.
   - If not auto-fixed: read the error output, apply the necessary fix
     manually, then re-run.
   - Repeat until all hooks pass.
5. **Run a full-repo check** — Once the changed-files pass is clean, run:

   ```bash
   pre-commit run --all-files
   ```

   This catches drift in files the current session didn't touch. Treat
   failures here exactly like changed-files failures: auto-fix in place where
   the hook supports it, otherwise read the error and fix manually — even in
   files outside the current change set — then re-run `--all-files` until
   clean. Do not go back and re-check the changed-files pass afterward; the
   two passes are sequential, not a combined loop.
6. **Report results** — Summarize both passes separately: which hooks ran,
   what failed, what was fixed, and confirm all checks pass.

## Important Rules

- Never skip or bypass failing hooks unless the user explicitly asks.
- Do not use `--no-verify` on commits.
- If the project is using `poetry` as the environment and package manager,
  modify any `pre-commit` commands accordingly.
- If `pre-commit` is not installed, inform the user and ask how they'd like
  to proceed.
- If `.pre-commit-config.yaml` does not exist, inform the user and ask how
  they'd like to proceed.
- Always re-run hooks after making fixes to confirm clean output.
- Always recommend additional or missing hooks that would usefully verify code if applicable
- The full-repo pass (step 5) always runs, with no skip option — it is the
  guarantee that changed-files-only checks don't let repo-wide drift slip
  through.
- Fixes made during the full-repo pass are in scope even for files the
  current session didn't touch, since the pass exists specifically to catch
  that drift.

## Output Format

After both passes pass, report like this:

```text
✅ Pre-commit results:

Changed files:
  - ruff ............. Passed
  - black ............ Fixed → Passed
  - isort ............ Fixed → Passed
  - trailing-whitespace Passed
  - end-of-file-fixer  Passed

Full repo:
  - ruff ............. Passed
  - black ............ Fixed → Passed
  - isort ............ Passed
  - trailing-whitespace Passed
  - end-of-file-fixer  Passed

All hooks passed on both passes. Files are ready to commit.
```
