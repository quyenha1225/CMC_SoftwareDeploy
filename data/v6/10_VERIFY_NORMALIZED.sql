SET NAMES utf8mb4;
CREATE OR REPLACE VIEW v_normalization_checks AS
SELECT 'SCHEDULE_ROOM_REFERENCE' check_name,COUNT(*) violation_count FROM section_schedules ss
LEFT JOIN rooms r ON r.id=ss.room_id WHERE r.id IS NULL OR ss.room<>r.code
UNION ALL SELECT 'EXAM_CATALOG_REFERENCE',COUNT(*) FROM exam_schedules ex
LEFT JOIN rooms r ON r.id=ex.room_id LEFT JOIN exam_types t ON t.id=ex.exam_type_id
WHERE r.id IS NULL OR t.id IS NULL OR ex.room<>r.code OR ex.exam_type<>t.name
UNION ALL SELECT 'EXAM_TIME_STATUS',COUNT(*) FROM exam_schedules
WHERE ends_at<=starts_at OR DATE(starts_at)<>DATE(ends_at) OR status NOT IN ('DRAFT','PUBLISHED','CANCELLED') OR data_origin NOT IN ('SCHOOL','DEMO')
UNION ALL SELECT 'DEMO_STUDENT_PROFILE_MISSING',COUNT(*) FROM students s JOIN users u ON u.id=s.user_id
WHERE LEFT(s.student_code,4)='DEMO' AND u.username LIKE 'student\_demo\_%'
AND (s.gender IS NULL OR s.nationality IS NULL OR s.phone IS NULL OR s.address IS NULL OR s.guardian_full_name IS NULL OR s.guardian_phone IS NULL)
UNION ALL SELECT 'SECTION_MISSING_GRADE_SHEET',COUNT(*) FROM course_sections cs LEFT JOIN grade_sheets gs ON gs.section_id=cs.id WHERE gs.id IS NULL
UNION ALL SELECT 'ENROLLMENT_DUPLICATE_COURSE',COUNT(*) FROM (
    SELECT e.student_id,cs.semester_id,cs.course_id FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id
    WHERE e.status<>'CANCELLED' GROUP BY e.student_id,cs.semester_id,cs.course_id HAVING COUNT(*)>1
) bad
UNION ALL SELECT 'EXAM_COLLISION',COUNT(*) FROM exam_schedules a JOIN exam_schedules b
ON a.id<b.id AND a.status<>'CANCELLED' AND b.status<>'CANCELLED' AND a.starts_at<b.ends_at AND b.starts_at<a.ends_at
JOIN course_sections ca ON ca.id=a.section_id JOIN course_sections cb ON cb.id=b.section_id
WHERE a.room_id=b.room_id OR a.section_id=b.section_id OR ca.lecturer_id=cb.lecturer_id OR EXISTS(
    SELECT 1 FROM enrollments ea JOIN enrollments eb ON eb.student_id=ea.student_id
    WHERE ea.section_id=a.section_id AND eb.section_id=b.section_id AND ea.status<>'CANCELLED' AND eb.status<>'CANCELLED')
UNION ALL SELECT 'INVOICE_OVERPAID',COUNT(*) FROM v_invoice_balances WHERE paid_amount>payable_amount
UNION ALL SELECT 'REMITTANCE_ALLOCATION_MISMATCH',COUNT(*) FROM v_ctsv_remittance_tracking WHERE status='CONFIRMED' AND difference_amount<>0
UNION ALL SELECT 'ACTIVE_MAILBOX_WITHOUT_DATE',COUNT(*) FROM student_school_mailboxes WHERE provisioning_status='ACTIVE' AND activated_at IS NULL;

SELECT check_name,violation_count FROM v_normalization_checks ORDER BY check_name;
