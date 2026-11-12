"""Read-only validation of every V6 table, SQL constraint and application dataset.

Writes aggregate reports only; never exports passwords, tokens or personal records.
Authentication creates temporary HTTP sessions, then logs out. No business writes.
"""
import argparse
from collections import defaultdict
import datetime as dt
from decimal import Decimal
import hashlib
import http.cookiejar
import json
import os
from pathlib import Path
import re
import subprocess
import urllib.error
import urllib.request
import urllib.parse

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--skip-api', action='store_true')
parser.add_argument('--base-url', default='http://127.0.0.1:5173')
args = parser.parse_args()
if urllib.parse.urlparse(args.base_url).hostname not in ['127.0.0.1','localhost','::1']:
    raise SystemExit('Account validation is restricted to the local application.')
cfg = {}
for line in (ROOT/'backend/.env.local').read_text(encoding='utf-8-sig').splitlines():
    if '=' in line and not line.lstrip().startswith('#'):
        key, value = line.split('=', 1); cfg[key.strip()] = value.strip()
cfg.update({key: os.environ[key] for key in ['DB_URL','DB_USERNAME','DB_PASSWORD'] if key in os.environ})
match = re.fullmatch(r'jdbc:mysql://([^/:]+)(?::(\d+))?/([a-zA-Z0-9_]+)(?:\?.*)?', cfg['DB_URL'])
if not match: raise SystemExit('Unsupported DB_URL')
database = match[3]
command = ['C:/Program Files/MySQL/MySQL Server 26.7/bin/mysql.exe', f'--host={match[1]}', f'--port={match[2] or 3306}', f'--user={cfg["DB_USERNAME"]}', f'--database={database}', '--default-character-set=utf8mb4','--batch','--raw','--skip-column-names']
child_env = {**os.environ, 'MYSQL_PWD': cfg['DB_PASSWORD']}

def sql(query):
    result = subprocess.run(command, input=('SET SESSION TRANSACTION READ ONLY; START TRANSACTION WITH CONSISTENT SNAPSHOT;\n'+query+';\nCOMMIT;').encode('utf-8'), capture_output=True, env=child_env)
    if result.returncode:
        error = result.stderr.decode('utf-8','replace').replace(cfg['DB_PASSWORD'],'[REDACTED]')
        raise RuntimeError(error)
    return result.stdout.decode('utf-8').strip()

def rows(query, fields):
    pairs = ','.join("'"+field+"',"+field for field in fields)
    return [json.loads(line) for line in sql('SELECT JSON_OBJECT('+pairs+') FROM ('+query+') dataset').splitlines() if line]

def q(identifier): return '`'+identifier.replace('`','``')+'`'

checks = []
def add(name, query, severity='error', explanation=''):
    checks.append({'name':name,'query':query,'severity':severity,'explanation':explanation})

objects = rows("SELECT TABLE_NAME name,TABLE_TYPE kind FROM information_schema.tables WHERE table_schema=DATABASE() ORDER BY table_name", ['name','kind'])
tables = [row['name'] for row in objects if row['kind']=='BASE TABLE']
columns = rows("SELECT table_name t,column_name c,data_type dtype,column_type ctype,is_nullable nullable FROM information_schema.columns WHERE table_schema=DATABASE() ORDER BY table_name,ordinal_position", ['t','c','dtype','ctype','nullable'])
fks = rows("SELECT table_name t,constraint_name k,column_name c,referenced_table_name rt,referenced_column_name rc,ordinal_position pos FROM information_schema.key_column_usage WHERE table_schema=DATABASE() AND referenced_table_name IS NOT NULL ORDER BY table_name,constraint_name,ordinal_position", ['t','k','c','rt','rc','pos'])
unique = rows("SELECT table_name t,index_name k,column_name c,seq_in_index pos FROM information_schema.statistics WHERE table_schema=DATABASE() AND non_unique=0 ORDER BY table_name,index_name,seq_in_index", ['t','k','c','pos'])
constraints = rows("SELECT tc.table_name t,tc.constraint_name k,cc.check_clause clause,tc.enforced enforced FROM information_schema.table_constraints tc JOIN information_schema.check_constraints cc ON cc.constraint_schema=tc.constraint_schema AND cc.constraint_name=tc.constraint_name WHERE tc.table_schema=DATABASE() AND tc.constraint_type='CHECK'", ['t','k','clause','enforced'])

