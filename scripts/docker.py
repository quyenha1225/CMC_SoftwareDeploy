"""Docker local operations. Secrets stay in ignored files, never in CLI arguments."""
import argparse
import base64
import datetime as dt
import hashlib
import http.cookiejar
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]

def invoke(command, *, capture=False, data=None, destination=None, check=True):
    if destination:
        with open(destination,'wb') as output:
            result=subprocess.run(command,cwd=ROOT,input=data,stdout=output,stderr=subprocess.PIPE)
    else:
        result=subprocess.run(command,cwd=ROOT,input=data,capture_output=capture)
    if check and result.returncode:
        if capture and result.stderr: print(result.stderr.decode('utf-8','replace')[-2000:],file=sys.stderr)
        raise RuntimeError('Operation failed: '+str(command[0])+' (exit '+str(result.returncode)+')')
    return result.stdout.decode('utf-8').strip() if capture else result.returncode

def settings(path):
    return dict(line.split('=',1) for line in path.read_text(encoding='utf-8-sig').splitlines() if '=' in line and not line.startswith('#'))

class Runtime:
    def __init__(self,env_file=None,context=None,production=False):
        self.env_file=Path(env_file or ROOT/'.env').resolve()
        self.config=settings(self.env_file)
        self.context=context or ('desktop-linux' if os.name=='nt' else '')
        self.docker=['docker']+(['--context',self.context] if self.context else [])
        self.compose=self.docker+['compose','--project-directory',str(ROOT),'--env-file',str(self.env_file),'-f',str(ROOT/('compose.prod.yaml' if production else 'compose.yaml'))]
        self.secret_dir=Path(self.config.get('SMS_SECRETS_DIR',str(ROOT/'.secrets')))
        if not self.secret_dir.is_absolute():self.secret_dir=ROOT/self.secret_dir
    def run(self,*args,**kwargs):return invoke(self.compose+list(args),**kwargs)
    def sql(self,query):
        return self.run('exec','-T','db','sh','-c','export MYSQL_PWD="$(cat /run/secrets/mysql_root_password)"; exec mysql -uroot --default-character-set=utf8mb4 --batch --raw --skip-column-names "$MYSQL_DATABASE"',data=query.encode('utf-8'),capture=True)
    def url(self):
        port=self.run('port','frontend','8080',capture=True).splitlines()[0].rsplit(':',1)[1]
        return 'http://127.0.0.1:'+port

def initialize(path,ci=False):
    if path.exists():raise RuntimeError('Environment already exists; existing secrets were not replaced.')
    folder=path.parent/('.secrets-ci' if ci else '.secrets')
    folder.mkdir(parents=True,exist_ok=True);folder.chmod(0o700)
    values={name:secrets.token_urlsafe(32) for name in ['mysql_root_password','db_password','migrator_password','bootstrap_password','grafana_password']}
    values['jwt_secret']=base64.b64encode(secrets.token_bytes(64)).decode()
    values['identity_key']=base64.b64encode(secrets.token_bytes(32)).decode()
    values['smtp_password']=''
    accounts=['principal','principal_demo','training_demo','ctsv_demo',*[f'lecturer_demo_{i:02}' for i in range(1,4)],*[f'student_demo_{i:03}' for i in range(1,7)],'applicant_demo_03','applicant_demo_04']
    passwords={name:secrets.token_urlsafe(18)+'Aa1!' for name in accounts}
    values['demo_accounts']='\n'.join(name+'='+passwords[name] for name in accounts)+'\n'
    for name,value in values.items():
        target=folder/name
        if target.exists():raise RuntimeError('Secret exists without environment file; review before retry.')
        target.write_text(value,encoding='utf-8');target.chmod(0o444)
    text=(ROOT/'.env.example').read_text()
    if ci:text=text.replace('COMPOSE_PROJECT_NAME=sms_local','COMPOSE_PROJECT_NAME=sms_ci_'+secrets.token_hex(4)).replace('APP_PORT=8088','APP_PORT=0')
    text+='\nSMS_SECRETS_DIR='+folder.as_posix()+'\nIMAGE_TAG='+os.getenv('IMAGE_TAG','local')+'\n'
    path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text,encoding='utf-8')
    destination=ROOT/'backend/.local/docker-credentials.md' if not ci else path.parent/'credentials.md'
    destination.parent.mkdir(parents=True,exist_ok=True)
    destination.write_text('# Docker local accounts\n\nDifferent passwords from the existing host database.\n\n| Username | Password |\n|---|---|\n'+'\n'.join(f'| `{name}` | `{passwords[name]}` |' for name in accounts)+'\n\nGrafana admin password is in the protected grafana_password secret file.\n',encoding='utf-8')
    print('Initialized non-secret environment and protected secret files. Credentials: '+str(destination))

