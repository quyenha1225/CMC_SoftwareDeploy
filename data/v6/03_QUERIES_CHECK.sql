-- =============================================================================
-- STUDENT MANAGEMENT SYSTEM | 03_QUERIES_CHECK.sql - V6
-- CHAY SAU 01_SCHEMA_ALL.sql & 02_SEED_DEMO.sql.
-- TAP TRUNG TOAN BO VIEW, QUERY TRA CUU, KIEM TRA TRUNG VA TOAN VEN.
-- CHAY LAI AN TOAN: CREATE OR REPLACE VIEW VA SELECT (KHONG CHINH SUA DATA).
-- KHI CSDL TRONG, DU KIEN 47 BANG + cac VIEW bao cao truong. Neu co V3 Google: co the co
-- them bang auth_identities cu (KHONG TU XOA DU LIEU).
-- =============================================================================
USE sms_db;
SET NAMES utf8mb4;

-- =============== CAC VIEW PHUC VU API / BAO CAO ===========================
-- VIEW: v_student_results
CREATE OR REPLACE VIEW v_student_results AS
SELECT e.id AS enrollment_id, s.id AS student_id, s.student_code,
       cs.id AS section_id, cs.section_code,
       c.course_code, c.credits,
       gs.status AS grade_sheet_status,
       g.attendance_score, g.midterm_score, g.final_score,
       CASE WHEN g.attendance_score IS NOT NULL
                  AND g.midterm_score IS NOT NULL AND g.final_score IS NOT NULL
            THEN ROUND((g.attendance_score * cs.attendance_weight
                      + g.midterm_score * cs.midterm_weight
                      + g.final_score * cs.final_weight) / 100.00, 2)
            ELSE NULL END AS total_score
FROM enrollments e
JOIN students s ON s.id = e.student_id
JOIN course_sections cs ON cs.id = e.section_id
JOIN courses c ON c.id = cs.course_id
LEFT JOIN grades g ON g.enrollment_id = e.id
LEFT JOIN grade_sheets gs ON gs.section_id = cs.id
WHERE e.status <> 'CANCELLED' AND gs.status = 'PUBLISHED';

-- VIEW: v_invoice_balances | debt is derived, not a stored per-student cache.
CREATE OR REPLACE VIEW v_invoice_balances AS
SELECT t.invoice_id,t.student_id,t.semester_id,t.issued_at,
       t.base_amount,t.discount_amount,t.debit_amount,t.credit_amount,
       GREATEST(t.base_amount-t.discount_amount+t.debit_amount-t.credit_amount,0.00) AS payable_amount,
       t.paid_amount,
       GREATEST(t.base_amount-t.discount_amount+t.debit_amount-t.credit_amount-t.paid_amount,0.00) AS remaining_amount,
       CASE
         WHEN t.base_amount-t.discount_amount+t.debit_amount-t.credit_amount <= t.paid_amount
              AND t.base_amount+t.debit_amount>0 THEN 'PAID'
         WHEN t.paid_amount>0 THEN 'PARTIAL'
         ELSE 'UNPAID' END AS payment_status
FROM (
 SELECT i.id AS invoice_id,i.student_id,i.semester_id,i.issued_at,
        COALESCE(it.base_amount,0.00) AS base_amount,i.discount_amount,
        COALESCE(ad.debit_amount,0.00) AS debit_amount,
        COALESCE(ad.credit_amount,0.00) AS credit_amount,
        COALESCE(p.paid_amount,0.00) AS paid_amount
 FROM invoices i
 LEFT JOIN (SELECT invoice_id,SUM(amount) AS base_amount
            FROM invoice_items GROUP BY invoice_id) it ON it.invoice_id=i.id
 LEFT JOIN (SELECT invoice_id,
              SUM(CASE WHEN kind='DEBIT' THEN amount ELSE 0 END) AS debit_amount,
              SUM(CASE WHEN kind='CREDIT' THEN amount ELSE 0 END) AS credit_amount
            FROM tuition_adjustments WHERE status='APPROVED'
            GROUP BY invoice_id) ad ON ad.invoice_id=i.id
 LEFT JOIN (SELECT invoice_id,SUM(amount) AS paid_amount
            FROM payments GROUP BY invoice_id) p ON p.invoice_id=i.id
) t;

-- VIEW: v_section_registration_counts
CREATE OR REPLACE VIEW v_section_registration_counts AS
SELECT cs.id AS section_id, cs.section_code, cs.capacity,
       COUNT(CASE WHEN e.status = 'REGISTERED' THEN 1 END) AS registered_count,
       cs.capacity - COUNT(CASE WHEN e.status = 'REGISTERED' THEN 1 END) AS remaining_seats
FROM course_sections cs
LEFT JOIN enrollments e ON e.section_id = cs.id
GROUP BY cs.id,cs.section_code,cs.capacity;

