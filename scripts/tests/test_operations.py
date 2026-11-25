"""Regression tests for release gates and non-destructive operations."""
import base64
import json
import os
from pathlib import Path
import sys
import tempfile
import subprocess
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import ci
import deploy
from docker import docker_command, initialize, prepare_demo_deployment, settings

class OperationsTests(unittest.TestCase):
    def test_discord_lookup_does_not_initialize_a_deployment(self):
        with patch.object(ci, 'invoke', return_value=''), patch.object(ci, 'initialize') as initialize:
            with self.assertRaisesRegex(RuntimeError, 'existing local Compose database was not found'):
                ci.local_deploy_runtime(require_existing=True)
        initialize.assert_not_called()

    def test_local_deploy_reuses_the_running_projects_environment(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            env_file = root / '.env'
            env_file.write_text('COMPOSE_PROJECT_NAME=sms_local\nSMS_SECRETS_DIR=.secrets\n')
            mounts = [
                {'Destination': '/run/secrets/' + name, 'Source': str(root / '.secrets' / name)}
                for name in ('mysql_root_password', 'db_password', 'migrator_password')
            ]
            info = [{'Config': {'Labels': {'com.docker.compose.project.working_dir': str(root)}},
                     'Mounts': mounts}]
            with patch.object(ci, 'invoke', side_effect=['local-db-id', json.dumps(info)]), \
                    patch.object(ci, 'initialize') as initialize:
                runtime = ci.local_deploy_runtime()
            initialize.assert_not_called()
            self.assertEqual(runtime.env_file, env_file.resolve())
            self.assertEqual(runtime.secret_dir, root.resolve() / '.secrets')
            self.assertEqual(runtime.compose[-2:], ['--project-name', 'sms_local'])

            mounts[0]['Source'] = str(root / 'another-directory' / 'mysql_root_password')
            with patch.object(ci, 'invoke', side_effect=['local-db-id', json.dumps(info)]):
                with self.assertRaisesRegex(RuntimeError, 'secret directory differs'):
                    ci.local_deploy_runtime()

    def test_local_deploy_backs_up_before_using_the_tested_images(self):
        events = []
        class LocalRuntime:
            env_file = Path('.env')
            secret_dir = Path('.secrets')
            def run(self, *args, **kwargs):
                events.append(args)
                return 'db\nbackend\n' if args[0] == 'ps' else ''
            def sql(self, query):
                return 'fixture-server\tsms_db\t1'

        with patch.dict(os.environ, {'IMAGE_TAG': 'a' * 40}, clear=True), \
                patch.object(ci, 'local_deploy_runtime', return_value=LocalRuntime()), \
                patch.object(ci, 'backup', side_effect=lambda _: events.append('backup')), \
                patch.object(ci, 'smoke', side_effect=lambda _: events.append('smoke')):
            ci.deploy_local()
        overlay = ('-f', str(ci.ROOT / 'compose.monitoring.yaml'), '--profile', 'monitoring')
        self.assertEqual(events, [
            ('config', '--quiet'),
            ('ps', '--status', 'running', '--services', 'db', 'backend'),
            'backup',
            ('ps', '--status', 'running', '--services', 'db'),
            ('--profile', 'tools', 'run', '--rm', '--no-deps', 'provision'),
            ('up', '-d', '--no-build', '--wait', '--wait-timeout', '300', 'frontend', 'backend'),
            ('--profile', 'tools', 'run', '--rm', '--no-deps', 'provision'),
            'smoke',
            (*overlay, 'up', '-d', '--no-build', '--wait', '--wait-timeout', '180',
             'prometheus', 'grafana', 'alertmanager', 'blackbox', 'cadvisor', 'node-exporter', 'volume-size'),
            (*overlay, 'ps'),
        ])

    def test_local_deploy_stops_before_rollout_on_preflight_mismatch(self):
        from unittest.mock import Mock
        runtime = Mock(env_file=Path('.env'), secret_dir=Path('.secrets'))
        runtime.run.return_value = 'db\nbackend'
        with patch.dict(os.environ, {'IMAGE_TAG': 'a' * 40}, clear=True), \
                patch.object(ci, 'local_deploy_runtime', return_value=runtime), \
                patch.object(ci, 'backup'), \
                patch.object(ci, 'prepare_demo_deployment', side_effect=RuntimeError('password mismatch')), \
                patch.object(ci, 'smoke') as smoke:
            with self.assertRaisesRegex(RuntimeError, 'password mismatch'):
                ci.deploy_local()
        self.assertFalse(any(call.args[0] == 'up' for call in runtime.run.call_args_list))
        smoke.assert_not_called()

    def test_new_demo_initialization_can_retry_after_migration_without_resetting_existing_databases(self):
        from unittest.mock import Mock
        with tempfile.TemporaryDirectory() as directory:
            runtime = Mock(secret_dir=Path(directory))
            runtime.sql.side_effect = ['fixture-server\tsms_db\t0',
                                       'fixture-server\tsms_db\t20', 'fixture-server\tsms_db\t20']
            runtime.run.side_effect = ['db', RuntimeError('interrupted after Flyway'), 'db', '', 'db', '']
            with self.assertRaisesRegex(RuntimeError, 'interrupted after Flyway'):
                prepare_demo_deployment(runtime)
            self.assertTrue((Path(directory) / '.demo-bootstrap-pending').is_file())
            prepare_demo_deployment(runtime)
            self.assertFalse((Path(directory) / '.demo-bootstrap-pending').exists())
            prepare_demo_deployment(runtime)
            self.assertEqual(runtime.run.call_args_list[1].args[-2:], ('provision', '--initialize'))
            self.assertEqual(runtime.run.call_args_list[3].args[-2:], ('provision', '--initialize'))
            self.assertEqual(runtime.run.call_args_list[5].args[-2:], ('--no-deps', 'provision'))

    def test_deploy_refuses_dirty_or_different_build_evidence(self):
        sha = 'a' * 40
        metadata = {'commit': sha, 'dirty': False, 'build_id': '75',
                    'build_url': 'http://jenkins.test/job/fixture/75/'}
        with tempfile.TemporaryDirectory() as directory, \
                patch.object(ci, 'REPORTS', Path(directory)), \
                patch.dict(os.environ, {'IMAGE_TAG': sha}, clear=True):
            (Path(directory) / 'build.json').write_text(json.dumps(metadata), encoding='utf-8')
            with patch.object(ci, 'source_identity', return_value=metadata):
                ci.require_clean_release()
            for changed in ({'dirty': True}, {'build_id': '76'}, {'build_id': None},
                            {'commit': 'b' * 40}):
                with patch.object(ci, 'source_identity', return_value={**metadata, **changed}), \
                        self.assertRaisesRegex(RuntimeError, 'clean checked-out commit'):
                    ci.require_clean_release()

    def test_remote_rollout_preserves_original_failure_and_archives_ssh_logs(self):
        failure = subprocess.CalledProcessError(1, ['ssh'])
        ssh_logs = subprocess.CompletedProcess(['ssh'], 0, b'password=fixture-secret\n', b'')
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with patch.dict(os.environ, {}, clear=True), patch.object(deploy, 'ROOT', root), \
                    patch.object(deploy, 'read_manifest'), patch.object(deploy.tarfile, 'open'), \
                    patch.object(deploy, 'remote_target', return_value=(
                        'staging', 'test@example.test', [], 'https://example.test', 'fixture')), \
                    patch.object(deploy.subprocess, 'run', side_effect=[None, failure, ssh_logs]) as run:
                with self.assertRaises(subprocess.CalledProcessError) as raised:
                    deploy.remote(root / 'release.json')
            self.assertIs(raised.exception, failure)
            self.assertEqual(run.call_args_list[-1].args[0][:2], ['ssh', 'test@example.test'])
            self.assertIn('compose.prod.yaml logs', run.call_args_list[-1].args[0][-1])
            log = (root / 'artifacts/reports/docker-server.log').read_text(encoding='utf-8')
            self.assertIn('[REDACTED]', log)
            self.assertNotIn('fixture-secret', log)

    def test_ci_creates_and_loads_images_from_the_dedicated_builder(self):
        endpoint = 'npipe:////./pipe/dockerDesktopLinuxEngine'
        with patch.dict(os.environ, {'SMS_CI_BUILDER': 'sms-jenkins-linux', 'DOCKER_HOST': endpoint}, clear=True), \
                patch.object(ci.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1)) as inspect, \
                patch.object(ci, 'run') as execute:
            ci.main('build')
        inspect.assert_called_once_with(
            ['docker', 'buildx', 'inspect', 'sms-jenkins-linux'], cwd=ci.ROOT, capture_output=True, text=True)
        commands = [call.args[0] for call in execute.call_args_list]
        self.assertEqual(commands[0], ['docker', 'buildx', 'create', '--name', 'sms-jenkins-linux',
                                       '--driver', 'docker-container',
                                       '--driver-opt', 'env.CONTAINERD_DISABLE_PIGZ=1', endpoint])
        self.assertEqual(commands[1], ['docker', 'buildx', 'inspect', '--bootstrap', 'sms-jenkins-linux'])
        self.assertEqual(len(commands[2:]), 3)
        for command, service in zip(commands[2:], ('backend', 'frontend', 'migration')):
            self.assertEqual(command[:6], ['docker', 'buildx', 'build', '--builder', 'sms-jenkins-linux', '--load'])
            self.assertIn('sms-' + service + ':local', command)

    def test_ci_rejects_a_builder_bound_to_another_engine(self):
        inspected = subprocess.CompletedProcess([], 0, stdout='Driver: docker-container\nEndpoint: other-engine\n')
        with patch.dict(os.environ, {'SMS_CI_BUILDER': 'sms-jenkins-linux', 'DOCKER_CONTEXT': 'desktop-linux'}, clear=True), \
                patch.object(ci.subprocess, 'run', return_value=inspected), patch.object(ci, 'run') as execute:
            with self.assertRaisesRegex(RuntimeError, 'not a docker-container builder for desktop-linux'):
                ci.ci_build_command()
        execute.assert_not_called()

    def test_ci_reuses_the_configured_builder(self):
        inspected = subprocess.CompletedProcess([], 0, stdout=(
            'Driver: docker-container\nEndpoint: desktop-linux\n'
            'Driver Options: env.CONTAINERD_DISABLE_PIGZ="1"\n'
        ))
        with patch.dict(os.environ, {'SMS_CI_BUILDER': 'sms-jenkins-linux', 'DOCKER_CONTEXT': 'desktop-linux'}, clear=True), \
                patch.object(ci.subprocess, 'run', return_value=inspected), patch.object(ci, 'run') as execute:
            ci.ci_build_command()
        execute.assert_called_once_with(['docker', 'buildx', 'inspect', '--bootstrap', 'sms-jenkins-linux'])

    def test_docker_uses_agent_environment_before_windows_default(self):
        with patch.object(os, 'name', 'nt'), patch.dict(os.environ, {}, clear=True):
            self.assertEqual(docker_command(), ['docker', '--host', 'npipe:////./pipe/dockerDesktopLinuxEngine'])
            with patch.dict(os.environ, {'DOCKER_HOST': 'npipe:////./pipe/custom'}):
                self.assertEqual(docker_command(), ['docker'])

    def test_docker_supports_sms_host_and_explicit_context(self):
        with patch.dict(os.environ, {'SMS_DOCKER_HOST': 'unix:///run/ci/docker.sock'}, clear=True):
            self.assertEqual(docker_command(), ['docker', '--host', 'unix:///run/ci/docker.sock'])
            self.assertEqual(docker_command('ci-linux'), ['docker', '--context', 'ci-linux'])

    def test_sonar_uses_absolute_paths_from_maven_module(self):
        with patch.dict(os.environ, {'SONAR_HOST_URL': 'http://sonar.invalid', 'SONAR_AUTH_TOKEN': 'test-placeholder'}), patch.object(ci, 'run') as execute:
            ci.main('sonar')
        command = execute.call_args.args[0]
        properties = dict(item[2:].split('=', 1) for item in command if item.startswith('-D'))
        for key in ['sonar.sources', 'sonar.tests', 'sonar.java.binaries', 'sonar.coverage.jacoco.xmlReportPaths', 'sonar.javascript.lcov.reportPaths']:
            for value in properties[key].split(','):
                self.assertTrue(Path(value).is_absolute(), (key, value))
                self.assertTrue(Path(value).is_relative_to(ci.ROOT))
                self.assertNotIn('/backend/backend/', value)
        self.assertEqual(properties['sonar.sources'], ','.join((ci.ROOT / value).as_posix() for value in ['backend/src/main/java', 'frontend/src']))
        self.assertEqual(execute.call_args.kwargs['env']['SONAR_TOKEN'], 'test-placeholder')

    def manifest(self):
        return {'commit':'a'*40,'images':{name:'registry.example/team/sms-'+name+'@sha256:'+'b'*64 for name in ['backend','frontend','migration']}}
    def check_manifest(self,value):
        with tempfile.TemporaryDirectory() as folder:
            target=Path(folder)/'release.json';target.write_text(json.dumps(value))
            return deploy.read_manifest(target)
    def test_accepts_three_immutable_artifacts(self):
        self.assertEqual(self.check_manifest(self.manifest())['commit'],'a'*40)
    def test_rejects_mutable_tag(self):
        value=self.manifest();value['images']['backend']='registry.example/backend:latest'
        with self.assertRaises(RuntimeError):self.check_manifest(value)
    def test_requires_migration_artifact(self):
        value=self.manifest();del value['images']['migration']
        with self.assertRaises(RuntimeError):self.check_manifest(value)
    def test_requires_full_commit(self):
        value=self.manifest();value['commit']='abc123'
        with self.assertRaises(RuntimeError):self.check_manifest(value)
    def test_partial_ddl_changes_prevent_automatic_rollback(self):
        class Fake:
            def __init__(self,ddl):self.ddl=ddl
            def sql(self,query):return '1' if query.startswith('SELECT COALESCE') else self.ddl
        self.assertNotEqual(deploy.schema(Fake('old ddl')),deploy.schema(Fake('partially changed ddl')))
    def test_init_generates_unique_secrets_without_passwords_in_env(self):
        with tempfile.TemporaryDirectory() as folder:
            env=Path(folder)/'.env';initialize(env,ci=True)
            config=settings(env);secret_dir=Path(config['SMS_SECRETS_DIR'])
            accounts=settings(secret_dir/'demo_accounts')
            self.assertEqual(len(accounts),15);self.assertEqual(len(set(accounts.values())),15)
            self.assertEqual(len(base64.b64decode((secret_dir/'jwt_secret').read_text())),64)
            self.assertNotIn('DB_PASSWORD',config)
            original=env.read_bytes()
            with self.assertRaises(RuntimeError):initialize(env,ci=True)
            self.assertEqual(original,env.read_bytes())
    def test_frontend_failure_stops_following_commands(self):
        with tempfile.TemporaryDirectory() as folder, patch.object(ci,'ROOT',Path(folder)), patch.object(ci,'run',side_effect=[None,RuntimeError('lint failed')]) as command:
            with self.assertRaises(RuntimeError):ci.main('frontend')
            self.assertEqual(command.call_count,2)
    def test_frontend_keeps_checks_and_uses_content_cache(self):
        with tempfile.TemporaryDirectory() as folder, patch.object(ci, 'ROOT', Path(folder)), patch.object(ci, 'run') as execute:
            ci.main('frontend')
        commands = [call.args[0] for call in execute.call_args_list]
        self.assertEqual(len(commands), 4)
        self.assertIn('--prefer-offline', commands[0])
        self.assertIn('--cache-strategy', commands[1])
        self.assertIn('content', commands[1])
        self.assertEqual(commands[2][2], 'test:ci')
        self.assertEqual(commands[3][2], 'build')

    def test_command_error_preserves_native_exit_code(self):
        result = subprocess.CompletedProcess(['node'], 3221225477)
        with patch.object(ci.subprocess, 'run', return_value=result):
            with self.assertRaisesRegex(RuntimeError, '0xC0000005'):
                ci.run(['node'])

    def test_pull_requests_cannot_publish(self):
        with patch.dict(os.environ,{'CHANGE_ID':'7'}):
            with self.assertRaises(RuntimeError):ci.main('publish')
    def test_failed_secret_scan_redacts_values_before_archiving(self):
        value='fixture-'+('x'*30)
        payload={'Metadata':{'ImageConfig':{'Env':['TOKEN='+value]}},'Results':[{'Secrets':[{'RuleID':'fixture','Match':value,'Code':{'Lines':[{'Content':value}]}}]}]}
        process=subprocess.CompletedProcess(['scanner'],1,stdout=json.dumps(payload).encode(),stderr=b'')
        with tempfile.TemporaryDirectory() as folder, patch.object(ci.subprocess,'run',return_value=process):
            target=Path(folder)/'report.json'
            with self.assertRaises(RuntimeError):ci.scan_report(['scanner'],target)
            self.assertNotIn(value,target.read_text())
            self.assertEqual(json.loads(target.read_text())['Results'][0]['Secrets'][0]['RuleID'],'fixture')
    def test_publish_requires_quality_gate(self):
        with patch.dict(os.environ,{},clear=True):
            with self.assertRaises(RuntimeError):ci.main('publish')


    def test_server_deploy_starts_monitoring_stack_and_waits(self):
        events = []
        class Runtime:
            def run(self, *args, **kwargs):
                events.append(args)
                return ""
        with tempfile.TemporaryDirectory() as folder, patch.object(deploy, 'ROOT', Path(folder)):
            monitor = Path(folder) / 'infrastructure' / 'monitoring'
            monitor.mkdir(parents=True)
            (monitor / 'prometheus.yml').write_text('test config')
            (monitor / 'alerts.yml').write_text('test rules')
            with patch.dict(os.environ, {}, clear=True):
                revision = deploy.start_monitoring(Runtime())
                overlay = ('-f', str(Path(folder) / 'compose.monitoring.yaml'), '--profile', 'monitoring')
                services = ('prometheus', 'grafana', 'alertmanager', 'blackbox', 'cadvisor', 'node-exporter', 'volume-size')
                self.assertEqual(events[0], (*overlay, 'up', '-d', '--no-build', '--wait', '--wait-timeout', '180', *services))
                self.assertEqual(events[1], (*overlay, 'ps'))
                self.assertEqual(os.environ['SMS_MONITORING_DIR'], monitor.as_posix())
                self.assertEqual(os.environ['SMS_MONITORING_REVISION'], revision)
                self.assertEqual(len(revision), 64)

if __name__=='__main__':unittest.main()
