# Issues: bugfix/pre-commit-check-autofix-detection

> Work complete — PR ready to merge.

## pre-commit-check: audit follow-ups (PCC-1)

**GitHub issue**: #146

**Blocked by**: None

**User stories**: 1, 2

### What to build

`pre-commit-check` finds autofixed files by comparing a content-hash snapshot of the dirty
files before and after each pass, instead of comparing file names.

### Acceptance criteria

- [x] Given a file already modified before a pass, when a hook rewrites it, then it is in
      the autofixed set because its hash changed.
- [x] Given a clean file, when a hook rewrites it, then it is in the autofixed set because
      it is new to the after-snapshot.
- [x] Given a modified file that no hook touches, when the pass ends, then it is not in the
      autofixed set.
- [x] Given the new snapshot commands, when the skill runs them, then `allowed-tools`
      scopes `git hash-object`, and the `unittest` suite passes.

---