-- VIEW: v_admission_document_checklist
CREATE OR REPLACE VIEW v_admission_document_checklist AS
SELECT a.id AS application_id, a.application_code,
       r.document_type, r.label, r.is_required,
       d.id AS latest_document_id, d.revision_no, d.status AS document_status,
       CASE WHEN r.is_required = 0 THEN 1
            WHEN d.id IS NOT NULL AND d.status = 'VERIFIED' THEN 1
            ELSE 0 END AS requirement_satisfied
FROM admission_applications a
JOIN admission_document_requirements r ON r.period_id = a.period_id
LEFT JOIN admission_documents d ON d.id = (
    SELECT d2.id FROM admission_documents d2
    WHERE d2.application_id = a.id AND d2.document_type = r.document_type
    ORDER BY d2.revision_no DESC, d2.id DESC LIMIT 1
);

-- VIEW: v_ctsv_fund_balances
CREATE OR REPLACE VIEW v_ctsv_fund_balances AS
SELECT f.id AS fund_id, f.code AS fund_code, f.name AS fund_name, f.channel,
  COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.fund_id=f.id),0.00) AS collected_amount,
  COALESCE((SELECT SUM(r.amount) FROM ctsv_remittances r
            WHERE r.fund_id=f.id AND r.status='CONFIRMED'),0.00) AS remitted_amount,
  COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.fund_id=f.id),0.00)
  - COALESCE((SELECT SUM(r.amount) FROM ctsv_remittances r
              WHERE r.fund_id=f.id AND r.status='CONFIRMED'),0.00) AS balance_amount
FROM ctsv_funds f;

-- VIEW: v_ctsv_semester_finance
CREATE OR REPLACE VIEW v_ctsv_semester_finance AS
SELECT s.id AS semester_id, ay.name AS academic_year, s.code AS semester_code,
  COALESCE((SELECT SUM(v.payable_amount) FROM v_invoice_balances v
            WHERE v.semester_id=s.id),0.00) AS total_tuition_due,
  COALESCE((SELECT SUM(p.amount) FROM payments p JOIN invoices i ON i.id=p.invoice_id
            WHERE i.semester_id=s.id),0.00) AS total_paid,
  COALESCE((SELECT SUM(p.amount) FROM payments p JOIN invoices i ON i.id=p.invoice_id
            WHERE i.semester_id=s.id AND p.fund_id IS NOT NULL),0.00) AS collected_via_ctsv,
  COALESCE((SELECT SUM(p.amount) FROM payments p JOIN invoices i ON i.id=p.invoice_id
            WHERE i.semester_id=s.id AND p.fund_id IS NULL),0.00) AS legacy_unassigned_paid,
  COALESCE((SELECT SUM(v.remaining_amount) FROM v_invoice_balances v
            WHERE v.semester_id=s.id),0.00) AS total_outstanding,
  COALESCE((SELECT SUM(r.amount) FROM ctsv_remittances r
            WHERE r.semester_id=s.id AND r.status='CONFIRMED'),0.00) AS remitted_to_school,
  (SELECT COUNT(*) FROM student_requests q
    WHERE q.created_at >= s.starts_on
      AND q.created_at < DATE_ADD(s.ends_on,INTERVAL 1 DAY)) AS student_issue_count,
  (SELECT COUNT(*) FROM student_requests q
    WHERE q.created_at >= s.starts_on AND q.created_at < DATE_ADD(s.ends_on,INTERVAL 1 DAY)
      AND q.status IN ('PENDING','PROCESSING')) AS unresolved_issue_count,
  (SELECT COUNT(DISTINCT q.id) FROM student_requests q
    JOIN student_request_review_events e ON e.request_id=q.id
    WHERE q.created_at >= s.starts_on AND q.created_at < DATE_ADD(s.ends_on,INTERVAL 1 DAY)
      AND e.action='ESCALATE_TO_SCHOOL') AS escalated_issue_count
FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id;

-- VIEW: v_admission_dossier_progress

CREATE OR REPLACE VIEW v_admission_dossier_progress AS
SELECT a.id AS application_id, a.application_code, a.status,
       COUNT(ch.document_type) AS documents_listed,
       SUM(CASE WHEN ch.is_required=1 THEN 1 ELSE 0 END) AS required_count,
       SUM(CASE WHEN ch.is_required=1 AND ch.requirement_satisfied=1 THEN 1 ELSE 0 END) AS verified_required_count,
       CASE WHEN SUM(CASE WHEN ch.is_required=1 AND ch.requirement_satisfied=0 THEN 1 ELSE 0 END)=0
            THEN 'DOCUMENTS_OK' ELSE 'DOCUMENTS_MISSING' END AS dossier_check
