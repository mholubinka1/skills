import re
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

UNSCOPED_BASH = {"Bash", "Bash(*)", "Bash(git *)"}
DESTRUCTIVE = [
    r"git push\s+\S",
    r"--force",
    r"reset --hard",
    r"branch -D",
    r"(^|\s)rm\s",
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


def _allowed_tools(skill_md_text):
    lines = skill_md_text.splitlines()
    if not lines or lines[0].strip() != "---":
        return []
    entries = []
    collecting = False
    for line in lines[1:]:
        if line.strip() == "---":
            break
        if collecting:
            item = re.match(r"\s+-\s+(.*\S)\s*$", line)
            if item:
                entries.append(item.group(1).strip("\"'"))
                continue
            collecting = False
        key = re.match(r"allowed-tools:\s*(.*)$", line)
        if key:
            value = key.group(1).strip()
            if value:
                entries.extend(_split_inline(value))
            else:
                collecting = True
    return entries


def allowed_tools_violations(skill_md_text):
    entries = _allowed_tools(skill_md_text)
    if not entries:
        return ["no allowed-tools"]
    violations = []
    for entry in entries:
        if entry in UNSCOPED_BASH:
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
        for entry in ("Bash", "Bash(*)", "Bash(git *)"):
            with self.subTest(entry=entry):
                violations = allowed_tools_violations(skill_with(block("Read", entry)))
                self.assertEqual(violations, [f"unscoped Bash: {entry}"])

    def test_destructive_patterns_are_flagged_naming_the_entry(self):
        for command in (
            "git push *",
            "git push origin main",
            "git push --force *",
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
