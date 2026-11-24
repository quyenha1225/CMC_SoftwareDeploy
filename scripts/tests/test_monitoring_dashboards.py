"""Regression tests for Grafana dashboard panel layout."""
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DASHBOARDS = (
    ROOT / "infrastructure/monitoring/grafana/dashboards/sms-infrastructure.json",
    ROOT / "infrastructure/monitoring/grafana/dashboards/sms.json",
)


class DashboardLayoutTests(unittest.TestCase):
    def test_dashboard_json_and_panel_ids_are_valid(self):
        for dashboard in DASHBOARDS:
            with self.subTest(dashboard=dashboard.name):
                data = json.loads(dashboard.read_text(encoding="utf-8"))
                panels = data.get("panels", [])
                ids = [panel.get("id") for panel in panels]
                self.assertTrue(panels, "Dashboard must contain panels")
                self.assertEqual(len(ids), len(set(ids)), "Panel IDs must be unique")

    def test_panels_fit_and_do_not_overlap(self):
        for dashboard in DASHBOARDS:
            with self.subTest(dashboard=dashboard.name):
                data = json.loads(dashboard.read_text(encoding="utf-8"))
                panels = data.get("panels", [])
                for panel in panels:
                    grid = panel.get("gridPos", {})
                    self.assertGreater(grid.get("w", 0), 0)
                    self.assertGreater(grid.get("h", 0), 0)
                    self.assertGreaterEqual(grid.get("x", -1), 0)
                    self.assertGreaterEqual(grid.get("y", -1), 0)
                    self.assertLessEqual(grid.get("x", 0) + grid.get("w", 0), 24,
                                     f"Panel {panel.get('id')} exceeds dashboard width")
                for index, first in enumerate(panels):
                    a = first["gridPos"]
                    for second in panels[index + 1:]:
                        b = second["gridPos"]
                        overlap = (
                            a["x"] < b["x"] + b["w"] and
                            a["x"] + a["w"] > b["x"] and
                            a["y"] < b["y"] + b["h"] and
                            a["y"] + a["h"] > b["y"]
                        )
                        self.assertFalse(
                            overlap,
                            f"Panels {first.get('id')} and {second.get('id')} overlap"
                        )


if __name__ == "__main__":
    unittest.main()