def smoke(runtime,login=True):
    url=runtime.url()
    results=[]
    for route in ['/','/healthz','/api/actuator/health']:
        with urllib.request.urlopen(url+route,timeout=15) as response:
            body=response.read()
            if response.status!=200:raise RuntimeError('Smoke failed: '+route)
            if route.endswith('/health') and json.loads(body)['status']!='UP':raise RuntimeError('Database readiness is not UP')
        results.append(route)
    if login:
        credentials=settings(runtime.secret_dir/'demo_accounts')
        for username,password in credentials.items():
            opener=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
            csrf=json.load(opener.open(url+'/api/auth/csrf',timeout=15))
            req=urllib.request.Request(url+'/api/auth/login',data=json.dumps({'username':username,'password':password}).encode(),headers={'Content-Type':'application/json',csrf['headerName']:csrf['token']})
            me=json.load(opener.open(req,timeout=15))
            if not me.get('roles'):raise RuntimeError('Account has no role')
            csrf=json.load(opener.open(url+'/api/auth/csrf',timeout=15))
            opener.open(urllib.request.Request(url+'/api/auth/logout',data=b'{}',headers={'Content-Type':'application/json',csrf['headerName']:csrf['token']}),timeout=15).close()
        results.append('15 role logins')
    for view in ['v_normalization_checks','v_approval_workflow_checks']:
        records=runtime.sql('SELECT check_name,violation_count FROM '+view)
        if any(int(line.rsplit('\t',1)[1]) for line in records.splitlines()):raise RuntimeError('SQL integrity failed: '+view)
    results.append('16 SQL integrity checks')
    print('PASS smoke '+url+': '+', '.join(results))
    return results

