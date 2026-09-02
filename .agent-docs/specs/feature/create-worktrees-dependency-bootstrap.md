# Optional dependency bootstrap for create-worktrees

## Problem Statement

`create-worktrees` creates an isolated git worktree so implementation work never touches the
main checkout. But a fresh worktree is a bare checkout: it has none of the gitignored
dependency artifacts (`.venv`, `node_modules`, NuGet caches, …) the main checkout built up
over time. Code that runs fine on `main` — a test suite, a CLI, a dev server — can fail to
execute at all in the worktree, and the person only discovers this partway through the task.

There is currently no step that closes that gap, and no ADR recording how it should be
closed (a draft, `0005-worktree-bootstrap-reinstalls-rather-than-copies-dependencies.md`,
exists but was never committed and describes behaviour that doesn't exist yet).

## Solution

Add an **optional** final step to `create-worktrees` that, right after a fresh worktree is
created, detects which dependency ecosystems the repo uses and offers — via a single `y`/`n`
prompt — to run each one's lockfile-respecting install inside the new worktree. The default
when there's no ecosystem, or no TTY, is to do nothing (or just print the commands as a
hint). Installs are best-effort: a failure is reported but never aborts worktree creation or
the `/implement` flow.

Because the common `/implement` task is a docs/skill/config edit that never executes the
target app, the step must not slow down or add network dependence to that path — hence the
prompt rather than an automatic install.

Commit ADR 0005 alongside, reworded to describe this prompted, non-automatic behaviour.

## User Stories

1. As someone starting work in a fresh worktree that I *will* run code in, I want to be
   offered a one-keystroke dependency install, so that the worktree behaves like `main`
   without me reconstructing the environment by hand.
2. As someone whose task is a docs/skill edit, I want the worktree created fast with no
   install running, so that `create-worktrees` (and `/implement` Step 0) stay quick.
3. As someone in a repo with no recognised ecosystem, I want the step to do nothing and stay
   silent, so that it never gets in the way.
4. As someone running `create-worktrees` non-interactively (piped, CI-like), I want it to
   never hang waiting for a `y`/`n`, so that automation doesn't stall.
5. As someone whose install fails (offline, missing tool, broken lockfile), I want a clear
   one-line reason and the worktree still created, so that I can do non-executing work now
   and fix the environment later.
6. As a maintainer, I want an unfamiliar ecosystem (Go, Rust, Ruby, or something newer) to
   still get a best-effort install and a loud, acknowledged prompt telling me to add it as a
   first-class entry, so that the gap is captured rather than silently skipped.
7. As a future reader of the codebase, I want an ADR that accurately says the bootstrap is
   opt-in and prompted, so that the "why not just copy `.venv`?" question is answered and
   nobody assumes it runs automatically.

## Implementation Decisions

- Files touched: `create-worktrees/SKILL.md`, `create-worktrees/REFERENCE.md`,
  `.agent-docs/adr/0005-worktree-bootstrap-reinstalls-rather-than-copies-dependencies.md`,
  `.agent-docs/context.md` (glossary entry — done inline during the grill).
