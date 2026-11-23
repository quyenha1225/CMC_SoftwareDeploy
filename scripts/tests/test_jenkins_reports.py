import io
import json
import os
import re
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from jenkins_incident import MAX_LOG_BYTES, read_console
from jenkins_reports import redact, summaries

ROOT = Path(__file__).resolve().parents[2]


class JenkinsReportsTests(unittest.TestCase):
    def test_reports_exclude_stale_files_and_preserve_structured_failure(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            surefire = root / "backend/target/surefire-reports"
            surefire.mkdir(parents=True)
            stale = surefire / "TEST-old.xml"
            stale.write_text('<testsuite><testcase name="stale"><failure/></testcase></testsuite>')
            os.utime(stale, (20, 20))
            current = surefire / "TEST-current.xml"
            current.write_text('<testsuite><testcase classname="InvoiceTest" name="totals">'
                               '<failure message="Expected 1 but got 2"/></testcase></testsuite>')
            lines = list(summaries(root, 100))
            self.assertEqual(len(lines), 2)
            self.assertIn("failures=1", lines[0])
            self.assertIn("InvoiceTest.totals", lines[1])
            self.assertIn("Expected 1 but got 2", lines[1])
            self.assertNotIn("stale", "\n".join(lines))

    def test_trivy_report_exposes_only_selected_attributes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            report = root / "artifacts/reports/trivy-backend.json"
            report.parent.mkdir(parents=True)
            report.write_text(json.dumps({"Results": [{"Target": "backend", "Vulnerabilities": [{
                "VulnerabilityID": "CVE-TEST", "PkgName": "example", "InstalledVersion": "1", "FixedVersion": "2",
                "Severity": "CRITICAL", "Description": "arbitrary report text"
            }], "Secrets": [{"RuleID": "example-key", "Match": "sensitive-match", "Code": "sensitive-code"}]}]}))
            evidence = "\n".join(summaries(root, 100))
            self.assertIn("findings=2", evidence)
            self.assertIn("CVE-TEST | example | 1 | CRITICAL | 2", evidence)
            self.assertNotRegex(evidence, "arbitrary report text|sensitive-")

    def test_long_console_preserves_both_ends_and_records_truncation(self):
        body = b"initial root evidence\n" + b"x" * MAX_LOG_BYTES + b"\nfinal failure"
        excerpt = read_console(io.BytesIO(body))
        self.assertLess(len(excerpt), MAX_LOG_BYTES)
        self.assertTrue(excerpt.startswith(b"initial root evidence"))
        self.assertIn(b"CI evidence limitation:", excerpt)
        self.assertTrue(excerpt.endswith(b"final failure"))

    def test_redacts_fallback_evidence(self):
        raw = ("Error response from daemon: password=test-secret\n"
               "https://discord.com/api/webhooks/123/example\nAuthorization: Bearer abcdefghijk")
        text = redact(raw)
        self.assertIn("Error response from daemon", text)
        self.assertNotRegex(text, "test-secret|webhooks|abcdefghijk")

    def test_jenkinsfile_uses_sandbox_safe_stage_tracking_and_python_wrapper(self):
        jenkins = (ROOT / "Jenkinsfile").read_text(encoding="utf-8")
        groovy = jenkins.split("writeFile file: notifier, text: '''", 1)[0]
        self.assertNotRegex(groovy, r"\\benv\\s*\\[")
        self.assertNotIn("stageKey(", groovy)
        self.assertIn("stageValue(it, 'state')", groovy)
        self.assertIn("stageValue(it, 'detail')", groovy)
        self.assertIn("stageValue(it, 'error')", groovy)
        self.assertIn("call scripts/jenkins-python.cmd", jenkins)
        self.assertNotIn("PYTHON_EXE", jenkins)
        for stage in ("Checkout", "Check Environment", "Prepare", "Backend Test", "Frontend Test",
                      "Validate Docker Compose", "SonarQube Analysis", "SonarQube Quality Gate",
                      "Build Docker Images", "MySQL Integration Tests", "Dependency and Image Scan",
                      "Secret Scan", "Deploy Local Docker", "Deploy Server SSH"):
            self.assertIn("case '" + stage + "':", groovy)

    def test_direct_discord_has_one_embed_for_each_terminal_status(self):
        jenkins = (ROOT / "Jenkinsfile").read_text(encoding="utf-8")
        embedded = re.search(r"writeFile file: notifier, text: '''(.*?)'''", jenkins, re.S)[1]
        code = compile(embedded, "Jenkinsfile Discord notifier", "exec")

        class Response(io.BytesIO):
            status = 200

        for status in ("SUCCESS", "FAILURE", "UNSTABLE", "ABORTED", "NOT_BUILT"):
            with self.subTest(status=status), patch.dict(os.environ, {
                "SMS_BUILD_RESULT": status, "SMS_BUILD_DURATION_MS": "4000", "BUILD_NUMBER": "54",
                "SMS_SUCCESS_REPORTS": "Backend JUnit tests=5" if status == "SUCCESS" else "",
                "SMS_STAGE_ERRORS": "Docker mount denied" if status == "FAILURE" else "",
                "DISCORD_WEBHOOK_URL": "https://discord.com/api/webhooks/123/test-fixture",
            }, clear=True), patch("urllib.request.build_opener") as build_opener:
                opener = build_opener.return_value
                opener.open.return_value = Response(b'{"id":"local-test"}')
                with patch("sys.stdout", new_callable=io.StringIO):
                    exec(code, {})
                opener.open.assert_called_once()
                embed, = json.loads(opener.open.call_args.args[0].data)["embeds"]
                self.assertIn(status, embed["title"])
                self.assertIn("#54", embed["description"])
                if status == "FAILURE":
                    self.assertIn("Docker mount denied", embed["fields"][0]["value"])
                if status == "SUCCESS":
                    self.assertIn("Backend JUnit tests=5", embed["fields"][0]["value"])
                    self.assertNotIn("deployment and smoke checks passed", embed["description"])
