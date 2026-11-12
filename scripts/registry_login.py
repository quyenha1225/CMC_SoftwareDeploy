"""Registry login over stdin; credentials never appear in command-line arguments."""
import os,re,subprocess,sys
namespace=os.environ.get('REGISTRY_NAMESPACE','')
registry=namespace.split('/')[0]
if not re.fullmatch(r'[a-zA-Z0-9.-]+(?::[0-9]+)?',registry):raise SystemExit('Invalid registry')
command=['docker']+(['--context','desktop-linux'] if os.name=='nt' else [])
if '--logout' in sys.argv:result=subprocess.run(command+['logout',registry])
else:result=subprocess.run(command+['login',registry,'--username',os.environ['REGISTRY_USER'],'--password-stdin'],input=os.environ['REGISTRY_PASSWORD'].encode())
raise SystemExit(result.returncode)