- **`create-worktrees/SKILL.md` — new Step 5 "Bootstrap dependencies (optional)"**, placed
  after Step 4 (worktree creation). It runs **only** on the fresh-creation path: Step 1
  (already isolated) and Step 2 (resume an existing worktree) both still stop before it.
  - Detect ecosystems by `update-dependencies`' Detection Table markers and its scan scope
    (repo root, plus one subdirectory level for a monorepo — carry that "monorepo" qualifier,
    don't broaden it) — **and also** note any other dependency manifest present that the table
    doesn't cover (`go.mod`, `Cargo.toml`, `Gemfile`, or comparable), so the unknown-ecosystem
    branch actually has an input. Do **not** restate the Detection Table's marker list;
    cross-reference it.
  - A single lead-in note handles the non-interactive case for **both** prompts once: both go
    through `AskUserQuestion`; with no interactive user, take the non-blocking default without
    reading stdin — *Skip* for the install, acknowledge-and-continue for the `ACTION NEEDED`
    gate. Steps 5.3 and 5.4 then only reference it ("per the note above"), neither restates
    it.
  - **Nothing detected** → Step 5 is a silent no-op.
  - **≥1 first-class ecosystem detected** → print each and its exact install command(s), then
    ask via `AskUserQuestion`: *"Install dependencies in this worktree now?"* with options
    *Install* / *Skip* (no interactive user, or any answer that is not a clear *Install* →
    *Skip*, per the note).
    - **Skip** → leave the printed commands as a copy-paste hint; continue.
    - **Install** → run every detected ecosystem's install (table below), recording pass/fail
      per ecosystem.
  - Any install failure — tool not on `PATH`, no network, unsatisfiable lock, venv creation
    unavailable, compile error — is reported on one line (naming the failing command and
    first error line) and does **not** abort. The worktree is already created and usable.
  - **Uncovered ecosystem(s)**: for any marker from step 1 that is not a first-class
    Detection Table ecosystem — if it is on the built-in courtesy list (Go `go.mod`, Rust
    `Cargo.toml`, Ruby `Gemfile`), attempt its conventional install
    (`go mod download` / `cargo fetch` / `bundle install`), non-fatal; otherwise attempt
    nothing. Then, once, covering every uncovered ecosystem found, print
    `ACTION NEEDED: add <ecosystem>[, <ecosystem>…] as a first-class entry in create-worktrees/REFERENCE.md`
    and use `AskUserQuestion` a single time to make the user acknowledge it before the
    workflow continues.
- **`create-worktrees/REFERENCE.md` — new section "Dependency bootstrap (Step 5)"**:
  - A lead-in: first-class ecosystems are the ones in `update-dependencies`' Detection Table;
    a manifest the table doesn't cover is an *uncovered* ecosystem handled by the courtesy
    list.
  - Install-command table (lockfile-respecting, **install not upgrade**), ecosystem name only
    — no marker parentheticals, since detection is delegated to `update-dependencies`:

    | Ecosystem | Install command |
    |---|---|
    | Python — uv | `uv sync` |
    | Python — Poetry | `poetry install` |
    | Python — PDM | `pdm install` |
    | Python — Pipenv | `pipenv sync` |
    | Python — pip | create a venv, then install into it (pip note) |
    | .NET / C# | `dotnet restore` |
    | Node — npm | `npm ci` |
    | Node — yarn | `yarn install --immutable` (Yarn 2+) or `yarn install --frozen-lockfile` (Yarn 1) — pick by `yarn --version` |
    | Node — pnpm | `pnpm install --frozen-lockfile` |

  - A **courtesy list** for uncovered ecosystems, mirroring `update-dependencies`' "Unknown
    ecosystems" section: Go → `go mod download`, Rust → `cargo fetch`, Ruby → `bundle install`
    — best-effort, non-fatal, always followed by the ACTION-NEEDED prompt. An uncovered
    marker not on the list gets no install attempt.
  - A **pip note**: create `.venv` and install into it (never global site-packages); pick the
    interpreter (`py`) first by probing `python3` then `python` with
    `"$py" -c "" >/dev/null 2>&1` (not `command -v`; same reason as
    `.pre-commit-config.yaml`'s `sync-claude-skills` hook), and the copy-paste block itself
    uses `"$py" -m venv .venv` so it matches the prose; if `"$py" -m venv .venv` fails,
    report it and skip the pip install.
- **`create-worktrees` frontmatter `description`** gains a clause: after creating a worktree
  it optionally bootstraps detected dependency ecosystems on a prompt.
- **ADR 0005**: commit the draft with the body reworded so the mechanism sentence reads,
  in substance, "after creating a worktree, `create-worktrees` detects ecosystems (reusing
  `update-dependencies`' detection, plus a courtesy list) and, on a prompt (default no,
  skipped when there is no interactive user), runs each detected ecosystem's
  lockfile-respecting install inside it" — i.e. drop "we now run … inside *every*
  newly-created worktree". The "Considered Options" section is kept, with one accuracy fix:
  the chosen-option bullet's "the only option that reliably reproduces 'this worktree runs
  code exactly as the main checkout does'" overclaim is softened (an install reproduces the
  declared lockfile, not `main`'s possibly-drifted artifacts). No `Status` frontmatter
  (matches ADRs 0001–0004).

## Testing Decisions

- No executable code — skill prose (`SKILL.md`/`REFERENCE.md`) and an ADR. No test files;
  no shell test harness in this repo. Consistent with the `uv-support` and
  `sync-hook-interpreter-selection` slices this session.
- Verification:
  1. Read-through: Step 5's branch logic (fresh-only, no-ecosystem no-op, y/n, no-TTY→n,
     non-fatal, unknown-ecosystem path) is internally consistent and the REFERENCE.md table
     is copy-paste-correct.
  2. Dogfood the install commands: in this worktree (this skills repo → Python) run the
     detected ecosystem's install command by hand and confirm it works and that a forced
     failure (e.g. tool renamed off PATH) is caught, not fatal.
  3. The create-then-prompt flow itself can't be fully exercised in-session (we're already
     isolated; Step 1 no-ops), so it's covered by read-through + the next real `/implement`
     run.
  4. `pre-commit run --all-files` + markdownlint on the changed files.

## Out of Scope

- Bootstrapping on **resume** (Step 2) or when already isolated (Step 1).
- Copying or symlinking `.venv` / `node_modules` from the main checkout — rejected in ADR
  0005, not revisited.
- Installing or managing `pre-commit` hooks in the worktree (`.git/hooks` is shared;
  `bin/update-skills` territory).
- Per-directory / per-ecosystem prompting in a monorepo — one `y`/`n` covers all detected.
- Running the target's tests to *prove* "code runs" — Step 5 installs and reports; it does
  not verify.
- Retrofitting existing worktrees.
- Any caching / speed work beyond what the package managers do natively.
- Persisting the unknown-ecosystem note to a file — it is print + acknowledgement only.

## Further Notes

- The ADR draft was rescued from a deleted worktree during a cleanup earlier in the same
  session that produced this spec; it is carried into this branch as an untracked file and
  committed here for the first time.
- `update-dependencies` remains the single source of truth for ecosystem *detection*; this
  change adds only the *install* command mapping, which `update-dependencies` (an
  upgrade-oriented skill) does not have.
