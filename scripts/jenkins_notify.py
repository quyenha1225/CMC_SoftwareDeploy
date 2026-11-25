"""Send the existing Jenkins Discord notification using bound credentials."""
import json
import os
from pathlib import Path
import re
import time
from urllib.error import HTTPError
from urllib.parse import parse_qsl, urlencode, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener

env = os.environ
result = env["SMS_BUILD_RESULT"]
stage = env.get("SMS_EVENT_STAGE")
commit = env.get("IMAGE_TAG", "")
if re.fullmatch(r"[0-9a-f]{40}", commit):
    commit = f"[{commit[:12]}](https://github.com/quyenha1225/CMC_SoftwareDeploy/commit/{commit})"
duration = int(env.get("SMS_BUILD_DURATION_MS", 0)) / 1000
if not duration and env.get("SMS_BUILD_STARTED_MS"):
    duration = max(0, time.time() - int(env["SMS_BUILD_STARTED_MS"]) / 1000)
fields = [
    f"{env.get('JOB_NAME', 'Jenkins')} #{env.get('BUILD_NUMBER', '?')}",
    f"Duration: {int(duration)}s",
    "Branch: " + (env.get("SMS_CHECKOUT_BRANCH") or env.get("BRANCH_NAME") or "unknown"),
    "Commit: " + (commit or "unknown"),
]
if stage:
    fields.append("Stage: " + stage)
if env.get("SMS_EVENT_CHECK"):
    fields.append("Check: " + env["SMS_EVENT_CHECK"])
if env.get("SMS_NOTIFICATION_CONTEXT"):
    fields.append(env["SMS_NOTIFICATION_CONTEXT"])
if env.get("SMS_PIPELINE_MODE"):
    fields.append("Mode: " + env["SMS_PIPELINE_MODE"])
if env.get("SMS_RELEASE_IMPORTED") == "true":
    fields.append("CI: verified release from build #" + env.get("RELEASE_BUILD", "?"))
elif env.get("SMS_CI_COMPLETED") == "true":
    fields.append("CI: passed")
if env.get("SMS_DEPLOY_COMPLETED") == "true":
    fields.append("CD: deployment and smoke checks passed")
    if env.get("SMS_DEPLOY_STAGE") == "Deploy Server SSH":
        fields.append("Public URL: " + env.get("SMS_SERVER_PUBLIC_URL", ""))
elif result == "STARTED" and stage in {"Deploy Local Docker", "Deploy Server SSH"}:
    fields.append("CD: deployment started")
elif env.get("SMS_DEPLOY_STARTED") == "true":
    fields.append("CD: deployment did not complete")
elif env.get("SMS_CI_COMPLETED") == "true":
    fields.append("CD: not run for this build")
if env.get("BUILD_URL"):
    fields.append("Console: " + env["BUILD_URL"].rstrip("/") + "/console")

summary = env.get("SMS_SUCCESS_REPORTS", "").splitlines()
if env.get("QUALITY_GATE_PASSED") == "true":
    summary.append("SonarQube Quality Gate: OK")
if env.get("SMS_IMAGES_BUILT") == "true":
    summary.append("Docker images: built")
if env.get("SMS_IMAGES_PUBLISHED") == "true":
    summary.append("Docker images: published")
if result == "ABORTED":
    fields.append("Build cancelled. See Jenkins for the cancellation source.")
if result == "NOT_BUILT":
    fields.append("Build did not execute. See Jenkins for details.")
embed_fields = []
if env.get("SMS_STAGE_SUMMARY") and result != "STARTED":
    embed_fields.append({"name": "Stages", "value": env["SMS_STAGE_SUMMARY"][:800]})
if env.get("SMS_STAGE_ERRORS") and result != "STARTED":
    embed_fields.insert(0, {"name": "Evidence", "value": env["SMS_STAGE_ERRORS"][:800]})
if summary:
    embed_fields.append({"name": "Checks and images", "value": chr(10).join(summary)[:800]})
payload = {
    "username": "SMS Jenkins",
    "allowed_mentions": {"parse": []},
    "embeds": [{"title": "Jenkins " + result + (" - " + stage if stage else ""),
                "description": chr(10).join(fields)[:2800],
                "color": {"SUCCESS": 0x2ecc71, "FAILURE": 0xe74c3c, "UNSTABLE": 0xf1c40f,
                          "STARTED": 0x3498db}.get(result, 0x7f8c8d),
                "fields": embed_fields}],
}

class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None

try:
    webhook = env.get("DISCORD_WEBHOOK_URL", "").strip()
    if not webhook and env.get("SMS_DISCORD_WEBHOOK_FILE"):
        webhook = Path(env["SMS_DISCORD_WEBHOOK_FILE"]).read_text(encoding="utf-8-sig").strip()
    url = urlsplit(webhook)
    if (url.scheme != "https" or url.netloc not in {"discord.com", "discordapp.com", "canary.discord.com", "ptb.discord.com"}
        or not re.fullmatch(r"/api/(?:v[0-9]+/)?webhooks/[0-9]+/[A-Za-z0-9_-]+", url.path)):
        raise ValueError("Invalid Discord webhook configuration")
    query = dict(parse_qsl(url.query))
    query["wait"] = "true"
    request = Request(url._replace(query=urlencode(query), fragment="").geturl(),
                      data=json.dumps(payload).encode("utf-8"),
                      headers={"Content-Type": "application/json", "User-Agent": "SMS-Jenkins/1.0"},
                      method="POST")
    opener = build_opener(NoRedirect)
    for attempt in range(2):
        try:
            with opener.open(request, timeout=4) as response:
                message = json.load(response)
                print(f"Discord notification delivered (HTTP {response.status}, message {message['id']}).")
            break
        except HTTPError as error:
            delay = float(error.headers.get("Retry-After", "1"))
            if attempt or error.code not in (429, 503) or not 0 <= delay <= 2:
                raise
            time.sleep(delay)
except HTTPError as error:
    print(f"Discord notification failed (HTTP {error.code}).")
except (OSError, ValueError, KeyError, RuntimeError) as error:
    print(f"Discord notification failed ({type(error).__name__}). Check the webhook and agent network.")