for group in [fks, unique]:
    grouped = defaultdict(list)
    for row in group: grouped[(row['t'],row['k'])].append(row)
    for (table, key), parts in grouped.items():
        if group is fks:
            valid = ' AND '.join('c.'+q(p['c'])+' IS NOT NULL' for p in parts)
            join = ' AND '.join('c.'+q(p['c'])+'=p.'+q(p['rc']) for p in parts)
            add('FK '+table+'.'+key, f'SELECT COUNT(*) FROM {q(table)} c WHERE {valid} AND NOT EXISTS(SELECT 1 FROM {q(parts[0]["rt"])} p WHERE {join})')
        else:
            cols = ','.join(q(p['c']) for p in parts)
            valid = ' AND '.join(q(p['c'])+' IS NOT NULL' for p in parts)
            add('UNIQUE '+table+'.'+key, f'SELECT COUNT(*) FROM (SELECT {cols} FROM {q(table)} WHERE {valid} GROUP BY {cols} HAVING COUNT(*)>1) duplicates')
for row in constraints:
    add('CHECK '+row['t']+'.'+row['k'], f'SELECT COUNT(*) FROM {q(row["t"])} WHERE NOT ({row['clause'].replace(chr(92)+chr(39),chr(39))})')
    add('ENFORCED '+row['t']+'.'+row['k'], 'SELECT '+('0' if row['enforced']=='YES' else '1'))
for row in columns:
    t,c = q(row['t']),q(row['c'])
    if row['t'] not in tables: continue
    if row['nullable']=='NO': add('NOT NULL '+row['t']+'.'+row['c'],f'SELECT COUNT(*) FROM {t} WHERE {c} IS NULL')
    if row['dtype']=='enum': add('ENUM '+row['t']+'.'+row['c'],f'SELECT COUNT(*) FROM {t} WHERE {c} IS NOT NULL AND {c}+0=0')
    if row['ctype']=='tinyint(1)': add('BOOLEAN '+row['t']+'.'+row['c'],f'SELECT COUNT(*) FROM {t} WHERE {c} NOT IN (0,1)')
    if row['dtype'] in ['date','datetime','timestamp']:
        add('DATE '+row['t']+'.'+row['c'],f"SELECT COUNT(*) FROM {t} WHERE {c} IS NOT NULL AND CAST({c} AS CHAR) LIKE '0000-%'")
    if row['dtype'] in ['varchar','char','text']:
        add('UTF8 '+row['t']+'.'+row['c'],f"SELECT COUNT(*) FROM {t} WHERE LOCATE(CONVERT(0xEFBFBD USING utf8mb4),CONVERT({c} USING utf8mb4))>0")
        if row['nullable']=='NO' and row['c'] not in ['password_hash']:
            add('BLANK '+row['t']+'.'+row['c'],f'SELECT COUNT(*) FROM {t} WHERE TRIM({c})=\'\'','warning','Chuỗi rỗng trong cột NOT NULL; cần phân biệt nội dung tùy chọn với định danh bắt buộc.')
        if row['c'] in ['email','personal_email','recipient_email','school_email']:
            add('EMAIL '+row['t']+'.'+row['c'],f"SELECT COUNT(*) FROM {t} WHERE {c} IS NOT NULL AND {c} NOT REGEXP '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$'")

