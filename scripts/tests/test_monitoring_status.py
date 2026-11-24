"""Unit tests for the Prometheus-to-Discord status report."""
import unittest
from unittest.mock import patch

import monitoring_status as monitor


def sample(value, labels=None):
    return {"metric": labels or {}, "value": [0, str(value)]}


class MonitoringStatusTests(unittest.TestCase):
    def test_report_includes_health_resource_and_container_sections(self):
        def fake_query(base, expression):
            if expression in monitor.CHECKS.values():
                return [sample(1)]
            if expression == monitor.CONTAINER_CPU:
                return [sample(12.4, {"name": "sms-backend"})]
            if expression == monitor.CONTAINER_RAM:
                return [sample(1024 ** 3, {"name": "sms-backend"})]
            if expression == 'ALERTS{alertstate="firing"}':
                return []
            if expression == monitor.METRICS["CPU máy chủ"]:
                return [sample(22.5)]
            if expression == monitor.METRICS["RAM đã dùng"]:
                return [sample(58.0)]
            if expression == monitor.METRICS["Ổ đĩa root đã dùng"]:
                return [sample(63.2)]
            if expression == monitor.METRICS["Uptime (giây)"]:
                return [sample(90061)]
            if expression == monitor.METRICS["Load average 1m"]:
                return [sample(1.4)]
            if expression == monitor.METRICS["Container đang thấy"]:
                return [sample(5)]
            if expression == monitor.METRICS["MySQL volume (bytes)"]:
                return [sample(2 * 1024 ** 3, {"volume": "mysql_data"})]
            if expression == monitor.METRICS["Private files volume (bytes)"]:
                return [sample(512 * 1024 ** 2, {"volume": "private_files"})]
            raise AssertionError("Unexpected PromQL: " + expression)

        with patch.object(monitor, "query", side_effect=fake_query):
            output = monitor.report("http://prometheus")
        self.assertIn("Frontend /healthz: OK", output)
        self.assertIn("CPU máy chủ: 22.5%", output)
        self.assertIn("RAM đã dùng: 58.0%", output)
        self.assertIn("Ổ đĩa root đã dùng: 63.2%", output)
        self.assertIn("1 ngày 1 giờ 1 phút", output)
        self.assertIn("MySQL volume (bytes): 2.00 GiB", output)
        self.assertIn("Top container CPU: sms-backend: 12.4 % CPU", output)
        self.assertIn("Top container RAM: sms-backend: 1.0 GiB RAM", output)
        self.assertIn("Phân tích: Chưa thấy vấn đề", output)
        self.assertIn("rule-based, không phải AI", output)

    def test_report_does_not_hide_failed_metric_queries(self):
        def fake_query(base, expression):
            if expression in monitor.CHECKS.values():
                return [sample(1)]
            if expression == 'ALERTS{alertstate="firing"}':
                return []
            if expression == monitor.CONTAINER_CPU or expression == monitor.CONTAINER_RAM:
                return []
            raise OSError("Prometheus unreachable")
        with patch.object(monitor, "query", side_effect=fake_query):
            output = monitor.report("http://prometheus")
        self.assertIn("CPU máy chủ: Không có dữ liệu", output)
        self.assertIn("Ổ đĩa root đã dùng: Không có dữ liệu", output)
        self.assertIn("Top container CPU: Không có dữ liệu", output)
        self.assertIn("Phân tích/rủi ro: Thiếu số liệu", output)

    def test_analysis_flags_high_resources_and_failed_probe(self):
        values = {"CPU máy chủ": 95, "RAM đã dùng": 91, "Ổ đĩa root đã dùng": 88}
        checks = {"Frontend /healthz": "Lỗi", "Backend readiness": "OK", "MySQL TCP": "OK"}
        message = monitor._analysis(values, checks, {"HostCPUHigh"})
        self.assertIn("Frontend /healthz lỗi", message)
        self.assertIn("CPU máy chủ cao", message)
        self.assertIn("RAM đã dùng cao", message)
        self.assertIn("Ổ đĩa root đã dùng cao", message)
        self.assertIn("alert firing", message)

    def test_bytes_and_uptime_format(self):
        self.assertIn("1.50 GiB", monitor._format_metric("MySQL volume (bytes)", 1.5 * 1024 ** 3))
        self.assertIn("0 ngày 0 giờ 0 phút", monitor._format_metric("Uptime (giây)", 59))
        self.assertIn("Không có dữ liệu", monitor._format_metric("CPU máy chủ", None))


if __name__ == "__main__":
    unittest.main()
