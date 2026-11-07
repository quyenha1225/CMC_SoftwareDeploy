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
