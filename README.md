# skills

A collection of Claude Code skills that sync automatically to `~/.claude/skills` on each commit.

## Setup

### Prerequisites

Install [pre-commit](https://pre-commit.com):

```bash
pip install pre-commit
pre-commit install
```

### Python environment

The `Sync Claude Skills` post-commit hook runs `sync_claude_skills.py` using the first PythPleon it finds, checked in this order:

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
