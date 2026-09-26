# Collate Review Criteria

Prompt for collating the review criteria staged in the Criteria gist into
`code-review/REVIEW-CRITERIA.md`. Run it from this repo's root, on an up-to-date `main`.

Collating means every gist entry ends in exactly one of four outcomes: **covered** by an
existing criterion as written, **widened** into an existing criterion, a **new** criterion, or
**dropped** with a stated reason. Every gist entry is accounted for; nothing is copied
verbatim.

## Sources

- [code-review/CRITERIA-GIST.md](code-review/CRITERIA-GIST.md) — the gist ID and the
  fetch/write commands.
- [code-review/REVIEW-CRITERIA.md](code-review/REVIEW-CRITERIA.md) — the durable criteria and
  their sections.
- [code-review/CRITERIA-STYLE.md](code-review/CRITERIA-STYLE.md) — the rules every new or
  widened criterion follows.

## Steps

### 1. Read

Fetch the gist's `CRITERIA.md` and read every entry under `## Criteria`. Read
`REVIEW-CRITERIA.md` and `CRITERIA-STYLE.md` in full. Record the exact label of every gist
entry you read — step 5 removes only these.

Done when you hold the full text of all three and the list of gist labels.

### 2. Map

Give each gist entry one outcome:

- **Covered** — an existing criterion already names the same defect. No edit.
- **Widened** — an existing criterion names the same defect in a narrower case, and one added
  word or clause covers the gist case while the line stays within the style rules.
- **New** — a distinct defect. Group gist entries into one new criterion only when they are
  the same defect; different defects stay separate, however related.
- **Dropped** — tooling already enforces it, or it is not durable. State the reason.

Done when every gist label maps to exactly one outcome.

### 3. Draft

Write each new criterion, and the full replacement text of each widened one, to the style
rules — generic, with the `(repo#PR)` tag removed. Place each new criterion in the section
that fits it. When a widening changes a label, find every other reference to the old label in
the repo.

Check every drafted line with a script: 30–60 words including the label, and a label of 3–8
words. Revise any line outside the bounds until all pass.

Done when every drafted line passes the script.

### 4. Review with the user

Present the full proposal: new criteria by section, widened criteria as full replacement
text, covered and dropped entries with one line each on why. Refine it with the user until
they approve.

Done when the user approves the list.

### 5. Apply

1. Create a branch from `main`.
2. In `REVIEW-CRITERIA.md`, append each new criterion to the end of its section's list and
   replace each widened criterion in place. Update every reference to a renamed label.
3. Run pre-commit on the changed files until it passes.
4. Commit, push, and open a PR listing the new, widened, covered and dropped outcomes.
5. After the user confirms the PR is merged, remove the collated entries from the gist:
   - Fetch the gist again immediately before writing.
   - Parse the whole `## Criteria` section. Labels can wrap across lines, so join each
     entry's lines before matching. If any line is neither part of an entry nor blank, stop
     and leave the gist untouched.
   - Remove exactly the labels recorded in step 1. Keep every other entry — it arrived after
     you read the gist.
   - Write through a `mktemp` file, check the write command's exit code, and delete the
     scratch file on every exit path.
   - Fetch the gist once more and confirm the collated labels are gone and the kept entries
     remain.

Done when the PR is merged and the gist holds only entries not yet collated.
