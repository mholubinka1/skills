import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "sync_claude_skills.py"


class SyncClaudeSkillsTest(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.repo = Path(tmp.name) / "repo"
        self.home = Path(tmp.name) / "home"
        self.installed = self.home / ".claude" / "skills"
        self.repo.mkdir()
        self.home.mkdir()
        self.git("init", "-q", "-b", "main")

    def git(self, *args):
        subprocess.run(["git", *args], cwd=self.repo, check=True)

    def add_skill(self, name, *files):
        skill = self.repo / name
        skill.mkdir(parents=True, exist_ok=True)
        (skill / "SKILL.md").write_text(f"---\nname: {name}\n---\n")
        for f in files:
            (skill / f).write_text(f)

    def sync(self):
        subprocess.run(
            [sys.executable, str(SCRIPT)],
            cwd=self.repo,
            env={**os.environ, "HOME": str(self.home)},
            check=True,
        )

    def test_file_deleted_from_a_skill_disappears_from_the_install(self):
        self.add_skill("alpha", "OLD.md")
        self.sync()
        (self.repo / "alpha" / "OLD.md").unlink()

        self.sync()

        self.assertTrue((self.installed / "alpha" / "SKILL.md").exists())
        self.assertFalse((self.installed / "alpha" / "OLD.md").exists())

    def manifest(self):
        return (self.installed / ".skills-repo-manifest").read_text().split()

    def install_unmanaged(self, name):
        skill = self.installed / name
        skill.mkdir(parents=True)
        (skill / "SKILL.md").write_text("unmanaged")

    def test_manifest_listed_skill_deleted_from_repo_is_uninstalled_on_default_branch(
        self,
    ):
        self.add_skill("alpha")
        self.add_skill("beta")
        self.sync()
        shutil.rmtree(self.repo / "beta")

        self.sync()

        self.assertFalse((self.installed / "beta").exists())
        self.assertTrue((self.installed / "alpha").exists())
        self.assertEqual(self.manifest(), ["alpha"])

    def test_manifest_listed_skill_deleted_on_a_feature_branch_stays_installed(self):
        self.add_skill("alpha")
        self.add_skill("beta")
        self.sync()
        shutil.rmtree(self.repo / "beta")
        self.git("checkout", "-q", "-b", "feature")

        self.sync()

        self.assertTrue((self.installed / "beta").exists())
        self.assertEqual(sorted(self.manifest()), ["alpha", "beta"])

    def test_installed_skill_not_in_manifest_is_never_removed(self):
        self.add_skill("alpha")
        self.sync()
        self.install_unmanaged("gamma")

        self.sync()

        self.assertTrue((self.installed / "gamma" / "SKILL.md").exists())
        self.assertEqual(self.manifest(), ["alpha"])

    def test_missing_manifest_prunes_nothing_and_a_manifest_is_written(self):
        self.install_unmanaged("gamma")
        self.add_skill("alpha")

        self.sync()

        self.assertTrue((self.installed / "gamma").exists())
        self.assertEqual(self.manifest(), ["alpha"])

    def test_default_branch_comes_from_origin_head(self):
        self.add_skill("alpha")
        self.add_skill("beta")
        self.git("checkout", "-q", "-b", "master")
        self.git(
            "symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/master"
        )
        self.sync()
        shutil.rmtree(self.repo / "beta")

        self.sync()

        self.assertFalse((self.installed / "beta").exists())

    def test_detached_head_prunes_nothing(self):
        self.add_skill("alpha")
        self.add_skill("beta")
        self.git("add", ".")
        self.git(
            "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "-m", "init"
        )
        self.sync()
        self.git("checkout", "-q", "--detach")
        shutil.rmtree(self.repo / "beta")

        self.sync()

        self.assertTrue((self.installed / "beta").exists())

    def test_manifest_name_outside_the_install_dir_is_never_removed(self):
        self.add_skill("alpha")
        self.sync()
        outside = self.installed.parent / "outside"
        outside.mkdir()
        with open(self.installed / ".skills-repo-manifest", "a") as f:
            f.write("../outside\n")

        self.sync()

        self.assertTrue(outside.exists())

    def test_symlinked_install_is_replaced_without_touching_its_target(self):
        target = self.home / "dev-alpha"
        target.mkdir()
        (target / "KEEP.md").write_text("keep")
        self.installed.mkdir(parents=True)
        (self.installed / "alpha").symlink_to(target)
        self.add_skill("alpha")

        self.sync()

        self.assertFalse((self.installed / "alpha").is_symlink())
        self.assertTrue((self.installed / "alpha" / "SKILL.md").exists())
        self.assertTrue((target / "KEEP.md").exists())


if __name__ == "__main__":
    unittest.main()
