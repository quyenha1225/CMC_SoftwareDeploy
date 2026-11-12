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
from docker import initialize,settings

class OperationsTests(unittest.TestCase):
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
        with patch.object(ci,'run',side_effect=[None,RuntimeError('lint failed')]) as command:
            with self.assertRaises(RuntimeError):ci.main('frontend')
            self.assertEqual(command.call_count,2)
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

if __name__=='__main__':unittest.main()
