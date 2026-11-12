#!/bin/bash
# Poll loop for address-copilot-comments Step 3: waits between Copilot review status checks
# itself, so the caller makes one long call instead of sequencing its own sleeps.
#
# Usage: poll-review-status.sh <owner> <repo> <pr_number> <baseline_review_id> [max_polls]
#
# <baseline_review_id> is required and may be an empty string (no review existed when the
# baseline was captured). [max_polls] defaults to 5.
#
# Each poll waits POLL_INTERVAL_SECONDS (default 60), then runs check-review-status.sh with
# the baseline. Polling stops at the first DECISION other than PENDING, or after max_polls.
#
# Prints the last check's four lines (see check-review-status.sh), then:
#   POLLS_RUN=<n>             (status checks made by this call)
#
# Exits 0 for any well-formed call, including DECISION=ERROR and DECISION=PENDING — branch
# on DECISION and POLLS_RUN, not the exit code. Exits 2 with a usage message on stderr for a
# malformed invocation, printing nothing on stdout.
set -u

DEFAULT_MAX_POLLS=5
DEFAULT_INTERVAL_SECONDS=60

usage() {
  echo "Usage: poll-review-status.sh <owner> <repo> <pr_number> <baseline_review_id> [max_polls]" >&2
  exit 2
}

if [ "$#" -lt 4 ] || [ "$#" -gt 5 ]; then
  usage
fi

OWNER="$1"
REPO="$2"
PR="$3"
BASELINE="$4"
MAX_POLLS="${5:-$DEFAULT_MAX_POLLS}"
INTERVAL_SECONDS="${POLL_INTERVAL_SECONDS:-$DEFAULT_INTERVAL_SECONDS}"

if ! [[ "$MAX_POLLS" =~ ^[1-9][0-9]*$ ]]; then
  echo "Invalid max_polls: must be a positive whole number." >&2
  usage
fi
if ! [[ "$INTERVAL_SECONDS" =~ ^[0-9]+$ ]]; then
  echo "Invalid POLL_INTERVAL_SECONDS: must be a whole number of seconds." >&2
  usage
fi

CHECK_SCRIPT="$(dirname "${BASH_SOURCE[0]}")/check-review-status.sh"

POLLS_RUN=0
while [ "$POLLS_RUN" -lt "$MAX_POLLS" ]; do
  sleep "$INTERVAL_SECONDS"
  STATUS=$(bash "$CHECK_SCRIPT" "$OWNER" "$REPO" "$PR" "$BASELINE")
  CHECK_EXIT=$?
  if [ "$CHECK_EXIT" -ne 0 ]; then
    exit "$CHECK_EXIT"
  fi
  POLLS_RUN=$((POLLS_RUN + 1))
  DECISION=$(printf '%s\n' "$STATUS" | sed -n 's/^DECISION=//p')
  if [ "$DECISION" != "PENDING" ]; then
    break
  fi
done

printf '%s\n' "$STATUS"
echo "POLLS_RUN=$POLLS_RUN"
