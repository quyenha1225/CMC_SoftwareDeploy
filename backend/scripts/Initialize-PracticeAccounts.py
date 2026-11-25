"""Activate only the named practice accounts; save unique credentials outside Git."""
import argparse
import json
import os
from pathlib import Path
import re
import secrets
import string
import subprocess

ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--database')
mode = parser.add_mutually_exclusive_group()
mode.add_argument('--prepare-rotation', action='store_true',
                  help='Generate private credentials and hash-only SQL for a practice server without connecting to MySQL.')
args=parser.parse_args()
if args.prepare_rotation and args.database:
    parser.error('--database is only used when connecting directly to MySQL')
folder=ROOT/'backend/.local';folder.mkdir(parents=True,exist_ok=True)
names=['principal','principal_demo','ctsv_demo','training_demo',*[f'lecturer_demo_{i:02}' for i in range(1,4)],*[f'student_demo_{i:03}' for i in range(1,7)],'applicant_demo_03','applicant_demo_04']
selection=','.join("'"+name+"'" for name in names)
if args.prepare_rotation:
    credentials = [
        {'username': name}
        for name in names
    ]
    issued = set()
    for row in credentials:
        while True:
            letters = ''.join(secrets.choice(string.ascii_lowercase) for _ in range(6))
            digits = ''.join(secrets.choice(string.digits) for _ in range(4))
            password = secrets.choice(string.ascii_uppercase) + letters + '@' + digits
            if password not in issued:
                issued.add(password)
                row['password'] = password
                break
    tasks = [f"{row['username']}\t{row['password']}\t-" for row in credentials]
    updates = []
else:
    cfg={}
    for line in (ROOT/'backend/.env.local').read_text(encoding='utf-8-sig').splitlines():
        if '=' in line and not line.lstrip().startswith('#'):
            key,value=line.split('=',1);cfg[key.strip()]=value.strip()
    cfg.update({key:os.environ[key] for key in ['DB_URL','DB_USERNAME','DB_PASSWORD'] if key in os.environ})
    match=re.fullmatch(r'jdbc:mysql://([^/:]+)(?::(\d+))?/([a-zA-Z0-9_]+)(?:\?.*)?',cfg['DB_URL'])
    if not match:raise SystemExit('Unsupported DB_URL')
    database=args.database or match[3]
    if not re.fullmatch(r'sms_v6_[a-zA-Z0-9_]+',database):raise SystemExit('Only sms_v6 practice databases are allowed')
    report=folder/f'actor-credentials-{database}.json'
    previous=json.loads(report.read_text(encoding='utf-8')) if report.exists() else []
    saved={row['username']:row['password'] for row in previous}
    admin=(folder/'admin-credentials.txt').read_text(encoding='utf-8')
    admin_password=re.search(r'^Password: (.+)$',admin,re.M)[1].strip()
    saved.setdefault('principal',admin_password)
    saved.setdefault('student_demo_001','SinhVien@Test2026!')
    client='C:/Program Files/MySQL/MySQL Server 26.7/bin/mysql.exe'
    child_env={**os.environ,'MYSQL_PWD':cfg['DB_PASSWORD']}
    def sql(text):
        result=subprocess.run([client,f'--host={match[1]}',f'--port={match[2] or 3306}',f'--user={cfg["DB_USERNAME"]}',f'--database={database}','--default-character-set=utf8mb4','--batch','--raw','--skip-column-names'],input=text.encode('utf-8'),capture_output=True,env=child_env)
        if result.returncode:raise SystemExit('Practice account operation failed; no password has been printed.')
        return result.stdout.decode('utf-8').strip()
    rows=sql(f"SELECT u.id,u.username,u.full_name,u.enabled,u.password_hash,GROUP_CONCAT(r.code ORDER BY r.code) FROM users u JOIN user_roles ur ON ur.user_id=u.id JOIN roles r ON r.id=ur.role_id WHERE u.username IN ({selection}) GROUP BY u.id ORDER BY u.id").splitlines()
    if len(rows)!=len(names):raise SystemExit('Practice users/roles incomplete; install complete SQL and bootstrap principal first.')
    credentials=[];tasks=[];updates=[]
    for line in rows:
        uid,username,full_name,enabled,hashed,roles=line.split('\t')
        if enabled=='1' and username not in saved:raise SystemExit(f'Existing enabled account has no saved password: {username}. It was not reset.')
        password=saved.get(username) if enabled=='1' else secrets.token_urlsafe(12)+'Aa1!'
        mode=hashed if enabled=='1' else '-'
        tasks.append(f'{username}\t{password}\t{mode}')
        credentials.append({'role':roles,'name':full_name,'username':username,'password':password})
