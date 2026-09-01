# Issues: chore/uv-support-update-dependencies

## Add uv as a recognised Python manager in update-dependencies (#73)

**Blocked by**: None

**User stories**: 1, 2, 3, 4, 5, 6

### What to build

Add `uv` as a first-class Python manager alongside Poetry, PDM, Pipenv, and pip in the
`update-dependencies` skill:

- A `Python (uv)` row in the REFERENCE.md Detection Table (marker: `uv.lock`, or
  `pyproject.toml` with `[tool.uv]`).
- A precedence note directly under the Detection Table spelling out the full Python manager
  fallback order, with `uv.lock` taking priority over any other tool table in
  `pyproject.toml`.
- A `uv` command subsection in REFERENCE.md's `## Python` section, placed first (before
  Poetry): `uv lock --upgrade` → `uv sync` → `uv tree --outdated` (noting the
  `uv pip list --outdated` fallback), with prose mirroring the Poetry entry's
  constraint-bound-bump / report-majors framing, plus a line on non-blocking `uv sync`
  failure handling.
- A `uv run pytest` note added to the Validation Commands table's Python row.
- SKILL.md Step 3's Python bullet updated to list uv; Step 6's staging example list updated
  to include `uv.lock`.
- `.agent-docs/context.md` Ecosystem entry updated to mention uv markers (already done
  inline during the grill session — this issue just needs to carry that edit through).

No control-flow change to any existing step; no change to the Poetry/PDM/Pipenv/pip flows.

### Acceptance criteria

- [ ] Detection Table has a `Python (uv)` row with the correct marker files.
- [ ] Precedence note states uv.lock wins, and gives the full fallback order
      (poetry → pdm → tool.uv → Pipfile → requirements.txt).
- [ ] `uv` command subsection appears first in `## Python`, before Poetry, with the
      `uv lock --upgrade` / `uv sync` / `uv tree --outdated` sequence and the `uv sync`
      failure-handling line.
- [ ] Validation Commands table's Python row mentions `uv run pytest`.
- [ ] SKILL.md Step 3 Python bullet and Step 6 staging example list both mention uv/`uv.lock`.
- [ ] `.agent-docs/context.md` Ecosystem entry mentions uv markers.
- [ ] `pre-commit run --all-files` passes on the changed files.
- [ ] No wording or command changes to the existing Poetry/PDM/Pipenv/pip/.NET/Node
      sections.

---
