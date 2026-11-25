"""Read-only Docker retention inventory for the SMS CI project.

No delete, prune, stop, registry mutation or volume operation is implemented.
Run when CI/CD is idle, using the same Docker context as Jenkins.
"""
import argparse
import datetime as dt
import json
from pathlib import Path
import re
import subprocess
import sys

from docker import docker_command
from ci_release import SERVICES, IMAGE_ID, DIGEST, atomic_json

TAG = re.compile(r'sms-(backend|frontend|migration):([0-9a-f]{40})')


def inventory(docker):
    def get(*args):
        return subprocess.check_output(docker + list(args), text=True, timeout=90)
    containers = get('ps', '-aq', '--no-trunc').splitlines()
    protected = set()
    if containers:
        protected.update(item['Image'] for item in json.loads(get('inspect', *containers)))
    ids = sorted(set(get('image', 'ls', '-aq', '--no-trunc').splitlines()))
    images = json.loads(get('image', 'inspect', *ids)) if ids else []
    return protected, images


def plan(images, used, releases, days, now):
    """Require complete three-image protection records; never recommend shared tags."""
    protected = set(used)
    protected_refs = set()
    for release in releases:
        ids = release.get('image_ids', {})
        digests = release.get('images', {})
        if (set(ids) != set(SERVICES) or set(digests) != set(SERVICES)
                or not all(IMAGE_ID.fullmatch(v) for v in ids.values())
                or not all(DIGEST.fullmatch(v) for v in digests.values())):
            raise RuntimeError('Every protected release must identify all three images and digests')
        protected.update(ids.values())
        protected_refs.update(digests.values())
    result = []
    for image in images:
        tags = image.get('RepoTags') or []
        digests = image.get('RepoDigests') or []
        image_id = image['Id']
        if image_id in protected or protected_refs.intersection(digests):
            continue
        if not tags or not all(TAG.fullmatch(tag) for tag in tags):
            continue
        if digests:  # published/shared image: registry policy is independent
            continue
        revision = (image.get('Config', {}).get('Labels') or {}).get('org.opencontainers.image.revision')
        if not revision or any(TAG.fullmatch(tag).group(2) != revision for tag in tags):
            continue
        created = dt.datetime.fromisoformat(image['Created'].replace('Z', '+00:00'))
        if created.tzinfo is None or now - created < dt.timedelta(days=days):
            continue
        result.append({'id': image_id, 'tags': sorted(tags), 'created': image['Created'],
                       'size_bytes_including_shared_layers': image['Size'],
                       'reason': 'old SMS commit-tagged image not referenced by a container or supplied release'})
    return sorted(result, key=lambda i: i['id'])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--protected-release', type=Path, action='append', required=True,
                        help='Repeat for current, rollback and pending releases in every environment.')
    parser.add_argument('--days', type=int, default=30)
    parser.add_argument('--output', type=Path, default=Path('artifacts/reports/docker-retention-plan.json'))
    args = parser.parse_args()
    if args.days < 30:
        parser.error('Minimum review age is 30 days')
    releases = [json.loads(path.read_text(encoding='utf-8-sig')) for path in args.protected_release]
    docker = docker_command()
    used, images = inventory(docker)
    report = {'mode': 'report-only', 'created_at': dt.datetime.now(dt.timezone.utc).isoformat(),
              'days': args.days, 'protected_release_count': len(releases),
              'container_image_count': len(used),
              'candidates': plan(images, used, releases, args.days, dt.datetime.now(dt.timezone.utc)),
              'limitations': ['Review every current, pending and rollback release before any manual removal.',
                              'Image sizes include shared layers and are not reclaimable-byte estimates.',
                              'Registry retention, BuildKit GC, backups and volumes are not modified.']}
    atomic_json(args.output, report)
    print('Retention report only: ' + str(args.output))


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError, ValueError, subprocess.SubprocessError) as error:
        print('Retention inventory stopped: ' + str(error), file=sys.stderr)
        sys.exit(1)
