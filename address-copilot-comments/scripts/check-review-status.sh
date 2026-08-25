#!/bin/bash
# Single-iteration Copilot review status check for address-copilot-comments Step 3/Step 7.
#
# Usage: check-review-status.sh <owner> <repo> <pr_number> [baseline_review_id]
#
# Prints, one per line:
#   THREAD_COUNT=<n>
#   SUPPRESSED_COUNT=<n>
#   CURRENT_REVIEW_ID=<id or empty>
#   DECISION=ACTIONABLE|CLEAN|PENDING|ERROR
#
# ACTIONABLE — unresolved Copilot threads or suppressed comments exist; go to Step 4.
# CLEAN      — called WITH a baseline (4th argument supplied) and CURRENT_REVIEW_ID is
#              non-empty and differs from it, with nothing actionable; go to Step 8.
# PENDING    — no new review yet, or this is the no-baseline capture call (see below) and
#              nothing is already actionable; wait and call again.
# ERROR      — a `gh api` call itself failed (network/auth/not-found). Never treated as
#              PENDING — stop and report to the user instead of looping forever.
#
# Called with only 3 arguments (no baseline), this also serves as the one-time baseline
# capture: take CURRENT_REVIEW_ID from the output as the baseline for later calls. This mode
# never reports CLEAN, since there's nothing yet to compare CURRENT_REVIEW_ID against.
#
# Exits 0 for any well-formed call, including DECISION=ERROR — branch on DECISION, not the
# exit code. Exits 2 with a usage message on stderr for a malformed invocation (wrong
# argument count, or an owner/repo/pr_number that doesn't look like a real GitHub identifier).
set -u

if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
  echo "Usage: check-review-status.sh <owner> <repo> <pr_number> [baseline_review_id]" >&2
  exit 2
fi

OWNER="$1"
REPO="$2"
PR="$3"
BASELINE="${4:-}"

if [ "$#" -eq 4 ]; then
  HAS_BASELINE=1
else
  HAS_BASELINE=0
fi

# owner/repo/PR flow into a GraphQL query and a REST path below — validate against GitHub's
# own identifier charset first rather than trusting the caller.
if ! [[ "$OWNER" =~ ^[A-Za-z0-9-]+$ ]] || ! [[ "$REPO" =~ ^[A-Za-z0-9._-]+$ ]] || ! [[ "$PR" =~ ^[0-9]+$ ]]; then
  echo "Invalid owner/repo/pr_number: must match GitHub's own identifier charset." >&2
  exit 2
fi

# -f always sends a string (needed for owner/repo — an all-digit org or user name is valid
# on GitHub, and -F's type auto-detection would otherwise send it as a JSON number, which the
# $owner/$repo: String! variables below would reject). -F sends $number as an actual number,
# matching its Int! declaration.
THREAD_COUNT=$(gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          isResolved
          comments(first: 1) {
            nodes { author { login } }
          }
        }
      }
    }
  }
}' -f owner="$OWNER" -f repo="$REPO" -F number="$PR" \
  --jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | select(.comments.nodes[0].author.login | test("copilot"; "i"))] | length')
THREAD_OK=$?

REVIEW_BODY=$(gh api "repos/$OWNER/$REPO/pulls/$PR/reviews?per_page=100" \
  --jq '[.[] | select(.user.login | test("copilot";"i"))] | last | .body // empty')
BODY_OK=$?

# A second, identical-endpoint call rather than reusing the one above. `gh api --jq` could
# extract both fields in one request (e.g. via @tsv), but a review body is arbitrary
# multi-line markdown — safely combining it with a single-line id in one delimited output
# would need base64-style encoding, whose decode flag differs between GNU (`base64 -d`) and
# BSD/macOS (`base64 -D`) coreutils. Two simple, single-value calls avoid that portability
# split; the extra request is the accepted trade-off.
CURRENT_REVIEW_ID=$(gh api "repos/$OWNER/$REPO/pulls/$PR/reviews?per_page=100" \
  --jq '[.[] | select(.user.login | test("copilot";"i"))] | last | .id // empty')
ID_OK=$?

if [ "$THREAD_OK" -ne 0 ] || [ "$BODY_OK" -ne 0 ] || [ "$ID_OK" -ne 0 ]; then
  echo "THREAD_COUNT="
  echo "SUPPRESSED_COUNT="
  echo "CURRENT_REVIEW_ID="
  echo "DECISION=ERROR"
  exit 0
fi

SUPPRESSED_COUNT=$(printf '%s' "$REVIEW_BODY" | grep -oE 'Suppressed comments \([0-9]+\)' | grep -oE '[0-9]+' | head -1)
SUPPRESSED_COUNT=${SUPPRESSED_COUNT:-0}

if [ "$THREAD_COUNT" -gt 0 ] || [ "$SUPPRESSED_COUNT" -gt 0 ]; then
  DECISION="ACTIONABLE"
elif [ "$HAS_BASELINE" -eq 1 ] && [ -n "$CURRENT_REVIEW_ID" ] && [ "$CURRENT_REVIEW_ID" != "$BASELINE" ]; then
  DECISION="CLEAN"
else
  DECISION="PENDING"
fi

echo "THREAD_COUNT=$THREAD_COUNT"
echo "SUPPRESSED_COUNT=$SUPPRESSED_COUNT"
echo "CURRENT_REVIEW_ID=$CURRENT_REVIEW_ID"
echo "DECISION=$DECISION"
