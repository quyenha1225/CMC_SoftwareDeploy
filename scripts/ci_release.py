"""Create and promote a Jenkins-owned, immutable release checkpoint.

The Jenkins controller and the reviewed CI job are the trust boundary. A SHA
or an arbitrary manifest from a workspace is not a release authorization.
"""
import base64
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
from urllib.parse import quote, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener
import xml.etree.ElementTree as ET

OWNER = 'SMS-CICD'
BRANCHES = {'quyen/admin', 'develop'}
SERVICES = ('backend', 'frontend', 'migration')
SHA = re.compile(r'[0-9a-f]{40}')
HASH = re.compile(r'[0-9a-f]{64}')
IMAGE_ID = re.compile(r'sha256:[0-9a-f]{64}')
DIGEST = re.compile(r'[a-z0-9._:/-]+@sha256:[0-9a-f]{64}')
REPORT = 'artifacts/reports/'
CHECKPOINT = REPORT + 'verified-release.json'
STAGES = ('Checkout', 'Check Environment', 'Prepare', 'Validate Docker Compose',
          'Backend Test', 'Frontend Test', 'SonarQube Analysis', 'SonarQube Quality Gate',
          'Build Docker Images', 'MySQL Integration Tests', 'Export Scan Images',
          'Dependency and Image Scan', 'Secret Scan')
REQUIRED = {REPORT + name + '.json' for name in (
    'build', 'image-identities', 'mysql-image-evidence', 'mysql-integration',
    'scan-archives', 'scan-completed-vuln', 'scan-completed-secret', 'npm-audit',
    'sonar-evidence', 'release')}
REQUIRED |= {REPORT + prefix + '-' + service + '.json'
             for prefix in ('trivy', 'trivy-secret')
             for service in ('filesystem', *SERVICES)}
FRONTEND_TEST = 'frontend/coverage/junit.xml'
BACKEND_TEST = re.compile(r'backend/target/surefire-reports/[^/\\]+\.xml')
MAX_FILE = 32 * 1024 * 1024
MAX_TOTAL = 128 * 1024 * 1024


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def read_bytes(path):
    require(path.is_file() and not path.is_symlink(), 'Missing release evidence: ' + path.name)
    require(path.stat().st_size <= MAX_FILE, 'Release evidence exceeds file limit')
    return path.read_bytes()


def atomic_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(value, indent=2, sort_keys=True), encoding='utf-8')
    temporary.replace(path)


def controller(env):
    value = env.get('JENKINS_URL', '').rstrip('/')
    url = urlsplit(value)
    require(bool(url.hostname) and not (url.username or url.password or url.query or url.fragment)
            and (url.scheme == 'https' or
                 (url.scheme == 'http' and url.hostname in ('localhost', '127.0.0.1', '::1'))),
            'Configure a trusted JENKINS_URL (HTTPS or loopback HTTP)')
    return value


def source_url(env, build):
    require(isinstance(build, str) and re.fullmatch(r'[1-9][0-9]{0,9}', build),
            'An exact positive CI release build number is required')
    return controller(env) + '/job/' + OWNER + '/' + build + '/'


def max_age(env):
    raw = env.get('SMS_RELEASE_MAX_AGE_HOURS', '24')
    require(raw.isdecimal() and 1 <= int(raw) <= 168, 'Invalid release age policy (1–168 hours)')
    return dt.timedelta(hours=int(raw))


def evidence_paths(root):
    paths = set(REQUIRED) | {FRONTEND_TEST}
    paths.update(p.relative_to(root).as_posix()
                 for p in (root / 'backend/target/surefire-reports').glob('*.xml'))
    require(any(BACKEND_TEST.fullmatch(p) for p in paths), 'Backend JUnit evidence missing')
    return sorted(paths)


def decode(data):
    return json.loads(data.decode('utf-8-sig'))


