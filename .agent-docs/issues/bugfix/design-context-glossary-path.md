# Issues: bugfix/design-context-glossary-path

> Work complete — PR ready to merge.

## design: audit follow-ups (DES-1)

**GitHub issue**: #154

**Blocked by**: None

**User stories**: 1, 2

### What to build

`design` records domain terms in `.agent-docs/context.md`, using the format file in
`init-agent-docs`, and no longer carries its own copy of that format.

### Acceptance criteria

- [x] Given a design session that settles a new term, when the skill records it, then it
      writes to `.agent-docs/context.md` and not to a root `CONTEXT.md`.
- [x] Given a repo with no glossary yet, when the first term is resolved, then
      `.agent-docs/context.md` is created in the `init-agent-docs` format.
- [x] Given the `design` skill directory, when listed, then it holds no `CONTEXT-FORMAT.md`.
- [x] Given the `design` frontmatter, when read, then `allowed-tools` has no `CONTEXT.md`
      entry, and the `unittest` suite passes.

---
