"""Read current Prometheus status and optionally post a compact report to Discord."""

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
METRICS = {
    "CPU máy chủ": '100 * (1 - avg(rate(node_cpu_seconds_total{job="sms-node",mode="idle"}[5m])))',
    "RAM đã dùng": '100 * (1 - node_memory_MemAvailable_bytes{job="sms-node"} / node_memory_MemTotal_bytes{job="sms-node"})',
    "Ổ đĩa root đã dùng": '100 * (1 - node_filesystem_avail_bytes{job="sms-node",mountpoint="/",fstype!~"tmpfs|overlay|squashfs"} / node_filesystem_size_bytes{job="sms-node",mountpoint="/",fstype!~"tmpfs|overlay|squashfs"})',
    "Uptime (giây)": 'time() - node_boot_time_seconds{job="sms-node"}',
    "Load average 1m": 'node_load1{job="sms-node"}',
    "Container đang thấy": 'count(container_last_seen{job="sms-cadvisor",name!=""})',
    "MySQL volume (bytes)": 'sms_volume_bytes{volume="mysql_data"}',
    "Private files volume (bytes)": 'sms_volume_bytes{volume="private_files"}',
}
CONTAINER_CPU = 'topk(5, sum by (name) (rate(container_cpu_usage_seconds_total{job="sms-cadvisor",name!=""}[5m])) * 100)'
CONTAINER_RAM = 'topk(5, sum by (name) (container_memory_working_set_bytes{job="sms-cadvisor",name!=""}))'


def query(base, expression):
    with urlopen(f"{base}/api/v1/query?{urlencode({'query': expression})}", timeout=5) as response:
        payload = json.load(response)
    if payload["status"] != "success":
        raise ValueError("Prometheus query failed")
    return payload["data"]["result"]


def _sample_value(rows):
    return float(rows[0]["value"][1]) if rows else None


def _format_metric(label, value):
    if value is None:
        return f"- {label}: Không có dữ liệu"
    if label.endswith("(bytes)"):
        return f"- {label}: {value / (1024 ** 3):.2f} GiB"
    if label == "Uptime (giây)":
        days, remainder = divmod(max(0, int(value)), 86400)
        hours, remainder = divmod(remainder, 3600)
        minutes, _ = divmod(remainder, 60)
        return f"- {label}: {days} ngày {hours} giờ {minutes} phút"
    if label in ("CPU máy chủ", "RAM đã dùng", "Ổ đĩa root đã dùng"):
        return f"- {label}: {value:.1f}%"
    return f"- {label}: {value:.2f}"


def _format_top(rows, unit):
    if not rows:
        return "Không có dữ liệu"
    ranked = sorted(rows, key=lambda row: float(row["value"][1]), reverse=True)[:5]
    return "; ".join(
        f'{row["metric"].get("name", "container")}: {float(row["value"][1]):.1f} {unit}'
        for row in ranked
    )


def _analysis(metrics, checks, alerts, missing_metrics=(), alerts_available=True):
    issues = []
    for service in ("Frontend /healthz", "Backend readiness", "MySQL TCP"):
        if checks.get(service) != "OK":
            issues.append(f"{service} lỗi hoặc chưa có dữ liệu")
    for name, threshold in (("CPU máy chủ", 90), ("RAM đã dùng", 90), ("Ổ đĩa root đã dùng", 85)):
        value = metrics.get(name)
        if value is not None and value >= threshold:
            issues.append(f"{name} cao (>= {threshold}%)")
    if missing_metrics:
        issues.append("Thiếu số liệu: " + ", ".join(missing_metrics))
    if not alerts_available:
        issues.append("Không truy vấn được danh sách cảnh báo")
    elif alerts:
        issues.append("Prometheus đang có alert firing")
    return ("Phân tích: Chưa thấy vấn đề từ số liệu có sẵn; tiếp tục theo dõi."
            if not issues else "Phân tích/rủi ro: " + "; ".join(issues) + ".")


def report(base):
    stamp = dt.datetime.now().astimezone().strftime("%Y-%m-%d %H:%M %z")
    lines = [f"**SMS | Trạng thái hệ thống** ({stamp})", "**Dịch vụ**"]
    checks = {}
    metrics = {}
    missing_metrics = []
    alerts = set()
    alerts_available = False
    for label, expression in CHECKS.items():
        try:
            rows = query(base, expression)
            samples = [row["value"][1] for row in rows]
            checks[label] = "OK" if samples and all(value == "1" for value in samples) else (
                "Lỗi" if "0" in samples else "Chưa có dữ liệu")
        except (OSError, ValueError, KeyError, TypeError, IndexError):
            checks[label] = "Không truy vấn được"
    lines.extend(f"- {label}: {state}" for label, state in checks.items())
    lines.append("**Tài nguyên máy chủ / volume**")
    for label, expression in METRICS.items():
        try:
            metrics[label] = _sample_value(query(base, expression))
        except (OSError, ValueError, KeyError, TypeError, IndexError):
            metrics[label] = None
            missing_metrics.append(label)
        lines.append(_format_metric(label, metrics[label]))
    try:
        rows = query(base, CONTAINER_CPU)
        if not rows:
            missing_metrics.append("Top container CPU")
        lines.append("- Top container CPU: " + _format_top(rows, "% CPU"))
    except (OSError, ValueError, KeyError, TypeError, IndexError):
        lines.append("- Top container CPU: Không truy vấn được")
    try:
        rows = query(base, CONTAINER_RAM)
        if not rows:
            missing_metrics.append("Top container RAM")
        rows = [{"metric": row["metric"], "value": [row["value"][0], float(row["value"][1]) / (1024 ** 3)]} for row in rows]
        lines.append("- Top container RAM: " + _format_top(rows, "GiB RAM"))
    except (OSError, ValueError, KeyError, TypeError, IndexError):
        lines.append("- Top container RAM: Không truy vấn được")
    try:
        rows = query(base, 'ALERTS{alertstate="firing"}')
        alerts_available = True
        alerts = {row["metric"].get("alertname", "Alert không tên") for row in rows}
        lines.append("**Cảnh báo đang phát**: " + (", ".join(sorted(alerts)) or "Không có"))
    except (OSError, ValueError, KeyError, TypeError, IndexError):
        lines.append("**Cảnh báo đang phát**: Không truy vấn được")
    lines.append(_analysis(metrics, checks, alerts, missing_metrics, alerts_available))
    lines.append("Ghi chú: phân tích rule-based, không phải AI; số liệu thiếu được báo rõ.")
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
    request = Request(webhook + "?wait=true", data=body,
                     headers={"Content-Type": "application/json", "User-Agent": "SMS Monitoring"})
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
