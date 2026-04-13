#!/usr/bin/env python3
import os
import shutil
import subprocess

repo = subprocess.check_output(["git", "rev-parse", "--show-toplevel"]).decode().strip()
dest = os.path.expanduser("~/.claude/skills")
os.makedirs(dest, exist_ok=True)

for dirpath, dirs, files in os.walk(repo):
    dirs[:] = [d for d in dirs if d != ".git"]
    if "SKILL.md" in files:
        name = os.path.basename(dirpath)
        dst = os.path.join(dest, name)
        shutil.copytree(dirpath, dst, dirs_exist_ok=True)
