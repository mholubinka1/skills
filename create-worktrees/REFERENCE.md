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

**Detection.** First-class ecosystems are the ones in `update-dependencies`' Detection Table — its marker rules, repo root plus one level of subdirectories. This skill adds only the install commands below (`update-dependencies` is upgrade-oriented and has none). Any dependency manifest the table doesn't cover is an *uncovered* ecosystem — handled by the courtesy list.

**Install commands** — lockfile-respecting (install, not upgrade):

| Ecosystem | Install command |
|---|---|
| Python — uv | `uv sync` |
| Python — Poetry | `poetry install` |
| Python — PDM | `pdm install` |
| Python — Pipenv | `pipenv sync` |
| Python — pip | create a venv, then install into it (see the pip note below) |
| .NET / C# | `dotnet restore` |
| Node — npm | `npm ci` |
| Node — yarn | `yarn install --immutable` (Yarn 2+) or `yarn install --frozen-lockfile` (Yarn 1) — pick by `yarn --version` |
| Node — pnpm | `pnpm install --frozen-lockfile` |

**pip note.** Create a project-local venv and install into it, so nothing lands in system or user site-packages:

```bash
python -m venv .venv
.venv/Scripts/pip install -r requirements.txt   # Windows
.venv/bin/pip install -r requirements.txt       # POSIX
```

Choose the `python` for `python -m venv` by probing `python3` then `python` with `"$py" -c "" >/dev/null 2>&1` rather than `command -v` — same reason as `.pre-commit-config.yaml`'s `sync-claude-skills` hook: a Windows Store `python3` alias is on `PATH` but exits non-zero. If `python -m venv .venv` itself fails (the platform's venv module is absent), report that and skip the pip install.

**Courtesy list** — uncovered ecosystems. Best-effort, always non-fatal, always followed by the Step 5 `ACTION NEEDED` prompt:

| Marker | Best-effort install |
|---|---|
| `go.mod` | `go mod download` |
| `Cargo.toml` | `cargo fetch` |
| `Gemfile` | `bundle install` |

An uncovered marker not on this list gets no install attempt — Step 5 still prints the `ACTION NEEDED` line and takes the acknowledgement.
