# Create Worktrees — Reference

## Slugify rule (Step 4)

Turn the trigger message into a short kebab-case fragment:

1. Take the first ~5 meaningful words (skip filler like "please", "can you", "I want to").
2. Lowercase, strip punctuation, join with hyphens.
3. Truncate to roughly 40 characters, cutting on a word boundary.

### Examples

| Trigger message | Slug |
|---|---|
| "Fix the flaky login test on CI" | `fix-flaky-login-test-ci` |
| "Can you add caching to the search endpoint?" | `add-caching-search-endpoint` |
| "The dependency update skill needs to also update pre-commit hooks" | `dependency-update-precommit-hooks` |

Exact wording doesn't matter — the slug only has to be recognisable enough to identify the worktree in `git worktree list` before `branch-hygiene` renames it later. Don't spend time optimising it.

## Why `.claude` and not `.claude/worktrees/`

`.claude/` is gitignored wholesale, matching this skills repo's own `.gitignore` convention — it also covers `settings.local.json` and other local-only state under `.claude/`, not just worktree directories.