business = {
 'ACCOUNT_ENABLED_WITHOUT_ROLE': 'SELECT COUNT(*) FROM users u WHERE enabled=TRUE AND NOT EXISTS(SELECT 1 FROM user_roles r WHERE r.user_id=u.id)',
 'ACCOUNT_ENABLED_INVALID_BCRYPT': "SELECT COUNT(*) FROM users WHERE enabled=TRUE AND password_hash NOT REGEXP '^[$]2[aby][$][0-9]{2}[$][./A-Za-z0-9]{53}$'",
 'STUDENT_WITHOUT_ROLE': "SELECT COUNT(*) FROM students s WHERE NOT EXISTS(SELECT 1 FROM user_roles ur JOIN roles r ON r.id=ur.role_id WHERE ur.user_id=s.user_id AND r.code='STUDENT')",
 'LECTURER_WITHOUT_ROLE': "SELECT COUNT(*) FROM lecturers l WHERE NOT EXISTS(SELECT 1 FROM user_roles ur JOIN roles r ON r.id=ur.role_id WHERE ur.user_id=l.user_id AND r.code='LECTURER')",
 'STUDENT_ROLE_WITHOUT_RECORD': "SELECT COUNT(*) FROM user_roles ur JOIN roles r ON r.id=ur.role_id WHERE r.code='STUDENT' AND NOT EXISTS(SELECT 1 FROM students s WHERE s.user_id=ur.user_id)",
 'LECTURER_ROLE_WITHOUT_RECORD': "SELECT COUNT(*) FROM user_roles ur JOIN roles r ON r.id=ur.role_id WHERE r.code='LECTURER' AND NOT EXISTS(SELECT 1 FROM lecturers l WHERE l.user_id=ur.user_id)",
 'STUDENT_FUTURE_BIRTH': 'SELECT COUNT(*) FROM students WHERE date_of_birth>CURRENT_DATE',
 'ADMISSION_FUTURE_BIRTH': 'SELECT COUNT(*) FROM admission_applications WHERE date_of_birth>CURRENT_DATE',
 'SEMESTER_OUTSIDE_YEAR': 'SELECT COUNT(*) FROM semesters s JOIN academic_years y ON y.id=s.academic_year_id WHERE s.starts_on<y.starts_on OR s.ends_on>y.ends_on',
 'SECTION_OVER_CAPACITY': "SELECT COUNT(*) FROM course_sections cs WHERE cs.capacity<(SELECT COUNT(*) FROM enrollments e WHERE e.section_id=cs.id AND e.status<>'CANCELLED')",
 'SECTION_WITHOUT_LECTURER': 'SELECT COUNT(*) FROM course_sections WHERE is_open=TRUE AND lecturer_id IS NULL',
 'SECTION_WITHOUT_SCHEDULE': 'SELECT COUNT(*) FROM course_sections cs WHERE is_open=TRUE AND NOT EXISTS(SELECT 1 FROM section_schedules ss WHERE ss.section_id=cs.id)',
 'ENROLLMENT_WITHOUT_GRADE': "SELECT COUNT(*) FROM enrollments e WHERE e.status<>'CANCELLED' AND NOT EXISTS(SELECT 1 FROM grades g WHERE g.enrollment_id=e.id)",
 'PUBLISHED_MISSING_SCORES': "SELECT COUNT(*) FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN grade_sheets gs ON gs.section_id=cs.id LEFT JOIN grades g ON g.enrollment_id=e.id WHERE e.status<>'CANCELLED' AND gs.status='PUBLISHED' AND (g.id IS NULL OR g.attendance_score IS NULL OR g.midterm_score IS NULL OR g.final_score IS NULL)",
 'INVOICE_WRONG_ENROLLMENT': 'SELECT COUNT(*) FROM invoice_items it JOIN invoices i ON i.id=it.invoice_id JOIN enrollments e ON e.id=it.enrollment_id JOIN course_sections cs ON cs.id=e.section_id WHERE e.student_id<>i.student_id OR cs.semester_id<>i.semester_id',
 'INVOICE_WITHOUT_ITEMS': 'SELECT COUNT(*) FROM invoices i WHERE NOT EXISTS(SELECT 1 FROM invoice_items it WHERE it.invoice_id=i.id)',
 'INVOICE_DISCOUNT_OVER_TOTAL': 'SELECT COUNT(*) FROM invoices i WHERE i.discount_amount>(SELECT COALESCE(SUM(credits_at_issue*unit_price_at_issue),0) FROM invoice_items it WHERE it.invoice_id=i.id)',
 'PAYMENT_FUTURE_DATE': 'SELECT COUNT(*) FROM payments WHERE paid_at>CURRENT_TIMESTAMP',
 'PAYMENT_WITHOUT_FUND': 'SELECT COUNT(*) FROM payments WHERE fund_id IS NULL',
 'REMITTANCE_PAYMENT_SCOPE': 'SELECT COUNT(*) FROM ctsv_remittance_allocations a JOIN ctsv_remittances r ON r.id=a.remittance_id JOIN payments p ON p.id=a.payment_id JOIN invoices i ON i.id=p.invoice_id WHERE r.fund_id<>p.fund_id OR r.semester_id<>i.semester_id',
 'REMITTANCE_OVER_ALLOCATION': "SELECT COUNT(*) FROM payments p WHERE p.amount<(SELECT COALESCE(SUM(a.allocated_amount),0) FROM ctsv_remittance_allocations a JOIN ctsv_remittances r ON r.id=a.remittance_id WHERE a.payment_id=p.id AND r.status<>'REJECTED')",
 'REMITTANCE_HEADER_MISMATCH': "SELECT COUNT(*) FROM ctsv_remittances r WHERE r.status IN ('SUBMITTED','CONFIRMED') AND r.amount<>(SELECT COALESCE(SUM(a.allocated_amount),0) FROM ctsv_remittance_allocations a WHERE a.remittance_id=r.id)",
 'APPROVED_ADJUSTMENT_WITHOUT_REVIEW': "SELECT COUNT(*) FROM tuition_adjustments WHERE status IN ('APPROVED','REJECTED') AND (approved_by IS NULL OR decided_at IS NULL)",
 'REPORT_SUBMISSION_WITHOUT_DATE': "SELECT COUNT(*) FROM ctsv_semester_reports WHERE status IN ('SUBMITTED','APPROVED','RETURNED') AND submitted_at IS NULL",
 'ENROLLED_ADMISSION_LINK': "SELECT COUNT(*) FROM admission_applications a JOIN students s ON s.id=a.student_id WHERE a.status='ENROLLED' AND (a.applicant_user_id<>s.user_id OR a.major_id<>(SELECT ac.major_id FROM academic_classes ac WHERE ac.id=s.class_id))",
 'ADMISSION_VERIFIED_DOC_NO_REVIEWER': "SELECT COUNT(*) FROM admission_documents WHERE status IN ('VERIFIED','REJECTED') AND (checked_by IS NULL OR checked_at IS NULL)",
 'SENT_EMAIL_WITHOUT_DATE': "SELECT COUNT(*) FROM outbound_emails WHERE delivery_status='SENT' AND sent_at IS NULL",
 'EMAIL_ATTEMPT_COUNT': 'SELECT COUNT(*) FROM outbound_emails e WHERE e.attempt_count<>(SELECT COUNT(*) FROM email_delivery_attempts a WHERE a.outbound_email_id=e.id)',
 'MAILBOX_DUPLICATE_ADDRESS': 'SELECT COUNT(*) FROM (SELECT LOWER(school_email) FROM student_school_mailboxes GROUP BY LOWER(school_email) HAVING COUNT(*)>1) duplicates',
 'RESET_TOKEN_HASH': "SELECT COUNT(*) FROM password_reset_tokens WHERE token_hash NOT REGEXP '^[0-9a-fA-F]{64}$'",
 'RESET_TOKEN_EXPIRY': 'SELECT COUNT(*) FROM password_reset_tokens WHERE expires_at<=created_at OR used_at<created_at',
}
business.update({
 'INVOICE_CANCELLED_REGISTRATION': "SELECT COUNT(*) FROM invoice_items it JOIN enrollments e ON e.id=it.enrollment_id WHERE e.status='CANCELLED'",
 'INVOICE_ITEM_AMOUNT': 'SELECT COUNT(*) FROM invoice_items WHERE amount<>credits_at_issue*unit_price_at_issue',
 'INVOICE_VIEW_ARITHMETIC': "SELECT COUNT(*) FROM v_invoice_balances v JOIN invoices i ON i.id=v.invoice_id WHERE v.base_amount<>(SELECT COALESCE(SUM(credits_at_issue*unit_price_at_issue),0) FROM invoice_items it WHERE it.invoice_id=i.id) OR v.paid_amount<>(SELECT COALESCE(SUM(amount),0) FROM payments p WHERE p.invoice_id=i.id) OR v.payable_amount<>GREATEST(v.base_amount-v.discount_amount+v.debit_amount-v.credit_amount,0) OR v.remaining_amount<>GREATEST(v.payable_amount-v.paid_amount,0)",
 'ADMISSION_REVIEW_QUEUE_PROVENANCE': "SELECT COUNT(*) FROM admission_applications a WHERE a.status='SENT_TO_SCHOOL' AND NOT EXISTS(SELECT 1 FROM admission_review_events e WHERE e.application_id=a.id AND e.event_type='SUBMIT_TO_SCHOOL')",
 'APPROVED_REPORT_EVENT': "SELECT COUNT(*) FROM ctsv_semester_reports r WHERE r.status='APPROVED' AND NOT EXISTS(SELECT 1 FROM ctsv_semester_report_reviews e WHERE e.report_id=r.id AND e.action='APPROVE')",
 'RESOLVED_REQUEST_WITHOUT_HANDLER': "SELECT COUNT(*) FROM student_requests WHERE status IN ('RESOLVED','REJECTED') AND (handled_by IS NULL OR handled_at IS NULL OR response IS NULL OR TRIM(response)='')",
 'APPROVED_PROPOSAL_INVOICE_MATCH': "SELECT COUNT(*) FROM invoice_proposals p JOIN invoices i ON i.id=p.invoice_id WHERE p.status='ISSUED' AND (i.student_id<>p.student_id OR i.semester_id<>p.semester_id OR i.discount_amount<>p.discount_amount)",
 'PROPOSAL_REVIEW_SELF_APPROVAL': "SELECT COUNT(*) FROM invoice_proposals WHERE status IN ('APPROVED','ISSUED') AND reviewed_by=prepared_by",
 'ADJUSTMENT_REVIEW_SELF_APPROVAL': "SELECT COUNT(*) FROM tuition_adjustments WHERE status='APPROVED' AND approved_by=requested_by",
 'REPORT_REVIEW_SELF_APPROVAL': "SELECT COUNT(*) FROM ctsv_semester_reports WHERE status='APPROVED' AND received_by=prepared_by",
 'REMITTANCE_REVIEW_SELF_APPROVAL': "SELECT COUNT(*) FROM ctsv_remittances WHERE status='CONFIRMED' AND reviewed_by=prepared_by",
 'IDENTITY_HMAC_FORMAT': "SELECT COUNT(*) FROM admission_identity_records WHERE identity_number_hmac IS NOT NULL AND identity_number_hmac NOT REGEXP '^[0-9a-fA-F]{64}$'",
})
for row in columns:
    if row['t'] in tables and row['c'] in ['phone','guardian_phone']:
        add('PHONE '+row['t']+'.'+row['c'], f"SELECT COUNT(*) FROM {q(row['t'])} WHERE {q(row['c'])} IS NOT NULL AND {q(row['c'])} NOT REGEXP '^[+]?[0-9 ()-]{{8,24}}$'")
