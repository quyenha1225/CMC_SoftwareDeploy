"""Offline release and retention regression tests; no Docker or network calls."""
import datetime as dt
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import ci_release as release
import docker_retention as retention

COMMIT = 'a' * 40
NOW = dt.datetime.now(dt.timezone.utc)
URL = 'http://localhost:8080/job/SMS-CICD/7/'
IDS = {s: 'sha256:' + str(i) * 64 for i, s in enumerate(release.SERVICES, 1)}
DIGESTS = {s: 'registry.example/sms-' + s + '@' + value for s, value in IDS.items()}


def fixture():
    identity = {'commit': COMMIT, 'dirty': False, 'build_id': '7', 'build_url': URL}
    built = {s: {'id': IDS[s], 'revision': COMMIT} for s in IDS}
    archives = {s: {'id': IDS[s], 'config_id': IDS[s]} for s in IDS}
    sonar = {'commit': COMMIT, 'task_id': 'task', 'analysis_id': 'analysis', 'status': 'OK'}
    values = {'build': identity, 'release': {'commit': COMMIT, 'images': DIGESTS},
              'mysql-integration': {'passed': True, 'image_tag': COMMIT,
                                    'restore': True, 'restart_persistence': True},
              'sonar-evidence': sonar, 'npm-audit': {'metadata': {'vulnerabilities': {'critical': 0}}}}
    for name, data in [('image-identities', built), ('mysql-image-evidence', built),
                       ('scan-archives', archives), ('scan-completed-vuln', archives),
                       ('scan-completed-secret', archives)]:
        values[name] = {'build': identity, 'data': data}
    for prefix in ('trivy', 'trivy-secret'):
        for service in ('filesystem', *release.SERVICES):
            values[prefix + '-' + service] = {'Results': [], 'Metadata': {'ImageID': IDS.get(service)}}
    files = {release.REPORT + name + '.json': json.dumps(value).encode()
             for name, value in values.items()}
    xml = b'<testsuite tests="1" failures="0" errors="0" skipped="0"><testcase name="test"/></testsuite>'
    files[release.FRONTEND_TEST] = xml
    files['backend/target/surefire-reports/TEST-example.xml'] = xml
    manifest = {'schema': 1, 'commit': COMMIT, 'branch': 'quyen/admin',
                'source': {'job': release.OWNER, 'build': '7', 'url': URL, 'mode': 'CI_ONLY'},
                'created_at': NOW.isoformat(), 'images': DIGESTS.copy(), 'image_ids': IDS.copy(),
                'stages': dict.fromkeys(release.STAGES, 'passed'), 'sonar': sonar,
                'scanner': 'aquasec/trivy:0.64.1',
                'policy': {'vulnerability': 'CRITICAL', 'secret': 'UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL',
                           'npm': 'critical'},
                'evidence': {p: release.sha(data) for p, data in files.items()}}
    return manifest, files


class ReleaseTests(unittest.TestCase):
    def check(self, manifest, files, **overrides):
        options = dict(commit=COMMIT, branch='quyen/admin', build_url=URL, now=NOW,
                       age=dt.timedelta(hours=24))
        options.update(overrides)
        return release.validate(manifest, files, **options)

    def test_valid(self):
        self.check(*fixture())

    def test_wrong_commit(self):
        with self.assertRaises(RuntimeError):
            self.check(*fixture(), commit='b' * 40)

    def test_expired(self):
        with self.assertRaises(RuntimeError):
            self.check(*fixture(), now=NOW + dt.timedelta(days=2))

    def test_tampered(self):
        manifest, files = fixture()
        files[release.FRONTEND_TEST] += b' '
        with self.assertRaises(RuntimeError):
            self.check(manifest, files)

    def test_missing_gate(self):
        manifest, files = fixture()
        manifest['stages']['Secret Scan'] = 'failed'
        with self.assertRaises(RuntimeError):
            self.check(manifest, files)

    def test_wrong_image(self):
        manifest, files = fixture()
        manifest['image_ids']['backend'] = 'sha256:' + 'f' * 64
        with self.assertRaises(RuntimeError):
            self.check(manifest, files)

    def test_critical_finding_even_with_updated_checksum(self):
        manifest, files = fixture()
        path = release.REPORT + 'trivy-backend.json'
        value = json.loads(files[path])
        value['Results'] = [{'Vulnerabilities': [{'Severity': 'CRITICAL'}]}]
        files[path] = json.dumps(value).encode()
        manifest['evidence'][path] = release.sha(files[path])
        with self.assertRaises(RuntimeError):
            self.check(manifest, files)

    def test_dirty_source_even_with_updated_checksum(self):
        manifest, files = fixture()
        path = release.REPORT + 'build.json'
        value = json.loads(files[path])
        value['dirty'] = True
        files[path] = json.dumps(value).encode()
        manifest['evidence'][path] = release.sha(files[path])
        with self.assertRaises(RuntimeError):
            self.check(manifest, files)


class RetentionTests(unittest.TestCase):
    def test_protect_used_release_shared_and_unlabeled(self):
        def image(i, tags, revision=COMMIT):
            return {'Id': 'sha256:' + str(i) * 64, 'RepoTags': tags, 'RepoDigests': [],
                    'Created': (NOW - dt.timedelta(days=40)).isoformat(), 'Size': 100,
                    'Config': {'Labels': {'org.opencontainers.image.revision': revision}}}
        tag = 'sms-backend:' + COMMIT
        images = [image(1, [tag]), image(4, [tag]), image(5, [tag, 'other:latest']),
                  image(6, [tag], None), image(7, [tag])]
        found = retention.plan(images, {images[1]['Id']},
                               [{'image_ids': IDS, 'images': DIGESTS}], 30, NOW)
        self.assertEqual([item['id'] for item in found], [images[4]['Id']])

    def test_incomplete_protection_rejected(self):
        with self.assertRaises(RuntimeError):
            retention.plan([], set(), [{'image_ids': {}}], 30, NOW)


if __name__ == '__main__':
    unittest.main()
