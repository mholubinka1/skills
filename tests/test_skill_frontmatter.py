import re
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

UNSCOPED_BASH = re.compile(
    r"Bash(\(\*\))?"
    r"|Bash\((git|gh|bash|sh|pwsh|powershell|cmd|python3?|node|npm|npx|yarn|pnpm"
    r"|dotnet|uv|pip|pipenv|poetry|pdm)[ :]?\*\)"
)
DESTRUCTIVE = [
    r"git push(\s+\S|\*|:)",
    r"--force",
    r"reset --hard",
    r"branch -D",
    r"(^|\s)rm(\s|\*|:|$)",
    r"git clean",
    r"stash pop",
    r"stash drop",
]


def _split_inline(value):
    """Split on commas/whitespace outside parentheses."""
    entries, current, depth = [], "", 0
    for ch in value:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if depth == 0 and (ch == "," or ch.isspace()):
            if current:
                entries.append(current)
            current = ""
        else:
            current += ch
    if current:
        entries.append(current)
    return entries


def _without_comment(text):
    return re.sub(r"(^|\s+)#.*$", "", text).strip()


def _allowed_tools(skill_md_text):
    """Return (entries, unsupported-syntax reason or None)."""
    lines = skill_md_text.splitlines()
    if not lines or lines[0].strip() != "---":
        return [], None
    entries = []
    collecting = False
    after_inline_value = False
    for line in lines[1:]:
        if line.strip() == "---":
            break
        if after_inline_value and _without_comment(line):
            if line[0].isspace():
                return entries, "multi-line value"
            after_inline_value = False
        if collecting:
            if not _without_comment(line):
                continue
            item = re.match(r"\s+-\s+(.*\S)\s*$", line)
            if item:
                entry = _without_comment(item.group(1))
                if entry[:1] in (">", "|"):
                    return entries, "block scalar"
                entries.append(entry.strip("\"'"))
                continue
            if line[0].isspace():
                return entries, "multi-line value"
            collecting = False
        key = re.match(r"allowed-tools:\s*(.*)$", line)
        if key:
            value = _without_comment(key.group(1))
            if value.startswith("[") and not value.endswith("]"):
                return entries, "wrapped flow list"
            if value[:1] in (">", "|"):
                return entries, "block scalar"
            value = value.removeprefix("[").removesuffix("]")
            if value:
                entries.extend(e.strip("\"'") for e in _split_inline(value))
                after_inline_value = True
            else:
                collecting = True
    return entries, None


def allowed_tools_violations(skill_md_text):
    entries, unsupported = _allowed_tools(skill_md_text)
    if unsupported:
        return [f"unsupported allowed-tools syntax: {unsupported}"]
    if not entries:
        return ["no allowed-tools"]
    violations = []
    for entry in entries:
        if UNSCOPED_BASH.fullmatch(entry):
            violations.append(f"unscoped Bash: {entry}")
            continue
        inner = re.fullmatch(r"Bash\((.*)\)", entry)
        if inner and any(re.search(p, inner.group(1)) for p in DESTRUCTIVE):
            violations.append(f"destructive pattern pre-approved: {entry}")
    return violations


def skill_with(allowed_tools_line):
    return (
        "---\nname: alpha\ndescription: Does a thing.\n"
        f"{allowed_tools_line}---\n\n# Alpha\n"
    )


def block(*entries):
    return "allowed-tools:\n" + "".join(f"  - {e}\n" for e in entries)