FROM admission_applications a
LEFT JOIN v_admission_document_checklist ch ON ch.application_id=a.id
GROUP BY a.id,a.application_code,a.status;

-- =============== KIEM TRA CU BAN 28 BANG / DU LIEU CO BAN =============
-- ============================================================================
-- SMS database integrity and idempotency verification (READ ONLY)
-- A healthy result has all violation_count values = 0.
-- Run this script after the seed, repeat the seed, then rerun this verification.
-- ============================================================================
USE sms_db;

SELECT 'TABLE_COUNT' AS metric, COUNT(*) AS metric_value
FROM information_schema.TABLES
WHERE TABLE_SCHEMA='sms_db' AND TABLE_TYPE='BASE TABLE';

SELECT 'VIEW_COUNT' AS metric, COUNT(*) AS metric_value
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA='sms_db' AND TABLE_NAME IN
 ('v_student_results','v_invoice_balances','v_section_registration_counts');

-- Counts: save these values; they must be unchanged after running the seed again.
SELECT 'roles' AS table_name, COUNT(*) AS row_count FROM roles
UNION ALL SELECT 'users_demo', COUNT(*) FROM users WHERE username IN ('principal_demo','training_demo','lecturer_demo_01','lecturer_demo_02','lecturer_demo_03','student_demo_001','student_demo_002','student_demo_003','student_demo_004','student_demo_005','student_demo_006')
UNION ALL SELECT 'user_roles', COUNT(*) FROM user_roles
UNION ALL SELECT 'faculties', COUNT(*) FROM faculties
UNION ALL SELECT 'majors', COUNT(*) FROM majors
UNION ALL SELECT 'cohorts', COUNT(*) FROM cohorts
UNION ALL SELECT 'academic_classes', COUNT(*) FROM academic_classes
UNION ALL SELECT 'students', COUNT(*) FROM students
UNION ALL SELECT 'lecturers', COUNT(*) FROM lecturers
UNION ALL SELECT 'academic_years', COUNT(*) FROM academic_years
UNION ALL SELECT 'semesters', COUNT(*) FROM semesters
UNION ALL SELECT 'courses', COUNT(*) FROM courses
UNION ALL SELECT 'curricula', COUNT(*) FROM curricula
UNION ALL SELECT 'curriculum_courses', COUNT(*) FROM curriculum_courses
UNION ALL SELECT 'course_sections', COUNT(*) FROM course_sections
UNION ALL SELECT 'section_schedules', COUNT(*) FROM section_schedules
UNION ALL SELECT 'enrollments', COUNT(*) FROM enrollments
UNION ALL SELECT 'grade_sheets', COUNT(*) FROM grade_sheets
UNION ALL SELECT 'grades', COUNT(*) FROM grades
UNION ALL SELECT 'grade_reviews', COUNT(*) FROM grade_reviews
UNION ALL SELECT 'tuition_rates', COUNT(*) FROM tuition_rates
UNION ALL SELECT 'invoices', COUNT(*) FROM invoices
UNION ALL SELECT 'invoice_items', COUNT(*) FROM invoice_items
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'student_requests', COUNT(*) FROM student_requests
UNION ALL SELECT 'notifications', COUNT(*) FROM notifications
UNION ALL SELECT 'notification_recipients', COUNT(*) FROM notification_recipients
UNION ALL SELECT 'audit_logs', COUNT(*) FROM audit_logs;

-- Business integrity checks, NOT a replacement for service-layer transactions.
SELECT 'DUPLICATE_STUDENT_CODES' AS check_name, COUNT(*) AS violation_count FROM (
  SELECT student_code FROM students GROUP BY student_code HAVING COUNT(*)>1
) t
UNION ALL SELECT 'DUPLICATE_ENROLLMENTS', COUNT(*) FROM (
  SELECT student_id, section_id FROM enrollments GROUP BY student_id,section_id HAVING COUNT(*)>1
) t
UNION ALL SELECT 'DUPLICATE_INVOICES', COUNT(*) FROM (
  SELECT student_id,semester_id FROM invoices GROUP BY student_id,semester_id HAVING COUNT(*)>1
) t
UNION ALL SELECT 'DUPLICATE_PAYMENT_REFERENCES', COUNT(*) FROM (
  SELECT reference_no FROM payments GROUP BY reference_no HAVING COUNT(*)>1
) t
UNION ALL SELECT 'INVOICE_ENROLLMENT_MISMATCH', COUNT(*)
  FROM invoice_items ii
  JOIN invoices i ON i.id=ii.invoice_id
  JOIN enrollments e ON e.id=ii.enrollment_id
  JOIN course_sections cs ON cs.id=e.section_id
  WHERE i.student_id<>e.student_id OR i.semester_id<>cs.semester_id
