-- Runnable review examples. No existing invoice, payment, rate or grade score is changed.
SET NAMES utf8mb4;
START TRANSACTION;

-- PĐT inbox: a complete lecturer-submitted sheet, with import event provenance.
INSERT INTO grade_reviews(sheet_id,actor_user_id,action,note,event_key)
SELECT gs.id,l.user_id,'SUBMIT','Giảng viên trình bảng điểm để PĐT kiểm tra.','TH14-NW103-SUBMIT'
FROM grade_sheets gs JOIN course_sections cs ON cs.id=gs.section_id JOIN lecturers l ON l.id=cs.lecturer_id
WHERE cs.section_code='NW103-01' AND gs.status='DRAFT'
AND NOT EXISTS(SELECT 1 FROM grade_reviews r WHERE r.event_key='TH14-NW103-SUBMIT');
UPDATE grade_sheets gs JOIN course_sections cs ON cs.id=gs.section_id
SET gs.status='SUBMITTED' WHERE cs.section_code='NW103-01' AND gs.status='DRAFT' AND gs.version_no=1
AND EXISTS(SELECT 1 FROM grade_reviews r WHERE r.sheet_id=gs.id AND r.event_key='TH14-NW103-SUBMIT');

-- BGH inbox: the already verified practical sheet carries explicit PĐT forwarding history.
INSERT INTO grade_reviews(sheet_id,actor_user_id,action,note,event_key)
SELECT gs.id,u.id,'VERIFY','PĐT đã kiểm tra và trình BGH xét duyệt.','TH14-BA101-VERIFY'
FROM grade_sheets gs JOIN course_sections cs ON cs.id=gs.section_id JOIN users u ON u.username='training_demo'
WHERE cs.section_code='BA101-01' AND gs.status='VERIFIED'
AND NOT EXISTS(SELECT 1 FROM grade_reviews r JOIN user_roles ur ON ur.user_id=r.actor_user_id JOIN roles ro ON ro.id=ur.role_id WHERE r.sheet_id=gs.id AND r.action='VERIFY' AND ro.code='TRAINING_OFFICE');

-- Two unbilled HK2 registrations provide one submitted proposal and one editable draft.
INSERT INTO enrollments(student_id,section_id,status)
SELECT s.id,cs.id,'REGISTERED' FROM students s JOIN users u ON u.id=s.user_id
JOIN course_sections cs ON cs.section_code='WD104-01'
WHERE u.username IN ('student_demo_003','student_demo_004')
AND NOT EXISTS(SELECT 1 FROM invoices i WHERE i.student_id=s.id AND i.semester_id=cs.semester_id)
AND NOT EXISTS(SELECT 1 FROM enrollments e WHERE e.student_id=s.id AND e.section_id=cs.id);
INSERT INTO grades(enrollment_id,remark)
SELECT e.id,'Chờ giảng viên nhập điểm học kỳ 2.' FROM enrollments e JOIN students s ON s.id=e.student_id
JOIN users u ON u.id=s.user_id JOIN course_sections cs ON cs.id=e.section_id
WHERE u.username IN ('student_demo_003','student_demo_004') AND cs.section_code='WD104-01'
AND NOT EXISTS(SELECT 1 FROM grades g WHERE g.enrollment_id=e.id);

INSERT INTO invoice_proposals(proposal_code,student_id,semester_id,prepared_by,status,note)
SELECT CONCAT('DHP-2026-HK2-',RIGHT(u.username,3)),s.id,cs.semester_id,prep.id,'DRAFT',
 'Đề nghị theo học phần đã đăng ký và đơn giá học kỳ; chưa phải hóa đơn hoặc khoản thu.'