# Also execute the aggregate business checks shipped in the original reference SQL.
reference='\n'.join(line for line in (ROOT/'data/v6/03_QUERIES_CHECK.sql').read_text(encoding='utf-8-sig').splitlines() if not line.lstrip().startswith('--'))
for statement in re.findall(r"SELECT '[A-Z_]+'.*?;",reference,re.S):
    if 'AS check_name' in statement and 'violation_count' in statement:
        for row in rows(statement.rstrip(';'),['check_name','violation_count']):
            add('ORIGINAL_SQL '+row['check_name'],'SELECT '+str(row['violation_count']))

for name, query in business.items():
    add(name, query, 'warning' if name=='PAYMENT_WITHOUT_FUND' else 'error', 'Chứng từ cũ chưa gắn quỹ; không tự suy đoán quỹ hoặc sửa số tiền.' if name=='PAYMENT_WITHOUT_FUND' else '')
# Timetable collisions in the same semester. Boundaries that merely touch do not collide.
collision = "FROM section_schedules a JOIN section_schedules b ON a.id<b.id AND a.day_of_week=b.day_of_week AND a.starts_at<b.ends_at AND b.starts_at<a.ends_at JOIN course_sections ca ON ca.id=a.section_id JOIN course_sections cb ON cb.id=b.section_id WHERE ca.semester_id=cb.semester_id"
add('SCHEDULE_ROOM_CONFLICT','SELECT COUNT(*) '+collision+' AND a.room_id=b.room_id')
add('SCHEDULE_LECTURER_CONFLICT','SELECT COUNT(*) '+collision+' AND ca.lecturer_id=cb.lecturer_id')
add('SCHEDULE_STUDENT_CONFLICT','SELECT COUNT(*) '+collision+" AND EXISTS(SELECT 1 FROM enrollments ea JOIN enrollments eb ON ea.student_id=eb.student_id WHERE ea.section_id=a.section_id AND eb.section_id=b.section_id AND ea.status<>'CANCELLED' AND eb.status<>'CANCELLED')")
for view in ['v_normalization_checks','v_approval_workflow_checks']:
    for row in rows('SELECT check_name,violation_count FROM '+view,['check_name','violation_count']):
        add('VIEW '+row['check_name'],'SELECT '+str(row['violation_count']))