class AllowedToolsGuardTest(unittest.TestCase):
    def test_skill_without_allowed_tools_is_flagged(self):
        text = "---\nname: alpha\ndescription: Does a thing.\n---\n\n# Alpha\n"
        self.assertEqual(allowed_tools_violations(text), ["no allowed-tools"])

    def test_unscoped_bash_is_flagged_naming_the_entry(self):
        for entry in (
            "Bash",
            "Bash(*)",
            "Bash(git *)",
            "Bash(gh *)",
            "Bash(bash *)",
            "Bash(python *)",
            "Bash(npm *)",
            "Bash(git:*)",
            "Bash(git*)",
            "Bash(yarn *)",
            "Bash(dotnet *)",
        ):
            with self.subTest(entry=entry):
                violations = allowed_tools_violations(skill_with(block("Read", entry)))
                self.assertEqual(violations, [f"unscoped Bash: {entry}"])

    def test_destructive_patterns_are_flagged_naming_the_entry(self):
        for command in (
            "git push *",
            "git push origin main",
            "git push --force *",
            "git push*",
            "git push:*",
            "rm",
            "rm*",
            "rm:*",
            "git reset --hard *",
            "git branch -D *",
            "rm *",
            "git clean *",
            "git stash pop",
            "git stash drop *",
        ):
            entry = f"Bash({command})"
            with self.subTest(entry=entry):
                violations = allowed_tools_violations(skill_with(block(entry)))
                self.assertEqual(
                    violations, [f"destructive pattern pre-approved: {entry}"]
                )

    def test_scoped_safe_entries_and_bare_git_push_pass(self):
        text = skill_with(
            block("Read", "Bash(git diff *)", "Bash(git push)", "Edit(.agent-docs/**)")
        )
        self.assertEqual(allowed_tools_violations(text), [])

    def test_inline_string_form_is_parsed(self):
        text = skill_with("allowed-tools: Read, Bash(git diff *) Bash(rm *)\n")
        self.assertEqual(
            allowed_tools_violations(text),
            ["destructive pattern pre-approved: Bash(rm *)"],
        )

    def test_quoted_and_commented_entries_are_parsed(self):
        for line in (
            'allowed-tools: "Bash(rm *)"\n',
            "allowed-tools: ['Bash(rm *)']\n",
            block("Bash(rm *) # needed for cleanup"),
        ):
            with self.subTest(line=line):
                self.assertEqual(
                    allowed_tools_violations(skill_with(line)),
                    ["destructive pattern pre-approved: Bash(rm *)"],
                )

    def test_blank_and_comment_lines_do_not_hide_later_block_entries(self):
        for field in (
            "allowed-tools:\n  - Read\n\n  - Bash(rm *)\n",
            "allowed-tools:\n  - Read\n  # cleanup\n  - Bash(rm *)\n",
            "allowed-tools: # pre-approved\n  - Read\n  - Bash(rm *)\n",
        ):
            with self.subTest(field=field):
                self.assertEqual(
                    allowed_tools_violations(skill_with(field)),
                    ["destructive pattern pre-approved: Bash(rm *)"],
                )

    def test_wrapped_flow_list_is_rejected_as_unsupported(self):
        text = skill_with("allowed-tools: [Read,\n  Bash(rm *)]\n")
        self.assertEqual(
            allowed_tools_violations(text),
            ["unsupported allowed-tools syntax: wrapped flow list"],
        )

    def test_block_scalar_is_rejected_as_unsupported(self):
        for indicator in (">", "|", ">-", "|+"):
            text = skill_with(f"allowed-tools: {indicator}\n  Read\n  Bash(rm *)\n")
            with self.subTest(indicator=indicator):
                self.assertEqual(
                    allowed_tools_violations(text),
                    ["unsupported allowed-tools syntax: block scalar"],
                )

    def test_inline_value_continued_on_next_line_is_rejected(self):
        for field in (
            "allowed-tools: Read\n  Bash(rm *)\n",
            'allowed-tools: "Read,\n  Bash(rm *)"\n',
        ):
            with self.subTest(field=field):
                self.assertEqual(
                    allowed_tools_violations(skill_with(field)),
                    ["unsupported allowed-tools syntax: multi-line value"],
                )

    def test_multi_line_block_items_are_rejected(self):
        cases = (
            ("allowed-tools:\n  - Read\n  Bash(rm *)\n", "multi-line value"),
            ("allowed-tools:\n  - Read\n  - >\n    Bash(rm *)\n", "block scalar"),
        )
        for field, reason in cases:
            with self.subTest(field=field):
                self.assertEqual(
                    allowed_tools_violations(skill_with(field)),
                    [f"unsupported allowed-tools syntax: {reason}"],
                )

    def test_flow_sequence_form_is_parsed(self):
        text = skill_with("allowed-tools: [Read, Bash(rm *)]\n")
        self.assertEqual(
            allowed_tools_violations(text),
            ["destructive pattern pre-approved: Bash(rm *)"],
        )


class RepoSkillsTest(unittest.TestCase):
    def test_every_skill_has_least_privilege_allowed_tools(self):
        skills = sorted(REPO.glob("*/SKILL.md"))
        self.assertTrue(skills)
        for path in skills:
            with self.subTest(skill=path.parent.name):
                self.assertEqual(
                    allowed_tools_violations(path.read_text(encoding="utf-8")), []
                )


if __name__ == "__main__":
    unittest.main()
