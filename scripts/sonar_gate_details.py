"""Print failed conditions from the exact SonarQube analysis used by Jenkins."""

import json
import os
from pathlib import Path
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, build_opener, HTTPRedirectHandler


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def main():
    report = Path(__file__).resolve().parents[1] / "backend/target/sonar/report-task.txt"
    try:
        metadata = dict(line.split("=", 1) for line in report.read_text(encoding="utf-8").splitlines()
                        if "=" in line)
        server = os.environ["SONAR_HOST_URL"].rstrip("/")
        token = os.environ["SONAR_AUTH_TOKEN"]
        opener = build_opener(NoRedirect)

        def get(path, **params):
            request = Request(f"{server}/api/{path}?{urlencode(params)}",
                              headers={"Authorization": f"Bearer {token}"})
            with opener.open(request, timeout=8) as response:
                return json.load(response)

        task = get("ce/task", id=metadata["ceTaskId"])["task"]
        gate = get("qualitygates/project_status", analysisId=task["analysisId"])["projectStatus"]
        if os.getenv('SMS_RECORD_SONAR_EVIDENCE') == 'true':
            if task.get('status') != 'SUCCESS' or gate.get('status') != 'OK':
                raise RuntimeError('Exact Sonar analysis did not pass')
            from ci_release import atomic_json
            atomic_json(report.parents[3] / 'artifacts/reports/sonar-evidence.json', {
                'commit': os.environ['IMAGE_TAG'], 'task_id': metadata['ceTaskId'],
                'analysis_id': task['analysisId'], 'status': gate['status']})
        for condition in gate["conditions"]:
            if condition["status"] == "ERROR":
                print(f"SonarQube Quality Gate ERROR: {condition['metricKey']} "
                      f"actual={condition.get('actualValue', '?')}; "
                      f"fails when {condition.get('comparator', '?')} {condition.get('errorThreshold', '?')}")
    except HTTPError as error:
        if os.getenv('SMS_RECORD_SONAR_EVIDENCE') == 'true':
            raise RuntimeError('Exact Sonar evidence unavailable') from None
        print(f"SonarQube Quality Gate details unavailable (HTTP {error.code}).")
    except (OSError, ValueError, KeyError, TypeError) as error:
        if os.getenv('SMS_RECORD_SONAR_EVIDENCE') == 'true':
            raise RuntimeError('Exact Sonar evidence unavailable') from None
        print(f"SonarQube Quality Gate details unavailable ({type(error).__name__}).")


if __name__ == "__main__":
    main()
