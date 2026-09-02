# Issues: feature/create-worktrees-dependency-bootstrap

## Add an optional dependency-bootstrap step to create-worktrees (#77)

**Blocked by**: None

**User stories**: 1, 2, 3, 4, 5, 6, 7

### What to build

Give `create-worktrees` an optional final step that offers to install a repo's
dependencies inside a freshly created worktree, so code that runs on `main` also runs
there — without copying or symlinking `.venv` / `node_modules` from the main checkout.

- **`create-worktrees/SKILL.md`** — new **Step 5, "Bootstrap dependencies (optional)"**,
  after Step 4:
  - Runs only on the fresh-creation path. Step 1 (already isolated) and Step 2 (resume) still
    stop before it.
  - Detect ecosystems using `update-dependencies`' Detection Table markers and its scan scope
    (repo root, plus one subdirectory level for a monorepo) — cross-reference that table,
    don't restate its marker list — **and also** note any dependency manifest the table
    doesn't cover.
  - Nothing detected → silent no-op.
  - ≥1 first-class ecosystem → print the ecosystems + exact install command(s), then an
    `AskUserQuestion` *Install* / *Skip* prompt ("Install dependencies in this worktree
    now?"). *Install* → run every detected ecosystem's install, pass/fail per ecosystem.
    *Skip* → leave the commands as a hint, continue. No interactive user, or any answer that
    is not a clear *Install* → *Skip*; never read stdin.
  - Any install failure (tool absent, offline, bad lock, venv creation unavailable, compile
    error) → one-line reason (failing command + first error line), non-fatal, worktree still
    created.
  - Uncovered ecosystem(s): if a courtesy-list marker is present (Go `go.mod`, Rust
    `Cargo.toml`, Ruby `Gemfile`) attempt its conventional install, non-fatal; other uncovered
    markers get no install. Then, once, covering every uncovered ecosystem found, print
    `ACTION NEEDED: add <ecosystem>[, …] as a first-class entry in
    create-worktrees/REFERENCE.md` and use `AskUserQuestion` a single time to force
    acknowledgement before continuing — or, with no interactive user, print the line and
    continue.
- **`create-worktrees/REFERENCE.md`** — new **"Dependency bootstrap (Step 5)"** section:
  a Detection lead-in (first-class = `update-dependencies`' Detection Table; framed as the
  lockfile-respecting *install*, not its *upgrade* flow; uncovered manifests → courtesy list
  installs the recognised ones, others get no install + `ACTION NEEDED`); the install-command
  table, ecosystem name only (`uv sync`, `poetry install`, `pdm install`, `pipenv sync`, pip
  = venv + pip note, `dotnet restore`, `npm ci`, yarn = `--immutable` (Yarn 2+) or
  `--frozen-lockfile` (Yarn 1) picked by `yarn --version`, `pnpm install --frozen-lockfile`);
  a pip note (pick `py` by probing `python3` then `python` with `"$py" -c ""`, not
  `command -v` — same idiom as `.pre-commit-config.yaml`'s sync-claude-skills hook; block
  uses `"$py" -m venv .venv`; if that fails, report and skip); the courtesy list
  (`go mod download`, `cargo fetch`, `bundle install`).
- **`create-worktrees` frontmatter `description`** — add a clause: after creating a worktree
  it optionally bootstraps detected dependency ecosystems on a prompt.
- **`.agent-docs/adr/0005-worktree-bootstrap-reinstalls-rather-than-copies-dependencies.md`**
  — commit the (previously untracked) draft, with the mechanism sentence reworded so it no
  longer claims automatic install on *every* worktree: "after creating a worktree,
  `create-worktrees` detects the repo's dependency ecosystems (reusing `update-dependencies`'
  detection, plus a courtesy list) and, on a prompt — default no, and skipped when there is
  no interactive user — runs each detected ecosystem's lockfile-respecting install inside
  it." The "Considered Options" section is kept, with only the chosen-option overclaim
  ("the only option that reliably reproduces …") softened. No `Status` frontmatter.
- **`.agent-docs/context.md`** — glossary entry "Worktree dependency bootstrap" (done inline
  during the grill; this issue carries it through).

No change to Steps 1–4, the `wip/` placeholder flow, or `.claude` gitignore handling.

### Acceptance criteria

- [ ] `create-worktrees/SKILL.md` has a Step 5 that runs only after a fresh worktree is
      created (not on already-isolated or resume).
- [ ] Step 5 detects first-class ecosystems via `update-dependencies`' Detection Table
      markers **and its scan scope** (repo root, plus one subdir level *for a monorepo* —
      carry that qualifier, don't broaden it), cross-referenced not restated, **and** also
      notes any dependency manifest the table doesn't cover, so the uncovered-ecosystem
      branch has an input.
- [ ] A lead-in note makes both prompts `AskUserQuestion` and gives the non-interactive
      default without a stdin read: *Skip* the install question, and print the `ACTION NEEDED`
      line then continue (nothing to gate on) — so Step 5.4 inherits the same handling as 5.3.
- [ ] The pip-note copy-paste block uses `"$py" -m venv .venv` (matching its own probe
      prose), not a hardcoded `python`.
- [ ] Nothing detected → Step 5 is a silent no-op.
- [ ] ≥1 first-class ecosystem → an `AskUserQuestion` *Install* / *Skip* prompt after showing
      the install command(s); *Install* runs all detected installs, *Skip* prints them as a
      hint.
- [ ] No interactive user (`AskUserQuestion` unavailable) → take *Skip*; never read stdin or
      block for input. Any answer that isn't a clear *Install* → *Skip*.
- [ ] Install failure is one-line, non-fatal, worktree still created; `/implement` continues.
- [ ] Uncovered ecosystem(s) → best-effort courtesy install for `go.mod`/`Cargo.toml`/
      `Gemfile` (non-fatal), nothing for others, then a single `ACTION NEEDED` print covering
      all of them + one `AskUserQuestion` acknowledgement (with no interactive user: print
      and continue).
- [ ] `create-worktrees/REFERENCE.md` has the "Dependency bootstrap (Step 5)" section with
      the install-command table (ecosystem name only, no marker parentheticals), the pip
      note, and the courtesy list; detection is cross-referenced to `update-dependencies`.
- [ ] The yarn row gives both `--immutable` (Yarn 2+) and `--frozen-lockfile` (Yarn 1) and
      says to pick by `yarn --version`.
- [ ] `create-worktrees` frontmatter `description` mentions the optional bootstrap.
- [ ] ADR 0005 is committed, body reworded to prompted/opt-in wording (plus courtesy list),
      no `Status` field; "Considered Options" kept with only the chosen-option overclaim
      softened.
- [ ] `.agent-docs/context.md` has the "Worktree dependency bootstrap" glossary entry.
- [ ] `pre-commit run --all-files` passes (markdownlint included).
- [ ] Steps 1–4 of `create-worktrees` are unchanged.

---
