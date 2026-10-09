#!/usr/bin/env python3
import os
import shutil
import subprocess
import tempfile

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
    if os.path.isdir(path) and not os.path.islink(path):
        shutil.rmtree(path)
    elif os.path.lexists(path):
        os.unlink(path)


current = []
keep = sorted(set(old))
try:
    for dirpath, dirs, files in os.walk(repo):
        dirs[:] = sorted(d for d in dirs if d not in (".git", ".claude"))
        if "SKILL.md" in files:
            name = os.path.basename(dirpath)
            dst = os.path.join(dest, name)
            # Copy into a per-run staging dir beside the install, so a failed copy
            # keeps the previous one and concurrent syncs never share a staging path.
            staging = tempfile.mkdtemp(prefix=f".{name}.new-", dir=dest)
            try:
                shutil.copytree(dirpath, os.path.join(staging, name))
                remove(dst)
                os.rename(os.path.join(staging, name), dst)
            finally:
                remove(staging)
            current.append(name)
            keep = sorted(set(old) | set(current))

    if branch == default_branch:
        for name in old:
            if name not in current:
                remove(os.path.join(dest, name))
        keep = current
finally:
    # Always record what is installed, even if a later copy failed.
    with open(manifest, "w") as f:
        f.write("".join(name + "\n" for name in keep))
