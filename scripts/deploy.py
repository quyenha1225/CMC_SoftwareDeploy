"""Deploy/rollback only tested immutable images; keep database rollback explicit."""
import argparse
import datetime as dt
import json
import hashlib
import os
from pathlib import Path
import re
import subprocess
import sys
import tarfile
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
    temp=path.with_suffix('.tmp')
    temp.write_text('\n'.join(k+'='+v for k,v in data.items())+'\n',encoding='utf-8');temp.replace(path)

def remote(manifest_path):
    read_manifest(manifest_path)
    target=os.environ['DEPLOY_TARGET']
    if target not in ['staging','production']:raise RuntimeError('Invalid deployment environment')
    host=os.environ[target.upper()+'_HOST'];user=os.environ['DEPLOY_USER']
    if not re.fullmatch(r'[A-Za-z0-9.-]+',host) or not re.fullmatch(r'[a-zA-Z0-9_-]+',user):raise RuntimeError('Invalid SSH target')
    options=['-i',os.environ['DEPLOY_KEY'],'-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','UserKnownHostsFile='+os.environ['DEPLOY_KNOWN_HOSTS']]
    bundle=ROOT/'artifacts/release-bundle.tar.gz';bundle.parent.mkdir(exist_ok=True)
    with tarfile.open(bundle,'w:gz') as archive:
        for item in ['compose.prod.yaml','compose.tls.yaml','scripts/docker.py','scripts/deploy.py','infrastructure']:
            archive.add(ROOT/item,arcname=item)
        archive.add(manifest_path,arcname='artifacts/reports/release.json')
    location='/opt/sms/'+target
    subprocess.run(['scp',*options,str(bundle),f'{user}@{host}:{location}/incoming-release.tar.gz'],check=True)
    approver=os.getenv('RELEASE_APPROVER','staging-ci')
    if not re.fullmatch(r'[A-Za-z0-9_.@-]+',approver):raise RuntimeError('Invalid approval identity')
    command=f'cd {location} && tar -xzf incoming-release.tar.gz && RELEASE_APPROVER={approver} python3 scripts/deploy.py apply --manifest artifacts/reports/release.json --allow-migration'
    subprocess.run(['ssh',*options,user+'@'+host,command],check=True)

def apply(manifest_path,allow_migration):
    manifest=read_manifest(manifest_path);runtime=Runtime(production=True)
    if runtime.config.get('SMS_SEED_DEMO','false')!='false':raise RuntimeError('Demo seed is forbidden on staging/production')
    if runtime.config.get('SMS_ENVIRONMENT') not in ['staging','production']:raise RuntimeError('Set the environment explicitly')
    if runtime.config['SMS_ENVIRONMENT']=='production' and (runtime.config.get('SESSION_SECURE')!='true' or not runtime.config.get('APP_DOMAIN')):raise RuntimeError('Production requires HTTPS domain and Secure cookies')
    if not allow_migration:raise RuntimeError('Review migration compatibility and approve before deployment')
    previous=dict(runtime.config);before=schema(runtime)
    snapshot=backup(runtime);restore_test(runtime,snapshot)
    current=dict(previous)
    for service,image in manifest['images'].items():current[service.upper()+'_IMAGE']=image
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
        if schema(runtime)==before and all(name+'_IMAGE' in previous for name in ['BACKEND','FRONTEND','MIGRATION']):
            save_env(runtime.env_file,previous);old=Runtime(production=True)
            old.run('up','-d','--no-build','--no-deps','backend','frontend')
            smoke(old,login=False)
            print('Previous application digests restored; failed release was not marked successful.')
        else:print('Database version changed or rollback images missing. Backup retained; manual DB compatibility/restore review required.',file=sys.stderr)
        raise
    receipt=manifest|{'environment':current['SMS_ENVIRONMENT'],'schema_version':schema(runtime),'backup':str(snapshot),'approver':os.getenv('RELEASE_APPROVER','manual'),'deployed_at':dt.datetime.now().isoformat()}
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
    parser.add_argument('command',choices=['remote','apply','rollback'])
    parser.add_argument('--manifest',required=True,type=Path)
    parser.add_argument('--allow-migration',action='store_true')
    args=parser.parse_args()
    try:
        if args.command=='remote':remote(args.manifest)
        elif args.command=='apply':apply(args.manifest,args.allow_migration)
        else:rollback(args.manifest)
    except (RuntimeError,OSError,subprocess.SubprocessError) as error:print('Deployment stopped: '+str(error),file=sys.stderr);sys.exit(1)