FROM students s JOIN users u ON u.id=s.user_id JOIN enrollments e ON e.student_id=s.id
JOIN course_sections cs ON cs.id=e.section_id AND cs.section_code='WD104-01'
JOIN users prep ON prep.username='ctsv_demo'
WHERE u.username IN ('student_demo_003','student_demo_004')
AND NOT EXISTS(SELECT 1 FROM invoices i WHERE i.student_id=s.id AND i.semester_id=cs.semester_id)
AND NOT EXISTS(SELECT 1 FROM invoice_proposals p WHERE p.student_id=s.id AND p.semester_id=cs.semester_id);
INSERT INTO invoice_proposal_items(proposal_id,enrollment_id,credits_at_proposal,unit_price_at_proposal)
SELECT p.id,e.id,c.credits,tr.price_per_credit FROM invoice_proposals p
JOIN enrollments e ON e.student_id=p.student_id JOIN course_sections cs ON cs.id=e.section_id AND cs.semester_id=p.semester_id
JOIN courses c ON c.id=cs.course_id JOIN tuition_rates tr ON tr.semester_id=p.semester_id
WHERE p.proposal_code IN ('DHP-2026-HK2-003','DHP-2026-HK2-004') AND p.status='DRAFT' AND e.status<>'CANCELLED'
AND NOT EXISTS(SELECT 1 FROM invoice_proposal_reviews r WHERE r.proposal_id=p.id)
AND NOT EXISTS(SELECT 1 FROM invoice_proposal_items it WHERE it.proposal_id=p.id AND it.enrollment_id=e.id);
INSERT INTO invoice_proposal_reviews(proposal_id,actor_user_id,action,from_status,to_status,note)
SELECT p.id,p.prepared_by,'SAVE',NULL,'DRAFT','CTSV lập đề nghị từ đăng ký và đơn giá học kỳ.' FROM invoice_proposals p
WHERE p.proposal_code IN ('DHP-2026-HK2-003','DHP-2026-HK2-004')
AND NOT EXISTS(SELECT 1 FROM invoice_proposal_reviews r WHERE r.proposal_id=p.id);
INSERT INTO invoice_proposal_reviews(proposal_id,actor_user_id,action,from_status,to_status,note)
SELECT p.id,p.prepared_by,'SUBMIT','DRAFT','SUBMITTED','CTSV trình BGH xét duyệt đề nghị học phí.' FROM invoice_proposals p
WHERE p.proposal_code='DHP-2026-HK2-003' AND p.status='DRAFT'
AND NOT EXISTS(SELECT 1 FROM invoice_proposal_reviews r WHERE r.proposal_id=p.id AND r.action='SUBMIT');
UPDATE invoice_proposals p SET p.status='SUBMITTED',p.submitted_at=CURRENT_TIMESTAMP
WHERE p.proposal_code='DHP-2026-HK2-003' AND p.status='DRAFT' AND p.submitted_at IS NULL
AND EXISTS(SELECT 1 FROM invoice_proposal_reviews r WHERE r.proposal_id=p.id AND r.action='SUBMIT');

-- Pending adjustment does not change balances until explicitly approved.
INSERT INTO tuition_adjustments(adjustment_code,invoice_id,kind,amount,reason,status,requested_by)
SELECT 'DCHP-TH14-001',v.invoice_id,'CREDIT',100000,'Đề nghị hỗ trợ học phí để thực hành xét duyệt.','REQUESTED',prep.id
FROM v_invoice_balances v JOIN students s ON s.id=v.student_id JOIN users u ON u.id=s.user_id
JOIN semesters se ON se.id=v.semester_id JOIN users prep ON prep.username='ctsv_demo'
WHERE u.username='student_demo_002' AND se.code='HK1' AND v.remaining_amount>=100000
AND NOT EXISTS(SELECT 1 FROM tuition_adjustments a WHERE a.adjustment_code='DCHP-TH14-001');

-- Allocate only the remaining collected money, not a fictional extra payment.
INSERT INTO ctsv_remittances(remittance_code,semester_id,fund_id,amount,status,prepared_by,note)
SELECT 'BG-TH14-002',i.semester_id,p.fund_id,p.amount-COALESCE(x.used_amount,0),'SUBMITTED',u.id,'Trình xác nhận bàn giao phần còn lại của chứng từ đã thu.'
FROM payments p JOIN invoices i ON i.id=p.invoice_id JOIN users u ON u.username='ctsv_demo'
LEFT JOIN (SELECT payment_id,SUM(allocated_amount) used_amount FROM ctsv_remittance_allocations GROUP BY payment_id) x ON x.payment_id=p.id
WHERE p.reference_no='CTSV-V4-DEMO-PAY-001' AND p.fund_id IS NOT NULL AND p.amount>COALESCE(x.used_amount,0)
AND NOT EXISTS(SELECT 1 FROM ctsv_remittances r WHERE r.remittance_code='BG-TH14-002');
INSERT INTO ctsv_remittance_allocations(remittance_id,payment_id,allocated_amount)
SELECT r.id,p.id,r.amount FROM ctsv_remittances r JOIN payments p ON p.reference_no='CTSV-V4-DEMO-PAY-001'
WHERE r.remittance_code='BG-TH14-002' AND NOT EXISTS(SELECT 1 FROM ctsv_remittance_allocations a WHERE a.remittance_id=r.id);

