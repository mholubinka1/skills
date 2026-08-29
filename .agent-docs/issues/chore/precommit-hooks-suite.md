# Issues: chore/precommit-hooks-suite

## 1. Make the repo a `uv` project (`pyproject.toml` + `uv.lock` + generated `requirements.txt`)

**GitHub**: #66

**Blocked by**: None

**User stories**: 2, 3

### What to build

- Add a `[project]` table to `pyproject.toml`: `name = "skills"`, `version = "0.0.0"`,
  one-line `description`, `requires-python = ">=3.13"`, `dependencies = []`. Add `[tool.uv]`
  with `package = false`. Keep `[tool.bandit]` unchanged.
- Run `uv lock` → commit `uv.lock`.
- Replace `requirements.txt` with `uv export --frozen --no-hashes --output-file requirements.txt`
  output → commit. Drop the old hand-written comment.

### Acceptance criteria

- [ ] `pyproject.toml` has a valid `[project]` table and `[tool.uv] package = false`;
      `[tool.bandit]` unchanged.
- [ ] `uv lock` succeeds; `uv.lock` is committed.
- [ ] `requirements.txt` is the `uv export` output, committed; no hand-written prose.
- [ ] `uv export --frozen` runs clean against the committed lock.
- [ ] `pre-commit-check` passes on the changed files.

---

## 2. Add the hook suite and clean `.pre-commit-config.yaml`

**GitHub**: #67

**Blocked by**: #66

**User stories**: 1, 4, 5

### What to build

- Add five `- repo:` blocks with pinned `rev`s:
  - `pip-audit` (`pypa/pip-audit`, id `pip-audit`)
  - `actionlint` (`rhysd/actionlint`, id `actionlint`)
  - `validate-pyproject` (`abravalheri/validate-pyproject`, id `validate-pyproject`)
  - `pyproject-fmt` (`tox-dev/pyproject-fmt`, id `pyproject-fmt`)
  - `uv-export` (`astral-sh/uv-pre-commit`, id `uv-export`, args
    `["--frozen", "--no-hashes", "--output-file", "requirements.txt"]`)
- Run `pre-commit autoupdate`; commit the resulting rev bumps (new and existing).
- Remove the duplicate `pre-commit/pre-commit-hooks` block (the `v6.0.0` one near the end);
  keep a single block at `rev: v6.0.0` running `trailing-whitespace` + `end-of-file-fixer`.
- Exactly one blank line between every top-level `- repo:` block.
- Run `pyproject-fmt` and commit its formatting of `pyproject.toml`.
- `pre-commit run --all-files` green — fix (do not suppress) any pre-existing finding a new
  hook surfaces.

### Acceptance criteria

- [ ] `pip-audit`, `actionlint`, `validate-pyproject`, `pyproject-fmt`, `uv-export` all
      present with pinned `rev`s and correct ids/args.
- [ ] `pre-commit-hooks` appears exactly once, at `rev: v6.0.0`, with both hooks.
- [ ] One blank line between every repo block, including around the `local` block.
- [ ] `pyproject.toml` is `pyproject-fmt`-clean and `validate-pyproject`-valid.
- [ ] `actionlint` runs without error (no workflows present).
- [ ] `pre-commit run --all-files` passes on both the changed-files and full-repo passes;
      any new-hook finding is fixed, not `# noqa`/skipped.
- [ ] `shellcheck` unchanged except a possible `autoupdate` rev bump; no `poetry-export`
      referenced anywhere.

---
