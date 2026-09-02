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
  - Detect ecosystems using `update-dependencies`' Detection Table markers (repo root + one
    subdirectory level) — cross-reference that table, don't restate its marker list.
  - No ecosystem detected → silent no-op.
  - ≥1 detected → print the ecosystems + exact install command(s), then one `y`/`n` prompt
    ("Install dependencies in this worktree now?"). `y` → run every detected ecosystem's
    install, pass/fail recorded per ecosystem. `n` → leave the commands as a hint, continue.
  - No TTY / non-interactive → behave as `n`; never read stdin.
  - Any install failure (tool absent, offline, bad lock, compile error) → one-line reason
    (failing command + first error line), non-fatal, worktree still created.
  - Unknown ecosystem: if a courtesy-list marker is present (Go `go.mod`, Rust `Cargo.toml`,
    Ruby `Gemfile`) attempt its conventional install, non-fatal; then — success or failure —
    print `ACTION NEEDED: add <ecosystem> as a first-class entry in
    create-worktrees/REFERENCE.md` and use `AskUserQuestion` to force acknowledgement before
    continuing. A marker matching nothing at all: same ACTION-NEEDED + ack, no install.
- **`create-worktrees/REFERENCE.md`** — new **"Dependency bootstrap (Step 5)"** section:
  lead-in stating detection is per `update-dependencies`' Detection Table; the
  lockfile-respecting install-command table (`uv sync`, `poetry install`, `pdm install`,
  `pipenv sync`, `python -m venv .venv` + `.venv/<bin>/pip install -r requirements.txt`,
  `dotnet restore`, `npm ci`, `yarn install --frozen-lockfile`,
  `pnpm install --frozen-lockfile`); the courtesy list (`go mod download`, `cargo fetch`,
  `bundle install`); a note that the plain-pip row picks `python` via the probe-by-running
  idiom from `.pre-commit-config.yaml`'s sync-claude-skills hook.
- **`create-worktrees` frontmatter `description`** — add a clause: after creating a worktree
  it optionally bootstraps detected dependency ecosystems on a prompt.
- **`.agent-docs/adr/0005-worktree-bootstrap-reinstalls-rather-than-copies-dependencies.md`**
  — commit the (previously untracked) draft, with the mechanism sentence reworded so it no
  longer claims automatic install on *every* worktree: "after creating a worktree,
  `create-worktrees` detects ecosystems and, on a `y`/`n` prompt (default no, skipped with
  no TTY), runs each detected ecosystem's lockfile-respecting install inside it." Keep the
  "Considered Options" section unchanged. No `Status` frontmatter.
- **`.agent-docs/context.md`** — glossary entry "Worktree dependency bootstrap" (done inline
  during the grill; this issue carries it through).

No change to Steps 1–4, the `wip/` placeholder flow, or `.claude` gitignore handling.

### Acceptance criteria

- [ ] `create-worktrees/SKILL.md` has a Step 5 that runs only after a fresh worktree is
      created (not on already-isolated or resume).
- [ ] Step 5 detects ecosystems via `update-dependencies`' Detection Table markers, root +
      one subdir level, and cross-references that table rather than restating the markers.
- [ ] No ecosystem → Step 5 is a silent no-op.
- [ ] ≥1 ecosystem → a single `y`/`n` prompt after showing the install command(s); `y` runs
      all detected installs, `n` prints them as a hint.
- [ ] No TTY → defaults to `n`, no stdin read.
- [ ] Install failure is one-line, non-fatal, worktree still created; `/implement` continues.
- [ ] Unknown ecosystem → best-effort courtesy install (non-fatal) + `ACTION NEEDED` print +
      `AskUserQuestion` acknowledgement gate before continuing.
- [ ] `create-worktrees/REFERENCE.md` has the "Dependency bootstrap (Step 5)" section with
      the install-command table and courtesy list; detection is cross-referenced to
      `update-dependencies`, not duplicated.
- [ ] `create-worktrees` frontmatter `description` mentions the optional bootstrap.
- [ ] ADR 0005 is committed, body reworded to prompted/opt-in wording, no `Status` field,
      "Considered Options" unchanged.
- [ ] `.agent-docs/context.md` has the "Worktree dependency bootstrap" glossary entry.
- [ ] `pre-commit run --all-files` passes (markdownlint included).
- [ ] Steps 1–4 of `create-worktrees` are unchanged.

---
