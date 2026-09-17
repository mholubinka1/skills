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

On Windows, `install.sh` itself still needs Git Bash to run (it's a bash script; it writes to
`~/.bashrc`, which Git for Windows' `~/.bash_profile` sources). But it also puts `update-skills`
on the per-user `PATH`, so afterwards `update-skills` itself works natively from `cmd.exe` and
PowerShell too (via `update-skills.cmd`/`update-skills.ps1`), not just from Git Bash.

### Prerequisites

Install [pre-commit](https://pre-commit.com):

```bash
pip install pre-commit
pre-commit install
```

### Python environment

The `Sync Claude Skills` post-commit hook and `update-skills` (`bin/update-skills`, the Git
Bash/macOS/Linux script) both run `sync_claude_skills.py` using the first Python they find,
checked in this order:

1. `.venv/Scripts/python` (Windows venv)
2. `.venv/Scripts/python.exe` (Windows venv, as seen from Git Bash)
3. `.venv/bin/python` (macOS/Linux venv)
4. System `python3`
5. System `python`

The native `update-skills.ps1`/`update-skills.cmd` (cmd.exe/PowerShell) checks the same venv
path (`.venv\Scripts\python.exe`) but falls back to Windows-native system interpreters only:
`py` (the official launcher, tried first) then `python` — never `python3`, which on native
Windows is either absent or the Windows Store's non-functional alias stub, never a real
interpreter.

Either script only uses its system interpreters to *create* the `.venv`; both always run
`pip` and the sync against the venv itself.

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
