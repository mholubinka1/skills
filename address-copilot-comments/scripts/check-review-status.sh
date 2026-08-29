#!/bin/bash
# Single-iteration Copilot review status check for address-copilot-comments Step 3/Step 7.
#
# Usage: check-review-status.sh <owner> <repo> <pr_number> [baseline_review_id]
#
# Prints, one per line:
#   THREAD_COUNT=<n>          (always numeric, including 0 on ERROR)
#   SUPPRESSED_COUNT=<n>      (always numeric, including 0 on ERROR)
#   CURRENT_REVIEW_ID=<id or empty>
#   DECISION=ACTIONABLE|CLEAN|PENDING|ERROR
#
# ACTIONABLE — unresolved Copilot threads or suppressed comments exist; go to Step 4.
# CLEAN      — called WITH a baseline (4th argument supplied, even if it was itself an empty
#              string), CURRENT_REVIEW_ID is non-empty, and it differs from the baseline, with
#              nothing actionable; go to Step 8. The baseline itself may legitimately be
#              empty (it means no prior review existed at capture time) — what matters is
#              that a baseline argument was supplied at all (see HAS_BASELINE below), not
#              that its value is non-empty.
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
# shellcheck disable=SC2016  # $owner/$repo/$number are GraphQL variables, not shell — must stay literal
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
  --jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | select((.comments.nodes[0].author.login // "") | test("copilot"; "i"))] | length')
# The `// ""` above guards against `test()` erroring on a null login (a thread with no
# comments, or whose first comment's author is a deleted/unavailable GitHub account) — without
# it, one such thread fails the whole GraphQL call and misreports a successful response as
# DECISION=ERROR. The same guard is applied to .user.login below for the same reason.
THREAD_OK=$?

# One call for both the id and the body: `--jq`'s comma operator emits each as its own
# top-level result, and gh prints one raw-text result per line — the id is always a single
# line (a bare number or empty), so it always occupies line 1, with the (possibly multi-line)
# body making up everything from line 2 on. No delimiter or encoding is needed to split them.
REVIEWS_RESULT=$(gh api "repos/$OWNER/$REPO/pulls/$PR/reviews?per_page=100" \
  --jq '[.[] | select((.user.login // "") | test("copilot";"i"))] | last | (.id // empty), (.body // empty)')
REVIEWS_OK=$?
CURRENT_REVIEW_ID=$(printf '%s\n' "$REVIEWS_RESULT" | head -1)
REVIEW_BODY=$(printf '%s\n' "$REVIEWS_RESULT" | tail -n +2)

if [ "$THREAD_OK" -ne 0 ] || [ "$REVIEWS_OK" -ne 0 ]; then
  echo "THREAD_COUNT=0"
  echo "SUPPRESSED_COUNT=0"
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
