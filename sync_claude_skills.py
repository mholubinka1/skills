#!/usr/bin/env python3
import os
import shutil
import subprocess

repo = subprocess.check_output(["git", "rev-parse", "--show-toplevel"]).decode().strip()
dest = os.path.expanduser("~/.claude/skills")
os.makedirs(dest, exist_ok=True)
manifest = os.path.join(dest, ".skills-repo-manifest")

try:
    head = (
        subprocess.check_output(
            ["git", "symbolic-ref", "--short", "refs/remotes/origin/HEAD"],
            cwd=repo,
            stderr=subprocess.DEVNULL,
        )
        .decode()
        .strip()
    )
    default_branch = head.removeprefix("origin/")
except subprocess.CalledProcessError:
    default_branch = "main"
branch = (
    subprocess.check_output(["git", "branch", "--show-current"], cwd=repo)
    .decode()
    .strip()
)

old = []
if os.path.exists(manifest):
    with open(manifest) as f:
        # Only plain directory names: never let a manifest line reach outside dest.
        old = [
            n
            for n in f.read().split()
            if os.path.basename(n) == n and n not in (".", "..")
        ]


def remove(path):
    if os.path.islink(path):
        os.unlink(path)
    elif os.path.exists(path):
        shutil.rmtree(path)


current = []
for dirpath, dirs, files in os.walk(repo):
    dirs[:] = [d for d in dirs if d not in (".git", ".claude")]
    if "SKILL.md" in files:
        name = os.path.basename(dirpath)
        current.append(name)
        dst = os.path.join(dest, name)
        remove(dst)
        shutil.copytree(dirpath, dst)

if branch == default_branch:
    for name in old:
        if name not in current:
            remove(os.path.join(dest, name))
    keep = current
else:
    keep = sorted(set(old) | set(current))

with open(manifest, "w") as f:
    f.write("".join(name + "\n" for name in keep))
