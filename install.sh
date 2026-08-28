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
	# Refuse to touch the file if the block is malformed (start without a
	# matching end, or vice versa): the removal awk below would otherwise treat
	# everything after a lone start marker as "inside the block" and drop it.
	starts="$(grep -cF "$marker_start" "$rc")"
	ends="$(grep -cF "$marker_end" "$rc")"
	if [ "$starts" != "$ends" ]; then
		echo "install.sh: $rc has an unbalanced update-skills block ($starts start / $ends end marker(s))." >&2
		echo "Fix or delete that block by hand, then re-run — refusing to edit and risk clobbering your shell config." >&2
		exit 1
	fi
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

# --- append the block, separated from existing content by exactly one blank line ---
touch "$rc"
if [ -s "$rc" ]; then
	# strip any trailing blank lines first, so the separator below is the only one
	tmp="$rc.us-tmp.$$"
	awk 'NF { for (i = 0; i < pending; i++) print ""; pending = 0; print; next }
	     { pending++ }' "$rc" > "$tmp" && mv "$tmp" "$rc"
	printf '\n' >> "$rc"
fi
printf '%s\n' "$block" >> "$rc"

echo "Added update-skills to your PATH via $rc."
case ":${PATH:-}:" in
	*":$bin_dir:"*) echo "(this shell already has $bin_dir on PATH)" ;;
	*) echo "Open a new terminal, or run: source $rc" ;;
esac
echo "Then run: update-skills"
