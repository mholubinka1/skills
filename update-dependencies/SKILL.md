---
name: update-dependencies
description: Runs a dependency update on the current repo, committing the result locally. Use when the user asks to update dependencies or refresh pre-commit hooks.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Edit
  - Bash(git status *)
  - Bash(git symbolic-ref refs/remotes/origin/HEAD --short)
  - Bash(git branch --show-current)
  - Bash(date +%F*)
  - Bash(git fetch *)
  - Bash(git pull *)
  - Bash(git checkout -b *)
  - Bash(git merge *)
  - Bash(git diff *)
  - Bash(git stash push *)
  - Bash(git stash list *)
  - Bash(git stash apply *)
  - Bash(git add *)
  - Bash(git commit *)
  - Bash(uv lock --upgrade)
  - Bash(uv sync)
  - Bash(uv tree --outdated)
  - Bash(uv pip list --outdated)
  - Bash(poetry update)
  - Bash(poetry show --outdated)
  - Bash(pdm update)
  - Bash(pdm outdated)
  - Bash(pipenv update *)
  - Bash(pip-compile --upgrade *)
  - Bash(pip list --outdated)
  - Bash(pip install -r requirements.txt)
  - Bash(dotnet list package --outdated)
  - Bash(dotnet add * package *)
  - Bash(dotnet tool list --global)
  - Bash(dotnet outdated *)
  - Bash(npm outdated)
  - Bash(npm update)
  - Bash(yarn --version)
  - Bash(yarn outdated)
  - Bash(yarn upgrade)
  - Bash(yarn up -R *)
  - Bash(pnpm outdated)
  - Bash(pnpm update)
  - Bash(pre-commit autoupdate *)
  - Bash(pre-commit run *)
context: fork
agent: general-purpose
model: haiku
effort: low
background: false
---

# Update Dependencies

Syncs with the default branch first (Dependabot may have already merged updates there), then updates dependencies to their latest patch/minor versions across every detected ecosystem, plus pre-commit hook versions. Commits the result locally.

See [REFERENCE.md](REFERENCE.md) for per-ecosystem detection rules and commands.

## Step 1: Sync with the default branch

1. Resolve the default branch: `git symbolic-ref refs/remotes/origin/HEAD --short`. It prints a ref such as `origin/main`; the part after `origin/` is the default branch name. If the command fails, stop and report it, telling the user to run `git remote set-head origin --auto`. Never guess `main` or `master`.
2. Run `git status --porcelain`. If it prints anything, the working tree is dirty. Set it aside and note the stash's SHA:

   ```bash
   date +%F-%H%M%S-%N
   git stash push -u -m "update-dependencies <that timestamp>"
   git stash list --format='%H %gs'
   ```

   The SHA is the first field of the line that ends with your message. Exactly one line must end with it. If more than one does, another session stashed under the same message and the run cannot tell which entry is its own: stop, leave every stash in place, and report each matching SHA. Otherwise keep the SHA for Step 6. The stash stack is shared with other worktrees and sessions, so from here on this stash is only ever named by its SHA.
3. Run `git fetch origin`.
4. If `git branch --show-current` prints the default branch name: pull latest (`git pull`), then create a dated branch off it: `git checkout -b chore/update-dependencies-<YYYY-MM-DD>`, with the date from `date +%F`. If that branch already exists, add `-2`, then `-3`, and so on.
5. Otherwise (already on a feature or dev branch): merge the default branch into it, `git merge origin/<default branch>`, to absorb anything Dependabot already merged.
6. On merge conflicts: stop immediately and leave the stash in place. Report the conflicted files (`git diff --name-only --diff-filter=U`) and the stash SHA — resolving them is the caller's job.

The stash stays set aside until Step 6, so the working tree holds only this run's changes while it updates and commits. Whenever the run stops early, report the stash SHA.

## Step 2: Detect ecosystems

Scan for marker files using the Detection Table and its scan scope in [REFERENCE.md](REFERENCE.md). Run the matching update flow for every ecosystem found — a repo can have more than one.

