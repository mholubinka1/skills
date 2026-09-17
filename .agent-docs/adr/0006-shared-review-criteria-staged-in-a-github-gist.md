# Newly discovered review criteria are staged in a GitHub gist, not a git-tracked file

`address-copilot-comments` used to append newly discovered review criteria to each target
repo's own `.agent-docs/review.md`, so a criterion found while reviewing one repo never
reached any other repo without someone manually copying it into this skills repo's
`code-review/REVIEW-CRITERIA.md`. We want a criterion discovered on any repo, on any machine,
to be visible to every other repo's next `/code-review` run immediately — before that manual
collation ever happens. Criteria are now written to and read from a single GitHub gist via
live `gh gist edit`/`gh gist view` calls at the moment of discovery and the moment of review,
with `code-review/REVIEW-CRITERIA.md` remaining the durable baseline that a human collates
the gist's contents into by hand, deleting each entry from the gist as it's copied over.

## Considered Options

- **A git-tracked staging file in this skills repo** (e.g. `code-review/NEW-CRITERIA.md`).
  Rejected: this repo's `sync_claude_skills.py` post-commit hook `copytree`-overwrites
  `~/.claude/skills/<skill>/` from the git checkout on every commit, so any criterion
  appended to the *runtime* copy between commits would be silently wiped the next time
  anyone committed anything else in this repo. It also only syncs on `git commit`, not on
  `git pull`, so a second machine would not pick up a new criterion until it happened to
  commit something itself.
- **A runtime-only file at `~/.claude/skills/code-review/<file>`, never git-tracked.** Solves
  the sync-hook clobber (the hook can't overwrite a file absent from its source tree) and
  works for sharing across repos on one machine, but stays purely local — a criterion found
  on one machine is invisible to any other machine, which was a hard requirement.
- **A dedicated small GitHub repo, read/written via `gh api` rather than a local clone.**
  Would have worked equally well and gets real PR review on the staging file if ever wanted,
  but adds a second GitHub repo to create, name, and administer for no capability the gist
  doesn't already provide.
- **A cloud-synced folder (iCloud Drive / Dropbox).** Rejected: propagation depends on a
  sync client already configured identically on every machine, and isn't a live round-trip —
  a discovery on one machine could sit unsynced for an arbitrary time before another machine's
  client picks it up.
- **A single secret GitHub gist, read/written live via the `gh` CLI (chosen).** Every
  `address-copilot-comments` write and every `code-review` read hits the network directly, so
  there is no local-checkout staleness or sync-hook interaction to reason about, and it works
  identically across every machine `gh` is authenticated on. Gist revisions are a free audit
  trail. The gist's ID is committed into this repo (`code-review/CRITERIA-GIST.md`) so both
  skills can find it without per-machine configuration.

## Consequences

- `code-review` Step 4 treats the gist as best-effort: if it's unreachable (no network, `gh`
  not authenticated, gist deleted), it warns and continues with `REVIEW-CRITERIA.md` alone,
  the same soft-fail treatment Step 3 already gives a missing spec.
- `gh gist edit` replaces a gist file's content wholesale, so two near-simultaneous writes
  from different machines can clobber each other (last write wins, no merge). Accepted as a
  low-probability, low-stakes race for a single-user tool — revisit only if it's ever
  observed in practice.
- Entries are tagged `(repo#PR)` rather than the old bare `(PR #64)`, since the gist now pools
  criteria from every repo instead of just one.