tools=folder/'tools';tools.mkdir(exist_ok=True)
source=tools/'PracticePassword.java'
source.write_text('''import java.io.*;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
class PracticePassword {
 public static void main(String[] args) throws Exception {
  var encoder=new BCryptPasswordEncoder(12);
  var reader=new BufferedReader(new InputStreamReader(System.in));
  for(String line;(line=reader.readLine())!=null;) {
   var parts=line.split("\\t",3);
   String answer;
   if (parts[2].equals("-")) {
    answer=encoder.encode(parts[1]);
    if (!encoder.matches(parts[1],answer)) throw new IllegalStateException("BCrypt verification failed");
   } else {
    answer=encoder.matches(parts[1],parts[2])?"MATCH":"MISMATCH";
   }
   System.out.println(parts[0]+"\\t"+answer);
  }
 }
}
''',encoding='utf-8')
cache=Path.home()/'.m2/repository'
crypto=sorted((cache/'org/springframework/security/spring-security-crypto').glob('*/*.jar'))[0]
logging=sorted((cache/'org/springframework/spring-jcl').glob('*/*.jar'))[0]
result=subprocess.run(['java','--class-path',str(crypto)+os.pathsep+str(logging),str(source)],input=('\n'.join(tasks)+'\n').encode(),capture_output=True)
if result.returncode:raise SystemExit('BCrypt generation/verification failed; database not changed.')
results = dict(line.split('\t', 1) for line in result.stdout.decode().splitlines())
if set(results) != set(names):
    raise SystemExit('Incomplete BCrypt output; database not changed.')
if args.prepare_rotation:
    if any(not re.fullmatch(r'\$2[aby]\$12\$[./A-Za-z0-9]{53}', value)
           for value in results.values()):
        raise SystemExit('Invalid BCrypt output; rotation files not created.')
    # Use a fresh directory so preparing another rotation cannot replace issued credentials.
    output = folder / f'practice-rotation-{secrets.token_hex(6)}'
    output.mkdir(mode=0o700)
    cases = '\n'.join(f"        WHEN '{name}' THEN '{results[name]}'" for name in names)
    statement = f'''-- Run on the intended practice database only.
-- If any account is missing, this statement updates zero rows.
UPDATE users AS u
JOIN (
    SELECT COUNT(DISTINCT username) AS account_count
    FROM users
    WHERE username IN ({selection})
) AS expected ON expected.account_count = {len(names)}
SET u.password_hash = CASE u.username
{cases}
    END,
    u.enabled = TRUE
WHERE u.username IN ({selection});
SELECT ROW_COUNT() AS changed_practice_accounts;
'''
    (output / 'apply.sql').write_text(statement, encoding='utf-8')
    (output / 'credentials.json').write_text(
        json.dumps(credentials, indent=2) + '\n', encoding='utf-8')
    print(f'Prepared {len(names)} practice accounts: {output}')
    raise SystemExit(0)

for username,value in results.items():
    if value=='MISMATCH':raise SystemExit(f'Password of {username} was changed outside the local record. Database not changed.')
    if value!='MATCH':updates.append(f"UPDATE users SET password_hash='{value}',enabled=TRUE WHERE username='{username}';")
activation='START TRANSACTION;\n'+'\n'.join(updates)+'\nCOMMIT;\n'
(folder/f'practice-account-activation-{database}.sql').write_text(activation,encoding='utf-8')
pending=report.with_suffix('.pending.json')
pending.write_text(json.dumps(credentials,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
sql(activation)
os.replace(pending,report)
labels={'PRINCIPAL':'Ban giám hiệu','CTSV':'CTSV','TRAINING_OFFICE':'Phòng Đào tạo','LECTURER':'Giảng viên','STUDENT':'Sinh viên','APPLICANT':'Ứng viên'}
text=['# Tài khoản thực hành trên máy','',f'Database: `{database}`. Không commit hoặc đưa tệp này vào seed công khai.','', '| Vai trò | Họ tên | Tài khoản | Mật khẩu |','|---|---|---|---|']
for row in credentials:text.append(f"| {labels.get(row['role'],row['role'])} | {row['name']} | `{row['username']}` | `{row['password']}` |")
(folder/f'actor-credentials-{database}.md').write_text('\n'.join(text)+'\n',encoding='utf-8')
print(f'Practice accounts ready: {len(credentials)}; newly activated: {len(updates)}. Existing enabled passwords preserved.')
print(f'Credentials saved privately: {report}')
