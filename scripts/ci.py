"""Cross-platform commands used by Jenkins; no secrets appear in command arguments."""
import argparse
import json
import datetime as dt
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
from docker import ROOT, Runtime, initialize, invoke, smoke, backup, restore_test

REPORTS=ROOT/'artifacts/reports'
REPORTS.mkdir(parents=True,exist_ok=True)
WIN=os.name=='nt'
MVN=str(ROOT/'backend'/('mvnw.cmd' if WIN else 'mvnw'))
MAVEN=[MVN] if WIN else ['sh',MVN]
NPM='npm.cmd' if WIN else 'npm'

def run(command,directory=None,**kwargs):
    # Log only the executable: command arguments can include sensitive values.
    started = time.monotonic()
    print('CI start: ' + str(command[0]), flush=True)
    result=subprocess.run(command,cwd=directory or ROOT,**kwargs)
    elapsed = time.monotonic() - started
    print(f'CI finish: {command[0]} elapsed={elapsed:.1f}s exit={result.returncode}', flush=True)
    if result.returncode:
        code = result.returncode & 0xffffffff
        raise RuntimeError(f'CI command failed: {command[0]} (exit {result.returncode}, hex 0x{code:08X}). See preceding output; subsequent gates remain blocked.')
    return result

def docker_cli():return ['docker']+(['--host','npipe:////./pipe/dockerDesktopLinuxEngine'] if WIN else [])

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

