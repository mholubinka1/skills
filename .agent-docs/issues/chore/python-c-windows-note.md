# Issues: chore/python-c-windows-note

## Document Windows python -c Bash-tool gotcha

**GitHub**: #54

**Blocked by**: None

**User stories**: 1, 2

### What to build

Add a new `## 7. Environment Notes` section to the end of both
`init-agent-docs/AGENT-TEMPLATE.md` and `.agent-docs/agent.md` (identically), with one bullet
scoped explicitly to Windows + Bash-tool-style shells, warning that a multi-line
`python -c "<script>"` can silently produce no output, and recommending writing the script to
a scratch file and running it directly instead.

### Acceptance criteria

- [ ] `init-agent-docs/AGENT-TEMPLATE.md` has a new `## 7. Environment Notes` section covering
      this gotcha.
- [ ] `.agent-docs/agent.md` has the identical section in the identical location.
- [ ] Both files remain byte-identical after the change.
- [ ] The note is explicitly scoped to Windows + Bash-tool-style shells, not stated as a
      universal rule.
- [ ] No existing section's wording changes in either file.
- [ ] `pre-commit-check` passes on both files.

---
