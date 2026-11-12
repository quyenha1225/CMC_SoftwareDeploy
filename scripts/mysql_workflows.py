"""Mutating end-to-end tests, restricted to a newly created sms_ci_* database."""
from concurrent.futures import ThreadPoolExecutor
import http.cookiejar
import json
import struct
import zlib
import urllib.error
import urllib.request
from docker import settings


def verify_workflows(runtime):
    if not runtime.config['COMPOSE_PROJECT_NAME'].startswith('sms_ci_'):
        raise RuntimeError('Workflow writes are allowed only in the isolated CI namespace')
    base=runtime.url();passwords=settings(runtime.secret_dir/'demo_accounts');clients={};checks=[]
    def api(actor,path,body=None,accepted=(200,)):
        opener=clients[actor];headers={'Content-Type':'application/json'}
        if body is not None:
            csrf=json.load(opener.open(base+'/api/auth/csrf',timeout=20));headers[csrf['headerName']]=csrf['token']
        request=urllib.request.Request(base+'/api'+path,data=None if body is None else json.dumps(body).encode(),headers=headers)
        try:
            with opener.open(request,timeout=30) as response:status=response.status;raw=response.read()
        except urllib.error.HTTPError as error:status=error.code;raw=error.read()
        if status not in accepted:raise RuntimeError('Workflow HTTP '+str(status)+' at '+path)
        return status,json.loads(raw) if raw else None
    def data(actor,path,body=None):return api(actor,path,body)[1]
    actors=['principal','ctsv_demo','training_demo','student_demo_001','student_demo_002','student_demo_004','applicant_demo_04']
    for actor in actors:
        clients[actor]=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
        data(actor,'/auth/login',{'username':actor,'password':passwords[actor]})
    try:
        # Production-only core schema: no demo accounts, students or receipts.
        core_db='sms_core_ci'
        exists=runtime.sql("SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='sms_core_ci'")
        if int(exists):raise RuntimeError('Core test schema already exists')
        runtime.sql("CREATE DATABASE sms_core_ci CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; GRANT ALL ON sms_core_ci.* TO 'sms_migrator'@'%';")
        runtime.run('run','--rm','-e','SMS_SEED_DEMO=false','-e','SMS_ENVIRONMENT=production','-e','FLYWAY_URL=jdbc:mysql://db:3306/sms_core_ci?allowPublicKeyRetrieval=true&useSSL=false','migrate')
        assert runtime.sql('SELECT COUNT(*) FROM sms_core_ci.roles').strip()=='6'
        assert runtime.sql('SELECT COUNT(*) FROM sms_core_ci.students').strip()=='0'
        assert runtime.sql('SELECT COUNT(*) FROM sms_core_ci.payments').strip()=='0'
        import subprocess
        for options,message in [
            (['-e','SMS_SEED_DEMO=true','-e','SMS_ENVIRONMENT=production','migrate','validate'],'Demo seed is forbidden'),
            (['migrate','clean'],'Only migrate, validate and info are allowed'),
        ]:
            rejection=subprocess.run(runtime.compose+['run','--rm',*options],capture_output=True)
            assert rejection.returncode!=0 and message in (rejection.stdout+rejection.stderr).decode('utf-8','replace')
        checks.append('Production core has 6 roles and zero students/payments; demo seed and clean rejected')
        pdt='training_demo';bgh='principal';ctsv='ctsv_demo';student='student_demo_001'
        sheets=data(pdt,'/resources/grade_sheets?size=50')['items']
        nw=next(row for row in sheets if row['section_code']=='NW103-01')
        api(bgh,f"/sections/{nw['section_id']}/sheet/VERIFY",{},accepted=(403,))
        data(pdt,f"/sections/{nw['section_id']}/sheet/VERIFY",{'note':'Isolated CI: verify and forward.'})
        data(bgh,f"/sections/{nw['section_id']}/sheet/APPROVE",{'note':'Isolated CI: approve.'})
        data(pdt,f"/sections/{nw['section_id']}/sheet/PUBLISH",{'note':'Isolated CI: publish.'})
        assert any(row['section_id']==nw['section_id'] for row in data(student,'/resources/grades')['items'])
        checks.append('PDT -> BGH -> PDT publication; wrong-role verification denied')

        proposals=data(bgh,'/reviews/invoice_proposals')['items']
        proposal=next(row for row in proposals if row['proposal_code']=='DHP-2026-HK2-003')
        issue={'student_id':proposal['student_id'],'semester_id':proposal['semester_id']}
        api(ctsv,'/invoices/issue',issue,accepted=(409,));api(bgh,'/invoices/issue',issue,accepted=(403,))
        data(bgh,f"/invoice-proposals/{proposal['id']}/APPROVE",{'note':'Isolated CI only.'})
        invoice=data(ctsv,'/invoices/issue',issue)['id']
        fund=int(runtime.sql('SELECT MIN(id) FROM ctsv_funds WHERE active=TRUE'))
        receipt={'invoice_id':invoice,'fund_id':fund,'amount':100000,'reference_no':'CI-PAYMENT-RACE-001','note':'Isolated CI only; no real money.'}
        with ThreadPoolExecutor(max_workers=2) as pool:
            outcomes=list(pool.map(lambda _:api(ctsv,'/payments',receipt,accepted=(200,409)),range(2)))
        assert sorted(status for status,_ in outcomes)==[200,409], str(outcomes)
        payment=next(body['id'] for status,body in outcomes if status==200)

        # Distinct references must not bypass the remaining-balance check under contention.
        competing=[dict(receipt,reference_no='CI-OVERPAY-RACE-'+str(index),amount=2000000) for index in range(2)]
        with ThreadPoolExecutor(max_workers=2) as pool:
            payments=list(pool.map(lambda payload:api(ctsv,'/payments',payload,accepted=(200,409)),competing))
        assert sorted(status for status,_ in payments)==[200,409],str(payments)
        checks.append('Concurrent different receipts cannot overpay one invoice')

        remittance=data(ctsv,'/remittances',{'fund_id':fund,'semester_id':proposal['semester_id'],'allocations':[{'payment_id':payment,'allocated_amount':100000}],'note':'Isolated CI only.'})['id']
        api(ctsv,f'/remittances/{remittance}/decision',{'approve':True},accepted=(403,))
        data(bgh,f'/remittances/{remittance}/decision',{'approve':True,'note':'Isolated CI only.'})
        checks.append('Reviewed invoice -> concurrent duplicate receipt blocked -> CTSV remittance -> BGH confirmation')

        candidate=next(row for row in data(pdt,'/resources/admissions?size=50')['items'] if row['application_code']=='APP-DEMO-V6-004')
        class_id=int(runtime.sql("SELECT id FROM academic_classes WHERE code='KTPM26-A'"))
        api(bgh,f"/admissions/{candidate['id']}/actions/ENROLL",{'student_code':'SV260007','class_id':class_id},accepted=(403,))
        data(pdt,f"/admissions/{candidate['id']}/actions/PDT_VERIFY",{'note':'Isolated CI only.'})
        data(pdt,f"/admissions/{candidate['id']}/actions/ENROLL",{'student_code':'SV260007','class_id':class_id})
        checks.append('BGH cannot issue MSSV; PDT verifies/enrolls after approval')

        # Open the registration window only in this disposable test fixture.
        wd=int(runtime.sql("SELECT id FROM course_sections WHERE section_code='WD104-01'"))
        runtime.sql(f"UPDATE semesters SET registration_from=DATE_SUB(NOW(),INTERVAL 1 DAY),registration_to=DATE_ADD(NOW(),INTERVAL 1 DAY),status='OPEN' WHERE id=(SELECT semester_id FROM course_sections WHERE id={wd})")
        data('applicant_demo_04',f'/sections/{wd}/register',{})
        assert any(row['section_id']==wd for row in data('applicant_demo_04','/timetable'))
        data('applicant_demo_04',f'/sections/{wd}/cancel',{})
        assert not any(row['section_id']==wd for row in data('applicant_demo_04','/timetable'))
        checks.append('Registration/cancellation updates timetable from enrollments')

        # Race two eligible students for the final available seat in this fixture.
        data('student_demo_004',f'/sections/{wd}/cancel',{})
        capacity=int(runtime.sql(f'SELECT capacity FROM course_sections WHERE id={wd}'))
        active=int(runtime.sql(f"SELECT COUNT(*) FROM enrollments WHERE section_id={wd} AND status<>'CANCELLED'"))
        runtime.sql(f'UPDATE course_sections SET capacity={active+1} WHERE id={wd}')
        competitors=['student_demo_004','applicant_demo_04']
        with ThreadPoolExecutor(max_workers=2) as pool:
            outcomes=list(pool.map(lambda actor:api(actor,f'/sections/{wd}/register',{},accepted=(200,409)),competitors))
        assert sorted(status for status,_ in outcomes)==[200,409], str(outcomes)
        assert int(runtime.sql(f"SELECT COUNT(*) FROM enrollments WHERE section_id={wd} AND status<>'CANCELLED'"))==active+1
        winner=competitors[next(index for index,(status,_) in enumerate(outcomes) if status==200)]
        if winner!='student_demo_004':
            data(winner,f'/sections/{wd}/cancel',{})
            data('student_demo_004',f'/sections/{wd}/register',{})
        runtime.sql(f'UPDATE course_sections SET capacity={capacity} WHERE id={wd}')
        checks.append('Concurrent registration for the last seat never exceeds section capacity')


        # Synthetic 32x32 PNG fixture, not an actual student's portrait.
        def chunk(kind,payload):
            return struct.pack('>I',len(payload))+kind+payload+struct.pack('>I',zlib.crc32(kind+payload)&0xffffffff)
        png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',32,32,8,2,0,0,0))+chunk(b'IDAT',zlib.compress((b'\0'+bytes([20,90,110])*32)*32))+chunk(b'IEND',b'')
        sid=data(student,'/me')['studentId'];boundary='sms-ci-upload'
        payload=(f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="ci-fixture.png"\r\nContent-Type: image/png\r\n\r\n'.encode()+png+f'\r\n--{boundary}--\r\n'.encode())
        csrf=json.load(clients[student].open(base+'/api/auth/csrf'))
        request=urllib.request.Request(base+f'/api/students/{sid}/photo',data=payload,headers={'Content-Type':'multipart/form-data; boundary='+boundary,csrf['headerName']:csrf['token']})
        with clients[student].open(request,timeout=30) as response:assert response.status==200
        with clients[student].open(base+f'/api/students/{sid}/photo',timeout=30) as response:assert response.read().startswith(b'\xff\xd8')
        api('student_demo_002',f'/students/{sid}/photo',accepted=(403,404))
        checks.append('Private PNG upload re-encoded to JPEG; another student cannot read it')

        print('PASS isolated MySQL business workflows: '+str(len(checks)))
        return checks
    finally:
        for actor in actors:
            try:api(actor,'/auth/logout',{},accepted=(204,))
            except Exception:pass
