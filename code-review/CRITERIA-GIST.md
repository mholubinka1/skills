# Criteria Gist

The single GitHub gist that stages newly discovered review criteria across every repo and
machine, before a human collates the durable ones into [REVIEW-CRITERIA.md](REVIEW-CRITERIA.md)
by hand. It's created as a *secret* gist (unlisted, not indexed or discoverable via search) —
but its ID is committed below in this public repo, which already makes it readable by anyone
who reads this file, so treat "secret" here as "not casually stumbled on," not as an actual
confidentiality boundary. **Never record anything sensitive in it** — only generalised,
non-identifying review criteria belong here, the same bar `REVIEW-CRITERIA.md` already holds
its own entries to.

- **Gist ID**: `12aa6da56817811e0f101d6c3cbf1d7f`
- **URL**: <https://gist.github.com/mholubinka1/12aa6da56817811e0f101d6c3cbf1d7f>
- **File**: `CRITERIA.md`

`address-copilot-comments` reads the gist ID from here to append newly discovered criteria
(`gh gist edit`). `code-review` Step 4 reads the gist ID from here to fetch the current
staged criteria live (`gh gist view`) alongside `REVIEW-CRITERIA.md`, and also appends —
once per repo — when it migrates a legacy `.agent-docs/review.md` into the gist. Neither
skill needs any other per-machine configuration to find it.

## Appending an entry

Whenever either skill above appends, it does so the same way — `gh gist edit` replaces a
file's content wholesale, so there is no partial-append:

1. Fetch the gist's current content: `gh gist view <gist-id> -f CRITERIA.md --raw`.
2. Append the new entry (or entries) to the end of its `## Criteria` list — the file always
   has one, per its own header.
3. Write that merged content to a local scratch file (e.g. via `mktemp`); `gh gist edit`
   reads its replacement content from a file path, not from inline text.
4. Write it back: `gh gist edit <gist-id> --filename CRITERIA.md <path-to-the-scratch-file>`.
5. Delete the scratch file — whether step 4 succeeded or failed. Nothing about it needs to
   survive past this procedure, successful or not.