UNION ALL SELECT 'CANCELLED_ENROLLMENT_BILLED', COUNT(*)
  FROM invoice_items ii JOIN enrollments e ON e.id=ii.enrollment_id
  WHERE e.status='CANCELLED'
UNION ALL SELECT 'OVERPAYMENT', COUNT(*)
  FROM v_invoice_balances WHERE paid_amount > payable_amount
UNION ALL SELECT 'DISCOUNT_EXCEEDS_BASE', COUNT(*)
  FROM v_invoice_balances WHERE discount_amount > base_amount
UNION ALL SELECT 'OVERCAPACITY', COUNT(*)
  FROM v_section_registration_counts WHERE registered_count > capacity
UNION ALL SELECT 'DUPLICATE_COURSE_SAME_SEMESTER', COUNT(*) FROM (
  SELECT e.student_id, cs.semester_id, cs.course_id
  FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id
  WHERE e.status='REGISTERED'
  GROUP BY e.student_id,cs.semester_id,cs.course_id HAVING COUNT(*)>1
) t
UNION ALL SELECT 'PUBLISHED_WITH_MISSING_GRADES', COUNT(*)
  FROM grade_sheets gs
  JOIN course_sections cs ON cs.id=gs.section_id
  JOIN enrollments e ON e.section_id=cs.id AND e.status<>'CANCELLED'
  LEFT JOIN grades g ON g.enrollment_id=e.id
  WHERE gs.status='PUBLISHED' AND
     (g.id IS NULL OR g.attendance_score IS NULL OR g.midterm_score IS NULL OR g.final_score IS NULL)
UNION ALL SELECT 'WEIGHTS_NOT_100', COUNT(*)
  FROM course_sections
  WHERE attendance_weight+midterm_weight+final_weight <> 100.00;

-- Helpful views for manual inspection.
SELECT * FROM v_section_registration_counts ORDER BY section_code;
SELECT invoice_id,student_id,base_amount,discount_amount,payable_amount,
       paid_amount,remaining_amount,payment_status
FROM v_invoice_balances ORDER BY invoice_id;
SELECT student_code,section_code,grade_sheet_status,total_score
FROM v_student_results ORDER BY student_code,section_code;

-- =============== KIEM TRA NGHIEP VU CTSV / QUY / EMAIL ===============
-- SMS V4 non-mutating validation. Run seed twice; counts must stay the same.
USE sms_db;
SELECT 'BASE_TABLE_COUNT' metric, COUNT(*) value FROM information_schema.TABLES
 WHERE TABLE_SCHEMA=DATABASE() AND TABLE_TYPE='BASE TABLE';
SELECT 'BASE_VIEWS' metric, COUNT(*) value FROM information_schema.VIEWS
 WHERE TABLE_SCHEMA=DATABASE();
SELECT 'CTSV' entity,COUNT(*) records FROM ctsv_funds
UNION ALL SELECT 'MAILBOX',COUNT(*) FROM student_school_mailboxes
UNION ALL SELECT 'ADMISSIONS',COUNT(*) FROM admission_applications
UNION ALL SELECT 'DOCUMENTS',COUNT(*) FROM admission_documents
UNION ALL SELECT 'REVIEWS',COUNT(*) FROM admission_review_events
UNION ALL SELECT 'CTSV_REMITTANCES',COUNT(*) FROM ctsv_remittances
UNION ALL SELECT 'CTSV_REPORTS',COUNT(*) FROM ctsv_semester_reports
UNION ALL SELECT 'OUTBOUND_EMAILS',COUNT(*) FROM outbound_emails
UNION ALL SELECT 'PAYMENTS',COUNT(*) FROM payments;

-- Each violation_count should be zero. Legacy payments/fund_id NULL are separately listed.
SELECT 'DUPLICATE_SCHOOL_EMAIL' check_name,COUNT(*) violation_count FROM (
 SELECT school_email FROM student_school_mailboxes GROUP BY school_email HAVING COUNT(*)>1) x
UNION ALL SELECT 'DUPLICATE_SCHOOL_MAILBOX_STUDENT',COUNT(*) FROM (
 SELECT student_id FROM student_school_mailboxes GROUP BY student_id HAVING COUNT(*)>1) x
UNION ALL SELECT 'DUPLICATE_ADMISSION_CODE',COUNT(*) FROM (
 SELECT application_code FROM admission_applications GROUP BY application_code HAVING COUNT(*)>1) x
UNION ALL SELECT 'DUPLICATE_PAYMENT_REFERENCE',COUNT(*) FROM (
 SELECT reference_no FROM payments GROUP BY reference_no HAVING COUNT(*)>1) x
UNION ALL SELECT 'DUPLICATE_REMITTANCE_CODE',COUNT(*) FROM (
 SELECT remittance_code FROM ctsv_remittances GROUP BY remittance_code HAVING COUNT(*)>1) x
