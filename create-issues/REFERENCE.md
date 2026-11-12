# Create Issues — Reference

Full command detail and templates. The process overview is in [SKILL.md](SKILL.md).

## Local issues file template (Step 5)

Write `.agent-docs/issues/<branch-name>.md` using this structure. Repeat the section for each approved slice.

```md
# Issues: <branch-name>

## <Slice title>

**GitHub issue**: not yet published

**Blocked by**: None / #<issue-number>

**User stories**: <numbers from spec>

### What to build

A concise description of this vertical slice end-to-end. No file paths or code snippets
unless a snippet encodes a decision more precisely than prose.

### Acceptance criteria

- [ ] Given <starting state>, when <action or event>, then <observable outcome>.
- [ ] Given <starting state>, when <action or event>, then <observable outcome>.

---
```

Every criterion is one Given-When-Then scenario, copied from the list approved in Step 4.
`/bdd` reads them as its scenario list, so a criterion in any other shape sends it back to
planning the slice from scratch.

`**GitHub issue**` names the one GitHub issue this slice is published as; `/pr-cleanup`
closes exactly those. `**Blocked by**` names other issues this slice waits on, which are
never closed from this file.

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

- [ ] Given <starting state>, when <action or event>, then <observable outcome>.
- [ ] Given <starting state>, when <action or event>, then <observable outcome>.

## Blocked by

None / #<issue-number>
EOF
)"
```

Copy the slice's acceptance criteria into the issue body word for word.

After publishing, update `.agent-docs/issues/<branch-name>.md` with the real GitHub issue numbers: each slice's own number replaces `not yet published` in its `**GitHub issue**` field (`**GitHub issue**: #<n>`), and blockers' numbers go in the `**Blocked by**` fields.
