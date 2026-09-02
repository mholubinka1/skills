# New worktrees bootstrap dependencies via fresh install, not by copying the main checkout's artifacts

`create-worktrees` creates an isolated git worktree so implementation work never touches the
main checkout — but a fresh worktree has none of the gitignored dependency artifacts
(`.venv`, `node_modules`, NuGet packages, etc.) that the main checkout accumulated over time,
so code that ran fine on `main` can fail to execute at all in the worktree. After creating a
worktree, `create-worktrees` detects the repo's dependency ecosystems (reusing
`update-dependencies`' detection, plus a courtesy list for ecosystems it doesn't cover) and,
on a prompt — default no, and skipped when there is no interactive user — runs each detected
ecosystem's lockfile-respecting install (`poetry install`, `npm ci`, `dotnet restore`,
`uv sync`, etc.) inside it, rather than copying or symlinking the equivalent artifacts from
the main checkout. The install is opt-in
because the common task edits only docs or skills and never runs the code, so an automatic
install would just add minutes and a network dependency to every worktree.

## Considered Options

- **Copy the existing artifacts from main** (e.g. `cp -r ../main/.venv .venv`). Rejected:
  Python virtualenvs in particular are not reliably relocatable — `pyvenv.cfg` and installed
  console-script shebangs can embed the original absolute path, so a copied `.venv` can
  silently break in ways that are hard to diagnose. It also does nothing when main's own
  environment was never set up in the first place, and produces no build/lockfile guarantees
  a real install would.
- **Symlink the artifacts instead of copying.** Rejected for the same relocatability risk as
  copying, plus a new one: a symlinked `node_modules`/`.venv` is a single physical directory
  shared across every worktree that points at it, so one worktree's `npm install` or `pip
  install` would silently mutate what every other worktree sees mid-task.
- **Fresh install per worktree (chosen).** Slower than copying, but it's exactly what a human
  cloning the repo fresh (or a CI runner) would do, so it reproduces the locked dependency
  set the repo declares rather than an ad-hoc copy of `main`'s possibly-drifted artifacts.
  Lockfile-respecting variants (`npm ci`, `poetry install`, `dotnet restore`) install the
  exact locked versions rather than silently drifting to newer ones.
