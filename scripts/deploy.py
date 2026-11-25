"""Deploy/rollback only tested immutable images; keep database rollback explicit."""
import argparse
import datetime as dt
import json
import hashlib
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tarfile
import tempfile
import time
from urllib.parse import urlsplit
from urllib.request import urlopen
from docker import ROOT, Runtime, settings, backup, restore_test, smoke

REQUIRED={'backend','frontend','migration'}
def read_manifest(path):
    data=json.loads(Path(path).read_text(encoding='utf-8-sig'))
    if not re.fullmatch(r'[0-9a-f]{40}',data.get('commit','')):raise RuntimeError('Release must identify a full commit SHA')
    if set(data.get('images',{}))!=REQUIRED:raise RuntimeError('Three immutable images required')
    for image in data['images'].values():
        if not re.fullmatch(r'[a-z0-9._:/-]+@sha256:[0-9a-f]{64}',image):raise RuntimeError('Image digest required; tags are not deployments')
    return data

def schema(runtime):
    # Include real DDL and failed migration records: MySQL DDL can partially commit.
    queries=[
        "SELECT table_name,column_name,column_type,is_nullable,column_default,extra,collation_name FROM information_schema.columns WHERE table_schema=DATABASE() ORDER BY table_name,ordinal_position",
        "SELECT table_name,index_name,non_unique,seq_in_index,column_name FROM information_schema.statistics WHERE table_schema=DATABASE() ORDER BY table_name,index_name,seq_in_index",
        "SELECT table_name,constraint_name,column_name,referenced_table_name,referenced_column_name FROM information_schema.key_column_usage WHERE table_schema=DATABASE() ORDER BY table_name,constraint_name,ordinal_position",
        "SELECT constraint_name,check_clause FROM information_schema.check_constraints WHERE constraint_schema=DATABASE() ORDER BY constraint_name",
        "SELECT table_name,view_definition FROM information_schema.views WHERE table_schema=DATABASE() ORDER BY table_name",
        "SELECT trigger_name,action_statement FROM information_schema.triggers WHERE trigger_schema=DATABASE() ORDER BY trigger_name",
        "SELECT routine_name,routine_definition FROM information_schema.routines WHERE routine_schema=DATABASE() ORDER BY routine_name",
        "SELECT installed_rank,version,checksum,success FROM flyway_schema_history ORDER BY installed_rank",
    ]
    signature=hashlib.sha256(runtime.sql(';'.join(queries)).encode('utf-8')).hexdigest()
    latest=runtime.sql("SELECT COALESCE((SELECT version FROM flyway_schema_history WHERE success=1 AND version IS NOT NULL ORDER BY installed_rank DESC LIMIT 1),'none')")
    return latest+':'+signature
def save_env(path,data):
    with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', dir=path.parent, delete=False) as stream:
        temp=Path(stream.name)
        stream.write('\n'.join(k+'='+v for k,v in data.items())+'\n')
    try:
        temp.replace(path)
    finally:
        temp.unlink(missing_ok=True)

def protect_jenkins_ssh_key():
    # Windows OpenSSH rejects inherited access for BUILTIN\\Users on Jenkins
    # file credentials. Restrict only the temporary bound key, not other files.
    if os.name != 'nt' or not os.getenv('BUILD_NUMBER'):
        return
    workspace = os.environ.get('WORKSPACE')
    if not workspace:
        raise RuntimeError('Windows Jenkins workspace is missing')
    key = Path(os.environ['DEPLOY_KEY'])
    credential_dir = Path(workspace + '@tmp') / 'secretFiles'
    if key.is_symlink() or not key.resolve().is_relative_to(credential_dir.resolve()):
        raise RuntimeError('Refusing to modify SSH key outside Jenkins temporary credentials')
    # Use the actual process identity (including LocalSystem or a service user).
    # No key content, password, or token is printed or copied.
    command = r"""
$ErrorActionPreference = 'Stop'
$path = $env:DEPLOY_KEY
$sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
$acl = New-Object System.Security.AccessControl.FileSecurity
$acl.SetAccessRuleProtection($true, $false)
$acl.SetOwner($sid)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($sid, 'FullControl', 'Allow')
$acl.AddAccessRule($rule)
Set-Acl -LiteralPath $path -AclObject $acl
$actual = Get-Acl -LiteralPath $path
$rules = @($actual.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier]))
if (-not $actual.AreAccessRulesProtected -or
    $actual.GetOwner([System.Security.Principal.SecurityIdentifier]).Value -ne $sid.Value -or
    $rules.Count -ne 1 -or $rules[0].IdentityReference.Value -ne $sid.Value -or
    $rules[0].IsInherited -or
    $rules[0].AccessControlType -ne [System.Security.AccessControl.AccessControlType]::Allow) {
    throw 'SSH key ACL verification failed'
}
"""
    subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive',
                    '-Command', command], check=True)
    print('Jenkins temporary SSH key ACL verified for the current service identity.', flush=True)

