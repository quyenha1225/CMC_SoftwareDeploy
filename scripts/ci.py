"""Cross-platform commands used by Jenkins; no secrets appear in command arguments."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import datetime as dt
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
from uuid import uuid4
from ci_artifacts import BuildArtifacts, DOCKERFILES
from docker import (ROOT, Runtime, initialize, invoke, smoke, backup, restore_test, docker_command,
                    settings, prepare_demo_deployment, verify_demo_after_rollout)
from jenkins_reports import redact, timing_event

REPORTS=ROOT/'artifacts/reports'
REPORTS.mkdir(parents=True,exist_ok=True)
WIN=os.name=='nt'
MVN=str(ROOT/'backend'/('mvnw.cmd' if WIN else 'mvnw'))
MAVEN=[MVN] if WIN else ['sh',MVN]
NPM='npm.cmd' if WIN else 'npm'

def record_check(label):
    print('CI check: ' + label, flush=True)
    timing_event(label)
    destination = os.getenv('SMS_CI_DETAIL_FILE')
    if destination:
        try:
            path = Path(destination)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(label + '\n', encoding='utf-8')
        except OSError:
            print('CI could not record the current check for Discord.', file=sys.stderr)

def run(command,directory=None,*,track_maven=False,**kwargs):
    # Log only the executable: command arguments can include sensitive values.
    started = time.monotonic()
    label = str(command[0])
    if command[:2] == ['node', 'tests/browser-full-ui.mjs']:
        label += ' browser role=' + kwargs.get('env', {}).get('SMS_UI_ROLE', 'unknown')
    print('CI start: ' + label, flush=True)
    if track_maven and os.getenv('SMS_CI_DETAIL_FILE'):
        with subprocess.Popen(command,cwd=directory or ROOT,stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT,**kwargs) as result:
            for line in result.stdout:
                sys.stdout.buffer.write(line)
                sys.stdout.buffer.flush()
                goal=re.search(rb'--- ([a-z0-9-]+):[a-zA-Z0-9.\-]+:([a-z0-9-]+) \(',line)
                if goal:
                    record_check('Backend Maven goal: ' + ':'.join(
                        part.decode('ascii') for part in goal.groups()))
            result.wait()
    else:
        result=subprocess.run(command,cwd=directory or ROOT,**kwargs)
    elapsed = time.monotonic() - started
    print(f'CI finish: {label} elapsed={elapsed:.1f}s exit={result.returncode}', flush=True)
    if result.returncode:
        code = result.returncode & 0xffffffff
        raise RuntimeError(f'CI command failed: {command[0]} (exit {result.returncode}, hex 0x{code:08X}). See preceding output; subsequent gates remain blocked.')
    return result

def scan_report(command,path):
    result=subprocess.run(command,cwd=ROOT,capture_output=True)
    if result.stderr:print(result.stderr.decode('utf-8','replace'),file=sys.stderr)
    try:report=json.loads(result.stdout)
    except json.JSONDecodeError:raise RuntimeError('Scanner did not produce a complete JSON report')
    # Do not publish detected secret values or image environment values in Jenkins artifacts.
    report.get('Metadata',{}).pop('ImageConfig',None)
    for target in report.get('Results',[]):
        for finding in target.get('Secrets',[]):
            finding.pop('Match',None);finding.pop('Code',None)
    path.write_text(json.dumps(report,indent=2),encoding='utf-8')
    if result.returncode:raise RuntimeError('Security gate failed: '+path.name)
    return report

def ci_build_command():
    docker = docker_command()
    builder = os.getenv('SMS_CI_BUILDER')
    if not builder:
        return docker + ['build']
    if not re.fullmatch(r'[a-zA-Z0-9][a-zA-Z0-9_.-]*', builder):
        raise RuntimeError('Invalid SMS_CI_BUILDER name')

    record_check('Start the dedicated Docker BuildKit builder: ' + builder)
    if len(docker) > 1:
        endpoint = docker[-1]
    else:
        endpoint = os.getenv('DOCKER_CONTEXT') or os.getenv('DOCKER_HOST')
        if not endpoint:
            endpoint = subprocess.check_output(docker + ['context', 'show'], cwd=ROOT, text=True).strip()

    buildx = docker + ['buildx']
    inspected = subprocess.run(buildx + ['inspect', builder], cwd=ROOT, capture_output=True, text=True)
    if inspected.returncode:
        run(buildx + ['create', '--name', builder, '--driver', 'docker-container',
                      '--driver-opt', 'env.CONTAINERD_DISABLE_PIGZ=1', endpoint])
    else:
        driver = re.findall(r'^Driver:\s+(.+)$', inspected.stdout, re.MULTILINE)
        endpoints = re.findall(r'^Endpoint:\s+(.+)$', inspected.stdout, re.MULTILINE)
        if driver != ['docker-container'] or endpoints != [endpoint]:
            raise RuntimeError(f'Builder {builder} is not a docker-container builder for {endpoint}. '
                               'Use a different SMS_CI_BUILDER name for this Docker endpoint.')
        if not re.search(r'^Driver Options:.*\benv\.CONTAINERD_DISABLE_PIGZ="1"(?:\s|$)',
                         inspected.stdout, re.MULTILINE):
            raise RuntimeError(f'Builder {builder} is missing the CI decompression setting. '
                               'Choose an unused SMS_CI_BUILDER name to create it with the correct settings.')
    run(buildx + ['inspect', '--bootstrap', builder])
    return buildx + ['build', '--builder', builder, '--load']


def local_deploy_runtime(*, require_existing=False):
    docker = docker_command()
    project = 'sms_local'
    database_ids = invoke(docker + [
        'ps', '-aq', '--filter', f'label=com.docker.compose.project={project}',
        '--filter', 'label=com.docker.compose.service=db',
    ], capture=True).splitlines()
    if len(database_ids) > 1:
        raise RuntimeError('More than one database container matches the local deployment.')
    if require_existing and not database_ids:
        raise RuntimeError('The existing local Compose database was not found.')

    project_directory = ROOT
    database = None
    if database_ids:
        database = json.loads(invoke(docker + ['inspect', database_ids[0]], capture=True))[0]
        working_dir = database['Config']['Labels'].get('com.docker.compose.project.working_dir')
        if not working_dir or not Path(working_dir).is_absolute():
            raise RuntimeError('Cannot determine the existing local Compose project directory.')
        project_directory = Path(working_dir)

    env_file = project_directory / '.env'
    if not env_file.is_file():
        if database:
            raise RuntimeError('The existing local database has no accessible .env in its Compose directory.')
        initialize(env_file)

    runtime = Runtime(env_file, project_directory=project_directory)
    if (runtime.config.get('COMPOSE_PROJECT_NAME', project) != project
            or runtime.config.get('SMS_ENVIRONMENT', 'local') != 'local'):
        raise RuntimeError('The local deployment requires the sms_local project configuration.')
    if database:
        mounts = {mount['Destination']: mount['Source'] for mount in database['Mounts']}
        for name in ('mysql_root_password', 'db_password', 'migrator_password'):
            source = mounts.get('/run/secrets/' + name)
            if not source or Path(source).resolve() != runtime.secret_dir / name:
                raise RuntimeError('The local deployment secret directory differs from the database mounts.')
    runtime.compose += ['--project-name', project]
    return runtime


def deploy_local():
    if not re.fullmatch(r'[0-9a-f]{40}', os.getenv('IMAGE_TAG', '')):
        raise RuntimeError('Local CI deployment requires the full checked-out commit SHA.')

    record_check('Resolve and validate the existing local Docker configuration')
    runtime = local_deploy_runtime()
    print('Local deployment target sms_local, environment file: ' + str(runtime.env_file), flush=True)
    os.environ['SMS_SECRETS_DIR'] = runtime.secret_dir.as_posix()
    runtime.run('config', '--quiet')
    running = runtime.run('ps', '--status', 'running', '--services', 'db', 'backend', capture=True).splitlines()
    if {'db', 'backend'}.issubset(running):
        record_check('Back up local database and files')
        backup(runtime)

    prepare_demo_deployment(runtime, record_check)
    record_check('Start frontend and backend, wait for health checks')
    runtime.run('up', '-d', '--no-build', '--wait', '--wait-timeout', '300', 'frontend', 'backend')
    record_check('Revalidate local demo credentials after rollout')
    verify_demo_after_rollout(runtime)
    record_check('Run HTTP, role login and SQL smoke checks')
    smoke(runtime)
    record_check('Deploy Prometheus, Grafana, Alertmanager and infrastructure exporters')
    monitoring = ROOT / 'infrastructure/monitoring'
    revision = hashlib.sha256()
    for config in sorted(path for path in monitoring.iterdir() if path.is_file()):
        revision.update(config.name.encode())
        revision.update(hashlib.sha256(config.read_bytes()).digest())
    os.environ['SMS_MONITORING_DIR'] = monitoring.as_posix()
    os.environ['SMS_MONITORING_REVISION'] = revision.hexdigest()
    overlay = ('-f', str(ROOT / 'compose.monitoring.yaml'), '--profile', 'monitoring')
    runtime.run(*overlay, 'up', '-d', '--no-build', '--wait', '--wait-timeout', '180',
                'prometheus', 'grafana', 'alertmanager', 'blackbox', 'cadvisor', 'node-exporter', 'volume-size')
    record_check('Read Docker container status')
    runtime.run(*overlay, 'ps')


def collect_local_logs():
    runtime = local_deploy_runtime(require_existing=True)
    os.environ['SMS_SECRETS_DIR'] = runtime.secret_dir.as_posix()
    result = subprocess.run(
        runtime.compose + ['logs', '--no-color', '--tail', '100', 'db', 'migrate', 'backend', 'frontend'],
        cwd=ROOT, capture_output=True, timeout=30)
    (REPORTS / 'docker-local.log').write_text(
        redact((result.stdout + result.stderr).decode('utf-8', 'replace'))[-65536:], encoding='utf-8')
    if result.returncode:
        raise RuntimeError('Local Docker log collection returned a nonzero exit code')


def check_source():
    tracked = subprocess.check_output(['git', 'ls-files'], cwd=ROOT, text=True).splitlines()
    if any('/.local/' in path or path.startswith(('.secrets/', 'backups/', 'scrip_password/'))
           or (Path(path).name.startswith('.env') and Path(path).name != '.env.example')
           for path in tracked):
        raise RuntimeError('Sensitive runtime files are tracked in Git')


def source_identity():
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    dirty = bool(subprocess.check_output(
        ['git', 'status', '--porcelain', '--untracked-files=all'], cwd=ROOT, text=True))
    return {'commit': commit, 'dirty': dirty, 'build_id': os.getenv('BUILD_NUMBER'),
            'build_url': os.getenv('BUILD_URL', 'local')}


def require_clean_release():
    previous = json.loads((REPORTS / 'build.json').read_text(encoding='utf-8'))
    current = source_identity()
    if (current != previous or current['dirty'] or not (current['build_id'] or '').isdecimal()
            or current['build_url'] == 'local'
            or current['commit'] != os.environ.get('IMAGE_TAG')):
        raise RuntimeError('Deployment requires the current build and its clean checked-out commit')


def build_artifacts():
    current = source_identity()
    if (current != json.loads((REPORTS / 'build.json').read_text(encoding='utf-8'))
            or current['commit'] != os.environ.get('IMAGE_TAG')):
        raise RuntimeError('CI inputs require the current checkout and build ID')
    return BuildArtifacts(ROOT, REPORTS, current, docker_command())


def collect_fixture_timeline(runtime):
    ids = runtime.run('ps', '--all', '--quiet', 'db', 'migrate', 'backend', 'frontend',
                      capture=True).splitlines()
    snapshots = json.loads(subprocess.check_output(runtime.docker + ['inspect', *ids], cwd=ROOT))
    data = {}
    for container in snapshots:
        state = container['State']
        name = container['Config']['Labels']['com.docker.compose.service']
        data[name] = {'started_at': state['StartedAt'], 'finished_at': state['FinishedAt'],
                      'exit_code': state['ExitCode'],
                      'health_samples': [{key: probe[key] for key in ('Start', 'End', 'ExitCode')}
                                         for probe in state.get('Health', {}).get('Log', [])]}
    (REPORTS / 'mysql-container-timeline.json').write_text(json.dumps(data, indent=2), encoding='utf-8')


def wait_for_docker():
    deadline = time.monotonic() + 120
    command = docker_command() + ['info', '--format', '{{.OSType}}']
    while True:
        try:
            result = subprocess.run(command, capture_output=True, text=True,
                                    errors='replace', timeout=10)
            if result.returncode == 0:
                engine_os = result.stdout.strip()
                if engine_os == 'linux':
                    print('Docker Linux Engine is ready.', flush=True)
                    return
                record_check(f'Docker Engine returned OS type {engine_os!r}; Linux containers are required.')
                raise RuntimeError('Docker Engine must be in Linux container mode.')
            output = result.stderr.strip()
            print(output or f'docker info exited with code {result.returncode}.', flush=True)
            message = output.lower()
            if 'cannot find the file specified' in message:
                detail = 'Docker Linux Engine named pipe is missing. The engine is unavailable to the Jenkins agent.'
            elif 'access is denied' in message or 'permission denied' in message:
                detail = 'Jenkins agent was denied access to the configured Docker Engine.'
            else:
                detail = f'Could not connect to the configured Docker Engine (docker info exit {result.returncode}).'
        except subprocess.TimeoutExpired:
            detail = 'Docker Engine did not respond to docker info within 10 seconds.'
            print(detail, flush=True)
        record_check(detail)
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise RuntimeError(f'Docker readiness checks expired. {detail}')
        print('Waiting for Docker Engine before retrying...', flush=True)
        time.sleep(min(5, remaining))


def main(step):
    record_check(step)
    if step=='preflight':
        record_check('Check Python 3.10+ and Docker CLI/Compose')
        if sys.version_info < (3, 10):
            raise RuntimeError('Python 3.10+ is required')
        for command in [docker_command()+['--version'], docker_command()+['compose','version']]:
            run(command)
        record_check('Check Java 21, Node 22.12+, npm and Chrome')
        java = run(['java','-version'], capture_output=True, text=True)
        print((java.stderr + java.stdout).strip(), flush=True)
        if not re.search(r'version "21[.]', java.stderr + java.stdout):
            raise RuntimeError('JDK 21 is required')
        node = run(['node','--version'], capture_output=True, text=True)
        version = node.stdout.strip().lstrip('v')
        print('Node ' + version, flush=True)
        major, minor = map(int, version.split('.')[:2])
        if major < 22 or (major == 22 and minor < 12):
            raise RuntimeError('Node 22.12+ is required')
        run([NPM,'--version'])
        chrome = os.getenv('CHROME_PATH', 'C:/Program Files/Google/Chrome/Application/chrome.exe'
                           if WIN else '/usr/bin/google-chrome')
        if not Path(chrome).is_file():
            raise RuntimeError('Google Chrome or CHROME_PATH is required for browser tests')
        record_check('Connect to the configured Docker Linux Engine')
        wait_for_docker()
    elif step=='docker-ready':
        wait_for_docker()
    elif step=='monitoring-config':
        root = (ROOT / 'infrastructure/monitoring').as_posix()
        command = docker_command() + ['run', '--rm', '--network', 'none', '--entrypoint', '/bin/promtool',
                                      '--mount', f'type=bind,source={root},target=/etc/prometheus,readonly',
                                      '--workdir', '/etc/prometheus', 'prom/prometheus:v3.4.1']
        record_check('Validate Prometheus scrape configuration and alert rules')
        run(command + ['check', 'config', '/etc/prometheus/prometheus.yml'])
        record_check('Test Prometheus alert firing and recovery rules')
        run(command + ['test', 'rules', 'alerts-infra.test.yml'])
    elif step=='prepare':
        record_check('Check tracked source and record the build identity')
        check_source()
        (REPORTS/'build.json').write_text(json.dumps(source_identity(), indent=2), encoding='utf-8')
        record_check('Run operations unit tests')
        run([sys.executable,'-m','unittest','discover','-s','scripts/tests','-v'])
    elif step=='backend':
        artifacts = build_artifacts()
        record_check('Backend Java: Maven clean verify (compile, tests, verification)')
        run([*MAVEN,'-B','-ntp','clean','verify'],ROOT/'backend',track_maven=True)
        artifacts.record_input('backend')
    elif step=='frontend':
        artifacts = build_artifacts()
        dotenv = [ROOT/'frontend'/name for name in ('.env','.env.local','.env.production','.env.production.local')]
        if any(path.exists() for path in dotenv) or any(key.startswith('VITE_') for key in os.environ):
            raise RuntimeError('CI production Vite build requires a checkout without local dotenv or VITE_* overrides')
        for filename in ['junit.xml','lcov.info','coverage-summary.json']:
            (ROOT/'frontend/coverage'/filename).unlink(missing_ok=True)
        for label, command in [
            ('Frontend dependency install (npm ci)', [NPM,'ci','--prefer-offline','--no-fund','--no-audit']),
            ('Frontend ESLint', [NPM,'run','lint','--','--cache','--cache-strategy','content','--cache-location','.eslintcache']),
            ('Frontend API and unit tests (npm run test:ci)', [NPM,'run','test:ci']),
            ('Frontend production build', [NPM,'run','build']),
        ]:
            record_check(label)
            if label == 'Frontend production build':
                env = {**os.environ, 'NODE_ENV': 'production'}
                run(command, ROOT/'frontend', env=env)
            else:
                run(command,ROOT/'frontend')
        artifacts.record_input('frontend')
    elif step=='sonar':
        if not os.getenv('SONAR_HOST_URL') or not os.getenv('SONAR_AUTH_TOKEN'):raise RuntimeError('Configure the Jenkins SonarQube server/credential first.')
        env={**os.environ,'SONAR_TOKEN':os.environ['SONAR_AUTH_TOKEN']}
        # Run a standalone scanner at repository root: Maven module scope excludes frontend.
        scanner_home = os.getenv('SONAR_SCANNER_HOME')
        scanner = str(Path(scanner_home) / 'bin' / ('sonar-scanner.bat' if WIN else 'sonar-scanner')) if scanner_home else shutil.which('sonar-scanner')
        if not scanner or not Path(scanner).is_file():
            raise RuntimeError('Install SonarScanner CLI on the agent and set SONAR_SCANNER_HOME (or PATH).')
        # Resolve Java dependencies for accurate semantic analysis outside Maven scanner.
        classpath = ROOT/'backend/target/sonar-classpath.txt'
        classpath.unlink(missing_ok=True)
        run([*MAVEN, '-B', '-ntp', 'dependency:build-classpath',
             '-Dmdep.outputFile='+str(classpath)], ROOT/'backend')
        libraries = classpath.read_text(encoding='utf-8').strip().split(os.pathsep)
        report = ROOT/'backend/target/sonar/report-task.txt'
        report.unlink(missing_ok=True)
        report.parent.mkdir(parents=True, exist_ok=True)
        for required in [ROOT/'frontend/src', ROOT/'frontend/coverage/lcov.info',
                         ROOT/'backend/target/classes', ROOT/'backend/target/site/jacoco/jacoco.xml']:
            if not required.exists():
                raise RuntimeError('Missing required Sonar input: '+str(required.relative_to(ROOT)))
        properties = {
            'sonar.projectKey': 'cmc-sms',
            'sonar.sourceEncoding': 'UTF-8',
            'sonar.sources': 'backend/src/main/java,frontend/src',
            'sonar.tests': 'backend/src/test/java,frontend/tests',
            'sonar.java.binaries': 'backend/target/classes',
            'sonar.java.test.binaries': 'backend/target/test-classes',
            'sonar.java.libraries': ','.join(Path(p).as_posix() for p in libraries if p),
            'sonar.java.test.libraries': ','.join(Path(p).as_posix() for p in libraries if p),
            'sonar.java.source': '21',
            'sonar.coverage.jacoco.xmlReportPaths': 'backend/target/site/jacoco/jacoco.xml',
            'sonar.javascript.lcov.reportPaths': 'frontend/coverage/lcov.info',
            'sonar.junit.reportPaths': 'backend/target/surefire-reports',
            'sonar.scanner.metadataFilePath': report.as_posix(),
        }
        # Keep the full Java classpath out of the Windows command line.
        config = report.parent / 'scanner.properties'
        config.write_text(''.join(key + '=' + value + '\n' for key, value in properties.items()), encoding='utf-8')
        run([scanner, '-Dproject.settings='+config.relative_to(ROOT).as_posix()], ROOT, env=env)
        if not report.is_file():
            raise RuntimeError('SonarScanner did not produce current task metadata')
    elif step=='build':
        build_artifacts().build_images(ci_build_command(), run, record_check)
    elif step=='seal-release':
        from ci_release import seal
        require_clean_release()
        seal(ROOT, source_identity(), build_artifacts().verify_gate_images(), os.environ)
    elif step=='promote-release':
        from ci_release import promote
        if source_identity()['dirty']:
            raise RuntimeError('Promotion requires a clean checkout')
        promote(ROOT, os.environ)
    elif step=='deploy-local':
        from ci_release import verify_local, pin_published
        if source_identity()['dirty']:
            raise RuntimeError('Deployment requires a clean checkout')
        pin_published(verify_local(ROOT, os.environ), docker_command(), ROOT)
        deploy_local()
    elif step=='deploy-local-logs':
        collect_local_logs()
    elif step=='mysql':
        artifacts = build_artifacts()
        tested_images = artifacts.pin_images()
        (REPORTS/'mysql-integration.json').unlink(missing_ok=True)
        actors={'PRINCIPAL':'principal','TRAINING_OFFICE':'training_demo','CTSV':'ctsv_demo','LECTURER':'lecturer_demo_01','STUDENT':'student_demo_001','APPLICANT':'applicant_demo_03'}
        for role in actors:
            (REPORTS / f'browser-{role}.log').unlink(missing_ok=True)
        # A cancelled build can leave containers behind. Each run gets a fresh project and secrets.
        directory = REPORTS.parent / f'sms-ci-{uuid4().hex}'
        # Docker Desktop needs to read bind-mounted secrets through the workspace ACL.
        # On Windows, mkdir(0700) can give the directory a private ACL.
        directory.mkdir(mode=0o777 if WIN else 0o700)
        try:
            env_file = directory / '.env'
            initialize(env_file, ci=True)
            runtime=Runtime(env_file)
            if not runtime.config['COMPOSE_PROJECT_NAME'].startswith('sms_ci_'):raise RuntimeError('Integration tests require an isolated CI project')
            try:
                record_check('MySQL integration: start database, migrations and application containers')
                runtime.run('up','-d','--no-build','--wait','--wait-timeout','300','frontend','backend')
                initial_images = artifacts.verify_runtime_images(runtime, tested_images)
                collect_fixture_timeline(runtime)
                record_check('MySQL integration: provision test accounts')
                runtime.run('run','--rm','--no-deps','provision','--initialize')
                record_check('MySQL integration: HTTP, role login and SQL smoke checks')
                results=smoke(runtime, report=record_check)
                record_check('MySQL integration: business workflow checks')
                from mysql_workflows import verify_workflows
                try:
                    workflows = verify_workflows(runtime)
                except Exception as error:
                    raise RuntimeError(f'MySQL business workflow failed: {type(error).__name__}: {error}') from error
                # Browser checks run against the same isolated MySQL fixture, not host data.
                credentials = settings(runtime.secret_dir / 'demo_accounts')
                base_url = runtime.url()
                record_check('MySQL integration: browser checks for all six roles')

                def check_browser(actor):
                    role, username = actor
                    started = time.monotonic()
                    browser_env = {
                        **os.environ,
                        'SMS_UI_BASE_URL': base_url,
                        'SMS_UI_ROLE': role,
                        'SMS_UI_USERNAME': username,
                        'SMS_UI_PASSWORD': credentials[username],
                        'SMS_UI_DEBUG_PORT': '0',
                        'SMS_UI_OUTPUT_DIR': str(directory / 'browser' / role),
                    }
                    browser_log = REPORTS / f'browser-{role}.log'
                    try:
                        with browser_log.open('wb') as output:
                            run(['node','tests/browser-full-ui.mjs'],ROOT/'frontend',env=browser_env,stdout=output,stderr=subprocess.STDOUT,timeout=180)
                    except (RuntimeError, subprocess.TimeoutExpired):
                        print(f'Browser integration failed for {role}. Report: {browser_log.name}', flush=True)
                        with browser_log.open('rb') as output:
                            output.seek(max(0, browser_log.stat().st_size - 4000))
                            detail = output.read().decode('utf-8', 'replace')
                        for password in credentials.values():
                            if password:
                                detail = detail.replace(password, '[REDACTED]')
                        print(detail, flush=True)
                        raise
                    return role, round(time.monotonic() - started, 3)

                with ThreadPoolExecutor(max_workers=2) as browsers:
                    browser_times = dict(browsers.map(check_browser, actors.items()))
                (REPORTS / 'mysql-browser-timings.json').write_text(
                    json.dumps(browser_times, indent=2), encoding='utf-8')
                record_check('MySQL integration: backup and restore')
                print('MySQL integration: backup and restore',flush=True)
                snapshot=backup(runtime)
                record_check('MySQL integration: restore the backup into an isolated container')
                restore_test(runtime,snapshot)
                record_check('MySQL integration: restart and persistence')
                print('MySQL integration: restart and persistence',flush=True)
                before=runtime.sql('SELECT COUNT(*) FROM students UNION ALL SELECT COUNT(*) FROM payments')
                runtime.run('restart','db');runtime.run('up','-d','--no-build','--wait','--wait-timeout','180','backend','frontend')
                if before!=runtime.sql('SELECT COUNT(*) FROM students UNION ALL SELECT COUNT(*) FROM payments'):raise RuntimeError('Persistence check failed')
                record_check('MySQL integration: smoke test after restart')
                smoke(runtime, report=record_check)
                final_images = artifacts.verify_runtime_images(runtime, tested_images)
                if initial_images != final_images:
                    raise RuntimeError('CI image identity changed after restart')
                artifacts.write('mysql-runtime-images', {'initial': initial_images, 'final': final_images})
                (REPORTS/'mysql-integration.json').write_text(json.dumps({'passed':True,'created_at':dt.datetime.now().isoformat(),'image_tag':os.getenv('IMAGE_TAG','local'),'checks':results,'workflows':workflows,'restore':True,'restart_persistence':True},indent=2))
                record_check('MySQL integration: collect logs and remove CI containers')
            finally:
                had_failure = sys.exc_info()[0] is not None
                try:
                    runtime.run('logs','--no-color','--tail','200','backend','migrate',destination=REPORTS/'mysql-runtime.log',check=False,timeout=30)
                except (OSError, subprocess.SubprocessError) as error:
                    print(f'CI evidence limitation: MySQL runtime log collection failed ({type(error).__name__})', flush=True)
                # Only the generated, disposable CI namespace is removed, never local/production volumes.
                try:
                    runtime.run('down','--volumes','--remove-orphans',timeout=90)
                except (RuntimeError, OSError, subprocess.SubprocessError) as error:
                    if not had_failure:
                        raise
                    print(f'CI cleanup warning: MySQL project teardown failed ({type(error).__name__})', flush=True)
        finally:
            had_failure = sys.exc_info()[0] is not None
            try:
                if WIN:
                    for secret in (directory / '.secrets-ci').glob('*'):
                        secret.chmod(0o600)
                shutil.rmtree(directory)
            except OSError as error:
                if not had_failure:
                    raise
                print(f'CI cleanup warning: fixture removal failed ({type(error).__name__})', flush=True)
        artifacts.write('mysql-image-evidence', tested_images)
    elif step=='scan-export':
        build_artifacts().export_scans(run, record_check)
    elif step=='cleanup-assets':
        # Use the recorded identity here so a late checkout change cannot prevent cleanup.
        path = REPORTS / 'build.json'
        if path.is_file():
            identity = json.loads(path.read_text(encoding='utf-8'))
            if (identity['build_id'] != os.getenv('BUILD_NUMBER')
                    or identity['build_url'] != os.getenv('BUILD_URL', 'local')):
                raise RuntimeError('Refusing temporary artifact cleanup for another build')
            BuildArtifacts(ROOT, REPORTS, identity, docker_command()).cleanup()
    elif step in ['security','secrets']:
        check_source()
        artifacts = build_artifacts()
        scanner='vuln' if step=='security' else 'secret'
        severity='CRITICAL' if step=='security' else 'UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL'
        prefix='trivy' if step=='security' else 'trivy-secret'
        for name in ['filesystem','backend','frontend','migration']:
            (REPORTS/(prefix+'-'+name+'.json')).unlink(missing_ok=True)
        if step == 'security':
            record_check('Frontend dependency audit (npm audit)')
            with open(REPORTS/'npm-audit.json','wb') as out:
                result=subprocess.run([NPM,'audit','--json','--audit-level=critical'],cwd=ROOT/'frontend',stdout=out)
            if result.returncode:raise RuntimeError('Dependency audit failed or could not complete')
        image=os.getenv('TRIVY_IMAGE','aquasec/trivy:0.64.1')
        skips=['backend/target','frontend/dist','.git','.secrets','backend/.local','backend/private-files','frontend/node_modules','frontend/.npm-cache','backups','artifacts']
        command=docker_command()+['run','--rm','-v',str(ROOT)+':/work:ro','-v','sms_trivy_cache:/root/.cache/','-w','/work',image,'fs','--timeout','15m','--no-progress','--parallel','1','--scanners',scanner,'--severity',severity,'--exit-code','1']
        for path in skips:command+=['--skip-dirs','/work/'+path]
        command+=['--skip-files','.env','--skip-files','backend/.env.local','--skip-files','frontend/.env.local','--format','json','.']
        record_check('Trivy filesystem scan: ' + scanner)
        scan_report(command,REPORTS/(prefix+'-filesystem.json'))
        scanned = {}
        for service in DOCKERFILES:
            record_check('Trivy image scan: ' + service + ' (' + scanner + ')')
            archive, entry = artifacts.scan_input(service, scanner, record=record_check)
            report = scan_report(docker_command()+['run','--rm','-v',str(archive)+':/image.tar:ro','-v','sms_trivy_cache:/root/.cache/',image,'image','--timeout','15m','--no-progress','--parallel','1','--input','/image.tar','--scanners',scanner,'--severity',severity,'--exit-code','1','--format','json'],REPORTS/(prefix+'-'+service+'.json'))
            if report.get('Metadata', {}).get('ImageID') != entry['config_id']:
                raise RuntimeError('Trivy reported a different image config: ' + service)
            artifacts.scan_input(service, scanner, repair=False)
            scanned[service] = entry
        artifacts.write('scan-completed-' + scanner, scanned)
    elif step=='publish':
        # Publish only the exact local images already tested/scanned. Registry login is external.
        if os.getenv('CHANGE_ID'):raise RuntimeError('Pull requests may not publish images')
        if os.getenv('QUALITY_GATE_PASSED')!='true':raise RuntimeError('Quality gate is not approved')
        require_clean_release()
        artifacts = build_artifacts()
        verified = artifacts.verify_gate_images()
        repository=os.environ['REGISTRY_NAMESPACE'].lower().rstrip('/')
        if not re.fullmatch(r'[a-z0-9.-]+(?:/[a-z0-9_.-]+)+',repository):raise RuntimeError('Invalid registry namespace')
        tag=os.environ['IMAGE_TAG'];manifest={'commit':tag,'images':{}}
        if not re.fullmatch(r'[0-9a-f]{40}',tag):raise RuntimeError('Publishing requires full commit SHA')
        for service in DOCKERFILES:
            target=repository+'/sms-'+service+':'+tag
            run(docker_command()+['tag',verified[service]['id'],target])
            result = subprocess.run(docker_command()+['push',target], cwd=ROOT, capture_output=True, text=True)
            print(redact(result.stdout + result.stderr), flush=True)
            matches = re.findall(r'\bdigest: (sha256:[0-9a-f]{64})\b', result.stdout)
            if result.returncode or len(matches) != 1:
                raise RuntimeError('Registry did not return one published digest: ' + service)
            digest = repository+'/sms-'+service+'@'+matches[0]
            published = artifacts.inspect(digest)
            if published['id'] != verified[service]['id']:
                raise RuntimeError('Registry digest did not identify the scanned image: ' + service)
            manifest['images'][service]=digest
        (REPORTS/'release.json').write_text(json.dumps(manifest,indent=2))
    else:raise RuntimeError('Unknown step')

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('step',choices=['preflight','docker-ready','monitoring-config','prepare','backend','frontend','sonar','build','deploy-local','deploy-local-logs','mysql','scan-export','security','secrets','cleanup-assets','publish','seal-release','promote-release'])
    try:main(parser.parse_args().step)
    except (RuntimeError,subprocess.SubprocessError,OSError) as error:
        print(f'CI failure: {error}', flush=True)
        sys.exit(1)
