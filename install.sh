#!/usr/bin/env bash
# install.sh — one-time setup: put the `update-skills` command on your PATH.
#
# Adds this repo's bin/ directory to PATH via a marker-delimited block in your
# shell rc file (~/.zshrc for zsh, ~/.bashrc otherwise — including Git Bash on
# Windows). Idempotent: re-running replaces a stale block in place (e.g. after
# moving the clone) rather than duplicating it.
set -euo pipefail

repo="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="$repo/bin"

marker_start="# >>> skills update-skills >>>"
marker_end="# <<< skills update-skills <<<"
path_line="export PATH=\"$bin_dir:\$PATH\""

# --- pick the rc file for the login shell ------------------------------
case "${SHELL:-}" in
	*zsh) rc="$HOME/.zshrc" ;;
	*) rc="$HOME/.bashrc" ;;
esac

block="$marker_start
# Added by skills/install.sh — puts the update-skills command on PATH.
$path_line
$marker_end"

# --- already set up? -------------------------------------------------
# "Set up" means our own marker block exists AND carries the current path_line.
# Matching path_line anywhere in the file would be fooled by a hand-added
# identical export sitting next to a stale (old-clone) marker block.
if [ -f "$rc" ] && grep -qF "$marker_start" "$rc"; then
	current_block="$(awk -v s="$marker_start" -v e="$marker_end" '
		$0 == s { inblock = 1 }
		inblock { print }
		$0 == e { inblock = 0 }
	' "$rc")"
	if printf '%s\n' "$current_block" | grep -qxF "$path_line"; then
		echo "update-skills is already set up in $rc — nothing to do."
		echo "If it isn't on your PATH yet, open a new terminal or run: source $rc"
		exit 0
	fi
	echo "Refreshing the update-skills block in $rc (clone path changed)."
	remaining="$(awk -v s="$marker_start" -v e="$marker_end" '
		$0 == s { skip = 1 }
		!skip  { print }
		$0 == e { skip = 0 }
	' "$rc")"
	if [ -n "$remaining" ]; then
		printf '%s\n' "$remaining" > "$rc"
	else
		: > "$rc"
	fi
fi

# --- append the block ----------------------------------------------
touch "$rc"
# separate from existing content with exactly one blank line
if [ -s "$rc" ] && [ -n "$(tail -c1 "$rc" 2>/dev/null)" ]; then
	printf '\n\n' >> "$rc"
elif [ -s "$rc" ]; then
	printf '\n' >> "$rc"
fi
printf '%s\n' "$block" >> "$rc"

echo "Added update-skills to your PATH via $rc."
case ":${PATH:-}:" in
	*":$bin_dir:"*) echo "(this shell already has $bin_dir on PATH)" ;;
	*) echo "Open a new terminal, or run: source $rc" ;;
esac
echo "Then run: update-skills"
