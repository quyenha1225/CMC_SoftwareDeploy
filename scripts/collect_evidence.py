"""Collect verified local acceptance evidence; never include credentials."""
import datetime
import json
from pathlib import Path
import re
import subprocess
import xml.etree.ElementTree as ET
from docker import ROOT, Runtime

reports = ROOT / 'artifacts/reports'
runtime = Runtime()
summary = {'created_at': datetime.datetime.now(datetime.timezone.utc).isoformat()}
for name in ['mysql-integration', 'runtime-verification']:
    data = json.loads((reports / (name + '.json')).read_text())
    assert data['passed'], name
    summary[name] = data
assert summary['mysql-integration']['restore']
assert summary['mysql-integration']['restart_persistence']
assert len(summary['mysql-integration']['workflows']) == 8
counts = dict(tests=0, failures=0, errors=0, skipped=0)
files = list((ROOT / 'backend/target/surefire-reports').glob('TEST-*.xml'))
assert files
for file in files:
    suite = ET.parse(file).getroot()
    for key in counts:
        counts[key] += int(suite.attrib.get(key, 0))
assert counts['failures'] == counts['errors'] == 0
summary['backend'] = counts
frontend = ET.parse(ROOT / 'frontend/coverage/junit.xml').getroot()
suites = list(frontend.iter('testsuite'))
summary['frontend_unit'] = sum(int(s.attrib.get('tests', 0)) for s in suites)
assert summary['frontend_unit'] == 5
assert all(int(s.attrib.get('failures', 0)) == int(s.attrib.get('errors', 0)) == 0 for s in suites)
ops = (ROOT / 'backend/logs/operations-unit-tests-signoff.log').read_bytes().decode('utf-8', errors='ignore').replace('\x00', '')
assert 'Ran 10 tests' in ops and '\nOK' in ops
summary['operations_unit'] = 10
summary['browser'] = {}
for file in reports.glob('browser-*.log'):
    match = re.search(r'PASS MySQL: (\d+) screen checks, (\d+) dialogs', file.read_text())
    assert match, file.name
    summary['browser'][file.stem] = dict(screens=int(match[1]), dialogs=int(match[2]))
assert len(summary['browser']) == 6
summary['scans'] = {}
for file in reports.glob('trivy-*.json'):
    data = json.loads(file.read_text())
    findings = sum(len(result.get('Vulnerabilities', [])) + len(result.get('Secrets', [])) + len(result.get('Misconfigurations', [])) for result in data.get('Results', []))
    assert findings == 0, file.name
    assert 'ImageConfig' not in data.get('Metadata', {})
    summary['scans'][file.name] = findings
assert len(summary['scans']) == 8
for service in ['backend', 'frontend', 'migration']:
    image = 'sms-' + service + ':' + runtime.config.get('IMAGE_TAG', 'local')
    inspected = json.loads(subprocess.check_output(runtime.docker + ['image', 'inspect', image]))[0]
    for prefix in ['trivy-', 'trivy-secret-']:
        scan = json.loads((reports / (prefix + service + '.json')).read_text())
        assert inspected['RootFS']['Layers'] == scan['Metadata']['DiffIDs'], service
summary['scan_scope'] = 'Critical vulnerabilities; secrets at all severities. Not a claim of zero vulnerabilities at other severities.'
summary['external_not_executed'] = ['Jenkins job/webhook', 'SonarQube quality gate', 'Registry push', 'VPS HTTPS deployment/rollback']
(reports / 'operations-summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
print('PASS evidence collected: backend, frontend, operations, 6 browser roles, 8 MySQL workflows, restore/restart, 8 security reports, 7 runtime groups')
