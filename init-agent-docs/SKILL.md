---
name: init-agent-docs
description: Bootstraps AI-agent documentation in the current repository — .agent-docs/ layout, agent.md, context.md, ADR migration, and a CLAUDE.md reference — idempotently. Use at the start of an implementation workflow to ensure agent standards are in place before work begins.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(git log -1 *)
context: fork
agent: general-purpose
model: haiku
effort: low
background: false
---

# init-agent-docs

Bootstraps `.agent-docs/agent.md`, `.agent-docs/context.md`, and a `CLAUDE.md` reference in
the current repository. When `.agent-docs/context.md` is present or moved into place, reviews
it against the format rules and improves it only where needed.

> **Assumption**: this skill must be invoked from the repository root. It writes paths
> relative to the current working directory.

See [REFERENCE.md](REFERENCE.md) for the full per-step detail.

## Steps

1. **Migrate existing agent-docs/ layout** — if the legacy `agent-docs/` directory exists, move `agent.md`, `context.md`, and `adr/` to `.agent-docs/`; warn about any unrecognised items.
2. **Create agent.md** — unless `.agent-docs/agent.md` already exists (then skip), write `AGENT-TEMPLATE.md` verbatim to it.
3. **Bootstrap or review context.md** — if `.agent-docs/context.md` exists, review it against `CONTEXT-FORMAT.md`; otherwise move the single `context.md` found in the repo root or `docs/` and review it, or, when none is found, generate a domain glossary from the codebase; report multiple candidates as ambiguous and go to Step 4.
4. **Migrate ADR files** — search `docs/`, `docs/adr/`, `agent-docs/docs/adr/`, and `.agent-docs/docs/adr/` for ADR files matching `[0-9]*-*.md`; move them to `.agent-docs/adr/`, resolving conflicts by git date.
5. **Create or append CLAUDE.md** — unless `CLAUDE.md` already references `.agent-docs/agent.md` (then skip; update the path if it references the old one), append the Agent Standards reference block to `CLAUDE.md` (create if missing).
6. **Summary** — report every action taken and every step skipped with a reason, ending with one line, `Skipped / risk:`, naming anything the caller must resolve.
