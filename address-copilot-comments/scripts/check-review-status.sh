#!/bin/bash
# Single-iteration Copilot review status check for address-copilot-comments Step 3/Step 7.
#
# Usage: check-review-status.sh <owner> <repo> <pr_number> [baseline_review_id]
#
# Prints, one per line:
#   THREAD_COUNT=<n>
#   SUPPRESSED_COUNT=<n>
#   CURRENT_REVIEW_ID=<id or empty>
#   DECISION=ACTIONABLE|CLEAN|PENDING
#
# ACTIONABLE — unresolved Copilot threads or suppressed comments exist; go to Step 4.
# CLEAN      — a new Copilot review exists (differs from baseline) with nothing actionable;
#              go to Step 8.
# PENDING    — no new review yet; wait and call again.
#
# Called with no baseline_review_id, this also serves as the one-time baseline capture:
# take CURRENT_REVIEW_ID from the output as the baseline for later calls. Always exits 0 —
# callers branch on DECISION, not the exit code.
set -u

OWNER="$1"
REPO="$2"
PR="$3"
BASELINE="${4:-}"

THREAD_COUNT=$(gh api graphql -f query='
query {
  repository(owner: "'"$OWNER"'", name: "'"$REPO"'") {
    pullRequest(number: '"$PR"') {
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
}' --jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | select(.comments.nodes[0].author.login | test("copilot"; "i"))] | length')

REVIEW_BODY=$(gh api "repos/$OWNER/$REPO/pulls/$PR/reviews?per_page=100" \
  --jq '[.[] | select(.user.login | test("copilot";"i"))] | last | .body // empty')

SUPPRESSED_COUNT=$(printf '%s' "$REVIEW_BODY" | grep -oE 'Suppressed comments \([0-9]+\)' | grep -oE '[0-9]+' | head -1)
SUPPRESSED_COUNT=${SUPPRESSED_COUNT:-0}

CURRENT_REVIEW_ID=$(gh api "repos/$OWNER/$REPO/pulls/$PR/reviews?per_page=100" \
  --jq '[.[] | select(.user.login | test("copilot";"i"))] | last | .id // empty')

if [ "$THREAD_COUNT" -gt 0 ] || [ "$SUPPRESSED_COUNT" -gt 0 ]; then
  DECISION="ACTIONABLE"
elif [ -n "$CURRENT_REVIEW_ID" ] && [ "$CURRENT_REVIEW_ID" != "$BASELINE" ]; then
  DECISION="CLEAN"
else
  DECISION="PENDING"
fi

echo "THREAD_COUNT=$THREAD_COUNT"
echo "SUPPRESSED_COUNT=$SUPPRESSED_COUNT"
echo "CURRENT_REVIEW_ID=$CURRENT_REVIEW_ID"
echo "DECISION=$DECISION"
