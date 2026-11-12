"""Back up, rehearse and apply reviewed V6 migrations without replacing original SQL.

Uses only Python's standard library and the installed MySQL client. Credentials stay
in the child process environment, never in command-line arguments or report files.
"""

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
SQL = ROOT / "data" / "v6"
VERSIONS = [
    "05_SECURITY_PROFILE.sql", "06_COMPLETE_SEED_LINKS.sql", "07_EXAM_SCHEDULES.sql",
    "08_NORMALIZE_ACADEMIC.sql", "09_COMPLETE_DEMO_DATA.sql", "10_VERIFY_NORMALIZED.sql",
    "11_MAILBOX_EMAIL_DELIVERY.sql", "12_PRACTICAL_IDENTITIES.sql", "13_INVOICE_REVIEW_WORKFLOW.sql", "14_REVIEW_PRACTICE_DATA.sql",
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--rehearse", action="store_true")
    group.add_argument("--apply", metavar="REHEARSAL_JSON")
    group.add_argument("--check", action="store_true", help="Read-only migration checksum and integrity checks")
    args = parser.parse_args()
    config = {}
    for line in (ROOT / "backend/.env.local").read_text(encoding="utf-8-sig").splitlines():
        if line.strip() and not line.lstrip().startswith("#") and "=" in line:
            key, value = line.split("=", 1)
            config[key.strip()] = value.strip()
    config.update({key: os.environ[key] for key in ["DB_URL", "DB_USERNAME", "DB_PASSWORD"] if key in os.environ})
    match = re.fullmatch(r"jdbc:mysql://([^/:]+)(?::(\d+))?/([a-zA-Z0-9_]+)(?:\?.*)?", config["DB_URL"])
    if not match:
        raise RuntimeError("Unsupported DB_URL. Expected a single named MySQL database.")
    host, port, database = match[1], match[2] or "3306", match[3]
    client_dir = Path("C:/Program Files/MySQL/MySQL Server 26.7/bin")
    mysql = shutil.which("mysql") or str(client_dir / "mysql.exe")
    dump = shutil.which("mysqldump") or str(client_dir / "mysqldump.exe")
    child_env = {**os.environ, "MYSQL_PWD": config["DB_PASSWORD"]}
    connection = [f"--host={host}", f"--port={port}", f"--user={config['DB_USERNAME']}", "--default-character-set=utf8mb4"]

    def execute(db, sql):
        command = [mysql, *connection, "--batch", "--raw", "--skip-column-names"]
        if db:
            command.append(f"--database={db}")
        result = subprocess.run(command, input=sql.encode("utf-8"), env=child_env, capture_output=True)
        if result.returncode:
            error = result.stderr.decode("utf-8", "replace")
            password = config.get("DB_PASSWORD", "")
            if password:
                error = error.replace(password, "[REDACTED]")
            raise RuntimeError(error.strip())
        return result.stdout.decode("utf-8", "replace").strip()

    def fingerprint(db):
        names = execute(db, "SELECT TABLE_NAME FROM information_schema.tables WHERE TABLE_SCHEMA=DATABASE() AND TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME").splitlines()
        content = execute(db, "CHECKSUM TABLE " + ",".join(f"`{name}`" for name in names))
        content = content.replace(db + ".", "")
        return hashlib.sha256(content.encode()).hexdigest()

    hashes = {name: hashlib.sha256((SQL / name).read_bytes()).hexdigest() for name in VERSIONS}

    def check_rows(db):
        base = execute(db, "SELECT check_name,violation_count FROM v_normalization_checks ORDER BY check_name")
        if execute(db, "SELECT COUNT(*) FROM information_schema.views WHERE table_schema=DATABASE() AND table_name='v_approval_workflow_checks'") == "1":
            base += "\n" + execute(db, "SELECT check_name,violation_count FROM v_approval_workflow_checks ORDER BY check_name")
        return base

    def migrate(db):
        execute(db, """CREATE TABLE IF NOT EXISTS schema_migrations (
            version VARCHAR(80) PRIMARY KEY, checksum CHAR(64) NOT NULL,
            applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci""")
        for name in VERSIONS:
            old = execute(db, f"SELECT checksum FROM schema_migrations WHERE version='{name}'")
            if old:
                if old != hashes[name]:
                    raise RuntimeError(f"Applied migration changed: {name}. Add a new migration instead.")
                continue
            execute(db, (SQL / name).read_text(encoding="utf-8-sig"))
            execute(db, f"INSERT INTO schema_migrations(version,checksum) VALUES('{name}','{hashes[name]}')")
            print(f"Applied {name} to {db}", flush=True)
        checks = check_rows(db)
        bad = [line for line in checks.splitlines() if int(line.rsplit("\t", 1)[1]) != 0]
        if bad:
            raise RuntimeError("Validation failed:\n" + "\n".join(bad))
        return checks

    if args.check:
        for name in VERSIONS:
            stored = execute(database, f"SELECT checksum FROM schema_migrations WHERE version='{name}'")
            if stored != hashes[name]:
                raise RuntimeError(f"Missing or modified migration: {name}")
        checks = check_rows(database)
        if any(int(line.rsplit("\t", 1)[1]) for line in checks.splitlines()):
            raise RuntimeError("Integrity checks failed:\n" + checks)
        print(checks)
        print("READ_ONLY_CHECK_OK")
    elif args.rehearse:
        stamp = dt.datetime.now().strftime("%Y%m%d_%H%M%S")
        folder = ROOT / "backend/.local/backups" / stamp
        folder.mkdir(parents=True, exist_ok=False)
        backup = folder / "before-migration.sql"
        before = fingerprint(database)
        result = subprocess.run([dump, *connection, "--single-transaction", "--routines", "--triggers", "--no-tablespaces", "--set-gtid-purged=OFF", "--column-statistics=0", f"--result-file={backup}", database], env=child_env, capture_output=True)
        if result.returncode:
            raise RuntimeError("Database backup failed; migration has not run.")
        clone = f"sms_v6_verify_{stamp}"
        execute(None, f"CREATE DATABASE `{clone}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
        contents = backup.read_text(encoding="utf-8").replace(f"`{database}`", f"`{clone}`")
        execute(clone, contents)
        if before != fingerprint(clone) or before != fingerprint(database):
            raise RuntimeError("Source changed during backup or clone differs; no live migration applied.")
        checks = migrate(clone)
        report = {"source": database, "clone": clone, "source_fingerprint": before, "hashes": hashes,
                  "backup": str(backup), "checks": checks.splitlines(), "created_at": stamp}
        report_path = folder / "rehearsal.json"
        report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"REHEARSAL_DATABASE={clone}\nREHEARSAL_REPORT={report_path}", flush=True)
    else:
        report = json.loads(Path(args.apply).read_text(encoding="utf-8"))
        if report["source"] != database or report["hashes"] != hashes or not Path(report["backup"]).is_file():
            raise RuntimeError("Rehearsal does not match current migrations/database or backup is missing.")
        if fingerprint(database) != report["source_fingerprint"]:
            raise RuntimeError("Source data changed since rehearsal. Rehearse again before applying.")
        if any(int(line.rsplit("\t", 1)[1]) for line in check_rows(report["clone"]).splitlines()):
            raise RuntimeError("Rehearsal database no longer passes checks.")
        print(migrate(database))
        print("LIVE_MIGRATION_OK. Backup and rehearsal database retained.")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, KeyError, OSError, ValueError) as error:
        print(f"Migration stopped: {error}", file=sys.stderr)
        sys.exit(1)