results = []
# Separate statements isolate errors so a bad check cannot hide remaining validations.
for offset in range(0,len(checks),75):
    batch = checks[offset:offset+75]
    statements = ['SELECT '+str(offset+i)+',('+item['query']+')' for i,item in enumerate(batch)]
    try:
        values = sql(';\n'.join(statements)).splitlines()
        for line in values:
            index,count = line.split('\t'); item=checks[int(index)]
            results.append({k:v for k,v in item.items() if k!='query'} | {'violations':int(count)})
    except RuntimeError:
        for item in batch:
            try: result={'violations':int(sql(item['query']))}
            except RuntimeError as error: result={'violations':None,'execution_error':str(error)}
            results.append({k:v for k,v in item.items() if k!='query'} | result)

inventory = []
for item in objects:
    try: inventory.append(item | {'rows':int(sql('SELECT COUNT(*) FROM '+q(item['name'])))})
    except RuntimeError as error: results.append({'name':'OBJECT '+item['name'],'severity':'error','violations':None,'execution_error':str(error)})

migration_names = re.findall(r'"(\d{2}_[A-Z_]+\.sql)"',(ROOT/'backend/scripts/Migrate-Database.py').read_text())
stored = {row['version']:row['checksum'] for row in rows('SELECT version,checksum FROM schema_migrations',['version','checksum'])}
for name in migration_names:
    valid=stored.get(name)==hashlib.sha256((ROOT/'data/v6'/name).read_bytes()).hexdigest()
    results.append({'name':'MIGRATION '+name,'severity':'error','violations':0 if valid else 1})