def backup(runtime):
    stamp=dt.datetime.now().strftime('%Y%m%d_%H%M%S')
    folder=ROOT/'backups'/runtime.config['COMPOSE_PROJECT_NAME']/stamp
    folder.mkdir(parents=True,exist_ok=False);folder.chmod(0o700)
    command=runtime.compose+['exec','-T','db','sh','-c','export MYSQL_PWD="$(cat /run/secrets/mysql_root_password)"; exec mysqldump -uroot --single-transaction --routines --triggers --no-tablespaces --set-gtid-purged=OFF --column-statistics=0 "$MYSQL_DATABASE"']
    invoke(command,destination=folder/'database.sql')
    runtime.run('exec','-T','backend','tar','-czf','-','-C','/app/private-files','.',destination=folder/'private-files.tar.gz')
    counts=runtime.sql("SELECT table_name FROM information_schema.tables WHERE table_schema=DATABASE() AND table_type='BASE TABLE'").splitlines()
    inventory={table:int(runtime.sql('SELECT COUNT(*) FROM `'+table+'`')) for table in counts}
    manifest={'created_at':stamp,'database':runtime.config.get('DB_NAME','sms_db'),'rows':inventory,'sha256':{name:hashlib.sha256((folder/name).read_bytes()).hexdigest() for name in ['database.sql','private-files.tar.gz']}}
    (folder/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    print('Backup created: '+str(folder));return folder

def restore_test(runtime,folder):
    folder=Path(folder).resolve();manifest=json.loads((folder/'manifest.json').read_text())
    for name,digest in manifest['sha256'].items():
        if hashlib.sha256((folder/name).read_bytes()).hexdigest()!=digest:raise RuntimeError('Backup checksum mismatch')
    name='sms-restore-'+secrets.token_hex(5)
    invoke(runtime.docker+['run','-d','--rm','--network','none','--name',name,'--tmpfs','/var/lib/mysql','-e','MYSQL_ALLOW_EMPTY_PASSWORD=yes','mysql:8.4.5'],capture=True)
    try:
        for _ in range(90):
            probe=subprocess.run(runtime.docker+['exec',name,'mysql','--protocol=tcp','--host=127.0.0.1','-uroot','--execute=SELECT 1'],capture_output=True)
            if probe.returncode==0:break
            time.sleep(1)
        else:raise RuntimeError('Restore database did not start')
        invoke(runtime.docker+['exec','-i',name,'mysql','-uroot'],data=b'CREATE DATABASE sms_restore CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;')
        source=(folder/'database.sql').read_text(encoding='utf-8')
        source=re.sub(r'DEFINER=`[^`]+`@`[^`]+`','',source)
        invoke(runtime.docker+['exec','-i',name,'mysql','-uroot','sms_restore'],data=source.encode())
        for table,count in manifest['rows'].items():
            actual=invoke(runtime.docker+['exec',name,'mysql','-uroot','--batch','--skip-column-names','sms_restore','-e','SELECT COUNT(*) FROM `'+table+'`'],capture=True)
            if int(actual)!=count:raise RuntimeError('Restore row mismatch: '+table)
        for view in ['v_normalization_checks','v_approval_workflow_checks']:
            values=invoke(runtime.docker+['exec',name,'mysql','-uroot','--batch','--skip-column-names','sms_restore','-e','SELECT violation_count FROM '+view],capture=True)
            if any(int(value) for value in values.splitlines()):raise RuntimeError('Restore integrity failed')
        # Verify archive readability without extracting sensitive documents onto the host.
        import tarfile
        with tarfile.open(folder/'private-files.tar.gz') as archive:
            if any(member.name.startswith('/') or '..' in Path(member.name).parts for member in archive.getmembers()):raise RuntimeError('Unsafe archive path')
        (folder/'restore-test.json').write_text(json.dumps({'passed':True,'tables':len(manifest['rows']),'private_archive_readable':True,'checked_at':dt.datetime.now().isoformat()},indent=2))
        print('PASS isolated restore: '+str(len(manifest['rows']))+' tables and private archive')
    finally:invoke(runtime.docker+['rm','-f',name],capture=True,check=False)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--env-file',type=Path,default=ROOT/'.env')
    parser.add_argument('--context')
    parser.add_argument('--production',action='store_true')
    parser.add_argument('command',choices=['init','config','up','status','smoke','backup','restore-test','restart-test','ci','logs'])
    parser.add_argument('--ci',action='store_true')
    parser.add_argument('--backup-dir',type=Path)
    args=parser.parse_args()
    if args.command=='init':initialize(args.env_file.resolve(),args.ci);return
    runtime=Runtime(args.env_file,args.context,args.production)
    if args.command=='config':runtime.run('config','--quiet')
    elif args.command in ['up','ci']:
        if args.production:raise RuntimeError('Use reviewed digest deployment, not local up.')
        runtime.run('up','-d','--build','--wait','--wait-timeout','300','frontend','backend')
        runtime.run('run','--rm','provision')
        smoke(runtime)
        if args.command=='ci':
            try:
                snapshot=backup(runtime);restore_test(runtime,snapshot)
                runtime.run('restart','db');runtime.run('up','-d','--wait','--wait-timeout','180','backend','frontend');smoke(runtime)
            finally:runtime.run('down','--remove-orphans')
    elif args.command=='status':runtime.run('ps','-a')
    elif args.command=='logs':runtime.run('logs','--tail','100','backend','migrate')
    elif args.command=='smoke':smoke(runtime,login=not args.production)
    elif args.command=='backup':backup(runtime)
    elif args.command=='restore-test':
        if not args.backup_dir:raise RuntimeError('--backup-dir required')
        restore_test(runtime,args.backup_dir)
    elif args.command=='restart-test':
        before=runtime.sql('SELECT COUNT(*) FROM students UNION ALL SELECT COUNT(*) FROM payments')
        runtime.run('restart','db');runtime.run('up','-d','--wait','--wait-timeout','180','backend','frontend')
        if before!=runtime.sql('SELECT COUNT(*) FROM students UNION ALL SELECT COUNT(*) FROM payments'):raise RuntimeError('Persistence check failed')
        smoke(runtime,login=not args.production)
        print('PASS MySQL restart retained students/payments')

if __name__=='__main__':
    try:main()
    except (RuntimeError,subprocess.SubprocessError,OSError,urllib.error.URLError) as failure:
        print('Stopped: '+str(failure),file=sys.stderr);sys.exit(1)
