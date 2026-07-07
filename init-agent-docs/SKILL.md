---
name: init-agent-docs
description: Bootstraps AI agent documentation in the current repository — migrates any legacy agent-docs/ layout to .agent-docs/, creates .agent-docs/agent.md with default behavioural standards, bootstraps .agent-docs/context.md as a domain glossary, migrates existing ADR files from docs/ to .agent-docs/adr/, and ensures CLAUDE.md references .agent-docs/agent.md. Idempotent — reports what was created, migrated, or skipped on each run. Use at the start of any implementation workflow to ensure agent standards are in place before work begins.
---

# init-agent-docs

Bootstraps `.agent-docs/agent.md`, `.agent-docs/context.md`, and a `CLAUDE.md` reference in
the current repository. Safe to run more than once — skips any step where the output already
exists.

> **Assumption**: this skill must be invoked from the repository root. It writes paths
> relative to the current working directory.

See [REFERENCE.md](REFERENCE.md) for the full per-step detail.

## Steps

1. **Migrate existing agent-docs/ layout** — if the legacy `agent-docs/` directory exists, move `agent.md`, `context.md`, and `adr/` to `.agent-docs/`; warn about any unrecognised items.
2. **Check for existing agent.md** — if `.agent-docs/agent.md` already exists, skip to Step 4.
3. **Create agent.md** — write `AGENT-TEMPLATE.md` verbatim to `.agent-docs/agent.md`.
4. **Check for existing context.md** — if `.agent-docs/context.md` already exists, skip to Step 7.
5. **Search for context.md to move** — look in the repo root and `docs/`; move it if exactly one is found; report ambiguity if multiple found.
6. **Create context.md from template** — if no existing `context.md` was found, write `CONTEXT-TEMPLATE.md` verbatim to `.agent-docs/context.md`.
7. **Migrate ADR files** — search `docs/`, `docs/adr/`, `agent-docs/docs/adr/`, and `.agent-docs/docs/adr/` for ADR files matching `[0-9]*-*.md`; move them to `.agent-docs/adr/`, resolving conflicts by git date.
8. **Check CLAUDE.md** — if `CLAUDE.md` already references `.agent-docs/agent.md`, skip to Step 10; if it references the old path, update it.
9. **Create or append CLAUDE.md** — append the Agent Standards reference block to `CLAUDE.md` (create if missing).
10. **Summary** — report every action taken and every step skipped with a reason.