UNION ALL SELECT 'DUPLICATE_EMAIL_EVENT',COUNT(*) FROM (
 SELECT event_key FROM outbound_emails GROUP BY event_key HAVING COUNT(*)>1) x
UNION ALL SELECT 'ENROLLED_BUT_MISSING_STUDENT',COUNT(*)
 FROM admission_applications a WHERE a.status='ENROLLED' AND a.student_id IS NULL
UNION ALL SELECT 'ENROLLED_WRONG_APPLICANT',COUNT(*)
 FROM admission_applications a JOIN students s ON s.id=a.student_id
 WHERE s.user_id<>a.applicant_user_id
UNION ALL SELECT 'CTSV_FUND_NEGATIVE',COUNT(*) FROM v_ctsv_fund_balances WHERE balance_amount < 0
UNION ALL SELECT 'MAILBOX_ACTIVE_NO_ACTIVATION_DATE',COUNT(*)
 FROM student_school_mailboxes WHERE provisioning_status='ACTIVE' AND activated_at IS NULL
UNION ALL SELECT 'PAYMENT_OVERPAID_INVOICE',COUNT(*)
 FROM v_invoice_balances WHERE paid_amount>payable_amount
UNION ALL SELECT 'REQUESTS_HANDLED_BY_MISSING_CTSV',COUNT(*) FROM (
 SELECT q.id FROM student_requests q
 JOIN users u ON u.id=q.handled_by
 LEFT JOIN user_roles ur ON ur.user_id=u.id
 LEFT JOIN roles r ON r.id=ur.role_id AND r.code='CTSV'
 WHERE q.handled_by IS NOT NULL AND q.request_code LIKE 'CTSV-V4-%'
 GROUP BY q.id HAVING SUM(CASE WHEN r.id IS NOT NULL THEN 1 ELSE 0 END)=0
) x;

-- Legacy data: do NOT automatically assign to CTSV fund without proof of collection.
SELECT 'UNASSIGNED_OLD_PAYMENTS' info,COUNT(*) payments_count
FROM payments WHERE fund_id IS NULL;

SELECT * FROM v_ctsv_fund_balances ORDER BY fund_code;
SELECT * FROM v_ctsv_semester_finance ORDER BY academic_year,semester_code;
SELECT a.application_code,a.status,u.email AS applicant_contact_email
FROM admission_applications a JOIN users u ON u.id=a.applicant_user_id
ORDER BY a.application_code;


-- =============== KIEM TRA HO SO THPT + GIAY TO DINH DANH =================
SELECT 'TOTAL_TABLES_V5' AS metric,COUNT(*) AS value
FROM information_schema.TABLES
WHERE TABLE_SCHEMA=DATABASE() AND TABLE_TYPE='BASE TABLE';
SELECT 'VIEWS_V5' AS metric,COUNT(*) AS value
FROM information_schema.VIEWS WHERE TABLE_SCHEMA=DATABASE();

SELECT 'DUPLICATE_PERSONAL_IDENTITY_APP' AS check_name,COUNT(*) AS violation_count
FROM (SELECT application_id FROM admission_identity_records
      GROUP BY application_id HAVING COUNT(*)>1) d
UNION ALL SELECT 'DUPLICATE_TRANSCRIPT_APP',COUNT(*) FROM
 (SELECT application_id FROM admission_high_school_records
  GROUP BY application_id HAVING COUNT(*)>1) d
UNION ALL SELECT 'DUPLICATE_SUBJECT_GRADE',COUNT(*) FROM
 (SELECT school_record_id,grade_level,subject_code FROM admission_high_school_scores
  GROUP BY school_record_id,grade_level,subject_code HAVING COUNT(*)>1) d
UNION ALL SELECT 'INVALID_SUBJECT_GRADE',COUNT(*) FROM admission_high_school_scores
 WHERE grade_level NOT IN (10,11,12) OR average_score NOT BETWEEN 0 AND 10
UNION ALL SELECT 'INCOMPLETE_SUBMITTED_APPLICATION',COUNT(*) FROM
 v_admission_dossier_progress
 WHERE status IN ('CTSV_APPROVED','SENT_TO_SCHOOL','SCHOOL_APPROVED','PDT_VERIFIED','ENROLLED')
   AND dossier_check='DOCUMENTS_MISSING';

-- HO SO CTSV: chi xem tiet do giay to, khong doc duong dan file public
SELECT a.application_code,a.status, p.documents_listed,p.required_count,
       p.verified_required_count,p.dossier_check
FROM admission_applications a JOIN v_admission_dossier_progress p
ON p.application_id=a.id
ORDER BY a.id DESC;

