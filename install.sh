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

# --- inspect any existing marker block(s) --------------------------------
# Trigger on EITHER marker: a lone end marker (from a half-deleted block) must
# reach the validator and fail safely now, not be ignored so a fresh block is
# appended and the next run bricks on end-before-start.
# One nesting-aware pass over the rc file classifies the current state:
#   MALFORMED <why>       markers nested, out of order, or unterminated
#   OK blocks=<n> match=<0|1>   n well-formed blocks; match=1 iff some block
#                              already carries the exact current path_line
# "Already set up" (no edit) is ONLY blocks=1 match=1. Anything else — a stale
# path, or duplicate blocks — is normalised to a single fresh block. A
# MALFORMED file is left untouched: the removal pass could otherwise swallow
# the user's real config below a broken marker.
if [ -f "$rc" ] && { grep -qF "$marker_start" "$rc" || grep -qF "$marker_end" "$rc"; }; then
	state="$(awk -v s="$marker_start" -v e="$marker_end" -v want="$path_line" '
		$0 == s { if (depth) { done = 1; print "MALFORMED nested-start-marker"; exit } depth = 1; blocks++; next }
		$0 == e { if (!depth) { done = 1; print "MALFORMED end-marker-before-start"; exit } depth = 0; next }
		depth && $0 == want { match_found = 1 }
		END {
			if (done) { exit }
			if (depth) { print "MALFORMED unterminated-block"; exit }
			printf "OK blocks=%d match=%d\n", blocks, match_found
		}
	' "$rc")"

	case "$state" in
		MALFORMED*)
			echo "install.sh: $rc has a broken update-skills block (${state#MALFORMED })." >&2
			echo "Fix or delete that block by hand, then re-run — refusing to edit and risk clobbering your shell config." >&2
			exit 1
			;;
		"OK blocks=1 match=1")
			echo "update-skills is already set up in $rc — nothing to do."
			echo "If it isn't on your PATH yet, open a new terminal or run: source $rc"
			exit 0
			;;
	esac

	echo "Refreshing the update-skills block in $rc."
	remaining="$(awk -v s="$marker_start" -v e="$marker_end" '
		$0 == s { skip = 1; next }
		$0 == e { skip = 0; next }
		!skip  { print }
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