def main(step):
    if step=='prepare':
        run([sys.executable,'-m','unittest','discover','-s','scripts/tests','-v'])
        for command in [['java','-version'],['node','--version'],[NPM,'--version'],docker_cli()+['version'],docker_cli()+['compose','version']]:run(command)
        java=subprocess.run(['java','-version'],capture_output=True,text=True)
        if not re.search(r'version "21[.]',java.stderr+java.stdout):raise RuntimeError('JDK 21 is required')
        version=subprocess.check_output(['node','--version'],text=True).strip().lstrip('v')
        major,minor=map(int,version.split('.')[:2])
        if major<22 or (major==22 and minor<12):raise RuntimeError('Node 22.12+ is required')
        chrome=os.getenv('CHROME_PATH','C:/Program Files/Google/Chrome/Application/chrome.exe' if WIN else '/usr/bin/google-chrome')
        if not Path(chrome).is_file():raise RuntimeError('Google Chrome or CHROME_PATH is required for browser tests')
        sha=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
        dirty=bool(subprocess.check_output(['git','status','--porcelain'],cwd=ROOT,text=True))
        (REPORTS/'build.json').write_text(json.dumps({'commit':sha,'dirty':dirty,'build_url':os.getenv('BUILD_URL','local')},indent=2))
    elif step=='backend':run([*MAVEN,'-B','-ntp','clean','verify'],ROOT/'backend')
    elif step=='frontend':
        for filename in ['junit.xml','lcov.info','coverage-summary.json']:
            (ROOT/'frontend/coverage'/filename).unlink(missing_ok=True)
        for command in [[NPM,'ci','--prefer-offline','--no-fund'],[NPM,'run','lint','--','--cache','--cache-strategy','content','--cache-location','.eslintcache'],[NPM,'run','test:ci'],[NPM,'run','build']]:run(command,ROOT/'frontend')
    elif step=='sonar':
        if not os.getenv('SONAR_HOST_URL') or not os.getenv('SONAR_AUTH_TOKEN'):raise RuntimeError('Configure the Jenkins SonarQube server/credential first.')
        env={**os.environ,'SONAR_TOKEN':os.environ['SONAR_AUTH_TOKEN']}
        # Maven resolves module paths against backend/, even with a project base override.
        # Absolute paths keep both Java and frontend scope independent of that module base.
        paths = {
            'sonar.sources': ['backend/src/main/java', 'frontend/src'],
            'sonar.tests': ['backend/src/test/java', 'frontend/tests'],
            'sonar.java.binaries': ['backend/target/classes'],
            'sonar.coverage.jacoco.xmlReportPaths': ['backend/target/site/jacoco/jacoco.xml'],
            'sonar.javascript.lcov.reportPaths': ['frontend/coverage/lcov.info'],
        }
        properties = ['-D' + key + '=' + ','.join((ROOT / path).resolve().as_posix() for path in values)
                      for key, values in paths.items()]
        run([*MAVEN, '-B', '-ntp',
             'org.sonarsource.scanner.maven:sonar-maven-plugin:5.1.0.4751:sonar',
             '-Dsonar.projectBaseDir=' + ROOT.as_posix(), '-Dsonar.projectKey=cmc-sms',
             '-Dsonar.sourceEncoding=UTF-8', *properties], ROOT/'backend', env=env)
    elif step=='build':
        tag=os.environ.get('IMAGE_TAG','local')
        if not re.fullmatch(r'[a-zA-Z0-9_.-]+',tag):raise RuntimeError('Invalid image tag')
        for service,path in [('backend','backend/Dockerfile'),('frontend','frontend/Dockerfile'),('migration','infrastructure/migration/Dockerfile')]:
            run(docker_cli()+['build','--label','org.opencontainers.image.revision='+tag,'-f',path,'-t','sms-'+service+':'+tag,'.'])
    elif step=='mysql':
        (REPORTS/'mysql-integration.json').unlink(missing_ok=True)
        env_file=ROOT/'artifacts/ci/.env'
        if not env_file.exists():initialize(env_file,ci=True)
        runtime=Runtime(env_file)
        if not runtime.config['COMPOSE_PROJECT_NAME'].startswith('sms_ci_'):raise RuntimeError('Integration tests require an isolated CI project')
        try:
            runtime.run('up','-d','--no-build','--wait','--wait-timeout','300','frontend','backend')
            runtime.run('run','--rm','provision')
            results=smoke(runtime)
            from mysql_workflows import verify_workflows
            workflows=verify_workflows(runtime)
            # Browser checks run against the same isolated MySQL fixture, not host data.
            credentials=__import__('docker').settings(runtime.secret_dir/'demo_accounts')
            actors={'PRINCIPAL':'principal','TRAINING_OFFICE':'training_demo','CTSV':'ctsv_demo','LECTURER':'lecturer_demo_01','STUDENT':'student_demo_001','APPLICANT':'applicant_demo_03'}
            for role,username in actors.items():
                browser_env={**os.environ,'SMS_UI_BASE_URL':runtime.url(),'SMS_UI_ROLE':role,'SMS_UI_USERNAME':username,'SMS_UI_PASSWORD':credentials[username],'SMS_UI_DEBUG_PORT':'9231'}
                with open(REPORTS/('browser-'+role+'.log'),'wb') as output:
                    run(['node','tests/browser-full-ui.mjs'],ROOT/'frontend',env=browser_env,stdout=output,stderr=subprocess.STDOUT)
            snapshot=backup(runtime);restore_test(runtime,snapshot)
            before=runtime.sql('SELECT COUNT(*) FROM students UNION ALL SELECT COUNT(*) FROM payments')
            runtime.run('restart','db');runtime.run('up','-d','--wait','--wait-timeout','180','backend','frontend')
            if before!=runtime.sql('SELECT COUNT(*) FROM students UNION ALL SELECT COUNT(*) FROM payments'):raise RuntimeError('Persistence check failed')
            smoke(runtime)
            (REPORTS/'mysql-integration.json').write_text(json.dumps({'passed':True,'created_at':dt.datetime.now().isoformat(),'image_tag':os.getenv('IMAGE_TAG','local'),'checks':results,'workflows':workflows,'restore':True,'restart_persistence':True},indent=2))
        finally:
            runtime.run('logs','--no-color','--tail','200','backend','migrate',destination=REPORTS/'mysql-runtime.log',check=False)
            # Only the generated, disposable CI namespace is removed, never local/production volumes.
            runtime.run('down','--volumes','--remove-orphans')
    elif step in ['security','secrets']:
        scanner='vuln' if step=='security' else 'secret'
        severity='CRITICAL' if step=='security' else 'UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL'
        prefix='trivy' if step=='security' else 'trivy-secret'
        for name in ['filesystem','backend','frontend','migration']:
            (REPORTS/(prefix+'-'+name+'.json')).unlink(missing_ok=True)
        tracked=subprocess.check_output(['git','ls-files'],cwd=ROOT,text=True).splitlines()
        prohibited=[p for p in tracked if '/.local/' in p or p.startswith(('.secrets/','backups/')) or (Path(p).name.startswith('.env') and Path(p).name!='.env.example')]
        if prohibited:raise RuntimeError('Sensitive runtime files are tracked in Git')
        with open(REPORTS/'npm-audit.json','wb') as out:
            result=subprocess.run([NPM,'audit','--json','--audit-level=critical'],cwd=ROOT/'frontend',stdout=out)
        if result.returncode:raise RuntimeError('Dependency audit failed or could not complete')
        image=os.getenv('TRIVY_IMAGE','aquasec/trivy:0.64.1')
        skips=['backend/target','frontend/dist','.git','.secrets','backend/.local','backend/private-files','frontend/node_modules','frontend/.npm-cache','backups','artifacts']
        command=docker_cli()+['run','--rm','-v',str(ROOT)+':/work:ro','-v','sms_trivy_cache:/root/.cache/','-w','/work',image,'fs','--timeout','15m','--no-progress','--scanners',scanner,'--severity',severity,'--exit-code','1']
        for path in skips:command+=['--skip-dirs','/work/'+path]
        command+=['--skip-files','.env','--skip-files','backend/.env.local','--skip-files','frontend/.env.local','--format','json','.']
        scan_report(command,REPORTS/(prefix+'-filesystem.json'))
        for service in ['backend','frontend','migration']:
            target='sms-'+service+':'+os.getenv('IMAGE_TAG','local')
            archive=ROOT/'artifacts'/('scan-'+service+'.tar')
            run(docker_cli()+['save','-o',str(archive),target])
            try:
                scan_report(docker_cli()+['run','--rm','-v',str(archive)+':/image.tar:ro','-v','sms_trivy_cache:/root/.cache/',image,'image','--timeout','15m','--no-progress','--input','/image.tar','--scanners',scanner,'--severity',severity,'--exit-code','1','--format','json'],REPORTS/(prefix+'-'+service+'.json'))
            finally:archive.unlink(missing_ok=True)
    elif step=='publish':
        # Publish only the exact local images already tested/scanned. Registry login is external.
        if os.getenv('CHANGE_ID'):raise RuntimeError('Pull requests may not publish images')
        if os.getenv('QUALITY_GATE_PASSED')!='true':raise RuntimeError('Quality gate is not approved')
        repository=os.environ['REGISTRY_NAMESPACE'].lower().rstrip('/')
        if not re.fullmatch(r'[a-z0-9.-]+(?:/[a-z0-9_.-]+)+',repository):raise RuntimeError('Invalid registry namespace')
        tag=os.environ['IMAGE_TAG'];manifest={'commit':tag,'images':{}}
        if not re.fullmatch(r'[0-9a-f]{40}',tag):raise RuntimeError('Publishing requires full commit SHA')
        for service in ['backend','frontend','migration']:
            target=repository+'/sms-'+service+':'+tag
            run(docker_cli()+['tag','sms-'+service+':'+tag,target]);run(docker_cli()+['push',target])
            digests=json.loads(subprocess.check_output(docker_cli()+['image','inspect',target,'--format','{{json .RepoDigests}}'],text=True))
            digest=next(value for value in digests if value.startswith(repository+'/sms-'+service+'@sha256:'))
            manifest['images'][service]=digest
        (REPORTS/'release.json').write_text(json.dumps(manifest,indent=2))
    else:raise RuntimeError('Unknown step')

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('step',choices=['prepare','backend','frontend','sonar','build','mysql','security','secrets','publish'])
    try:main(parser.parse_args().step)
    except (RuntimeError,subprocess.SubprocessError,OSError) as error:print(str(error),file=sys.stderr);sys.exit(1)