-- DANH SACH HO SO VA HOC BA, CCCD CHI HIEN 4 SO CUOI (KHONG DOC SO GOC)
SELECT a.application_code,a.status,
       i.identity_type, i.identity_last4,
       hs.school_name,hs.graduation_year,hs.graduation_status,hs.transcript_average
FROM admission_applications a
LEFT JOIN admission_identity_records i ON i.application_id=a.id
LEFT JOIN admission_high_school_records hs ON hs.application_id=a.id
ORDER BY a.application_code;

-- DIEM HOC BA THEO KHOI, THEO MON
SELECT a.application_code,g.grade_level,g.subject_code,g.average_score
FROM admission_high_school_scores g
JOIN admission_high_school_records hs ON hs.id=g.school_record_id
JOIN admission_applications a ON a.id=hs.application_id
ORDER BY a.application_code,g.grade_level,g.subject_code;

-- DANH SACH NHUNG GIAY TO CON THIEU/CHUA DUOC XAC MINH
SELECT a.application_code,c.document_type,c.label,c.document_status,c.revision_no
FROM v_admission_document_checklist c
JOIN admission_applications a ON a.id=c.application_id
WHERE c.is_required=1 AND c.requirement_satisfied=0
ORDER BY a.application_code,c.document_type;

-- CHI TIET CAC KHOA NGOAI TOAN CSDL DE KIEM TRA ERD
SELECT TABLE_NAME,COLUMN_NAME,REFERENCED_TABLE_NAME,REFERENCED_COLUMN_NAME,CONSTRAINT_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA=DATABASE() AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME,CONSTRAINT_NAME,ORDINAL_POSITION;


-- =============================================================================
-- V6 - TONG HOP TOAN TRUONG, LICH HOC, NHAP DIEM, DUYET HO SO BGH, BAO CAO
-- Tat ca la VIEW/SELECT. Khong luu lai tong cong no de tranh lech so lieu.
-- =============================================================================

-- Hang doi BGH la MOT tap con cua admission_applications, khong can bang rieng.
CREATE OR REPLACE VIEW v_school_admission_queue AS
SELECT a.id AS application_id,a.application_code,a.status,
       a.legal_full_name,a.personal_email,a.phone,
       a.major_id,a.period_id,a.assigned_ctsv_user_id,a.submitted_at,
       p.required_count,p.verified_required_count,p.dossier_check
FROM admission_applications a
LEFT JOIN v_admission_dossier_progress p ON p.application_id=a.id
WHERE a.status='SENT_TO_SCHOOL';

-- Mot su kien duyet/trai lai phai tham chieu ho so; viewer co the filter theo role.
CREATE OR REPLACE VIEW v_school_admission_decisions AS
SELECT a.id AS application_id,a.application_code,a.status AS current_status,
       e.id AS decision_event_id,e.event_type,e.from_status,e.to_status,
       e.actor_user_id,u.full_name AS reviewer_name,e.note,e.created_at,
       CASE WHEN EXISTS (SELECT 1 FROM user_roles ur JOIN roles r ON r.id=ur.role_id
                         WHERE ur.user_id=e.actor_user_id AND r.code='PRINCIPAL')
            THEN 1 ELSE 0 END AS reviewer_is_bgh
FROM admission_review_events e
JOIN admission_applications a ON a.id=e.application_id
JOIN users u ON u.id=e.actor_user_id
WHERE e.event_type IN ('SCHOOL_APPROVE','SCHOOL_REJECT');

-- Danh sach hoc phan da dang ky la NGUON DUY NHAT cho thoi khoa bieu va nhap diem.
CREATE OR REPLACE VIEW v_student_timetable AS
SELECT e.id AS enrollment_id,e.student_id,cs.id AS section_id,cs.semester_id,
       c.course_code,c.title AS course_title,cs.section_code,
       sch.day_of_week,sch.starts_at,sch.ends_at,sch.room,
       cs.lecturer_id,u.full_name AS lecturer_name,e.status AS enrollment_status
FROM enrollments e
JOIN course_sections cs ON cs.id=e.section_id
JOIN courses c ON c.id=cs.course_id
JOIN section_schedules sch ON sch.section_id=cs.id
LEFT JOIN lecturers l ON l.id=cs.lecturer_id
LEFT JOIN users u ON u.id=l.user_id
WHERE e.status IN ('REGISTERED','COMPLETED');

CREATE OR REPLACE VIEW v_grade_entry_roster AS
SELECT e.id AS enrollment_id,e.student_id,s.student_code,u.full_name AS student_name,
       cs.id AS section_id,cs.section_code,cs.lecturer_id,cs.semester_id,
       gs.id AS grade_sheet_id,gs.status AS sheet_status,
       g.id AS grade_id,g.attendance_score,g.midterm_score,g.final_score,e.status AS enrollment_status
