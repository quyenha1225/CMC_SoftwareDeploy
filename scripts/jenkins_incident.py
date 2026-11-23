"""Transfer a Jenkins console to the SMS incident receiver."""

import argparse
import base64
from http.cookiejar import CookieJar
import json
import os
from pathlib import Path
import sys
import time
from urllib.error import HTTPError
from urllib.parse import urlsplit
from urllib.request import HTTPCookieProcessor, HTTPRedirectHandler, Request, build_opener


MAX_LOG_BYTES = 10 * 1024 * 1024
INCIDENT_PATH = "/api/ops/jenkins-incidents"


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def endpoint(value):
    url = urlsplit(value)
    loopback = url.scheme == "http" and url.hostname in {"localhost", "127.0.0.1", "::1"}
    if (not url.hostname or url.username or url.password or url.query or url.fragment
            or (url.scheme != "https" and not loopback)):
        raise ValueError("Use HTTPS for remote endpoints or HTTP on loopback.")
    return value.rstrip("/")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-url", default=os.getenv("BUILD_URL"))
    parser.add_argument("--console-file", type=Path, help="Replay a saved Jenkins console.")
    parser.add_argument("--result", default=os.getenv("SMS_JENKINS_BUILD_RESULT"),
                        choices=["FAILURE", "UNSTABLE", "ABORTED", "NOT_BUILT"])
    args = parser.parse_args()
    try:
        build_url = endpoint(args.build_url or "")
        receiver = endpoint(os.environ["SMS_JENKINS_INGEST_URL"])
        if not receiver.endswith(INCIDENT_PATH):
            raise ValueError("Expected the SMS Jenkins incident endpoint.")
        csrf_url = receiver.removesuffix(INCIDENT_PATH) + "/api/auth/csrf"
        if not args.result:
            raise ValueError("Missing build result.")
        job, build = build_url.rsplit("/", 1)
        if "/job/" not in job or not build.isdecimal():
            raise ValueError("Expected a Jenkins build URL.")
        ingest_token = os.environ["SMS_JENKINS_INGEST_TOKEN"]
        if args.console_file:
            with args.console_file.open("rb") as log:
                console = log.read(MAX_LOG_BYTES + 1)
        else:
            login = os.environ["SMS_JENKINS_CONSOLE_USER"]
            api_token = os.environ["SMS_JENKINS_CONSOLE_TOKEN"]
            credentials = base64.b64encode(f"{login}:{api_token}".encode()).decode("ascii")
            opener = build_opener(NoRedirect)
            console_request = Request(build_url + "/consoleText",
                                      headers={"Authorization": "Basic " + credentials})
            with opener.open(console_request, timeout=10) as response:
                if response.headers.get_content_type() != "text/plain":
                    raise ValueError("Jenkins consoleText did not return plain text.")
                console = response.read(MAX_LOG_BYTES + 1)
        if not console or len(console) > MAX_LOG_BYTES:
            raise ValueError("Jenkins console is empty or exceeds 10 MiB.")
        headers = {
            "Content-Type": "text/plain; charset=utf-8",
            "X-Jenkins-Token": ingest_token,
            "X-Jenkins-Job": job,
            "X-Jenkins-Build": build,
            "X-Jenkins-Result": args.result,
        }
        receiver_client = build_opener(NoRedirect, HTTPCookieProcessor(CookieJar()))
        for attempt in range(3):
            try:
                with receiver_client.open(csrf_url, timeout=8) as response:
                    csrf = json.load(response)
                upload = Request(receiver, data=console, method="POST",
                                 headers={**headers, csrf["headerName"]: csrf["token"]})
                with receiver_client.open(upload, timeout=8) as response:
                    if response.status != 202:
                        raise ValueError(f"Unexpected receiver HTTP status {response.status}.")
                print(f"Jenkins incident accepted for build #{build}.")
                return 0
            except HTTPError as error:
                if error.code < 500 or attempt == 2:
                    raise
            except OSError:
                if attempt == 2:
                    raise
            time.sleep(2 ** attempt)
    except HTTPError as error:
        print(f"Jenkins incident transfer failed (HTTP {error.code}).", file=sys.stderr)
    except (OSError, KeyError, ValueError) as error:
        detail = str(error) if isinstance(error, ValueError) else type(error).__name__
        print(f"Jenkins incident transfer failed ({detail}).", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
