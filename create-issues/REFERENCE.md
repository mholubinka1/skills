# Create Issues — Reference

Full command detail and templates. The process overview is in [SKILL.md](SKILL.md).

## Local issues file template (Step 5)

Write `.agent-docs/issues/<branch-name>.md` using this structure. Repeat the section for each approved slice.

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

## GitHub issue creation command (Step 6)

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

After publishing, update `.agent-docs/issues/<branch-name>.md` with the real GitHub issue numbers in the "Blocked by" fields.
