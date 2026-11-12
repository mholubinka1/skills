# Issues: bugfix/update-dependencies-audit-followups

## update-dependencies: audit follow-ups (UD-1, UD-2, UD-3, UD-4, UD-5, UD-6)

**GitHub**: #151

**Blocked by**: None

**User stories**: 1, 2, 3, 4, 5, 6, 7

### What to build

Fix the six audit findings in the `update-dependencies` skill: restore the stash by SHA and
only after the commit, edit `requirements.txt` pins in place, resolve the default branch
and date the branch name, report hook autofixes, and pick yarn commands by version. Keep
`allowed-tools` matching the commands run.

### Acceptance criteria

- [ ] Given another entry on top of the stash stack, when the skill restores its stash,
      then it applies its own entry by SHA and never runs `git stash pop` (UD-1).
- [ ] Given a dirty working tree, when the skill commits, then the stash is still set
      aside, and it is restored only after the commit (UD-3).
- [ ] Given a plain `requirements.txt`, when a package gets a patch or minor bump, then
      only that package's pin changes and `pip freeze` is never run (UD-2).
- [ ] Given a repo whose default branch is not `main`, when Step 1 runs, then the branch
      is resolved from `origin/HEAD`, and a new branch gets a dated name (UD-4).
- [ ] Given a hook that rewrites a file under `--all-files`, when the run reports, then the
      file is listed as an uncommitted hook autofix (UD-5).
- [ ] Given Yarn 3 or later, when the Node flow runs, then it uses `yarn up -R` and not
      `yarn outdated` / `yarn upgrade` (UD-6).
- [ ] `allowed-tools` matches the commands the skill runs, and the `unittest` suite passes.

---
