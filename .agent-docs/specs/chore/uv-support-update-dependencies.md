# Add uv Support to the update-dependencies Skill

## Problem Statement

The `update-dependencies` skill documents four Python managers — Poetry, PDM, Pipenv, and
pip — but not [uv](https://docs.astral.sh/uv/), which has become a mainstream Python package
manager and is increasingly the only lockfile a new project ships. When the skill is run
against a uv repo today, one of two things goes wrong:

- If `pyproject.toml` also carries a `[tool.poetry]` or `[tool.pdm]` table (common when uv
  is adopted for locking while older tool config lingers), the skill runs the wrong
  manager's commands.
- If `pyproject.toml` is PEP 621-only with just a `uv.lock` beside it, no Detection Table
  row matches and the repo is not recognised as Python at all.

Either way the user gets no uv dependency bump from a skill whose whole job is to bump
dependencies across every detected ecosystem.

## Solution

Treat uv as a first-class Python **manager** within the existing Python **ecosystem**: add a
Detection Table row, a precedence rule that disambiguates a multi-tool `pyproject.toml`, a
`uv` command subsection mirroring the Poetry entry's shape, and a validation-command note.
The skill then detects a uv repo, runs `uv lock --upgrade` + `uv sync` to bump within the
`pyproject.toml` constraints, lists still-outdated packages as major-bump candidates for the
report, and stages `uv.lock` in the local commit — with no behavioural change for any
non-uv repo.

## User Stories

1. As a developer running `/update-dependencies` against a repo locked with uv, I want the
   skill to recognise the uv ecosystem and run `uv lock --upgrade` + `uv sync`, so that my
   uv dependencies get the same patch/minor bump the other ecosystems already get.
2. As a developer whose `pyproject.toml` carries both `[tool.poetry]` (metadata) and a
   `uv.lock`, I want a documented precedence rule that picks uv, so that the skill does not
   run `poetry update` against a uv-managed project.
3. As a developer whose `pyproject.toml` is PEP 621-only with a `uv.lock` beside it, I want
   that combination detected as Python, so that the repo is not silently reported as "no
   known ecosystem".
4. As a developer reading the run report, I want packages that uv could not advance to
   latest (held back by a `pyproject.toml` constraint) listed as major-bump candidates, so
   that I know what a manual constraint change would unlock — consistent with how Poetry and
   npm results are reported.
5. As a developer reviewing the local commit, I want `uv.lock` (and `pyproject.toml` if the
   upgrade touched it) staged and nothing else, so that the commit matches the skill's
   existing "only stage what this run touched" rule.
6. As an agent maintaining `.agent-docs/context.md`, I want the Ecosystem glossary entry's
   marker examples to mention uv, so that the domain vocabulary stays in step with the
   skill.

## Implementation Decisions

- Files touched: `update-dependencies/REFERENCE.md`, `update-dependencies/SKILL.md`,
  `.agent-docs/context.md`.
- **Detection Table** (`REFERENCE.md`) — add a `Python (uv)` row: marker files
  `uv.lock`, or `pyproject.toml` with `[tool.uv]`; "Manager selected by" = `—`.
- **Python manager precedence note** (`REFERENCE.md`) — new paragraph immediately after the
  "check one level of subdirectories" paragraph under the Detection Table. States: if
  `uv.lock` is present, use the uv flow for that directory and skip the other Python flows
  there, even when `pyproject.toml` also has `[tool.poetry]` or `[tool.pdm]`; with no
  `uv.lock`, fall back in this order: `[tool.poetry]` → `[tool.pdm]` → `[tool.uv]` →
  `Pipfile` → `requirements.txt`. This makes the previously-implicit ordering explicit as a
  side benefit.
- **`uv` command subsection** (`REFERENCE.md` `## Python`) — placed **first**, before the
  Poetry entry, mirroring the Detection Table row order. Command sequence:
  `uv lock --upgrade` → `uv sync` → `uv tree --outdated` (with a concrete fallback: if
  `uv tree --outdated` exits non-zero on an older uv without the flag, use
  `uv pip list --outdated`). Prose mirrors the Poetry entry: `uv lock --upgrade` moves each
  dependency that isn't held at an exact version to the newest version the `pyproject.toml`
  constraints allow and rewrites `uv.lock`; `uv sync` reconciles the environment; with
  normal constraints this is patch/minor only; anything `uv tree --outdated` still shows
  behind is constraint-bound (a direct `pyproject.toml` constraint or a transitive
  requirement) — report as a major bump candidate, don't widen a `pyproject.toml`
  constraint to chase it. Adds one skill-specific line: if `uv lock --upgrade` or `uv sync`
  fails (resolution conflict, no network, unsatisfiable constraint), record it in the report
  and carry on — do not revert or block the commit (consistent with the skill's best-effort,
  non-blocking posture).
- **Validation Commands table** (`REFERENCE.md`) — the Python row gains a parenthetical:
  `pytest` (for a uv project, `uv run pytest`) if a `tests/` dir or a `pytest` dependency is
  present, else skip.
- **SKILL.md Step 3** — the Python bullet becomes "uv, Poetry, PDM, Pipenv, or pip, selected
  by marker file."
- **SKILL.md Step 6** — the staging-example parenthetical gains `uv.lock` alongside
  `poetry.lock`.
- **`.agent-docs/context.md`** — the **Ecosystem** entry's marker examples gain
  "`uv.lock` → uv", inserted after the existing `pyproject.toml` → Poetry example. Only the
  unambiguous `uv.lock` marker is listed in the glossary; the `[tool.uv]`-without-lockfile
  case is left to the precedence note in REFERENCE.md, which is the canonical place for
  resolution order. Done inline during the grill session.
- No change to any step's control flow beyond naming uv as a detected manager. The existing
  Step 3 rule "if a required package manager binary isn't installed for a detected
  ecosystem, report and skip" already covers a missing `uv` on `PATH` with no new text.

## Testing Decisions

- No executable code changes, so no unit tests and no BDD red-green loop — the BDD step for
  this slice is the edit plus `pre-commit-check` plus commit.
- Verification seams:
  1. `pre-commit run --all-files` passes (markdown formatting / repo linters).
  2. Read-through: the Detection row, precedence note, and `uv` subsection are internally
     consistent with the existing table order and copy-pasteable.
  3. `code-review` Spec axis confirms the change matches this spec.
- Prior art: `chore/gh-jq-arg-pitfall-doc` and `chore/python-c-windows-note` are recent
  documentation-only slices verified the same way.

## Out of Scope

- uv as a pre-commit hook language accelerator — Step 4 stays `pre-commit autoupdate` as-is.
- `uv tool` / `uv self` upgrades (globally installed uv tools or uv itself).
- Installing uv when it is absent — the existing report-and-skip rule covers it.
- `uv pip compile` of a `requirements.in` — the pip-tools entry stays the documented path.
- Special handling of dependency groups / extras — `uv lock --upgrade` covers all groups by
  default.
- Any behavioural change to the Poetry / PDM / Pipenv / pip flows.

## Further Notes

- uv subsection ordering (first, before Poetry) and the precedence note's full-ordering form
  were both explicitly chosen during the grill session over the narrower alternatives.
- A stale local branch `chore/update-dependencies-uv-support` exists from an earlier aborted
  attempt (unpushed, no commits beyond `origin/main`); it is checked out in the main
  worktree and should be deleted there once this work lands.
