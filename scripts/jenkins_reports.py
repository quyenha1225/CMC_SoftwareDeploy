"""Bounded, build-scoped summaries of reports produced by CI gates."""

import json
import os
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path


def fresh(path, started):
    try:
        return started > 0 and path.stat().st_mtime >= started and path.stat().st_size <= 8 * 1024 * 1024
    except OSError:
        return False


def summaries(root, started):
    """Yield only selected report attributes. Leave console output to the sender."""
    for label, files in (
        ("Backend JUnit", sorted((root / "backend/target/surefire-reports").glob("TEST-*.xml"))),
        ("Frontend JUnit", [root / "frontend/coverage/junit.xml"]),
    ):
        totals = dict(tests=0, failures=0, errors=0, skipped=0)
        failures = []
        parsed = 0
        for path in files[:250]:
            if not fresh(path, started):
                continue
            try:
                report = ET.parse(path).getroot()
                cases = list(report.iter("testcase"))
                totals["tests"] += len(cases)
                for case in cases:
                    for tag, key in (("failure", "failures"), ("error", "errors"), ("skipped", "skipped")):
                        node = case.find(tag)
                        if node is None:
                            continue
                        totals[key] += 1
                        if tag != "skipped" and len(failures) < 6:
                            message = (node.get("message") or node.text or "").strip().splitlines()
                            failures.append(f"{label} {case.get('classname', '')}.{case.get('name', '')}"
                                            + (f" — {message[0]}" if message else ""))
                parsed += 1
            except (OSError, ET.ParseError):
                yield f"CI evidence limitation: {label} report invalid"
        if parsed:
            yield f"CI report: {label} " + ", ".join(f"{key}={value}" for key, value in totals.items())
            for failure in failures:
                yield "CI test failure: " + failure.replace("\n", " ")[:500]

    reports = root / "artifacts/reports"
    for path in sorted(reports.glob("trivy-*.json"))[:12]:
        if not fresh(path, started):
            continue
        try:
            report = json.loads(path.read_text(encoding="utf-8"))
            count = 0
            details = []
            for result in report.get("Results") or []:
                for key in ("Vulnerabilities", "Secrets", "Misconfigurations"):
                    for finding in result.get(key) or []:
                        count += 1
                        if len(details) < 3:
                            values = [result.get("Target"), finding.get("VulnerabilityID") or finding.get("RuleID")
                                      or finding.get("ID"), finding.get("PkgName"), finding.get("InstalledVersion"),
                                      finding.get("Severity"), finding.get("FixedVersion")]
                            details.append(" | ".join(str(value) for value in values if value)[:460])
            yield f"CI report: Trivy {path.stem} findings={count}"
            for detail in details:
                yield "CI security finding: " + detail.replace("\n", " ")
        except (OSError, ValueError, TypeError, AttributeError):
            yield f"CI evidence limitation: unreadable Trivy report {path.stem}"

    coverage = root / "frontend/coverage/coverage-summary.json"
    if fresh(coverage, started):
        try:
            value = json.loads(coverage.read_text(encoding="utf-8"))["total"]["lines"]["pct"]
            if isinstance(value, (float, int)) and 0 <= value <= 100:
                yield f"CI report: Frontend line coverage {value}%"
        except (OSError, ValueError, KeyError, TypeError):
            yield "CI evidence limitation: invalid frontend coverage report"
    jacoco = root / "backend/target/site/jacoco/jacoco.xml"
    if fresh(jacoco, started):
        try:
            for counter in ET.parse(jacoco).getroot().findall("counter"):
                if counter.get("type") == "LINE":
                    covered = int(counter.get("covered", "0"))
                    missed = int(counter.get("missed", "0"))
                    if covered + missed > 0:
                        yield f"CI report: Backend line coverage {covered / (covered + missed):.1%}"
                    break
        except (OSError, ValueError, ET.ParseError):
            yield "CI evidence limitation: invalid JaCoCo report"
    mysql = reports / "mysql-integration.json"
    if fresh(mysql, started):
        try:
            report = json.loads(mysql.read_text(encoding="utf-8"))
            if report.get("passed") is True:
                yield f"CI report: MySQL integration passed, workflows={len(report.get('workflows') or [])}"
        except (OSError, ValueError, TypeError, AttributeError):
            yield "CI evidence limitation: invalid MySQL integration report"