def remote_target():
    target=os.environ.get('DEPLOY_TARGET', 'production')
    if target not in ['staging','production']:raise RuntimeError('Invalid deployment environment')
    host=os.environ.get(target.upper()+'_HOST', '');user=os.environ.get('DEPLOY_USER', '')
    if not re.fullmatch(r'[A-Za-z0-9.-]+',host) or not re.fullmatch(r'[a-zA-Z0-9_-]+',user):raise RuntimeError('Invalid SSH target')
    for name in ('DEPLOY_KEY', 'DEPLOY_KNOWN_HOSTS'):
        if not os.environ.get(name) or not Path(os.environ[name]).is_file():
            raise RuntimeError('Missing SSH credential file: '+name)
    public_url=os.environ.get('SMS_SERVER_PUBLIC_URL', '').rstrip('/')
    url=urlsplit(public_url)
    if url.scheme!='https' or not url.hostname or url.username or url.password or url.path or url.query or url.fragment:
        raise RuntimeError('SMS_SERVER_PUBLIC_URL must be an HTTPS origin')
    approver=os.getenv('RELEASE_APPROVER','jenkins-ci')
    if not re.fullmatch(r'[A-Za-z0-9_.@-]+',approver):raise RuntimeError('Invalid approval identity')
    protect_jenkins_ssh_key()
    options=['-i',os.environ['DEPLOY_KEY'],'-o','BatchMode=yes','-o','StrictHostKeyChecking=yes',
             '-o','ConnectTimeout=10','-o','IdentitiesOnly=yes',
             '-o','UserKnownHostsFile="'+os.environ['DEPLOY_KNOWN_HOSTS']+'"']
    return target, f'{user}@{host}', options, public_url, approver

def public_smoke(public_url):
    for attempt in range(6):
        try:
            with urlopen(public_url+'/', timeout=10) as front:
                if front.status!=200 or front.headers.get_content_type()!='text/html' or front.geturl().rstrip('/')!=public_url:
                    raise RuntimeError('Public frontend did not return the expected HTTPS page')
            with urlopen(public_url+'/api/actuator/health', timeout=10) as health:
                if health.status!=200 or health.geturl()!=public_url+'/api/actuator/health' or json.load(health).get('status')!='UP':
                    raise RuntimeError('Public backend readiness is not UP')
            print('PUBLIC_SMOKE_OK '+public_url)
            return
        except (OSError, ValueError, RuntimeError) as failure:
            if attempt==5:
                raise RuntimeError('Public smoke failed after remote deploy: '+str(failure)) from failure
            time.sleep(5)

