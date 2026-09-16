# Issues: feature/shared-review-criteria-gist

## Create the shared Criteria gist (#99)

**Blocked by**: None

**User stories**: 1, 2, 3

### What to build

Create a real secret GitHub gist that will hold staged review criteria, in the same
bold-label-plus-one-line-rule style as `code-review/REVIEW-CRITERIA.md`, each entry tagged
`(repo#PR)`. Give it a short header explaining its purpose and the collation convention
(copy durable entries into `REVIEW-CRITERIA.md`, then delete them from the gist). Record its
ID/URL in a new `code-review/CRITERIA-GIST.md` in this skills repo. Update
`REVIEW-CRITERIA.md`'s own header so "promote durable ones into a shared criteria file, by
hand" points at the Criteria gist by name/location instead of being vague.

### Acceptance criteria

- [x] A real secret gist exists containing one criteria file with an explanatory header and
      the `(repo#PR)` tagging convention documented.
- [x] `gh gist edit` (append an entry) followed by `gh gist view --raw` (read it back) round
      trips correctly — the appended entry appears verbatim.
- [x] `code-review/CRITERIA-GIST.md` exists, is committed, and contains the gist's ID/URL and
      a one-line explanation of what it is.
- [x] `code-review/REVIEW-CRITERIA.md`'s header references the Criteria gist and spells out
      the collate-then-delete convention.

---

## Write new criteria to the gist instead of a local review.md (#101)

**Blocked by**: #99

**User stories**: 2

### What to build

Update `address-copilot-comments` (SKILL.md and REFERENCE.md) so every instruction that
today appends a generalised criterion to the target repo's `.agent-docs/review.md` instead
appends it to the Criteria gist: read the gist ID from `code-review/CRITERIA-GIST.md`, fetch
its current content, append the new entry tagged `(repo#PR)` (deriving the repo name the same
way `gh` already resolves the current repo), and write the full content back via `gh gist
edit`. Remove all language describing `review.md` as something this skill maintains.

### Acceptance criteria

- [x] `address-copilot-comments`'s SKILL.md/REFERENCE.md no longer mention writing to
      `.agent-docs/review.md` anywhere.
- [x] The rewritten instructions specify: read gist ID from `CRITERIA-GIST.md`, fetch current
      content, append tagged entry, write back whole content.
- [x] A dry-run walkthrough of the rewritten steps against a hypothetical accepted Copilot
      finding produces an unambiguous, correctly-tagged gist entry. (Verified live: appended
      `- **Dry-run smoke test**: ... (skills#101)` via `gh gist edit`, read it back verbatim,
      then cleared it.)
- [x] Push-backs ("Ignored.") are still never recorded, matching today's behaviour.

Also removed `init-agent-docs/REVIEW-TEMPLATE.md`: this issue's rewrite deleted the last live
reference to it (address-copilot-comments no longer needs it for a "review.md doesn't exist"
fallback), so nothing legitimately points at it anymore — resolves the note left on issue #100.

---

## Migrate existing review.md into the gist and read criteria live (#102)

**Blocked by**: #99

**User stories**: 1, 4, 5

### What to build

Update `code-review/SKILL.md` Step 4 to, before reading any criteria: check whether the
target repo has `.agent-docs/review.md`; if it does, read its entries, append them
(`repo#PR`-tagged) to the gist via the same read-append-write as the writer side, then delete
`.agent-docs/review.md` from the target repo. Then read criteria from three sources: the
skill's own `REVIEW-CRITERIA.md` (unchanged), the target repo's `.agent-docs/review.md` (now
only ever hit mid-migration, immediately before deletion), and the Criteria gist fetched live
via `gh gist view --raw`. If the gist is unreachable for any reason (no network, `gh` not
authenticated, gist deleted), warn once and continue with `REVIEW-CRITERIA.md` alone rather
than blocking the review.

### Acceptance criteria

- [ ] Running the updated Step 4 against this skills repo's own `.agent-docs/review.md` (12
      entries, PRs #64–#97) migrates all 12 into the gist tagged with this repo's name, and
      `.agent-docs/review.md` no longer exists afterward.
- [ ] Running Step 4 a second time against a repo with no `.agent-docs/review.md` does nothing
      extra (idempotent) — no error, no duplicate migration.
- [ ] Simulating an unreachable gist (bad ID, no auth) produces the warning and the review
      still proceeds using `REVIEW-CRITERIA.md` alone.
- [ ] The Standards sub-agent prompt in Step 4 is updated to describe all three criteria
      sources it's being fed.

---

## Stop bootstrapping review.md in new repos (#100)

**Blocked by**: None

**User stories**: 1

### What to build

Remove `init-agent-docs`' Step 7 ("Bootstrap review.md") entirely from SKILL.md and
REFERENCE.md, renumbering the subsequent steps (old Step 8 onward shift down by one). Remove
`REVIEW-TEMPLATE.md` if nothing else references it after this change.

### Acceptance criteria

- [x] Running `init-agent-docs` against a fresh repo with no `.agent-docs/` directory does not
      create a `review.md` file.
- [x] SKILL.md's step list and REFERENCE.md's step-by-step detail no longer mention
      `review.md` or contain a step numbered as the old Step 7; numbering is contiguous.
- [x] `REVIEW-TEMPLATE.md` is removed if it has no remaining reference, or left with a note if
      something still legitimately points at it. (Left in place: `address-copilot-comments/REFERENCE.md`
      still references it for the legacy "create review.md" path — issue #101 removes that
      reference, at which point `REVIEW-TEMPLATE.md` has no remaining use.)

---
