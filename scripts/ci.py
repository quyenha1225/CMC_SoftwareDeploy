"""Cross-platform commands used by Jenkins; no secrets appear in command arguments."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from docker import ROOT, Runtime, initialize, invoke, smoke, backup, restore_test

REPORTS=ROOT/'artifacts/reports'
REPORTS.mkdir(parents=True,exist_ok=True)
WIN=os.name=='nt'
MVN=str(ROOT/'backend'/('mvnw.cmd' if WIN else 'mvnw'))
NPM='npm.cmd' if WIN else 'npm'

def run(command,directory=None,**kwargs):
    result=subprocess.run(command,cwd=directory or ROOT,**kwargs)
    if result.returncode:raise RuntimeError('CI command failed: '+str(command[0]))
    return result

def docker_cli():return ['docker']+(['--context','desktop-linux'] if WIN else [])

def main(step):
    if step=='prepare':
        for command in [['java','-version'],['node','--version'],[NPM,'--version'],docker_cli()+['version'],docker_cli()+['compose','version']]:run(command)
        sha=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
        dirty=bool(subprocess.check_output(['git','status','--porcelain'],cwd=ROOT,text=True))
        (REPORTS/'build.json').write_text(json.dumps({'commit':sha,'dirty':dirty,'build_url':os.getenv('BUILD_URL','local')},indent=2))
    elif step=='backend':run([MVN,'-B','-ntp','clean','verify'],ROOT/'backend')
    elif step=='frontend':
        for command in [[NPM,'ci'],[NPM,'run','lint'],[NPM,'run','test:ci'],[NPM,'run','build']]:run(command,ROOT/'frontend')
    elif step=='sonar':
        if not os.getenv('SONAR_HOST_URL') or not os.getenv('SONAR_AUTH_TOKEN'):raise RuntimeError('Configure the Jenkins SonarQube server/credential first.')
        env={**os.environ,'SONAR_TOKEN':os.environ['SONAR_AUTH_TOKEN']}
        run([MVN,'-B','-ntp','org.sonarsource.scanner.maven:sonar-maven-plugin:5.1.0.4751:sonar', '-Dsonar.projectBaseDir='+str(ROOT), '-Dsonar.projectKey=cmc-sms','-Dsonar.sources=backend/src/main/java,frontend/src','-Dsonar.tests=backend/src/test/java,frontend/tests','-Dsonar.java.binaries=backend/target/classes','-Dsonar.coverage.jacoco.xmlReportPaths=backend/target/site/jacoco/jacoco.xml','-Dsonar.javascript.lcov.reportPaths=frontend/coverage/lcov.info'],ROOT/'backend',env=env)
    elif step=='build':
        tag=os.environ.get('IMAGE_TAG','local')
        if not re.fullmatch(r'[a-zA-Z0-9_.-]+',tag):raise RuntimeError('Invalid image tag')
        for service,path in [('backend','backend/Dockerfile'),('frontend','frontend/Dockerfile'),('migration','infrastructure/migration/Dockerfile')]:
            run(docker_cli()+['build','--label','org.opencontainers.image.revision='+tag,'-f',path,'-t','sms-'+service+':'+tag,'.'])
    elif step=='mysql':
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
            snapshot=backup(runtime);restore_test(runtime,snapshot)
            before=runtime.sql('SELECT COUNT(*) FROM students UNION ALL SELECT COUNT(*) FROM payments')
            runtime.run('restart','db');runtime.run('up','-d','--wait','--wait-timeout','180','backend','frontend')
            if before!=runtime.sql('SELECT COUNT(*) FROM students UNION ALL SELECT COUNT(*) FROM payments'):raise RuntimeError('Persistence check failed')
            smoke(runtime)
            (REPORTS/'mysql-integration.json').write_text(json.dumps({'passed':True,'checks':results,'workflows':workflows,'restore':True,'restart_persistence':True},indent=2))
        finally:
            runtime.run('logs','--no-color','--tail','200','backend','migrate',destination=REPORTS/'mysql-runtime.log',check=False)
            # Only the generated, disposable CI namespace is removed, never local/production volumes.
            runtime.run('down','--volumes','--remove-orphans')
    elif step=='security':
        tracked=subprocess.check_output(['git','ls-files'],cwd=ROOT,text=True).splitlines()
        prohibited=[p for p in tracked if '/.local/' in p or p.startswith(('.secrets/','backups/')) or Path(p).name in ['.env','.env.local']]
        if prohibited:raise RuntimeError('Sensitive runtime files are tracked in Git')
        with open(REPORTS/'npm-audit.json','wb') as out:
            result=subprocess.run([NPM,'audit','--json','--audit-level=critical'],cwd=ROOT/'frontend',stdout=out)
        if result.returncode:raise RuntimeError('Dependency audit failed or could not complete')
        image=os.getenv('TRIVY_IMAGE','aquasec/trivy:0.64.1')
        skips=['.git','.secrets','backend/.local','backend/private-files','frontend/node_modules','frontend/.npm-cache','backups','artifacts']
        command=docker_cli()+['run','--rm','-v',str(ROOT)+':/work:ro','-v','sms_trivy_cache:/root/.cache/','-w','/work',image,'fs','--no-progress','--scanners','vuln,secret','--severity','CRITICAL','--exit-code','1']
        for path in skips:command+=['--skip-dirs',path]
        command+=['--skip-files','**/.env*','--format','json','.']
        with open(REPORTS/'trivy-filesystem.json','wb') as out:run(command,stdout=out)
        for service in ['backend','frontend','migration']:
            target='sms-'+service+':'+os.getenv('IMAGE_TAG','local')
            archive=ROOT/'artifacts'/('scan-'+service+'.tar')
            run(docker_cli()+['save','-o',str(archive),target])
            try:
                with open(REPORTS/('trivy-'+service+'.json'),'wb') as out:
                    run(docker_cli()+['run','--rm','-v',str(archive)+':/image.tar:ro','-v','sms_trivy_cache:/root/.cache/',image,'image','--no-progress','--input','/image.tar','--severity','CRITICAL','--exit-code','1','--format','json'],stdout=out)
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
    parser.add_argument('step',choices=['prepare','backend','frontend','sonar','build','mysql','security','publish'])
    try:main(parser.parse_args().step)
    except (RuntimeError,subprocess.SubprocessError,OSError) as error:print(str(error),file=sys.stderr);sys.exit(1)