# Check actual private storage separately from SQL metadata, without exporting keys.
files_dir=Path(cfg.get('SMS_FILES_DIR','./private-files'))
if not files_dir.is_absolute(): files_dir=ROOT/'backend'/files_dir
files_dir=files_dir.resolve()
file_checks=[]
for table in ['admission_documents','student_request_attachments','student_profile_photos']:
    fields=['storage_key','mime_type']+(['size_bytes'] if table!='student_profile_photos' else [])
    records=rows('SELECT '+','.join(fields)+' FROM '+table,fields)
    missing=invalid=wrong_size=0
    for record in records:
        key=record['storage_key']
        if not re.fullmatch(r'[a-f0-9-]{36}',key): missing+=1;continue
        target=(files_dir/key).resolve()
        if not target.is_relative_to(files_dir): invalid+=1;continue
        if not target.is_file(): missing+=1;continue
        if 'size_bytes' in record and target.stat().st_size!=record['size_bytes']: wrong_size+=1
    for label,count,severity,note in [
        ('MISSING_PRIVATE_FILE',missing,'warning','Có metadata seed nhưng chưa có tệp hợp lệ trong kho riêng; không tạo giấy tờ thay thế.'),
        ('UNSAFE_FILE_PATH',invalid,'error','Đường dẫn nằm ngoài kho riêng.'),
        ('FILE_SIZE_MISMATCH',wrong_size,'error','Kích thước tệp không khớp metadata.')]:
        results.append({'name':label+' '+table,'violations':count,'severity':severity,'explanation':note,'category':'files'})
    file_checks.append({'table':table,'records':len(records),'missing':missing,'invalid_path':invalid,'wrong_size':wrong_size})
no_photo=int(sql('SELECT COUNT(*) FROM students s WHERE NOT EXISTS(SELECT 1 FROM student_profile_photos p WHERE p.student_id=s.id)'))
results.append({'name':'STUDENT_WITHOUT_UPLOADED_PHOTO','violations':no_photo,'severity':'warning','explanation':'Chưa tải ảnh hồ sơ; giao diện dùng ảnh đại diện chữ cái. Không phải lỗi khóa/SQL.','category':'files'})

report = {'generated_at':dt.datetime.now().isoformat(timespec='seconds'),'database':database,'scope':'Aggregate read-only validation; no business records modified.','inventory':inventory,'sql_checks':results,'api_checks':[],'file_checks':file_checks}
report['optional_completeness']=rows("SELECT s.student_code,COUNT(p.student_id) has_photo FROM students s LEFT JOIN student_profile_photos p ON p.student_id=s.id GROUP BY s.id,s.student_code",['student_code','has_photo'])

