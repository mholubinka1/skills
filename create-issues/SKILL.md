---
name: create-issues
description: Break a spec into vertical-slice issues, write them to .agent-docs/issues/<branch-name>.md, and mirror to GitHub. Use after /write-spec when the spec is ready to be broken into implementation work.
attribution: Based on to-issues (Matt Pocock, mattpocock/skills)
---

# Create Issues

Break the spec into independently-grabbable vertical slice issues. Write locally first, then push to GitHub.

## Process

### 1. Read the spec

```bash
git branch --show-current
```

Read `.agent-docs/specs/<branch-name>.md`. If it does not exist, tell the user to run `/write-spec` first.

### 2. Explore the codebase

If not already done, explore the codebase to understand the current state. Issue titles and descriptions should use the domain glossary vocabulary from `.agent-docs/context.md`. Respect ADRs in `.agent-docs/adr/`.

Look for prefactoring opportunities — "make the change easy, then make the easy change."

### 3. Draft vertical slices

Break the spec into **tracer bullet** issues. Each issue is a thin vertical slice cutting through ALL integration layers end-to-end, not a horizontal layer slice.

Each slice must:

- Deliver a narrow but complete path through every layer (schema, API, UI, tests)
- Be demoable or verifiable on its own when complete
- Have any required prefactoring as its own preceding slice

### 4. Three amigos review

Present the proposed breakdown as a numbered list. For each slice show:

- **Title**: short descriptive name
- **Blocked by**: which other slices must complete first (if any)
- **User stories covered**: which user stories from the spec this addresses

Ask the user:

- Does the granularity feel right?
- Are the dependency relationships correct?
- Should any slices be merged or split further?

Iterate until the user approves the breakdown.

### 5. Write the local issues file

Create `.agent-docs/issues/` if it does not exist. Write `.agent-docs/issues/<branch-name>.md`:

```md
# Issues: <branch-name>

## <Slice title>

**Blocked by**: None / #<issue-number>

**User stories**: <numbers from spec>

### What to build

A concise description of this vertical slice end-to-end. No file paths or code snippets
unless a snippet encodes a decision more precisely than prose.

### Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

---
```

Repeat for each approved slice.

### 6. Push to GitHub

Verify `gh` is available:

```bash
gh --version
```

Publish issues in dependency order (blockers first) so real issue numbers can be referenced. For each slice:

```bash
gh issue create \
  --title "<slice title>" \
  --body "$(cat <<'EOF'
## Parent

<link to parent spec issue if one exists, otherwise omit>

## What to build

<description>

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

None / #<issue-number>
EOF
)"
```

After publishing, update the `.agent-docs/issues/<branch-name>.md` file with the real GitHub issue numbers in the "Blocked by" fields.
