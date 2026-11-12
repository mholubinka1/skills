# design records glossary terms in .agent-docs/context.md

## Problem Statement

Audit finding DES-1 (#143; GitHub issue #154): the `design` skill records domain terms in a
`CONTEXT.md` at the repo root, following its own copy of `CONTEXT-FORMAT.md`. No other skill
reads that file. `write-spec`, `create-issues` and `init-agent-docs` all use the glossary at
`.agent-docs/context.md`, so terms settled during a design session never reach the spec or
the issues, and a second, competing glossary appears in the repo.

## Solution

`design` writes terms to `.agent-docs/context.md`, in the format `init-agent-docs` already
documents. `design`'s own copy of the format file is deleted.

## User Stories

1. As a user finishing a design session, I want new terms recorded in
   `.agent-docs/context.md`, so that `write-spec` and `create-issues` use them.
2. As a maintainer, I want one glossary file and one format file, so that the two cannot
   drift apart.

## Implementation Decisions

- **`design` SKILL, "Update domain docs inline"**: the glossary bullet names
  `.agent-docs/context.md`, links the format file in the `init-agent-docs` skill, says to
  create the glossary in that format when it is missing, and rules out a root `CONTEXT.md`.
- **`design`'s `CONTEXT-FORMAT.md` is deleted.** The `init-agent-docs` copy has the same
  Structure and Rules sections. The deleted copy's extra section, on a root `CONTEXT.md`
  and a `CONTEXT-MAP.md` for multi-context repos, described files no skill reads.
- **Description**: says "glossary terms" instead of "CONTEXT.md terms".
- **`allowed-tools`**: `Edit(CONTEXT.md)` and `Write(CONTEXT.md)` are removed;
  `.agent-docs/**` already covers the glossary.

## Testing Decisions

- Prose change to a skill definition; there is no executable behaviour to test red-green.
- The frontmatter guard tests and the Markdown link check must pass.

## Out of Scope

- Migrating a root `CONTEXT.md` that an earlier design session may have left in some repo.
- Multi-context glossaries.
- The `init-agent-docs` format file's own wording.

## Further Notes

Closes #154.