FROM enrollments e
JOIN students s ON s.id=e.student_id
JOIN users u ON u.id=s.user_id
JOIN course_sections cs ON cs.id=e.section_id
LEFT JOIN grade_sheets gs ON gs.section_id=cs.id
LEFT JOIN grades g ON g.enrollment_id=e.id
WHERE e.status IN ('REGISTERED','COMPLETED');

-- CONG NO CA TRUONG THEO HOC KY; bao gom tat ca sinh vien, khong chi mot ho so.
CREATE OR REPLACE VIEW v_school_tuition_by_semester AS
SELECT se.id AS semester_id,ay.name AS academic_year,se.code AS semester_code,
       COUNT(b.invoice_id) AS invoice_count,
       COUNT(DISTINCT b.student_id) AS students_billed,
       COALESCE(SUM(b.base_amount),0.00) AS base_amount,
       COALESCE(SUM(b.discount_amount),0.00) AS discounted_amount,
       COALESCE(SUM(b.debit_amount),0.00) AS approved_extra_fees,
       COALESCE(SUM(b.credit_amount),0.00) AS approved_credits,
       COALESCE(SUM(b.payable_amount),0.00) AS total_receivables,
       COALESCE(SUM(b.paid_amount),0.00) AS collected,
       COALESCE(SUM(b.remaining_amount),0.00) AS outstanding,
       COALESCE(SUM(CASE WHEN b.remaining_amount>0 THEN 1 ELSE 0 END),0) AS unpaid_invoice_count
FROM semesters se
JOIN academic_years ay ON ay.id=se.academic_year_id
LEFT JOIN v_invoice_balances b ON b.semester_id=se.id
GROUP BY se.id,ay.name,se.code;

-- Tong so CA TRUONG qua tat ca hoc ky; truong co mot ma so quy uoc SCHOOL.
CREATE OR REPLACE VIEW v_school_tuition_total AS
SELECT 'SCHOOL' AS scope_code,
       COALESCE(SUM(total_receivables),0.00) AS total_receivables,
       COALESCE(SUM(collected),0.00) AS collected,
       COALESCE(SUM(outstanding),0.00) AS outstanding,
       COALESCE(SUM(invoice_count),0) AS invoice_count,
       COALESCE(SUM(unpaid_invoice_count),0) AS unpaid_invoice_count
FROM v_school_tuition_by_semester;

-- Bao cao CTSV duoc BGH doc tu cung 1 report_id, khong nhan ban bang thong ke.
CREATE OR REPLACE VIEW v_school_ctsv_report_register AS
SELECT r.id AS report_id,r.report_code,r.semester_id,r.status,r.prepared_by,
       r.received_by,r.submitted_at,r.reviewed_at,
       f.total_tuition_due,f.total_paid,f.total_outstanding,
       f.collected_via_ctsv,f.legacy_unassigned_paid,f.remitted_to_school,
       f.student_issue_count,f.unresolved_issue_count,f.escalated_issue_count,
       (SELECT COUNT(*) FROM ctsv_semester_report_reviews ev WHERE ev.report_id=r.id) AS review_events
FROM ctsv_semester_reports r
JOIN v_ctsv_semester_finance f ON f.semester_id=r.semester_id;

CREATE OR REPLACE VIEW v_email_delivery_history AS
SELECT o.id AS email_id,o.event_key,o.template_code,o.recipient_email,
       o.delivery_status,o.queued_at,o.sent_at,
       COUNT(a.id) AS logged_attempts,
       MAX(a.attempted_at) AS last_attempt_at,
       MAX(CASE WHEN a.result='SENT' THEN a.attempted_at ELSE NULL END) AS last_success_at
FROM outbound_emails o
LEFT JOIN email_delivery_attempts a ON a.outbound_email_id=o.id
GROUP BY o.id,o.event_key,o.template_code,o.recipient_email,
         o.delivery_status,o.queued_at,o.sent_at;

-- Bao cao cong no truong - dong hoc phi qua quy CTSV - ban giao theo ky.
SELECT * FROM v_school_tuition_total;
SELECT * FROM v_school_tuition_by_semester ORDER BY academic_year,semester_code;
SELECT * FROM v_ctsv_semester_finance ORDER BY academic_year,semester_code;
SELECT * FROM v_school_ctsv_report_register ORDER BY semester_id;

-- Ho so CTSV chuyen BGH + lich su BGH duyet chung 1 application_id.
SELECT * FROM v_school_admission_queue ORDER BY application_code;
SELECT * FROM v_school_admission_decisions ORDER BY created_at DESC;

-- Du lieu sinh vien - dang ky - lich - diem dung chung enrollment_id.
SELECT enrollment_id,student_id,section_id,course_code,day_of_week,starts_at,room
  FROM v_student_timetable ORDER BY student_id,day_of_week,starts_at;
