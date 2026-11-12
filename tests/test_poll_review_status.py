import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
POLL_SCRIPT = REPO / "address-copilot-comments" / "scripts" / "poll-review-status.sh"
NEW_REVIEW_ID = "42"
BASELINE_REVIEW_ID = "7"
# Resolved to a full path: on Windows a bare "bash" launches the WSL stub in System32
# rather than the bash found on PATH.
BASH = shutil.which("bash")

# Stands in for the GitHub CLI: the thread-count call prints STUB_THREADS, and the reviews
# call prints the new review ID from the STUB_REVIEW_ON_CALL-th call onwards.
STUB_GH = """#!/bin/bash
if [ -n "${STUB_GH_FAILS:-}" ]; then
  exit 1
fi
if [ "$2" = "graphql" ]; then
  echo "${STUB_THREADS:-0}"
  exit 0
fi
calls=$(cat "$STUB_STATE" 2>/dev/null || echo 0)
calls=$((calls + 1))
echo "$calls" > "$STUB_STATE"
if [ "$calls" -ge "${STUB_REVIEW_ON_CALL:-999}" ]; then
  echo "${STUB_REVIEW_ID}"
fi
"""


@unittest.skipUnless(BASH, "bash is not available")
class PollReviewStatusTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        stub = self.tmp / "bin" / "gh"
        stub.parent.mkdir()
        stub.write_text(STUB_GH, encoding="utf-8", newline="\n")
        stub.chmod(0o755)

    def poll(self, *args, **stub_settings):
        env = {
            **os.environ,
            "PATH": f"{self.tmp / 'bin'}{os.pathsep}{os.environ['PATH']}",
            "POLL_INTERVAL_SECONDS": "0",
            "STUB_STATE": str(self.tmp / "review-calls"),
            "STUB_REVIEW_ID": NEW_REVIEW_ID,
            **stub_settings,
        }
        return subprocess.run(
            [BASH, str(POLL_SCRIPT), *args],
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )

    def fields(self, result):
        return dict(line.split("=", 1) for line in result.stdout.splitlines())

    def test_stops_on_the_poll_where_a_clean_review_lands(self):
        result = self.poll(
            "acme", "widgets", "12", BASELINE_REVIEW_ID, STUB_REVIEW_ON_CALL="3"
        )

        fields = self.fields(result)
        self.assertEqual(fields["DECISION"], "CLEAN")
        self.assertEqual(fields["CURRENT_REVIEW_ID"], NEW_REVIEW_ID)
        self.assertEqual(fields["POLLS_RUN"], "3")

    def test_runs_every_poll_when_no_review_lands(self):
        result = self.poll("acme", "widgets", "12", BASELINE_REVIEW_ID)

        fields = self.fields(result)
        self.assertEqual(fields["DECISION"], "PENDING")
        self.assertEqual(fields["POLLS_RUN"], "5")

    def test_poll_cap_can_be_set(self):
        result = self.poll("acme", "widgets", "12", BASELINE_REVIEW_ID, "2")

        self.assertEqual(self.fields(result)["POLLS_RUN"], "2")

    def test_empty_baseline_still_reports_clean_for_a_first_review(self):
        result = self.poll("acme", "widgets", "12", "", STUB_REVIEW_ON_CALL="1")

        fields = self.fields(result)
        self.assertEqual(fields["DECISION"], "CLEAN")
        self.assertEqual(fields["POLLS_RUN"], "1")

    def test_stops_at_once_when_threads_are_actionable(self):
        result = self.poll(
            "acme", "widgets", "12", BASELINE_REVIEW_ID, STUB_THREADS="2"
        )

        fields = self.fields(result)
        self.assertEqual(fields["DECISION"], "ACTIONABLE")
        self.assertEqual(fields["THREAD_COUNT"], "2")
        self.assertEqual(fields["POLLS_RUN"], "1")

    def test_stops_at_once_when_gh_fails(self):
        result = self.poll(
            "acme", "widgets", "12", BASELINE_REVIEW_ID, STUB_GH_FAILS="1"
        )

        fields = self.fields(result)
        self.assertEqual(fields["DECISION"], "ERROR")
        self.assertEqual(fields["POLLS_RUN"], "1")
        self.assertEqual(result.returncode, 0)

    def test_missing_baseline_argument_is_a_usage_error(self):
        result = self.poll("acme", "widgets", "12")

        self.assertEqual(result.returncode, 2)
        self.assertRegex(result.stderr, "Usage")
        self.assertEqual(result.stdout, "")

    def test_non_numeric_poll_cap_is_a_usage_error(self):
        result = self.poll("acme", "widgets", "12", BASELINE_REVIEW_ID, "many")

        self.assertEqual(result.returncode, 2)
        self.assertEqual(result.stdout, "")

    def test_invalid_repository_identifier_is_a_usage_error(self):
        result = self.poll("acme", "wid gets", "12", BASELINE_REVIEW_ID)

        self.assertEqual(result.returncode, 2)
        self.assertEqual(result.stdout, "")


if __name__ == "__main__":
    unittest.main()