-- A closed prior semester permits report review without submitting current-term reports early.
INSERT INTO academic_years(name,starts_on,ends_on)
SELECT '2025-2026','2025-09-01','2026-08-31' WHERE NOT EXISTS(SELECT 1 FROM academic_years WHERE name='2025-2026');
INSERT INTO semesters(academic_year_id,code,starts_on,ends_on,status)
SELECT ay.id,'HK2','2026-02-01','2026-06-25','CLOSED' FROM academic_years ay WHERE ay.name='2025-2026'
AND NOT EXISTS(SELECT 1 FROM semesters s WHERE s.academic_year_id=ay.id AND s.code='HK2');
INSERT INTO ctsv_semester_reports(report_code,semester_id,prepared_by,status,submitted_at,note)
SELECT 'BC-2025-HK2-TH',s.id,u.id,'SUBMITTED',CURRENT_TIMESTAMP,'Không có hóa đơn/khoản thu trong kỳ này trong phạm vi dữ liệu thực hành.'
FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id JOIN users u ON u.username='ctsv_demo'
WHERE ay.name='2025-2026' AND s.code='HK2' AND s.ends_on<CURRENT_DATE
AND NOT EXISTS(SELECT 1 FROM ctsv_semester_reports r WHERE r.semester_id=s.id);
INSERT INTO ctsv_semester_report_reviews(report_id,actor_user_id,action,note,event_key)
SELECT r.id,r.prepared_by,'SUBMIT','CTSV trình báo cáo học kỳ đã kết thúc.','TH14-REPORT-SUBMIT'
FROM ctsv_semester_reports r WHERE r.report_code='BC-2025-HK2-TH'
AND NOT EXISTS(SELECT 1 FROM ctsv_semester_report_reviews rv WHERE rv.report_id=r.id AND rv.action='SUBMIT');
COMMIT;

CREATE OR REPLACE VIEW v_approval_workflow_checks AS
SELECT 'PROPOSAL_WITHOUT_ITEMS' check_name,COUNT(*) violation_count FROM invoice_proposals p
WHERE NOT EXISTS(SELECT 1 FROM invoice_proposal_items it WHERE it.proposal_id=p.id)
UNION ALL SELECT 'PROPOSAL_WRONG_ENROLLMENT',COUNT(*) FROM invoice_proposal_items it JOIN invoice_proposals p ON p.id=it.proposal_id
JOIN enrollments e ON e.id=it.enrollment_id JOIN course_sections cs ON cs.id=e.section_id WHERE e.student_id<>p.student_id OR cs.semester_id<>p.semester_id
UNION ALL SELECT 'PROPOSAL_MISSING_SUBMISSION',COUNT(*) FROM invoice_proposals p WHERE p.status='SUBMITTED'
AND NOT EXISTS(SELECT 1 FROM invoice_proposal_reviews r JOIN user_roles ur ON ur.user_id=r.actor_user_id JOIN roles ro ON ro.id=ur.role_id WHERE r.proposal_id=p.id AND r.action='SUBMIT' AND ro.code='CTSV')
UNION ALL SELECT 'PROPOSAL_MISSING_APPROVAL',COUNT(*) FROM invoice_proposals p WHERE p.status IN ('APPROVED','ISSUED')
AND NOT EXISTS(SELECT 1 FROM invoice_proposal_reviews r JOIN user_roles ur ON ur.user_id=r.actor_user_id JOIN roles ro ON ro.id=ur.role_id WHERE r.proposal_id=p.id AND r.action='APPROVE' AND ro.code='PRINCIPAL' AND r.actor_user_id<>p.prepared_by)
UNION ALL SELECT 'VERIFIED_SHEET_WITHOUT_PDT',COUNT(*) FROM grade_sheets gs WHERE gs.status='VERIFIED'
AND NOT EXISTS(SELECT 1 FROM grade_reviews r JOIN user_roles ur ON ur.user_id=r.actor_user_id JOIN roles ro ON ro.id=ur.role_id WHERE r.sheet_id=gs.id AND r.action='VERIFY' AND ro.code='TRAINING_OFFICE')
UNION ALL SELECT 'PROPOSAL_DISCOUNT_OVER_TOTAL',COUNT(*) FROM invoice_proposals p
WHERE p.discount_amount>(SELECT COALESCE(SUM(it.credits_at_proposal*it.unit_price_at_proposal),0) FROM invoice_proposal_items it WHERE it.proposal_id=p.id);
SELECT * FROM v_approval_workflow_checks;
