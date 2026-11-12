"""Verify Docker isolation, production rendering and optional monitoring without printing secrets."""
import argparse
import base64
import json
import os
from pathlib import Path
import subprocess
import urllib.error
import urllib.request
from docker import ROOT,Runtime

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--monitoring',action='store_true')
args=parser.parse_args();runtime=Runtime();checks=[]
def get(url,headers=None):
    with urllib.request.urlopen(urllib.request.Request(url,headers=headers or {}),timeout=15) as response:return json.load(response)
config=json.loads(runtime.run('config','--format','json',capture=True))
for service in ['backend','db','migrate']:
    if config['services'][service].get('ports'):raise RuntimeError(service+' must not publish ports')
checks.append('DB/API/management ports are private')
with urllib.request.urlopen(runtime.url(),timeout=15) as page:
    if not page.headers.get('Content-Security-Policy'):raise RuntimeError('Homepage CSP header missing')
    if page.headers.get('X-Content-Type-Options')!='nosniff':raise RuntimeError('Homepage nosniff header missing')
checks.append('Homepage preserves CSP/nosniff headers with cache policy')
for service in ['frontend','backend']:
    identifier=runtime.run('ps','-q',service,capture=True)
    record=json.loads(subprocess.check_output(runtime.docker+['inspect',identifier]))[0]
    if record['Config']['User'] in ['', '0','root','0:0']:raise RuntimeError(service+' runs as root')
    if not record['HostConfig']['ReadonlyRootfs']:raise RuntimeError(service+' rootfs is writable')
    if record['State']['Health']['Status']!='healthy':raise RuntimeError(service+' is not healthy')
checks.append('FE/BE non-root, read-only, healthy')
for route,status in [('/api/resources/users',401),('/api/actuator/prometheus',404)]:
    try:urllib.request.urlopen(runtime.url()+route);raise RuntimeError('Protected route was public')
    except urllib.error.HTTPError as error:
        if error.code!=status:raise
checks.append('Anonymous business API denied; management metrics blocked by Nginx')
# Config-only rendering: dummy digests are never pulled or treated as releases.
env={**os.environ,**{s+'_IMAGE':'example.invalid/sms-'+s.lower()+'@sha256:'+'0'*64 for s in ['BACKEND','FRONTEND','MIGRATION']},'SMS_SEED_DEMO':'false','SESSION_SECURE':'true','SMS_ENVIRONMENT':'production','APP_DOMAIN':'example.invalid','SMS_PUBLIC_URL':'https://example.invalid'}
result=subprocess.run(runtime.docker+['compose','--env-file',str(runtime.env_file),'-f','compose.prod.yaml','-f','compose.tls.yaml','config','--format','json'],cwd=ROOT,env=env,capture_output=True,check=True)
production=json.loads(result.stdout)
for service in production['services'].values():
    if 'build' in service:raise RuntimeError('Production must not build images')
if production['services']['migrate']['environment']['SMS_SEED_DEMO']!='false':raise RuntimeError('Production demo seed enabled')
if production['services']['backend']['environment']['SESSION_SECURE']!='true':raise RuntimeError('Production secure cookies disabled')
checks.append('Production/TLS Compose renders without build, with secure cookies and no demo seed')
if args.monitoring:
    targets=get('http://127.0.0.1:'+runtime.config.get('PROMETHEUS_PORT','9090')+'/api/v1/targets')['data']['activeTargets']
    if not targets or any(target['health']!='up' for target in targets):raise RuntimeError('Metrics scrape failed')
    grafana='http://127.0.0.1:'+runtime.config.get('GRAFANA_PORT','3000')
    if get(grafana+'/api/health')['database']!='ok':raise RuntimeError('Grafana unhealthy')
    password=(runtime.secret_dir/'grafana_password').read_text().strip()
    headers={'Authorization':'Basic '+base64.b64encode(('admin:'+password).encode()).decode()}
    dashboards=get(grafana+'/api/search?query=SMS',headers)
    if not any(item['uid']=='sms-operations' for item in dashboards):raise RuntimeError('Dashboard missing')
    checks.append('Prometheus UP, Grafana healthy, SMS dashboard provisioned')
for name in ['.env','.secrets/jwt_secret','backend/.local/docker-credentials.md']:
    if subprocess.run(['git','check-ignore','-q',name],cwd=ROOT).returncode:raise RuntimeError('Runtime secret path not ignored')
checks.append('Runtime environment/secrets/credentials excluded from Git')
report={'passed':True,'website':runtime.url(),'checks':checks,'images':{}}
for service in ['backend','frontend','migration']:
    image='sms-'+service+':'+runtime.config.get('IMAGE_TAG','local')
    report['images'][service]=json.loads(subprocess.check_output(runtime.docker+['image','inspect',image]))[0]['Id']
folder=ROOT/'artifacts/reports';folder.mkdir(parents=True,exist_ok=True)
(folder/'runtime-verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('PASS Docker runtime verification: '+str(len(checks))+' groups; '+runtime.url())
