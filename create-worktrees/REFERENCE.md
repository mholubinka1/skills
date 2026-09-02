# Create Worktrees — Reference

## Slugify rule (Step 4)

Turn the trigger message into a short kebab-case fragment:

1. Take the first ~5 meaningful words (skip filler like "please", "can you", "I want to").
2. Lowercase, strip punctuation, join with hyphens.
3. Truncate to roughly 40 characters, cutting on a word boundary.

### Examples

| Trigger message | Slug |
|---|---|
| "Fix the flaky login test on CI" | `fix-flaky-login-test-ci` |
| "Can you add caching to the search endpoint?" | `add-caching-search-endpoint` |
| "Update pre-commit hooks to their latest versions" | `update-pre-commit-hooks-latest-versions` |

Exact wording doesn't matter — the slug only has to be recognisable enough to identify the worktree in `git worktree list` before `branch-hygiene` switches it over to the real branch name later. Don't spend time optimising it.

## Why `.claude` and not `.claude/worktrees/`

`.claude` is gitignored wholesale, matching this skills repo's own `.gitignore` convention — it also covers `settings.local.json` and other local-only state under `.claude/`, not just worktree directories.

## Dependency bootstrap (Step 5)

A fresh worktree has none of the gitignored dependency artifacts the main checkout accumulated. Step 5 offers to install them so the worktree runs code the same way `main` does.

**Detection.** Ecosystems are detected exactly as in `update-dependencies`' Detection Table — its marker rules, repo root plus one level of subdirectories. This skill adds only the install commands below; `update-dependencies` is upgrade-oriented and has none.

**Install commands** — lockfile-respecting (install, not upgrade):

| Ecosystem | Install command |
|---|---|
| Python — uv | `uv sync` |
| Python — Poetry | `poetry install` |
| Python — PDM | `pdm install` |
| Python — Pipenv | `pipenv sync` |
| Python — pip (`requirements.txt`) | `python -m venv .venv`, then `.venv/Scripts/pip` (Windows) / `.venv/bin/pip` (POSIX) `install -r requirements.txt` |
| .NET / C# | `dotnet restore` |
| Node — npm (`package-lock.json`) | `npm ci` |
| Node — yarn (`yarn.lock`) | `yarn install --frozen-lockfile` |
| Node — pnpm (`pnpm-lock.yaml`) | `pnpm install --frozen-lockfile` |

For the pip row, choose the `python` for `venv` creation by probing each candidate with `"$py" -c "" >/dev/null 2>&1` rather than `command -v` — the same reason as `.pre-commit-config.yaml`'s `sync-claude-skills` hook: a Windows Store `python3` alias is on `PATH` but exits non-zero.

**Courtesy list** — ecosystems without a first-class entry. Best-effort, always non-fatal, and always followed by the Step 5 `ACTION NEEDED` prompt:

| Marker | Best-effort install |
|---|---|
| `go.mod` | `go mod download` |
| `Cargo.toml` | `cargo fetch` |
| `Gemfile` | `bundle install` |

Any other unrecognised dependency marker: attempt no install; Step 5 still prints the `ACTION NEEDED` line and takes the acknowledgement.
