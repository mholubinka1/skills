---
name: update-dependencies
description: Syncs the current repo with main/master, then updates dependencies to their latest patch/minor versions across detected ecosystems (Python, .NET/C#, Node/TypeScript/React) and bumps pre-commit hook versions, committing the result locally. Use when the user asks to update dependencies or refresh pre-commit hooks.
---

# Update Dependencies

Syncs with `main`/`master` first (Dependabot may have already merged updates there), then updates dependencies to their latest patch/minor versions across every detected ecosystem, plus pre-commit hook versions. Commits the result locally — it never pushes or opens a PR.

See [REFERENCE.md](REFERENCE.md) for per-ecosystem detection rules and commands.

## Step 1: Sync with main/master

1. Run `git status`. If the working tree is dirty, stash it: `git stash push -u -m "update-dependencies: pre-sync stash"`.
2. Run `git fetch origin`.
3. If the current branch is `main`/`master`: pull latest (`git pull`), then create a fresh branch off it, e.g. `git checkout -b chore/update-dependencies`.
4. Otherwise (already on a feature/dev branch): merge latest main/master into it, e.g. `git merge origin/main` (or `origin/master`), to absorb anything Dependabot already merged.
5. On merge conflicts: stop immediately. Do not auto-resolve. Leave any stash in place and point the user at the `resolving-merge-conflicts` skill.
6. If a stash was created in step 1 and the sync succeeded cleanly, pop it: `git stash pop`. On a conflict popping the stash, stop and hand off to the user — do not auto-resolve.

## Step 2: Detect ecosystems

Scan the repo root, and one level of subdirectories for monorepos, for marker files. See the Detection Table in [REFERENCE.md](REFERENCE.md). Run the matching update flow for every ecosystem found — a repo can have more than one.

If nothing matches, report that no known ecosystem was detected and give brief generic pointers (see Unknown Ecosystems in REFERENCE.md). Do not fail the run.

## Step 3: Update dependencies per ecosystem

For each detected ecosystem, follow its command sequence in [REFERENCE.md](REFERENCE.md):

- **Python** — uv, Poetry, PDM, Pipenv, or pip, selected by marker file.
- **.NET / C#** — `dotnet` CLI (covers any `.csproj`/`.sln`).
- **Node / TypeScript / React** — npm, yarn, or pnpm, selected by lockfile.

Apply patch/minor bumps only. Record any package where a major version is available but not applied — these go in the final report, not the working tree.

If a required package manager binary isn't installed for a detected ecosystem (e.g. `pyproject.toml` present but `poetry` not on `PATH`), report it and skip that ecosystem rather than failing the whole run.

## Step 4: Update pre-commit hooks

If `.pre-commit-config.yaml` exists at the repo root:

1. Run `pre-commit autoupdate`.
2. Run `pre-commit run --all-files` and record pass/fail per hook. A newly bumped hook surfacing a failure is expected and useful — report it, don't fix it silently.

## Step 5: Best-effort validation

For each ecosystem updated, run its standard build/test command if one is detectable — see Validation Commands in [REFERENCE.md](REFERENCE.md). Never block or revert on failure; just record pass/fail for the report.

## Step 6: Commit

Stage only the files this run actually touched — dependency manifests, lockfiles, and `.pre-commit-config.yaml` (e.g. `package.json`, `package-lock.json`, `requirements.txt`, `poetry.lock`, `uv.lock`, `pyproject.toml`, `*.csproj`, `.pre-commit-config.yaml`). Never `git add -A` or `git add .`: a stash popped back in Step 1 may contain unrelated in-progress work that must not be bundled into this commit.

Commit with a clear, descriptive message summarizing what was updated per ecosystem, e.g.:

```text
chore: update dependencies (patch/minor)

- npm: react 18.2.0 -> 18.2.3, typescript 5.3.2 -> 5.3.4
- pre-commit: black 23.12.0 -> 24.1.1
```

Do not push. Commit even if best-effort validation (Step 5) or the pre-commit `--all-files` run (Step 4) reported failures — those results are already captured in the report for the user to act on.

## Step 7: Report

Summarize:

- The branch the updates landed on, and whether it was newly created.
- Per ecosystem: packages updated (old → new version), and majors available but not applied.
- Pre-commit: hooks bumped, and the `--all-files` result.
- Validation: build/test result per ecosystem, if run.
- The commit created (hash + message summary), and an explicit note that it was not pushed — the next step (review, test, push/PR) is up to the user, or a follow-on skill like `code-review`.

## Important rules

- Never apply major version bumps automatically.
- Never push, and never open a PR — this skill commits locally only.
- Only stage files this run touched; never `git add -A`/`git add .`.
- Never auto-resolve merge or stash conflicts — stop and hand off.
- If a package manager isn't installed for a detected ecosystem, report and skip it rather than failing the whole run.
