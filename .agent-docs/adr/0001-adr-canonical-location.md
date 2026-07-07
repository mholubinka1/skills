# ADR canonical location is .agent-docs/adr/, not .agent-docs/docs/adr/

`design/ADR-FORMAT.md` previously specified `.agent-docs/docs/adr/` as the canonical ADR path, but `init-agent-docs` and the `design` skill consistently created and referenced `.agent-docs/adr/` directly. We decided that `.agent-docs/adr/` is the canonical location: the `docs/` nesting adds no value, the shorter path is easier to type and read, and it matches how `init-agent-docs` lazily creates the directory. `design/ADR-FORMAT.md` has been updated to reflect this.
