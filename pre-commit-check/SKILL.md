---
name: pre-commit-check
description: Run pre-commit hooks after writing or modifying code. Use when code has been written, edited, or generated, or when the user asks to lint, format, or validate code quality.
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
5. **Report results** — Summarize which hooks ran, what failed, what was
   fixed, and confirm all checks pass.

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
- Stage auto-fixed files with `git add` before reporting success.

## Output Format

After all hooks pass, report like this:

```text
✅ Pre-commit results:
  - ruff ............. Passed
  - black ............ Fixed → Passed
  - isort ............ Fixed → Passed
  - trailing-whitespace Passed
  - end-of-file-fixer  Passed

All hooks passed. Files are ready to commit.
```
