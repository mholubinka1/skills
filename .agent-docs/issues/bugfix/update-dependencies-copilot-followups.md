# Issues: bugfix/update-dependencies-copilot-followups

## update-dependencies: Copilot review follow-ups from PR #163

**GitHub**: none — follow-up to the Copilot review on PR #163

**Blocked by**: None

**User stories**: 1, 2, 3

### What to build

Fix the three Copilot findings left on PR #163: make the stash lookup stop on an ambiguous
match, skip hash-checked pins in the plain-pip flow, and detect hook rewrites of files the
run already changed.

### Acceptance criteria

- [x] Given two stash entries ending with the run's message, when Step 1 looks up its SHA,
      then the run stops, leaves both entries in place and reports both SHAs.
- [x] Given a `requirements.txt` pin with `--hash` options, when the package has a patch or
      minor bump, then the pin is left unchanged and reported as skipped.
- [x] Given a hook that rewrites a manifest this run already changed, when the run reports,
      then the file is listed as a hook autofix and marked as committed.
- [x] Given a hook that rewrites or creates any other file, when the run commits, then that
      file stays unstaged and is listed as an uncommitted hook autofix.
- [x] `allowed-tools` matches the commands the skill runs, and the `unittest` suite passes.

---