SELECT enrollment_id,student_code,section_code,sheet_status,attendance_score,midterm_score,final_score
  FROM v_grade_entry_roster ORDER BY section_code,student_code;

-- NGHIEM THU V6: cac vi pham phai la 0 (neu du lieu goc da sach)
SELECT 'SCHOOL_APPROVED_WITHOUT_BGH_EVENT' AS check_name,COUNT(*) AS violation_count
FROM admission_applications a
WHERE a.status IN ('SCHOOL_APPROVED','PDT_VERIFIED','ENROLLED')
  AND NOT EXISTS (SELECT 1 FROM admission_review_events e
    WHERE e.application_id=a.id AND e.event_type='SCHOOL_APPROVE')
UNION ALL
SELECT 'SCHOOL_EVENT_ACTOR_NOT_PRINCIPAL',COUNT(*) FROM v_school_admission_decisions
WHERE reviewer_is_bgh=0
UNION ALL
SELECT 'SCHOOL_APPROVED_WITHOUT_CTSV_FORWARD',COUNT(*)
FROM admission_applications a
WHERE a.status IN ('SCHOOL_APPROVED','PDT_VERIFIED','ENROLLED')
AND NOT EXISTS(SELECT 1 FROM admission_review_events e
  WHERE e.application_id=a.id AND e.event_type='SUBMIT_TO_SCHOOL')
UNION ALL
SELECT 'INVOICE_OVERPAID_AFTER_ADJUSTMENT',COUNT(*) FROM v_invoice_balances
WHERE paid_amount>payable_amount
UNION ALL
SELECT 'CTSV_REPORT_APPROVED_WITHOUT_EVENT',COUNT(*)
FROM ctsv_semester_reports r
WHERE r.status='APPROVED'
  AND NOT EXISTS (SELECT 1 FROM ctsv_semester_report_reviews rv
    WHERE rv.report_id=r.id AND rv.action='APPROVE')
UNION ALL
SELECT 'ACTIVE_MAILBOX_WITHOUT_DATE',COUNT(*)
FROM student_school_mailboxes
WHERE provisioning_status='ACTIVE' AND activated_at IS NULL;

SELECT 'TABLES' AS entity_type,COUNT(*) AS total FROM information_schema.TABLES
 WHERE TABLE_SCHEMA=DATABASE() AND TABLE_TYPE='BASE TABLE'
UNION ALL SELECT 'VIEWS',COUNT(*) FROM information_schema.VIEWS
 WHERE TABLE_SCHEMA=DATABASE();

-- Viec doi trang thai CTSV/BGH, tinh va ghi cong no, tinh so du quy, cap MSSV,
-- gui email va phan quyen la nghiep vu phai viet trong Backend transaction.
-- DB KHONG phai co che bao mat cho nguoi dung neu app su dung 1 user MySQL.


-- V6: KHOP DOI SOAT CHI TIET TIEN BAN GIAO - GHI THEO CHUNG TU THANH TOAN
CREATE OR REPLACE VIEW v_ctsv_remittance_tracking AS
SELECT r.id AS remittance_id,r.remittance_code,r.semester_id,r.fund_id,
       r.status,r.amount AS declared_amount,
       COALESCE(x.allocated_amount,0.00) AS allocated_amount,
       r.amount - COALESCE(x.allocated_amount,0.00) AS difference_amount,
       COALESCE(x.payment_count,0) AS payment_count
FROM ctsv_remittances r
LEFT JOIN (SELECT remittance_id,SUM(allocated_amount) AS allocated_amount,
                  COUNT(*) AS payment_count
           FROM ctsv_remittance_allocations GROUP BY remittance_id) x
ON x.remittance_id=r.id;

SELECT * FROM v_ctsv_remittance_tracking ORDER BY remittance_code;

SELECT 'CONFIRMED_REMITTANCE_ALLOCATION_MISMATCH' AS check_name,
       COUNT(*) AS violation_count FROM v_ctsv_remittance_tracking
WHERE status='CONFIRMED' AND difference_amount<>0
UNION ALL
SELECT 'PAYMENT_ALLOCATED_MORE_THAN_COLLECTED',COUNT(*) FROM (
 SELECT p.id FROM payments p
 JOIN ctsv_remittance_allocations a ON a.payment_id=p.id
 GROUP BY p.id,p.amount HAVING SUM(a.allocated_amount)>p.amount
) bad
UNION ALL
SELECT 'REMITTANCE_ALLOCATION_WRONG_FUND_OR_SEMESTER',COUNT(*)
FROM ctsv_remittance_allocations a
JOIN ctsv_remittances r ON r.id=a.remittance_id
JOIN payments p ON p.id=a.payment_id
JOIN invoices i ON i.id=p.invoice_id
WHERE p.fund_id<>r.fund_id OR i.semester_id<>r.semester_id OR p.fund_id IS NULL;
