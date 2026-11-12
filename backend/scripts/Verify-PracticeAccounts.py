"""Check all saved practice logins; optional workflow mutations are clone-only."""
import argparse
import http.cookiejar
import json
from pathlib import Path
import urllib.error
import urllib.parse
import urllib.request

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--base-url',default='http://127.0.0.1:5173')
parser.add_argument('--credentials',required=True)
parser.add_argument('--mutate',action='store_true')
args=parser.parse_args()
path=Path(args.credentials)
if args.mutate and ('verify' not in path.name or urllib.parse.urlparse(args.base_url).port!=5176):
    raise SystemExit('Workflow writes are restricted to the verification database/port 5176.')
accounts=json.loads(path.read_text(encoding='utf-8'))
clients={}
for entry in accounts:
    opener=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
    clients[entry['username']]=opener
def request(username,route,body=None,method=None,expected=200):
    opener=clients[username];headers={'Content-Type':'application/json'}
    if body is not None:
        csrf=json.load(opener.open(args.base_url+'/api/auth/csrf',timeout=20))
        headers[csrf['headerName']]=csrf['token']
    payload=None if body is None else json.dumps(body).encode()
    req=urllib.request.Request(args.base_url+'/api'+route,data=payload,headers=headers,method=method or ('GET' if body is None else 'POST'))
    try:
        with opener.open(req,timeout=30) as response:
            status=response.status;raw=response.read()
    except urllib.error.HTTPError as error:
        status=error.code;raw=error.read()
    if status!=expected:
        raise AssertionError(f'{username} {route}: expected {expected}, got {status}; '+raw.decode('utf-8','replace'))
    return json.loads(raw) if raw else None
for entry in accounts:
    user=request(entry['username'],'/auth/login',{'username':entry['username'],'password':entry['password']})
    assert set(entry['role'].split(',')).issubset(set(user['roles']))
print(f'PASS {len(accounts)} account logins with assigned roles; passwords were not logged.')

if args.mutate:
    principal='principal';ctsv='ctsv_demo';pdt='training_demo'
    queue=request(principal,'/reviews/grade_sheets')['items']
    assert all(row['status']=='VERIFIED' for row in queue)
    sheets=request(pdt,'/resources/grade_sheets?size=50')['items']
    nw=next(row for row in sheets if row['section_code']=='NW103-01')
    if nw['status'] != 'PUBLISHED':
        request(principal,f"/sections/{nw['section_id']}/sheet/VERIFY",{},expected=403)
        request(pdt,f"/sections/{nw['section_id']}/sheet/VERIFY",{'note':'Verification database: PĐT checks and forwards.'})
        request(principal,f"/sections/{nw['section_id']}/sheet/APPROVE",{'note':'Verification database: BGH approves.'})
        request(pdt,f"/sections/{nw['section_id']}/sheet/PUBLISH",{'note':'Verification database: publish approved grades.'})
    request('student_demo_001','/resources/grades')
    print('PASS lecturer -> PĐT -> BGH -> PĐT publication boundaries.')

    proposal=next(row for row in request(principal,'/reviews/invoice_proposals')['items'] if row['proposal_code']=='DHP-2026-HK2-003')
    issue={'student_id':proposal['student_id'],'semester_id':proposal['semester_id']}
    before=request(ctsv,'/resources/invoices')['total']
    request(ctsv,'/invoices/issue',issue,expected=409)
    request(principal,'/invoices/issue',issue,expected=403)
    request(principal,f"/invoice-proposals/{proposal['id']}/APPROVE",{'note':'Verification database only.'})
    assert request(ctsv,'/resources/invoices')['total']==before,'BGH approval must not issue an invoice itself'
    request(ctsv,'/invoices/issue',issue)
    assert request(ctsv,'/resources/invoices')['total']==before+1
    print('PASS proposal review does not issue/collect money; only CTSV issues approved snapshots.')

    other=next(row for row in request(ctsv,'/resources/invoice_proposals?size=50')['items'] if row['proposal_code']=='DHP-2026-HK2-004')
    request(ctsv,f"/invoice-proposals/{other['id']}/SUBMIT",{'note':'Verification database only.'})
    request(principal,f"/invoice-proposals/{other['id']}/RETURN",{'note':'Bổ sung căn cứ trước khi xét duyệt.'})
    request(ctsv,f"/invoice-proposals/{other['id']}",{'discount_amount':0,'note':'Đã bổ sung hồ sơ.'},method='PUT')
    print('PASS return reason and revision workflow.')

    admissions=request(pdt,'/resources/admissions?size=50')['items']
    candidate=next(row for row in admissions if row['application_code']=='APP-DEMO-V6-004')
    request(principal,f"/admissions/{candidate['id']}/actions/ENROLL",{'student_code':'SV260007','class_id':1},expected=403)
    request(pdt,f"/admissions/{candidate['id']}/actions/PDT_VERIFY",{'note':'Verification database only.'})
    classroom=next(row for row in request(pdt,'/lookups')['academic_classes'] if row['code']=='KTPM26-A')
    request(pdt,f"/admissions/{candidate['id']}/actions/ENROLL",{'student_code':'SV260007','class_id':classroom['id'],'note':'Verification database only.'})
    print('PASS BGH cannot enroll a student; PĐT verifies/enrolls only after school approval.')

for entry in accounts:
    request(entry['username'],'/auth/logout',{},expected=204)