If nothing matches, report that no known ecosystem was detected and give brief generic pointers (see Unknown Ecosystems in REFERENCE.md). Do not fail the run.

## Step 3: Update dependencies per ecosystem

For each detected ecosystem, follow its command sequence in [REFERENCE.md](REFERENCE.md).

Apply patch/minor bumps only. Record any package where a major version is available but not applied — these go in the final report, not the working tree.

If a required package manager binary isn't installed for a detected ecosystem (e.g. `pyproject.toml` present but `poetry` not on `PATH`), report it and skip that ecosystem rather than failing the whole run.

## Step 4: Update pre-commit hooks

If `.pre-commit-config.yaml` exists at the repo root:

1. Run `pre-commit autoupdate`.
2. Stage this run's changes so far, by path: each manifest and lockfile Step 3 changed, and `.pre-commit-config.yaml`. The index now holds them as they were before any hook ran.
3. Run `git diff --name-only` and `git status --porcelain`. Note the tracked files the first lists — Step 3 changed them and step 2 did not stage them, such as a regenerated `.pnp.cjs` — and the untracked (`??`) files in the second.
4. Run `pre-commit run --all-files` and record pass/fail per hook. A newly bumped hook surfacing a failure is expected and useful — report it, don't fix it silently.
5. Find the hook autofixes. `git diff --name-only` compares the working tree with the index, so a file staged in step 2 appears in it only when a hook rewrote it. Every file it lists now that step 3 did not note was rewritten by a hook. Run `git status --porcelain` again: an untracked file that step 3 did not note was created by a hook. Record all of these as the hook autofixes.
6. Where a hook rewrote a file staged in step 2, `git add` that file again, so the commit holds the version that passes the hooks, and record the autofix as committed. Leave every other autofix in the working tree, unstaged, for the user to review.

## Step 5: Best-effort validation

For each ecosystem updated, run its standard build/test command if one is detectable — see Validation Commands in [REFERENCE.md](REFERENCE.md). This step is **best-effort**: failures never block or revert anything and never stop the commit; just record pass/fail for the report.

## Step 6: Commit

Stage only the files this run actually touched — dependency manifests, lockfiles, and `.pre-commit-config.yaml` (e.g. `package.json`, `package-lock.json`, `requirements.txt`, `poetry.lock`, `uv.lock`, `pyproject.toml`, `*.csproj`, `.pre-commit-config.yaml`). Step 4 has already staged them when it ran. Never `git add -A` or `git add .`: the hook autofixes Step 4 left unstaged are not part of this commit.

Commit with a clear, descriptive message summarizing what was updated per ecosystem, e.g.:

```text
chore: update dependencies (patch/minor)

- npm: react 18.2.0 -> 18.2.3, typescript 5.3.2 -> 5.3.4
- pre-commit: black 23.12.0 -> 24.1.1
```

Do not push. Commit even when Step 4 or Step 5 reported failures; their results are already captured in the report for the user to act on.

**Then restore the stash**, if Step 1 made one — after the commit, or straight away when there was nothing to commit:

```bash
git stash apply <stash SHA from Step 1>
```

Never run `git stash pop` or a bare `git stash apply`: the top of the shared stack may be another session's entry. On a conflict applying the stash, stop and hand off to the user with the SHA — do not auto-resolve. A successful apply leaves the entry on the stack; leave it there and report it, so the user can drop it once they have checked their work is back.

## Step 7: Report

Summarize:

- The branch the updates landed on, and whether it was newly created.
- Per ecosystem: packages updated (old → new version), and majors available but not applied.
- Pre-commit: hooks bumped, the `--all-files` result, and every hook autofix from Step 4 by file path, noting for each whether it was committed with the file this run changed or is uncommitted.
- Validation: build/test result per ecosystem, if run.
- Stash: if Step 1 stashed work, whether it was restored, and its SHA with a note that the entry is still on the stash stack.
- The commit created (hash + message summary), and an explicit note that it was not pushed — the next step (review, test, push/PR) is up to the user, or a follow-on skill like `code-review`.
- `Skipped / risk:` one line naming any ecosystem skipped and any failure the user must act on.
