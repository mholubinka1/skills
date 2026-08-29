# Issues: chore/review-criteria-change-hygiene

> Work complete — PR ready to merge.

## Add change-hygiene review criteria to `code-review/REVIEW-CRITERIA.md`

**GitHub**: #59

**Blocked by**: None

**User stories**: 1–7

### What to build

Fold seven generalised review lessons (from the PR #58 / `update-skills` retrospective) into
`code-review/REVIEW-CRITERIA.md`, in the file's existing terse imperative style. The whole
file is passed verbatim to the `code-review` Standards sub-agent.

- **Code Correctness** — three new bullets:
  - Destructive edits to files the change doesn't own (shell rc, another team's
    config/schema, a user document): "structure not understood" must be a safe refusal that
    leaves the file untouched, never a best-effort edit that can truncate/corrupt.
  - A check that inspects one artefact when the thing being verified needs several (one of N
    hooks, config keys, migrations).
  - Code shelling out to external tools (`git`/`pip`/network/`venv`…) without guarding
    foreseeable failures or attaching an actionable cause; error text asserting one cause
    when several are possible.
- **Code Quality** — one new bullet: a comment or doc claiming a stronger guarantee than the
  code delivers ("exactly one", "in place", "atomic", "idempotent").
- **Security and Performance** — two new bullets:
  - An unsafe fallback: when the preferred resource is missing, doing something materially
    riskier (global/system install, unpinned version, world-writable path) instead of
    failing clearly.
  - Predictable temp paths (`$f.$$`, fixed `/tmp` names, PID suffixes) that should be
    `mktemp`; temp files not cleaned up on failure.
- **Documentation** — rewrite the existing "Stale rationale sweep" bullet so it covers both
  design-rationale/invariant comments *and* a changed value/order/enumeration that is
  restated in prose elsewhere (README, config comment, spec, another doc): every
  restatement must move in the same change. One bullet, not two.

No new section. Fowler smell baseline and the top-of-file preamble unchanged.
`code-review/SKILL.md` unchanged.

### Acceptance criteria

- [x] `code-review/REVIEW-CRITERIA.md` contains all seven points: 3 in Code Correctness, 1
      in Code Quality, 2 in Security and Performance, and the rewritten Documentation
      bullet.
- [x] The Documentation "Stale rationale sweep" bullet is rewritten (not duplicated) and
      still covers everything the original did, plus restated values/orders/enumerations.
- [x] Every new bullet is generic — no `update-skills`, shell-rc, or PR-#58 specifics — and
      matches the length/voice of the other bullets in its section.
- [x] The Fowler smell baseline section and the two-rule preamble are byte-unchanged.
- [x] `code-review/SKILL.md` is unchanged.
- [x] Cross-check recorded: each of the 15 retrospective findings maps to at least one
      bullet (existing or new) that would now flag it.
- [x] `pre-commit-check` passes.

---