def build_metadata(env):
    branch = re.sub(r"[^a-zA-Z0-9/_.-]", "", env.get("SMS_CHECKOUT_BRANCH", "") or env.get("BRANCH_NAME", ""))
    commit = env.get("IMAGE_TAG", "")
    duration = env.get("SMS_BUILD_DURATION_MS", "")
    job = re.sub(r"[^a-zA-Z0-9/_.-]", "", env.get("JOB_NAME", ""))
    lines = [f"Job: {job[:150]}" if job else "", f"Branch: {branch[:150] or 'unknown'}"]
    if re.fullmatch(r"[0-9a-f]{40}", commit):
        lines.append(f"Commit: [{commit[:12]}](https://github.com/quyenha1225/CMC_SoftwareDeploy/commit/{commit})")
    started = env.get("SMS_BUILD_STARTED_MS", "")
    if duration.isdecimal() and int(duration):
        lines.append(f"Duration: {int(duration) // 1000}s")
    elif started.isdecimal() and int(started):
        lines.append(f"Duration: {max(0, int(time.time() - int(started) / 1000))}s")
    return " | ".join(filter(None, lines))


def timing_event(label=None, *, exit_code=None):
    destination = os.getenv("SMS_CI_TIMING_FILE")
    if destination:
        event = {"at_ms": time.time_ns() // 1_000_000}
        event.update({"check": label} if exit_code is None else {"exit_code": exit_code})
        with Path(destination).open("a", encoding="utf-8") as stream:
            stream.write(json.dumps(event) + "\n")


def export_timings(root, timing_dir, env):
    stages = []
    limitations = []
    observed_at = time.time_ns() // 1_000_000
    for start_file in timing_dir.glob("stage-*.start"):
        name, started = start_file.read_text(encoding="utf-8").splitlines()
        finish_file = start_file.with_suffix(".end")
        if finish_file.exists():
            status, ended = finish_file.read_text(encoding="utf-8").splitlines()
            duration = max(0, int(ended) - int(started))
        else:
            status, duration = "interrupted", None
        stages.append({"stage": name, "status": status, "start_ms": int(started),
                       "duration_ms": duration})

    work = []
    for step in sorted(timing_dir.glob("work-*.jsonl")):
        events = []
        lines = step.read_text(encoding="utf-8").splitlines(keepends=True)
        for index, line in enumerate(lines):
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                if index != len(lines) - 1 or line.endswith("\n"):
                    raise
                limitations.append(f"{step.name}: last timing event was interrupted")
        checks = [
            {"name": current["check"], "start_ms": current["at_ms"],
             "duration_ms": max(0, following["at_ms"] - current["at_ms"])}
            for current, following in zip(events, events[1:]) if "check" in current
        ]
        if events:
            last = events[-1]
            if "check" in last:
                checks.append({"name": last["check"], "start_ms": last["at_ms"],
                               "duration_ms": None})
            work.append({"step": step.stem.removeprefix("work-"),
                         "exit_code": last.get("exit_code"), "checks": checks})
    commit = env.get("IMAGE_TAG", "")
    report = {"job": env.get("JOB_NAME"), "build_id": env.get("BUILD_NUMBER"),
              "build_url": env.get("BUILD_URL"),
              "commit": commit if re.fullmatch(r"[0-9a-f]{40}", commit) else None,
              "result": env.get("SMS_BUILD_RESULT"), "observed_at_ms": observed_at,
              "stages": sorted(stages, key=lambda stage: stage["start_ms"]),
              "work": work, "limitations": limitations}
    destination = root / "artifacts/reports/stage-timings.json"
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_suffix(".tmp")
    temporary.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    temporary.replace(destination)


def capture_step(step, command=None):
    """Keep a small excerpt for the Jenkins-only fallback when incident transfer fails."""
    destination = Path(os.environ["SMS_CI_DETAIL_FILE"] + ".error")
    try:
        destination.unlink(missing_ok=True)
    except OSError:
        print("CI evidence limitation: could not clear the fallback excerpt.", file=sys.stderr)
        destination = None
    important = []
    wrappers = []
    specific = re.compile(
        r"Error response from daemon|failed to solve|Caused by:|COMPILATION ERROR|"
        r"\[ERROR\].+|\d+:\d+\s+error\s|AssertionError|FlywayException|"
        r"Restore (?:row mismatch|integrity failed)|SonarQube Quality Gate ERROR|"
        r"Security gate failed|Scanner did not produce|Smoke failed|Permission denied|"
        r"Core test schema already exists|Browser integration failed|npm (?:ERR!|error)", re.I)
    if command is None:
        command = [sys.executable, str(Path(__file__).with_name("ci.py")), step]
    with subprocess.Popen(command,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT) as child:
        for data in child.stdout:
            sys.stdout.buffer.write(data)
            sys.stdout.buffer.flush()
            line = data.decode("utf-8", "replace").strip()
            if len(important) < 3 and specific.search(line) and not line.startswith("[WARNING]"):
                important.append(line[:320])
            elif line.startswith(("CI failure:", "Deployment stopped:")) and len(wrappers) < 2:
                wrappers.append(line[:320])
        result = child.wait()
    timing_event(exit_code=result)
    if result and destination is not None:
        try:
            # Redact before the fallback excerpt reaches the workspace or Discord.
            lines = important[:2] + wrappers[-1:]
            destination.write_text(redact("\n".join(lines)), encoding="utf-8")
        except OSError:
            print("CI evidence limitation: could not save fallback excerpt.", file=sys.stderr)
    return result


def redact(text):
    text = re.sub(r"-----BEGIN [^\n]*PRIVATE KEY-----[\s\S]*?(?:-----END [^\n]*PRIVATE KEY-----|\Z)",
                  "[REDACTED]", text)
    return re.sub(
        r"https?://[^\s/]+/api/(?:v\d+/)?webhooks/[^\s]+|https?://[^\s/@]+:[^\s/@]+@|"
        r"\b(?:bearer|basic)\s+[a-z0-9._+/=-]{8,}|"
        r"\b(?:gh[pousr]_|sk-)[a-z0-9_-]{16,}|\bAKIA[A-Z0-9]{16}|"
        r"(?i:\b[\w.-]*(?:password|passwd|secret|token|api[_-]?key)[\w.-]*"
        r"[\"']?[ \t]*(?::[ \t]*(?!(?m:Access is denied\.?[ \t]*$))|=[ \t]*)"
        r"(?:\"[^\"\r\n]*\"?|'[^'\r\n]*'|[^\s,;]+))",
        "[REDACTED]", text, flags=re.I)


if __name__ == "__main__":
    if sys.argv[1] == "--timings":
        export_timings(Path.cwd(), Path(os.environ["SMS_TIMING_DIR"]), os.environ)
    elif sys.argv[1] == "--deploy":
        step = sys.argv[2]
        command = [sys.executable, str(Path(__file__).with_name("deploy.py")), *sys.argv[2:]]
        timing_event("Server deployment: " + step)
        sys.exit(capture_step(step, command))
    elif sys.argv[1] == "--summary":
        started = int(os.environ["SMS_BUILD_STARTED_MS"]) / 1000
        root = Path(__file__).resolve().parents[1]
        lines = [line.removeprefix("CI report: ") for line in summaries(root, started)
                 if line.startswith("CI report: ")]
        print(redact("\n".join(lines))[:1000])
    else:
        sys.exit(capture_step(sys.argv[1]))
