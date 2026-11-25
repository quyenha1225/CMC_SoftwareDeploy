"""Build-scoped inputs, Docker identities and scan archives for the Jenkins run."""

from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess
import tarfile
import tempfile
import zipfile


DOCKERFILES = {
    'backend': 'backend/Dockerfile',
    'frontend': 'frontend/Dockerfile',
    'migration': 'infrastructure/migration/Dockerfile',
}
DIGEST = re.compile(r'sha256:[0-9a-f]{64}')


def sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


class BuildArtifacts:
    def __init__(self, root, reports, identity, docker):
        self.root, self.reports, self.identity, self.docker = root, reports, identity, docker
        key = hashlib.sha256(json.dumps(identity, sort_keys=True).encode()).hexdigest()
        self.work = reports.parent / 'ci-assets' / key

    def write(self, name, data):
        path = self.reports / (name + '.json')
        with path.with_suffix('.tmp').open('w', encoding='utf-8') as stream:
            json.dump({'build': self.identity, 'data': data}, stream, indent=2)
        path.with_suffix('.tmp').replace(path)

    def read(self, name):
        report = json.loads((self.reports / (name + '.json')).read_text(encoding='utf-8'))
        if report['build'] != self.identity:
            raise RuntimeError('Artifact belongs to a different build: ' + name)
        return report['data']

    def inputs(self, service):
        if service == 'backend':
            jar = self.root / 'backend/target/backend-0.0.1-SNAPSHOT.jar'
            if jar.is_symlink():
                raise RuntimeError('The CI JAR cannot be a symbolic link')
            with zipfile.ZipFile(jar) as archive:
                name = 'BOOT-INF/classes/com/sms/backend/'
                version = archive.read(name + 'BackendApplication.class')[6:8]
                if version != b'\x00A' or name + 'bootstrap/DemoProvisioner.class' not in archive.namelist():
                    raise RuntimeError('Expected the Java 21 Spring Boot JAR with DemoProvisioner')
            return {'backend.jar': jar}
        dist = self.root / 'frontend/dist'
        if dist.is_symlink() or not (dist / 'index.html').is_file():
            raise RuntimeError('Expected a Vite production dist with index.html')
        files = {}
        for path in sorted(dist.rglob('*')):
            relative = path.relative_to(dist)
            if path.is_symlink() or any(p.startswith('.') for p in relative.parts):
                raise RuntimeError('Unexpected hidden file or symlink in the frontend artifact')
            if path.is_file():
                if path.suffix.lower() not in {'.html', '.js', '.css', '.svg', '.jpg', '.jpeg',
                                               '.png', '.webp', '.ico', '.woff', '.woff2', '.gif', '.avif'}:
                    raise RuntimeError('Unexpected file type in the frontend artifact: ' + relative.as_posix())
                files[relative.as_posix()] = path
        return files

    def record_input(self, service):
        self.write('input-' + service, {name: sha256(path) for name, path in self.inputs(service).items()})

    def stage_input(self, service, destination):
        paths = self.inputs(service)
        expected = self.read('input-' + service)
        if set(paths) != set(expected):
            raise RuntimeError('Build input file list changed: ' + service)
        destination.mkdir()
        for name, source in paths.items():
            target = destination / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
            if sha256(target) != expected[name]:
                raise RuntimeError('Build input checksum changed: ' + service + '/' + name)

    def inspect(self, reference):
        raw = subprocess.check_output(self.docker + ['image', 'inspect', reference], cwd=self.root)
        image = json.loads(raw)[0]
        if not DIGEST.fullmatch(image['Id']) or image['Os'] != 'linux':
            raise RuntimeError('Expected an immutable Linux Docker image ID')
        return {'id': image['Id'], 'layers': image['RootFS']['Layers'], 'size': image['Size'],
                'architecture': image['Architecture'], 'revision': image['Config']['Labels'].get(
                    'org.opencontainers.image.revision'), 'digests': image.get('RepoDigests') or []}

    def build_images(self, build, run, record):
        self.work.mkdir(parents=True, exist_ok=True)
        images = {}
        with tempfile.TemporaryDirectory(prefix='package-', dir=self.work) as folder:
            package = Path(folder)
            for service, path in DOCKERFILES.items():
                record('Docker image packaging: ' + service)
                arguments = []
                if service != 'migration':
                    context = package / service
                    self.stage_input(service, context)
                    arguments = ['--target', 'ci-runtime', '--build-context', f'ci_artifact={context.as_posix()}']
                iid = package / (service + '.iid')
                tag = self.identity['commit']
                run(build + arguments + ['--iidfile', str(iid), '--label',
                    'org.opencontainers.image.revision=' + tag, '-f', path, '-t', f'sms-{service}:{tag}', '.'])
                image_id = iid.read_text(encoding='utf-8').strip()
                image = self.inspect(image_id)
                if image['id'] != image_id or image['revision'] != tag:
                    raise RuntimeError('Built image does not match its release identity: ' + service)
                image.pop('digests')
                images[service] = image
        if len({image['architecture'] for image in images.values()}) != 1:
            raise RuntimeError('Release images must use the same Linux CPU architecture')
        self.write('image-identities', images)

    def pin_images(self):
        images = self.read('image-identities')
        if set(images) != set(DOCKERFILES):
            raise RuntimeError('Expected exactly three recorded images')
        for service, expected in images.items():
            current = self.inspect(expected['id'])
            current.pop('digests')
            if current != expected:
                raise RuntimeError('Build image identity changed: ' + service)
            os.environ['SMS_CI_' + service.upper() + '_IMAGE'] = expected['id']
        return images

    def verify_runtime_images(self, runtime, expected):
        """Check actual Compose containers, not just the tags requested at startup."""
        if set(expected) != set(DOCKERFILES):
            raise RuntimeError('Expected three CI images')
        if not runtime.config.get('COMPOSE_PROJECT_NAME', '').startswith('sms_ci_'):
            raise RuntimeError('Runtime image verification requires an isolated CI project')
        actual = {}
        for service in DOCKERFILES:
            compose_service = 'migrate' if service == 'migration' else service
            containers = runtime.run('ps', '--all', '--quiet', compose_service, capture=True).splitlines()
            if len(containers) != 1:
                raise RuntimeError('Expected exactly one CI container: ' + compose_service)
            raw = subprocess.check_output(
                runtime.docker + ['inspect', containers[0]], cwd=self.root)
            container = json.loads(raw)[0]
            labels = container['Config']['Labels']
            if (labels.get('com.docker.compose.project') != runtime.config['COMPOSE_PROJECT_NAME']
                    or labels.get('com.docker.compose.service') != compose_service
                    or container['Image'] != expected[service]['id']):
                raise RuntimeError('CI runtime image differs from the built image: ' + service)
            actual[service] = container['Image']
        return actual

    def export_scans(self, run, record):
        images = self.pin_images()
        directory = self.work / 'scans'
        directory.mkdir(parents=True, exist_ok=False)
        required = sum(image['size'] for image in images.values()) * 2 + 256 * 1024 * 1024
        free = shutil.disk_usage(directory).free
        record(f'Check scan disk space ({free} bytes free, {required} bytes required)')
        if free < required:
            raise RuntimeError('Insufficient disk space for the three temporary scan archives')
        records = {}
        for service, image in images.items():
            record('Export immutable image once: ' + service)
            path = directory / (service + '.tar')
            run(self.docker + ['save', '-o', str(path), image['id']])
            with tarfile.open(path, 'r:') as archive:
                entries = json.load(archive.extractfile('manifest.json'))
                if len(entries) != 1:
                    raise RuntimeError('Expected one image in the scan archive: ' + service)
                config = archive.extractfile(entries[0]['Config']).read()
            exported = json.loads(config)
            if (exported['rootfs']['diff_ids'] != image['layers']
                    or exported.get('os') != 'linux'
                    or exported.get('architecture') != image['architecture']
                    or (exported.get('config', {}).get('Labels') or {}).get(
                        'org.opencontainers.image.revision') != image['revision']):
                raise RuntimeError('Scan archive does not match the built image identity: ' + service)
            records[service] = {'id': image['id'], 'sha256': sha256(path), 'size': path.stat().st_size,
                                'config_id': 'sha256:' + hashlib.sha256(config).hexdigest()}
        self.write('scan-archives', records)

    def scan_input(self, service):
        entry = self.read('scan-archives')[service]
        image = self.read('image-identities')[service]
        path = self.work / 'scans' / (service + '.tar')
        if entry['id'] != image['id'] or path.stat().st_size != entry['size'] or sha256(path) != entry['sha256']:
            raise RuntimeError('Scan input failed verification: ' + service)
        return path, entry

    def verify_gate_images(self):
        images = self.pin_images()
        if self.read('mysql-image-evidence') != images:
            raise RuntimeError('MySQL integration was not completed against these images')
        archives = self.read('scan-archives')
        for scanner in ('vuln', 'secret'):
            if self.read('scan-completed-' + scanner) != archives:
                raise RuntimeError('Required image scan evidence is missing or stale: ' + scanner)
        return images

    def cleanup(self):
        if self.work.is_symlink() or not self.work.resolve().is_relative_to(self.reports.parent.resolve()):
            raise RuntimeError('Refusing cleanup outside the CI workspace')
        if self.work.exists():
            shutil.rmtree(self.work)
