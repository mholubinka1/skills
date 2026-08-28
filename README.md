# skills

A collection of Claude Code skills that sync automatically to `~/.claude/skills` on each commit.

## Setup

### Keeping skills in sync (`update-skills`)

On a machine that just *uses* these skills, clone the repo and run once:

```bash
./install.sh
```

This adds `update-skills` to your `PATH` — via `~/.zshrc` for zsh (macOS default), or
`~/.bashrc` otherwise (Git Bash on Windows, Linux). Open a new terminal or `source` that
file, then run `update-skills` any time to fast-forward this clone to `main` and re-sync
`~/.claude/skills`. It refuses to run if the clone has uncommitted changes.

The first `update-skills` run also creates `.venv` and installs the pre-commit hooks, so on
a consume-only machine this is the only setup you need — the rest of this section is for
contributors.

On Windows, run both `./install.sh` and `update-skills` from Git Bash (the shell the rest of
this guide assumes); `install.sh` writes to `~/.bashrc`, which Git for Windows' `~/.bash_profile`
sources.

### Prerequisites

Install [pre-commit](https://pre-commit.com):

```bash
pip install pre-commit
pre-commit install
```

### Python environment

The `Sync Claude Skills` post-commit hook runs `sync_claude_skills.py` using the first Python it finds, checked in this order:

1. `.venv/Scripts/python` (Windows venv)
2. `.venv/bin/python` (macOS/Linux venv)
3. System `python3`
4. System `python`

**macOS/Linux:**

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install pre-commit
pre-commit install
```

**Windows (Git Bash):**

```bash
python -m venv .venv
source .venv/Scripts/activate
pip install pre-commit
pre-commit install
```

No extra packages are required beyond the standard library — the venv is optional but preferred to isolate `pre-commit` itself.