if not args.skip_api:
    credentials=json.loads((ROOT/f'backend/.local/actor-credentials-{database}.json').read_text(encoding='utf-8'))
    for entry in credentials:
        opener=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
        account_checks=[]
        def api(path, body=None, expected=200):
            headers={'Content-Type':'application/json'}
            if body is not None:
                csrf=json.load(opener.open(args.base_url+'/api/auth/csrf',timeout=15))
                headers[csrf['headerName']]=csrf['token']
            req=urllib.request.Request(args.base_url+'/api'+path,data=None if body is None else json.dumps(body).encode(),headers=headers)
            try:
                with opener.open(req,timeout=30) as response: status=response.status;raw=response.read()
            except urllib.error.HTTPError as error: status=error.code;raw=error.read()
            assert status==expected, f'{path}: HTTP {status}, expected {expected}'
            return json.loads(raw) if raw else None
        try:
            me=api('/auth/login',{'username':entry['username'],'password':entry['password']})
            assert set(entry['role'].split(',')).issubset(set(me['roles']))
            account_checks.append('LOGIN_ROLE')
            allowed_sections=set()
            if entry['role']=='LECTURER':
                allowed_sections={row['id'] for row in rows('SELECT id FROM course_sections WHERE lecturer_id='+str(int(me['lecturerId'])),['id'])}
            elif entry['role']=='STUDENT':
                allowed_sections={row['section_id'] for row in rows("SELECT section_id FROM enrollments WHERE status<>'CANCELLED' AND student_id="+str(int(me['studentId'])),['section_id'])}

            meta=api('/meta')['resources'];api('/lookups');account_checks.append('METADATA_LOOKUPS')
            for resource in meta:
                key=resource['key'];found=[];page=1;total=None
                while True:
                    result=api(f'/resources/{key}?page={page}&size=50')
                    if total is None: total=result['total']
                    assert total==result['total'],f'{key}: total changed during scan'
                    assert result['page']==page and result['size']==50
                    found.extend(result['items'])
                    if len(found)>=total: break
                    assert result['items'],f'{key}: premature empty page';page+=1
                    assert page<1000
                assert len(found)==total, f'{key}: count mismatch'
                ids=[row.get('invoice_id') if key=='invoices' else row.get('id') for row in found]
                assert len(ids)==len(set(ids)),f'{key}: duplicated IDs across pages'
                for row in found:
                    assert not any(field in row for field in ['password_hash','token_hash','storage_key']),f'{key}: private field leaked'
                    if entry['role']=='STUDENT':
                        if key in ['students','enrollments','grades','invoices','payments','requests','mailboxes']:
                            actual=row['id'] if key=='students' else row.get('student_id')
                            assert actual==me['studentId'],f'{key}: another student record'
                        if key=='grades': assert row['sheet_status']=='PUBLISHED'
                    if entry['role']=='LECTURER' and key in ['sections','grade_sheets','grades','enrollments']:
                        section=row['id'] if key=='sections' else row['section_id']
                        assert section in allowed_sections,f'{key}: unassigned lecturer class'
                    if entry['role']=='APPLICANT' and key=='admissions': assert row['applicant_user_id']==me['id']
                for row in found:
                    record_id=row.get('invoice_id') if key=='invoices' else row.get('id')
                    detail_path={
                        'invoice_proposals':f'/invoice-proposals/{record_id}',
                        'admissions':f'/admissions/{record_id}',
                        'requests':f'/requests/{record_id}/detail',
                        'sections':f'/sections/{record_id}/detail',
                        'invoices':f'/invoices/{record_id}/items',
                        'grade_sheets':f'/grade-sheets/{record_id}/reviews',
                        'reports':f'/reports/{record_id}/summary',
                        'curricula':f'/curricula/{record_id}/courses',
                    }.get(key)
                    if detail_path:
                        detail=api(detail_path)
                        if key=='invoices':
                            assert all(item['invoice_id']==record_id for item in detail)
                            assert sum(Decimal(str(item['amount'])) for item in detail)==Decimal(str(row['base_amount'])),'Invoice item total mismatch'
                        if key=='invoice_proposals':
                            amount=sum(Decimal(str(item['amount'])) for item in detail['items'])
                            assert amount==Decimal(str(detail['gross_amount']))
                            assert amount-Decimal(str(detail['discount_amount']))==Decimal(str(detail['payable_amount']))
                        account_checks.append('DETAIL '+key+' '+str(record_id))

                account_checks.append('RESOURCE '+key+': '+str(total))
            if 'PRINCIPAL' in me['roles']:
                for key,states in {'grade_sheets':['VERIFIED'],'admissions':['SENT_TO_SCHOOL'],'invoice_proposals':['SUBMITTED'],'adjustments':['REQUESTED'],'remittances':['SUBMITTED'],'reports':['SUBMITTED']}.items():
                    for view in ['pending','history']:
                        result=api(f'/reviews/{key}?view={view}&size=50')
                        if view=='pending': assert all(row['status'] in states for row in result['items'])
                        account_checks.append('REVIEW '+key+' '+view+': '+str(result['total']))
            if set(me['roles']) & {'PRINCIPAL','TRAINING_OFFICE','LECTURER','STUDENT'}:
                timetable=api('/timetable')
                if entry['role'] in ['LECTURER','STUDENT']:
                    assert all(row['section_id'] in allowed_sections for row in timetable),'Timetable belongs to another account'
                account_checks.append('TIMETABLE')
                exams=api('/exams')
                if entry['role'] in ['LECTURER','STUDENT']:
                    assert all(row['section_id'] in allowed_sections and row['status']=='PUBLISHED' for row in exams),'Unpublished or unassigned exams exposed'
                account_checks.append('EXAMS')
            if entry['role']=='STUDENT':
                profile=api('/student/profile');academic=api('/student/academic')
                assert profile['id']==me['studentId'] and academic['profile'][0]['id']==me['studentId']
                for enrollment in academic['enrollments']:
                    assert enrollment['student_id']==me['studentId']
                    if enrollment['sheet_status']!='PUBLISHED':
                        assert all(enrollment[field] is None for field in ['attendance_score','midterm_score','final_score','total_score','remark']),'Unpublished grade exposed'
                account_checks.append('STUDENT_PROFILE_ACADEMIC')
            if entry['role'] in ['STUDENT','APPLICANT','LECTURER']:
                api('/resources/users',expected=403);api('/reviews/invoice_proposals',expected=403)
                account_checks.append('DENY_STAFF_DATA')
            report['api_checks'].append({'username':entry['username'],'role':entry['role'],'passed':True,'checks':account_checks})
        except Exception as error:
            report['api_checks'].append({'username':entry['username'],'role':entry['role'],'passed':False,'checks':account_checks,'error':str(error)})
        finally:
            try: api('/auth/logout',{},expected=204)
            except Exception: pass