def validate(manifest, files, *, commit, branch, build_url, now, age):
    require(isinstance(manifest, dict) and manifest.get('schema') == 1,
            'Unsupported release checkpoint')
    require(bool(SHA.fullmatch(commit)) and manifest.get('commit') == commit
            and branch in BRANCHES and manifest.get('branch') == branch,
            'Release commit or branch differs from the clean checkout')
    source = manifest.get('source', {})
    require(source.get('job') == OWNER and source.get('url') == build_url
            and source.get('build') == build_url.rstrip('/').rsplit('/', 1)[-1]
            and source.get('mode') in ('FULL', 'CI_ONLY'), 'Untrusted release source')
    created = dt.datetime.fromisoformat(manifest['created_at'])
    require(created.tzinfo is not None and dt.timedelta() <= now - created <= age,
            'Release scan evidence has expired or is dated in the future')
    require(manifest.get('stages') == {stage: 'passed' for stage in STAGES},
            'A required CI stage did not pass')
    require(manifest.get('policy') == {'vulnerability': 'CRITICAL',
                'secret': 'UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL', 'npm': 'critical'},
            'Unexpected security policy')
    require(bool(re.fullmatch(r'[a-zA-Z0-9._:/@-]+', manifest.get('scanner', ''))),
            'Missing scanner identity')
    checks = manifest.get('evidence', {})
    require(isinstance(checks, dict) and REQUIRED | {FRONTEND_TEST} <= set(checks)
            and any(BACKEND_TEST.fullmatch(p) for p in checks)
            and all(p in REQUIRED or p == FRONTEND_TEST or BACKEND_TEST.fullmatch(p)
                    for p in checks)
            and set(files) == set(checks) and len(checks) <= 300,
            'Required release evidence is incomplete or unexpected')
    require(sum(map(len, files.values())) <= MAX_TOTAL, 'Release evidence exceeds total limit')
    for path, value in checks.items():
        require(isinstance(value, str) and HASH.fullmatch(value) and sha(files[path]) == value,
                'Evidence checksum mismatch: ' + path)
    def report(name):
        return decode(files[REPORT + name + '.json'])
    identity = report('build')
    require(identity == {'commit': commit, 'dirty': False, 'build_id': source['build'],
                         'build_url': build_url}, 'Release build identity is not clean or trusted')
    images = manifest.get('images', {})
    ids = manifest.get('image_ids', {})
    require(set(images) == set(ids) == set(SERVICES)
            and all(isinstance(x, str) and DIGEST.fullmatch(x) for x in images.values())
            and all(isinstance(x, str) and IMAGE_ID.fullmatch(x) for x in ids.values()),
            'Three immutable published image digests and config IDs are required')
    require(report('release') == {'commit': commit, 'images': images},
            'Published release manifest differs from the checkpoint')
    def bound(name):
        value = report(name)
        require(value.get('build') == identity, 'Evidence belongs to a different build: ' + name)
        return value['data']
    built = bound('image-identities')
    require(set(built) == set(SERVICES)
            and all(built[s]['id'] == ids[s] and built[s]['revision'] == commit for s in SERVICES),
            'Built images do not match the release')
    require(bound('mysql-image-evidence') == built, 'Integration tested different images')
    integration = report('mysql-integration')
    require(integration.get('passed') is True and integration.get('image_tag') == commit
            and integration.get('restore') is True and integration.get('restart_persistence') is True,
            'Integration test evidence is incomplete')
    archives = bound('scan-archives')
    require(set(archives) == set(SERVICES)
            and all(archives[s]['id'] == ids[s] for s in SERVICES),
            'Scan archives do not match built images')
    for scanner, prefix in (('vuln', 'trivy'), ('secret', 'trivy-secret')):
        require(bound('scan-completed-' + scanner) == archives, 'Scan checkpoint missing: ' + scanner)
        for service in SERVICES:
            require(report(prefix + '-' + service).get('Metadata', {}).get('ImageID')
                    == archives[service]['config_id'] == ids[service], 'Scanned image differs: ' + service)
        for service in ('filesystem', *SERVICES):
            scan = report(prefix + '-' + service)
            require(isinstance(scan.get('Results'), list) or scan.get('Results') is None,
                    'Invalid scan report')
            for result in scan.get('Results') or []:
                if scanner == 'secret':
                    require(not result.get('Secrets'), 'Secret finding in release evidence')
                else:
                    require(not any(v.get('Severity') == 'CRITICAL'
                                    for v in result.get('Vulnerabilities') or []),
                            'Critical vulnerability in release evidence')
    audit = report('npm-audit')
    require(audit.get('metadata', {}).get('vulnerabilities', {}).get('critical') == 0,
            'npm critical vulnerability evidence missing or failed')
    sonar = report('sonar-evidence')
    require(sonar == manifest.get('sonar') and sonar.get('status') == 'OK'
            and sonar.get('commit') == commit and bool(sonar.get('task_id'))
            and bool(sonar.get('analysis_id')), 'Sonar evidence missing or mismatched')
    for group in ([FRONTEND_TEST], [p for p in checks if BACKEND_TEST.fullmatch(p)]):
        total = 0
        for path in group:
            xml = ET.fromstring(files[path])
            suites = [xml] if xml.tag == 'testsuite' else list(xml.iter('testsuite'))
            for suite in suites:
                require(int(suite.get('failures', 0)) == 0 and int(suite.get('errors', 0)) == 0,
                        'JUnit contains a failure: ' + path)
                total += int(suite.get('tests', 0)) - int(suite.get('skipped', 0))
        require(total > 0, 'JUnit evidence contains no executed tests')
    return manifest


