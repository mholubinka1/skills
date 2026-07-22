# Update Dependencies — Reference

Detection rules, per-ecosystem commands, and validation commands. Workflow steps are in [SKILL.md](SKILL.md).

## Detection Table

| Ecosystem | Marker file(s) | Manager selected by |
|---|---|---|
| Python (Poetry) | `pyproject.toml` with `[tool.poetry]` | — |
| Python (PDM) | `pyproject.toml` with `[tool.pdm]` | — |
| Python (Pipenv) | `Pipfile` | — |
| Python (pip) | `requirements.txt`, no `pyproject.toml`/`Pipfile` | `requirements.in` present → pip-tools flow |
| .NET / C# | `*.csproj` or `*.sln` | `dotnet` CLI (covers all cases) |
| Node / TS / React | `package.json` | lockfile: `package-lock.json` → npm, `yarn.lock` → yarn, `pnpm-lock.yaml` → pnpm |

Check the repo root first. For monorepos, also check one level of subdirectories (e.g. `packages/*`, `services/*`) and run each ecosystem's flow per matching directory.

## Python

**Poetry** (`pyproject.toml` has `[tool.poetry]`):

```bash
poetry update
poetry show --outdated   # anything still listed exceeds the pyproject.toml constraint — report as a major bump candidate
```

**PDM** (`pyproject.toml` has `[tool.pdm]`):

```bash
pdm update
pdm outdated
```

**Pipenv** (`Pipfile`):

```bash
pipenv update
pipenv update --outdated
```

**pip with pip-tools** (`requirements.in` present):

```bash
pip-compile --upgrade requirements.in
pip install -r requirements.txt
```

**Plain pip** (`requirements.txt` only, no `pyproject.toml`/`Pipfile`/`requirements.in`):

Plain pip has no built-in semver-aware "update within range" command. List outdated packages for visibility rather than blindly upgrading everything to latest:

```bash
pip list --outdated
```

For packages where only the patch/minor version changed, upgrade and re-pin explicitly:

```bash
pip install --upgrade "<package>==<new-version>"
pip freeze > requirements.txt
```

## .NET / C\#

```bash
dotnet list package --outdated
```

For each package where the latest version's major matches the current major, bump it explicitly:

```bash
dotnet add <project.csproj> package <PackageName> --version <latest-minor-or-patch>
```

Packages where the latest major differs from the current major are majors — report, don't apply.

If `dotnet-outdated-tool` is already installed (check with `dotnet tool list --global`), it can do this in one step:

```bash
dotnet outdated -u -vl Minor
```

## Node / TypeScript / React

Selected by lockfile present.

**npm** (`package-lock.json`):

```bash
npm outdated
npm update
```

`npm update` bumps within the semver ranges already declared in `package.json` (patch/minor only, given normal `^`/`~` ranges). Rows in `npm outdated` where `Latest` > `Wanted` are majors — report, don't apply.

**yarn** (`yarn.lock`):

```bash
yarn outdated
yarn upgrade
```

**pnpm** (`pnpm-lock.yaml`):

```bash
pnpm outdated
pnpm update
```

React itself is just an npm-style package — no special-casing beyond the above. If `react`/`react-dom` have a major available, call it out explicitly in the report: React majors commonly need peer-dependency and codemod follow-up beyond a simple version bump.

## Pre-commit hooks

```bash
pre-commit autoupdate
pre-commit run --all-files
```

Requires `.pre-commit-config.yaml` at the repo root.

## Validation commands (best-effort, non-blocking)

Run if detectable; record pass/fail only — never block or revert on failure.

| Ecosystem | Command |
|---|---|
| Python | `pytest` if a `tests/` dir or a `pytest` dependency is present, else skip |
| .NET | `dotnet build`, then `dotnet test` if a test project (e.g. `*.Tests.csproj`) exists |
| Node | `npm test` / `yarn test` / `pnpm test` if a `test` script exists in `package.json`; else `npm run build` / equivalent if a `build` script exists |

## Unknown ecosystems

If none of the marker files above are found, report that no known ecosystem was detected (list what was checked) and offer brief generic pointers rather than failing the run:

- Go: `go get -u ./... && go mod tidy`
- Rust: `cargo update`
- Ruby: `bundle update --patch`

These are not implemented as full flows — just a courtesy pointer.