def remote(manifest_path):
    from jenkins_reports import redact, timing_event
    manifest = read_manifest(manifest_path)
    if os.getenv('BUILD_NUMBER'):
        from ci import source_identity
        from ci_release import verify_local
        if source_identity()['dirty']:
            raise RuntimeError('Server deployment requires a clean checkout')
        checkpoint = verify_local(ROOT, os.environ)
        if manifest != {'commit': checkpoint['commit'], 'images': checkpoint['images']}:
            raise RuntimeError('Server release manifest does not match verified CI evidence')
    target, destination, options, public_url, approver=remote_target()
    timing_event('Package the server release bundle')
    bundle=ROOT/'artifacts/release-bundle.tar.gz';bundle.parent.mkdir(exist_ok=True)
    with tarfile.open(bundle,'w:gz') as archive:
        for item in ['compose.prod.yaml','compose.tls.yaml','compose.monitoring.yaml','scripts/docker.py','scripts/deploy.py','infrastructure']:
            archive.add(ROOT/item,arcname=item)
        archive.add(manifest_path,arcname='artifacts/reports/release.json')
    location='/opt/sms/'+target
    timing_event('Transfer the release bundle over SSH')
    subprocess.run(['scp',*options,str(bundle),f'{destination}:{location}/incoming-release.tar.gz'],check=True)
    command=(f'cd {location} && tar -xzf incoming-release.tar.gz && '
             f'RELEASE_APPROVER={approver} SMS_EXPECTED_DEPLOY_ENV={target} '
             f'SMS_EXPECTED_PUBLIC_URL={shlex.quote(public_url)} '
             'python3 scripts/deploy.py apply --manifest artifacts/reports/release.json --allow-migration')
    try:
        timing_event('Apply the release on the remote server')
        subprocess.run(['ssh',*options,destination,command],check=True)
        timing_event('Check public HTTPS and backend readiness')
        public_smoke(public_url)
    except (RuntimeError, OSError, subprocess.SubprocessError):
        timing_event('Collect logs from the remote Compose target')
        log_command = (f'cd {location} && docker compose --env-file .env -f compose.prod.yaml '
                       'logs --no-color --tail=100 db migrate backend frontend')
        try:
            result = subprocess.run(['ssh', *options, destination, log_command],
                                    capture_output=True, timeout=30)
            destination_log = ROOT / 'artifacts/reports/docker-server.log'
            destination_log.parent.mkdir(parents=True, exist_ok=True)
            content = (result.stdout + result.stderr).decode('utf-8', 'replace')
            destination_log.write_text(redact(content)[-65536:], encoding='utf-8')
            if result.returncode:
                print('CI evidence limitation: remote Compose log command failed.', file=sys.stderr)
        except (OSError, subprocess.SubprocessError) as error:
            print(f'CI evidence limitation: server logs unavailable ({type(error).__name__}).',
                  file=sys.stderr)
        raise

def start_monitoring(runtime):
    monitoring=ROOT/'infrastructure/monitoring'
    revision=hashlib.sha256()
    for config in sorted(path for path in monitoring.iterdir() if path.is_file()):
        revision.update(config.name.encode())
        revision.update(hashlib.sha256(config.read_bytes()).digest())
    os.environ['SMS_MONITORING_DIR']=monitoring.as_posix()
    os.environ['SMS_MONITORING_REVISION']=revision.hexdigest()
    overlay=('-f',str(ROOT/'compose.monitoring.yaml'),'--profile','monitoring')
    services=('prometheus','grafana','alertmanager','blackbox','cadvisor','node-exporter','volume-size')
    runtime.run(*overlay,'up','-d','--no-build','--wait','--wait-timeout','180',*services)
    runtime.run(*overlay,'ps')
    return revision.hexdigest()