def seal(root, identity, built, env):
    require(env.get('JOB_NAME') == OWNER and env.get('SMS_PIPELINE_MODE') in ('FULL', 'CI_ONLY')
            and not env.get('CHANGE_ID') and not env.get('TAG_NAME')
            and env.get('QUALITY_GATE_PASSED') == 'true' and env.get('SMS_CI_COMPLETED') == 'true',
            'Only the approved CI owner may seal a release after all gates')
    build_url = source_url(env, identity['build_id'])
    require(identity['build_url'].rstrip('/') + '/' == build_url and not identity['dirty'],
            'CI identity does not match its trusted Jenkins build URL')
    files = {path: read_bytes(root / path) for path in evidence_paths(root)}
    release = decode(files[REPORT + 'release.json'])
    now = dt.datetime.now(dt.timezone.utc)
    manifest = {'schema': 1, 'commit': identity['commit'], 'branch': env['SMS_CHECKOUT_BRANCH'],
                'source': {'job': OWNER, 'build': identity['build_id'], 'url': build_url,
                           'mode': env['SMS_PIPELINE_MODE']},
                'created_at': now.isoformat(), 'images': release['images'],
                'image_ids': {s: built[s]['id'] for s in SERVICES},
                'stages': {s: env.get('SMS_STAGE_' + s.replace(' ', '_')) for s in STAGES},
                'policy': {'vulnerability': 'CRITICAL', 'secret': 'UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL',
                           'npm': 'critical'},
                'scanner': env.get('TRIVY_IMAGE', 'aquasec/trivy:0.64.1'),
                'sonar': decode(files[REPORT + 'sonar-evidence.json']),
                'evidence': {p: sha(data) for p, data in files.items()}}
    validate(manifest, files, commit=identity['commit'], branch=env['SMS_CHECKOUT_BRANCH'],
             build_url=build_url, now=now, age=max_age(env))
    atomic_json(root / CHECKPOINT, manifest)
    return manifest


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def fetcher(env, url):
    # Only a controller-provided URL and fixed CI job are accepted. Never follow redirects.
    auth = base64.b64encode((env['SMS_JENKINS_CONSOLE_USER'] + ':' +
                             env['SMS_JENKINS_CONSOLE_TOKEN']).encode()).decode('ascii')
    opener = build_opener(NoRedirect)
    def get(relative):
        request = Request(url + relative, headers={'Authorization': 'Basic ' + auth})
        with opener.open(request, timeout=20) as response:
            data = response.read(MAX_FILE + 1)
        require(len(data) <= MAX_FILE, 'Jenkins artifact exceeds file limit')
        return data
    return get


