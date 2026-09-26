# Collate Review Criteria

Prompt for collating the review criteria staged in the Criteria gist into
`code-review/REVIEW-CRITERIA.md`. Run it from this repo's root, on an up-to-date `main`.

The aim is the **fewest criteria that still cover every gist entry**. Gist entries are raw
findings, one per fixed Copilot comment; a collated criterion summarises the defect they share,
so several entries often become one criterion or fold into one that already exists. Each
criterion is written fresh from that shared defect, in the voice of the style rules.

## Steps

### 1. Read

Read these in full:

- The gist's `CRITERIA.md` — its ID and fetch command are in
  [code-review/CRITERIA-GIST.md](code-review/CRITERIA-GIST.md).
- [code-review/REVIEW-CRITERIA.md](code-review/REVIEW-CRITERIA.md) — the existing criteria and
  their sections.
- [code-review/CRITERIA-STYLE.md](code-review/CRITERIA-STYLE.md) — the rules every new or
  widened criterion follows.

Record the exact label of every entry under the gist's `## Criteria` — step 5 removes only
these. If there are none, report that there is nothing to collate and stop.

Done when you hold all three in full and the list of gist labels.

### 2. Map

Give each gist entry one outcome, trying them in this order and taking the first that fits:

1. **Covered** — an existing criterion already names the same defect. No edit.
2. **Widened** — an existing criterion names the same defect in a narrower case, and one added
   word or clause covers the gist case while the line stays within the style rules.
3. **New** — no existing criterion names the defect. Merge every gist entry that shares the
   defect into one new criterion that summarises them all.
4. **Dropped** — tooling already enforces it, or it describes a one-off situation no other
   change would repeat. State the reason.

The style rules set the limit on merging: one criterion names one defect. When entries look
related but a single line would need two triggers or two fixes, they are two defects and
become two criteria.

Done when every gist label maps to exactly one outcome and no two new criteria name the same
defect.

### 3. Draft

Write each new criterion, and the full replacement text of each widened one, to the style
rules. Place each new criterion in the section that fits it. When a widening changes a label,
find every other reference to the old label in the repo.

Check each drafted line against every style rule in turn. Check the word and label limits with
a script rather than by eye.

Done when every drafted line meets every style rule and the script reports no line outside the
limits.

### 4. Review with the user

Present the full proposal:

- New criteria by section, and widened criteria as full replacement text — each followed by
  the gist labels it covers.
- Covered and dropped entries, one line each on why.

Refine it with the user until they approve.

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
   - Write the result back with steps 3–5 of "Appending an entry" in `CRITERIA-GIST.md`, and
     confirm the write command exits zero.
   - Fetch the gist once more and confirm the collated labels are gone and the kept entries
     remain.

Done when the PR is merged and the gist holds only entries not yet collated.
