# Issues: chore/sed-rename-caution

> Work complete — PR ready to merge.

## Warn against unanchored sed renames in agent standards

**GitHub**: #52

**Blocked by**: None

**User stories**: 1, 2

### What to build

Add a bullet under "Production Code Quality" in both `init-agent-docs/AGENT-TEMPLATE.md` and
this repo's own `.agent-docs/agent.md` (identically), warning against unanchored `sed`/regex
find-replace for identifier renames and recommending word-boundary-anchored patterns or a
proper multi-file rename tool instead.

### Acceptance criteria

- [x] `init-agent-docs/AGENT-TEMPLATE.md` has a new bullet under Production Code Quality
      covering this warning.
- [x] `.agent-docs/agent.md` has the identical bullet in the identical location.
- [x] Both files remain byte-identical after the change.
- [x] No existing bullet's wording changes in either file.
- [x] `pre-commit-check` passes on both files.

---
