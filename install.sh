#!/usr/bin/env bash
# install.sh — one-time setup: put the `update-skills` command on your PATH.
#
# Adds this repo's bin/ directory to PATH via a marker-delimited block in your
# shell rc file (~/.zshrc for zsh, ~/.bashrc otherwise — including Git Bash on
# Windows). Idempotent: re-running drops any existing block(s) and appends one
# current block at the end of the file, so a moved clone or a duplicate is
# corrected without ever stacking blocks up.
#
# On Windows, this also persists bin/ onto the per-user PATH environment
# variable — the one thing cmd.exe and PowerShell both read directly, with no
# $PROFILE edit needed — so update-skills.cmd/.ps1 work outside Git Bash too.
# That runs in addition to, never instead of, the rc-file wiring above.
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

# Set when the rc-file block is already correct, so the append section below
# is skipped. On non-Windows this still exits immediately, same as before —
# only on Windows does the script continue past it into the PATH section.
rc_already_set_up=""

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
			if [ "${OS:-}" != "Windows_NT" ]; then
				exit 0
			fi
			rc_already_set_up=1
			;;
	esac

	if [ -z "$rc_already_set_up" ]; then
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
fi

if [ -z "$rc_already_set_up" ]; then
	# --- append the block, separated from existing content by exactly one blank line ---
	touch "$rc"
	if [ -s "$rc" ]; then
		# strip any trailing blank lines first, so the separator below is the only one.
		# mktemp (not "$rc.$$") avoids a predictable name / symlink footgun; same dir
		# keeps the mv atomic.
		tmp="$(mktemp "$(dirname "$rc")/.update-skills.XXXXXX")"
		if awk 'NF { for (i = 0; i < pending; i++) print ""; pending = 0; print; next }
		        { pending++ }' "$rc" > "$tmp"; then
			mv "$tmp" "$rc"
		else
			rm -f "$tmp"
			echo "install.sh: failed to normalise $rc — left unchanged." >&2
			exit 1
		fi
		printf '\n' >> "$rc"
	fi
	printf '%s\n' "$block" >> "$rc"

	echo "Added update-skills to your PATH via $rc."
	case ":${PATH:-}:" in
		*":$bin_dir:"*) echo "(this shell already has $bin_dir on PATH)" ;;
		*) echo "Open a new terminal, or run: source $rc" ;;
	esac
fi

# --- Windows: also persist bin_dir onto the per-user PATH -----------------
# cmd.exe and PowerShell both read this one per-user environment variable
# directly — a freshly opened window picks it up with no $PROFILE edit.
if [ "${OS:-}" = "Windows_NT" ]; then
	if ! command -v cygpath >/dev/null 2>&1; then
		echo "install.sh: cygpath not found — cannot convert $bin_dir to a native Windows path for cmd.exe/PowerShell." >&2
		exit 1
	fi
	win_bin_dir="$(cygpath -w "$bin_dir")"

	if ! command -v powershell.exe >/dev/null 2>&1; then
		echo "install.sh: powershell.exe not found — cannot configure the Windows PATH for cmd.exe/PowerShell. Add $win_bin_dir to your user PATH manually." >&2
		exit 1
	fi

	ps_helper="$(mktemp --suffix=.ps1)"
	trap 'rm -f "$ps_helper"' EXIT
	cat > "$ps_helper" <<'PS1_EOF'
param([Parameter(Mandatory = $true)][string]$BinDir)

$currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($null -eq $currentPath) { $currentPath = '' }
$entries = @($currentPath -split ';' | Where-Object { $_ -ne '' })

# "Ours" is identified by content (both entry points present), not by an
# assumed folder name -- correct even if the clone was renamed, though a
# stale entry whose directory has since been deleted entirely can't be
# identified this way (nothing left to inspect) and is left in place.
$oursIndexes = @()
for ($i = 0; $i -lt $entries.Count; $i++) {
    $dir = $entries[$i]
    if ((Test-Path (Join-Path $dir 'update-skills.cmd') -PathType Leaf) -and
        (Test-Path (Join-Path $dir 'update-skills.ps1') -PathType Leaf)) {
        $oursIndexes += $i
    }
}

if ($oursIndexes.Count -eq 1 -and $entries[$oursIndexes[0]] -eq $BinDir) {
    Write-Output 'STATUS:unchanged'
    exit 0
}

$hadOurs = $oursIndexes.Count -gt 0
$kept = @()
for ($i = 0; $i -lt $entries.Count; $i++) {
    if ($oursIndexes -notcontains $i) { $kept += $entries[$i] }
}
$kept += $BinDir
[Environment]::SetEnvironmentVariable('Path', ($kept -join ';'), 'User')

if ($hadOurs) {
    Write-Output 'STATUS:replaced'
} else {
    Write-Output 'STATUS:added'
}
PS1_EOF

	# Assignment as an `if` condition (not `x=$(...)` on its own line) is
	# deliberate: under `set -e`, a plain failing assignment kills the script
	# immediately -- before the failure can be reported with its actual cause.
	# Inside an `if` condition, a non-zero exit is just data, so both paths
	# below run normally. $ps_helper cleanup is handled by the trap above, so
	# it runs even if this command substitution itself is what fails.
	if win_output="$(powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ps_helper" -BinDir "$win_bin_dir" 2>&1)"; then
		win_exit=0
	else
		win_exit=$?
	fi

	if [ "$win_exit" -ne 0 ]; then
		echo "install.sh: the Windows PATH update failed (powershell.exe exited $win_exit):" >&2
		printf '%s\n' "$win_output" >&2
		exit 1
	fi

	win_status="$(printf '%s\n' "$win_output" | tail -n 1)"

	case "$win_status" in
		STATUS:unchanged)
			echo "update-skills is already on the per-user PATH — cmd.exe and PowerShell need no change."
			;;
		STATUS:added)
			echo "Added $win_bin_dir to the per-user PATH for cmd.exe and PowerShell."
			;;
		STATUS:replaced)
			echo "Replaced a stale update-skills PATH entry with $win_bin_dir."
			;;
		*)
			echo "install.sh: could not confirm the Windows PATH update (unexpected output: $win_status) — check cmd.exe/PowerShell manually." >&2
			exit 1
			;;
	esac
fi

echo "Then run: update-skills"
