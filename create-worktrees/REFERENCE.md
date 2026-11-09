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

## Why `.claude` and not `.claude/worktrees/`

`.claude` is gitignored wholesale, matching this skills repo's own `.gitignore` convention — it also covers `settings.local.json` and other local-only state under `.claude/`, not just worktree directories.

## Dependency bootstrap (Step 5)

**Detection.** First-class ecosystems are the ones in `../update-dependencies/REFERENCE.md` "Detection Table", with its marker rules and scan scope. For each one detected, run its command from the install table below — the lockfile-respecting *install*, not the *upgrade* flow `update-dependencies` documents. Any dependency manifest the Detection Table doesn't cover is an *uncovered* ecosystem.

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

**pip note.** Create a project-local venv and install into it, so nothing lands in system or user site-packages. First pick the interpreter (`py`) — probe `python3` then `python` with `"$py" -c "" >/dev/null 2>&1` and take the first that runs, rather than `command -v`: a Windows Store `python3` alias is on `PATH` but exits non-zero. Then:

```bash
"$py" -m venv .venv
.venv/Scripts/pip install -r requirements.txt   # Windows
.venv/bin/pip install -r requirements.txt       # POSIX
```

If `"$py" -m venv .venv` itself fails (the platform's venv module is absent), report that and skip the pip install.

## Install handover (Step 5)

Installing is mechanical, so it runs in a Haiku sub-agent with an empty context. Dispatch one `Agent` call, `subagent_type: general-purpose`, `model: haiku`, `run_in_background: false`, and wait for its report. Handover:

```text
In <worktree path>, run these install commands, one ecosystem at a time:
<ecosystem>: <command(s) printed in Step 5>, one line each
A failing install does not stop the others.
Return per ecosystem: pass, or fail with the failing command and its first error line.
```

## Uncovered ecosystems (Step 5)

**Courtesy list** — best-effort, always non-fatal, always followed by the `ACTION NEEDED` prompt below. Attempt each recognised one's install whatever the *Install* answer, in the Install sub-agent (add it to the handover above, or dispatch that handover with only these commands), reported like a first-class install.

| Marker | Best-effort install |
|---|---|
| `go.mod` | `go mod download` |
| `Cargo.toml` | `cargo fetch` |
| `Gemfile` | `bundle install` |

An uncovered marker not on this list gets no install attempt.

Then print once, covering every uncovered ecosystem found:

`ACTION NEEDED: add <ecosystem>[, <ecosystem>…] as a first-class entry in create-worktrees/REFERENCE.md`

and use `AskUserQuestion` a single time to make the user acknowledge it before the workflow continues. Non-interactive: print it and continue.
