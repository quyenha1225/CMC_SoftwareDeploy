"""Registry login over stdin; credentials never appear in command-line arguments."""
import os,re,subprocess,sys
from pathlib import Path
namespace=os.environ.get('REGISTRY_NAMESPACE','')
registry=namespace.split('/')[0]
if not re.fullmatch(r'[a-zA-Z0-9.-]+(?::[0-9]+)?',registry):raise SystemExit('Invalid registry')
folder=Path(os.environ['DOCKER_CONFIG']).resolve()
folder.mkdir(parents=True,exist_ok=True);folder.chmod(0o700)
command=['docker']+(['--host','npipe:////./pipe/dockerDesktopLinuxEngine'] if os.name=='nt' else [])
if '--logout' in sys.argv:
    result=subprocess.run(command+['logout',registry])
    (folder/'config.json').unlink(missing_ok=True)
else:result=subprocess.run(command+['login',registry,'--username',os.environ['REGISTRY_USER'],'--password-stdin'],input=os.environ['REGISTRY_PASSWORD'].encode())
raise SystemExit(result.returncode)