def apply(manifest_path,allow_migration):
    manifest=read_manifest(manifest_path);runtime=Runtime(production=True)
    if runtime.config.get('SMS_SEED_DEMO','false')!='false':raise RuntimeError('Demo seed is forbidden on staging/production')
    if runtime.config.get('SMS_ENVIRONMENT') not in ['staging','production']:raise RuntimeError('Set the environment explicitly')
    expected=os.getenv('SMS_EXPECTED_DEPLOY_ENV')
    if expected and runtime.config['SMS_ENVIRONMENT']!=expected:raise RuntimeError('SSH target environment differs from the server configuration')
    expected_url=os.getenv('SMS_EXPECTED_PUBLIC_URL')
    if expected_url and runtime.config.get('SMS_PUBLIC_URL','').rstrip('/')!=expected_url:raise RuntimeError('Public URL differs from the server configuration')
    if runtime.config['SMS_ENVIRONMENT']=='production' and (runtime.config.get('SESSION_SECURE')!='true' or not runtime.config.get('APP_DOMAIN')):raise RuntimeError('Production requires HTTPS domain and Secure cookies')
    if not allow_migration:raise RuntimeError('Review migration compatibility and approve before deployment')
    previous=dict(runtime.config)
    image_keys={name.upper()+'_IMAGE' for name in REQUIRED}
    configured=image_keys.intersection(previous)
    if configured and configured!=image_keys:
        raise RuntimeError('Existing deployment must define all three image digests')
    current=dict(previous)
    for service,image in manifest['images'].items():current[service.upper()+'_IMAGE']=image
    snapshot=None
    before=None
    if configured:
        before=schema(runtime)
        snapshot=backup(runtime);restore_test(runtime,snapshot)
    else:
        # The first release may initialize a clean database. Existing data needs
        # the normal backup/restore path and explicit previous image digests.
        save_env(runtime.env_file,current)
        try:
            runtime=Runtime(production=True)
            runtime.run('up','-d','--wait','--wait-timeout','240','db')
            if runtime.sql("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE()")!='0':
                raise RuntimeError('First deploy requires an empty database')
        finally:
            save_env(runtime.env_file,previous)
    save_env(runtime.env_file,current);runtime=Runtime(production=True)
    try:
        runtime.run('pull','backend','frontend','migrate')
        runtime.run('run','--rm','migrate')
        runtime.run('up','-d','--no-build','--wait','--wait-timeout','240','backend','frontend')
        if current.get('APP_DOMAIN'):
            subprocess.run(runtime.compose+['-f',str(ROOT/'compose.tls.yaml'),'up','-d','gateway'],cwd=ROOT,check=True)
        smoke(runtime,login=False)
    except Exception:
        # Application rollback only when the database version did not change.
        if before is None:
            print('Initial deployment failed. Inspect the migration state before retrying.',file=sys.stderr)
        elif schema(runtime)==before:
            save_env(runtime.env_file,previous);old=Runtime(production=True)
            old.run('up','-d','--no-build','--no-deps','backend','frontend')
            smoke(old,login=False)
            print('Previous application digests restored; failed release was not marked successful.')
        else:print('Database version changed or rollback images missing. Backup retained; manual DB compatibility/restore review required.',file=sys.stderr)
        raise
    start_monitoring(runtime)
    receipt=manifest|{'environment':current['SMS_ENVIRONMENT'],'schema_version':schema(runtime),'backup':str(snapshot) if snapshot else None,'approver':os.getenv('RELEASE_APPROVER','manual'),'deployed_at':dt.datetime.now().isoformat()}
    folder=ROOT/'.local/releases';folder.mkdir(parents=True,exist_ok=True)
    (folder/(dt.datetime.now().strftime('%Y%m%d_%H%M%S')+'.json')).write_text(json.dumps(receipt,indent=2))
    print('DEPLOY_OK commit='+manifest['commit'])

def rollback(receipt_path):
    receipt=read_manifest(receipt_path);runtime=Runtime(production=True)
    if receipt.get('schema_version')!=schema(runtime):raise RuntimeError('Schema version differs. Review DB compatibility/restore plan before rollback.')
    config=dict(runtime.config)
    for service,image in receipt['images'].items():config[service.upper()+'_IMAGE']=image
    save_env(runtime.env_file,config);runtime=Runtime(production=True)
    runtime.run('pull','backend','frontend');runtime.run('up','-d','--no-build','--no-deps','backend','frontend')
    smoke(runtime,login=False);print('ROLLBACK_OK commit='+receipt['commit'])

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command',choices=['check-target','remote','apply','rollback'])
    parser.add_argument('--manifest',type=Path)
    parser.add_argument('--allow-migration',action='store_true')
    args=parser.parse_args()
    try:
        if args.command=='check-target':
            target, destination, options, _, _ = remote_target()
            subprocess.run(['ssh', *options, destination,
                            f'cd /opt/sms/{target} && test -f .env && docker compose version && python3 --version'],
                           check=True)
        elif not args.manifest:parser.error('--manifest is required for this command')
        elif args.command=='remote':remote(args.manifest)
        elif args.command=='apply':apply(args.manifest,args.allow_migration)
        else:rollback(args.manifest)
    except (RuntimeError,OSError,ValueError,subprocess.SubprocessError) as error:print('Deployment stopped: '+str(error),file=sys.stderr);sys.exit(1)