errors=[row for row in results if row['severity']=='error' and row.get('violations')!=0]
warnings=[row for row in results if row['severity']=='warning' and row.get('violations')!=0]
api_errors=[row for row in report['api_checks'] if not row['passed']]
report['summary']={'tables':len(tables),'views':len(objects)-len(tables),'data_checks':len(results),'sql_checks':sum(row.get('category')!='files' for row in results),'sql_failed':len(errors),'sql_warnings':len(warnings),'accounts_checked':len(report['api_checks']),'api_checks':sum(len(row['checks']) for row in report['api_checks']),'api_failed':len(api_errors)}
folder=ROOT/'backend/.local/validation';folder.mkdir(exist_ok=True)
json_path=folder/'all-data-validation.json';json_path.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
lines=['# Kiểm tra toàn bộ dữ liệu V6','',f'Thời điểm: {report["generated_at"]}. Database: `{database}`.','',f'Phạm vi: {len(tables)} bảng, {len(objects)-len(tables)} view, {len(results)} kiểm tra dữ liệu SQL/tệp hồ sơ và {len(report["api_checks"])} tài khoản. Không thay đổi bản ghi nghiệp vụ.','',f'Lỗi dữ liệu: **{len(errors)}**. Cảnh báo dữ liệu: **{len(warnings)}**. Tài khoản có lỗi kiểm tra API: **{len(api_errors)}**.','','## Lỗi và cảnh báo','']
for row in errors+warnings:lines.append(f'- {row["severity"].upper()}: `{row["name"]}` — {row.get("violations")} bản ghi. '+row.get('explanation','')+row.get('execution_error',''))
for row in api_errors:lines.append(f'- API `{row["username"]}`: {row["error"]}')
if not errors+warnings+api_errors:lines.append('Không phát hiện vi phạm trong các kiểm tra đã chạy.')
lines+=['','## Kiểm kê bảng và view','','| Bảng / view | Loại | Số bản ghi |','|---|---|---:|']
for row in inventory:lines.append(f'| {row["name"]} | {row["kind"]} | {row["rows"]} |')
lines+=['','## Kiểm tra API theo tài khoản','','| Tài khoản | Vai trò | Kết quả | Số kiểm tra |','|---|---|---|---:|']
for row in report['api_checks']:lines.append(f'| {row["username"]} | {row["role"]} | {"Đạt" if row["passed"] else "Lỗi"} | {len(row["checks"])} |')
lines+=['','## Chạy lại kiểm tra','','```powershell','python backend/scripts/Validate-AllData.py','```','','Script đọc kết nối từ `backend/.env.local` và tài khoản riêng trong `backend/.local/`; không ghi mật khẩu vào báo cáo. Dùng `--skip-api` nếu chỉ cần quét SQL/tệp hồ sơ. JSON chi tiết ở `backend/.local/validation/all-data-validation.json`.','','## Cách xử lý dữ liệu còn thiếu','','- Chứng từ chưa gắn quỹ: đối chiếu sổ thu để xác định quỹ chính xác; không suy đoán từ số tiền.','- Giấy tờ seed: tải lên các tệp tương ứng qua hồ sơ; không tạo giấy tờ cá nhân giả để làm đủ tệp.','- Ảnh hồ sơ: tải ảnh JPEG/PNG trong hồ sơ sinh viên; đây là trường tùy chọn.','','## Giới hạn','','Trường NULL hoặc bảng rỗng có thể hợp lệ theo trạng thái nghiệp vụ. Ảnh/hồ sơ tải lên, email thực tế và dữ liệu chính thức của trường cần đối chiếu nguồn; không tự tạo chứng từ hoặc thông tin cá nhân để làm đầy dữ liệu. Báo cáo JSON riêng chứa kết quả từng phép kiểm tra, không chứa mật khẩu/token.']
(ROOT/'docs/VALIDATE_TOAN_BO_DU_LIEU.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps(report['summary']))
for row in errors+warnings:print(row['severity'].upper()+': '+row['name']+' = '+str(row.get('violations')))
for row in api_errors:print('API: '+row['username']+' '+row['error'])
print('REPORT=docs/VALIDATE_TOAN_BO_DU_LIEU.md')
raise SystemExit(1 if errors or api_errors else 0)