def promote(root, env, *, get=None):
    commit, branch = env.get('IMAGE_TAG', ''), env.get('SMS_CHECKOUT_BRANCH', '')
    require(env.get('RELEASE_SHA') == commit and bool(SHA.fullmatch(commit)),
            'RELEASE_SHA must match the exact checked-out commit')
    url = source_url(env, env.get('RELEASE_BUILD'))
    get = get or fetcher(env, url)
    metadata = decode(get('api/json?tree=number,building,result,url,artifacts%5BrelativePath%5D'))
    require(metadata.get('building') is False and metadata.get('url', '').rstrip('/') + '/' == url
            and str(metadata.get('number')) == env['RELEASE_BUILD']
            and metadata.get('result') in ('SUCCESS', 'FAILURE'), 'CI source has not completed')
    archived = {entry['relativePath'] for entry in metadata.get('artifacts', [])}
    require(CHECKPOINT in archived, 'CI build has no approved release checkpoint')
    manifest = decode(get('artifact/' + CHECKPOINT))
    if metadata['result'] == 'FAILURE':
        require(manifest.get('source', {}).get('mode') == 'FULL',
                'A failed CI_ONLY build cannot be promoted')
    checks = manifest.get('evidence', {})
    require(isinstance(checks, dict) and len(checks) <= 300
            and all(p in archived and (p in REQUIRED or p == FRONTEND_TEST or BACKEND_TEST.fullmatch(p))
                    for p in checks), 'Unexpected or missing archived release evidence')
    files, size = {}, 0
    for path in checks:
        data = get('artifact/' + quote(path, safe='/'))
        size += len(data)
        require(size <= MAX_TOTAL, 'Release evidence exceeds total limit')
        files[path] = data
    validate(manifest, files, commit=commit, branch=branch, build_url=url,
             now=dt.datetime.now(dt.timezone.utc), age=max_age(env))
    evidence_root = root / REPORT / 'promoted-evidence'
    require(not evidence_root.exists(), 'Promotion evidence directory already exists')
    for path, data in files.items():
        destination = evidence_root / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
    atomic_json(root / REPORT / 'release.json', {'commit': commit, 'images': manifest['images']})
    atomic_json(root / CHECKPOINT, manifest)
    print('Verified release imported from CI build #' + env['RELEASE_BUILD'])
    return manifest


def verify_local(root, env):
    manifest = decode(read_bytes(root / CHECKPOINT))
    imported = env.get('SMS_PIPELINE_MODE') in ('DEPLOY_LOCAL_ONLY', 'DEPLOY_SERVER_ONLY')
    build = env.get('RELEASE_BUILD') if imported else env.get('BUILD_NUMBER')
    url = source_url(env, build)
    if imported:
        require(env.get('RELEASE_SHA') == env.get('IMAGE_TAG'), 'Promotion SHA changed')
    source = root / REPORT / 'promoted-evidence' if imported else root
    checks = manifest.get('evidence', {})
    require(isinstance(checks, dict) and len(checks) <= 300
            and all(p in REQUIRED or p == FRONTEND_TEST or BACKEND_TEST.fullmatch(p) for p in checks),
            'Unexpected release evidence paths')
    files = {path: read_bytes(source / path) for path in checks}
    validate(manifest, files, commit=env['IMAGE_TAG'], branch=env['SMS_CHECKOUT_BRANCH'],
             build_url=url, now=dt.datetime.now(dt.timezone.utc), age=max_age(env))
    require(decode(read_bytes(root / REPORT / 'release.json')) ==
            {'commit': manifest['commit'], 'images': manifest['images']},
            'Deployment manifest was changed after verification')
    return manifest


def pin_published(manifest, docker, root):
    # Compose gets immutable local IDs only after verifying the corresponding registry digest.
    for service in SERVICES:
        digest = manifest['images'][service]
        inspect = docker + ['image', 'inspect', digest, '--format', '{{.Id}}']
        result = subprocess.run(inspect, cwd=root, capture_output=True, text=True)
        if result.returncode:
            subprocess.run(docker + ['pull', digest], cwd=root, check=True)
            result = subprocess.run(inspect, cwd=root, capture_output=True, text=True, check=True)
        require(result.stdout.strip() == manifest['image_ids'][service],
                'Published digest does not identify the tested image: ' + service)
        os.environ['SMS_CI_' + service.upper() + '_IMAGE'] = manifest['image_ids'][service]
