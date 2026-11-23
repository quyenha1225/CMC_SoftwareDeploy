"""Read the current Prometheus status and optionally post it to Discord."""

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import re
import sys
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import HTTPRedirectHandler, Request, build_opener, urlopen

from docker import ROOT, settings


CHECKS = {
    "Frontend /healthz": 'up{job="sms-frontend-probe"} * probe_success{job="sms-frontend-probe"}',
    "Backend readiness": 'up{job="sms-backend-readiness-probe"} * probe_success{job="sms-backend-readiness-probe"}',
    "MySQL TCP": 'up{job="sms-mysql-probe"} * probe_success{job="sms-mysql-probe"}',
    "Alertmanager": 'up{job="sms-monitoring",instance="alertmanager:9093"}',
    "Grafana": 'up{job="sms-monitoring",instance="grafana:3000"}',
}


def query(base, expression):
    with urlopen(f"{base}/api/v1/query?{urlencode({'query': expression})}", timeout=5) as response:
        payload = json.load(response)
    if payload["status"] != "success":
        raise ValueError("Prometheus query failed")
    return payload["data"]["result"]


def report(base):
    stamp = dt.datetime.now().astimezone().strftime("%Y-%m-%d %H:%M %z")
    lines = [f"**SMS | Trạng thái hệ thống** ({stamp})"]
    checks = list(CHECKS.values())
    # One instant query keeps all checks and firing alerts on the same evaluation time.
    expressions = [
        f'label_replace(({expr}), "sms_check", "{index}", "__name__", ".*")'
        for index, expr in enumerate(checks)
    ]
    expressions.append('ALERTS{alertstate="firing"}')
    try:
        rows = query(base, " or ".join(expressions))
        values = {index: [] for index in range(len(checks))}
        alerts = set()
        for row in rows:
            labels = row["metric"]
            if "sms_check" in labels:
                values[int(labels["sms_check"])].append(row["value"][1])
            else:
                alerts.add(labels["alertname"])
    except (OSError, ValueError, KeyError, TypeError):
        return "\n".join(lines + ["Prometheus: không lấy được dữ liệu. Trạng thái các dịch vụ chưa xác định."])
    for index, label in enumerate(CHECKS):
        samples = values[index]
        state = "OK" if samples and all(value == "1" for value in samples) else (
            "Lỗi" if "0" in samples else "Chưa có dữ liệu"
        )
        lines.append(f"- {label}: {state}")
    lines.append("Cảnh báo đang phát: " + (", ".join(sorted(alerts)) or "Không có"))
    return "\n".join(lines)


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def send_discord(secret, message):
    webhook = secret.read_text(encoding="utf-8-sig").strip()
    if not re.fullmatch(r"https://discord\.com/api/webhooks/\d+/[\w-]+", webhook):
        raise ValueError("Webhook Discord trống hoặc sai định dạng.")
    content = message if len(message) <= 1800 else message[:1799] + "…"
    body = json.dumps({"content": content, "allowed_mentions": {"parse": []}}).encode("utf-8")
    request = Request(
        webhook + "?wait=true", data=body,
        headers={"Content-Type": "application/json", "User-Agent": "SMS Monitoring"},
    )
    try:
        with build_opener(NoRedirect).open(request, timeout=10):
            pass
    except HTTPError as error:
        raise ValueError(f"Discord trả về HTTP {error.code}.") from None
    except OSError:
        raise ValueError("Không kết nối được Discord.") from None


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--env-file", type=Path, default=ROOT / ".env")
    parser.add_argument("--discord", action="store_true", help="Post the report to Discord")
    args = parser.parse_args()
    try:
        config = settings(args.env_file) if args.env_file.exists() else {}
        port = int(os.environ.get("PROMETHEUS_PORT") or config.get("PROMETHEUS_PORT") or 9090)
        message = report(f"http://127.0.0.1:{port}")
        print(message)
        if args.discord:
            secret_dir = Path(os.environ.get("SMS_SECRETS_DIR") or config.get("SMS_SECRETS_DIR") or ".secrets")
            send_discord(ROOT / secret_dir / "discord_webhook_url", message)
    except (OSError, ValueError) as error:
        print(f"Không tạo hoặc gửi được bản tin: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
