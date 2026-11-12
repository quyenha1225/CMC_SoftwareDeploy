-- Add only missing operational links; preserve all original seed rows and files.
-- Addresses below are reservations, not provisioned or deliverable Google mailboxes.
START TRANSACTION;
INSERT INTO grade_sheets(section_id,status)
SELECT cs.id,'DRAFT' FROM course_sections cs
WHERE NOT EXISTS(SELECT 1 FROM grade_sheets gs WHERE gs.section_id=cs.id);

INSERT INTO student_school_mailboxes(student_id,school_email,provisioning_status,note)
SELECT s.id,CONCAT(LOWER(s.student_code),'@student.campus.edu.vn'),'RESERVED',
 'Planned address only. Configure the real school address and provision at the provider before activation.'
FROM students s
WHERE NOT EXISTS(SELECT 1 FROM student_school_mailboxes m WHERE m.student_id=s.id)
AND NOT EXISTS(SELECT 1 FROM student_school_mailboxes m WHERE m.school_email=CONCAT(LOWER(s.student_code),'@student.campus.edu.vn'));
COMMIT;
